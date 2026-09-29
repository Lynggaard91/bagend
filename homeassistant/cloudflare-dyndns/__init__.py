import logging
import asyncio
from datetime import timedelta
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.event import async_track_time_interval
from homeassistant.helpers.aiohttp_client import async_get_clientsession

from .const import (
    DOMAIN,
    CONF_API_TOKEN,
    CONF_ZONE_ID,
    CONF_RECORD_NAME,
    CONF_ENABLE_PROXY,
    CONF_IP_MODE,
    CONF_STATIC_IP,
    IP_MODE_STATIC,
)

_LOGGER = logging.getLogger(__name__)


async def async_issue_origin_ca_cert(hass, session, api_token, record_name):
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.x509.oid import NameOID
    from cryptography import x509
    import os

    cert_path = hass.config.path("ssl", "fullchain.pem")

    def _cert_valid_for_host():
        if not os.path.exists(cert_path):
            return False
        try:
            data = open(cert_path, "rb").read()
            cert = x509.load_pem_x509_certificate(data)
            san = cert.extensions.get_extension_for_class(x509.SubjectAlternativeName)
            return record_name in san.value.get_values_for_type(x509.DNSName)
        except Exception:
            return False

    already_valid = await hass.async_add_executor_job(_cert_valid_for_host)
    if already_valid:
        _LOGGER.debug("Origin CA cert for %s already exists, skipping issuance", record_name)
        return

    # Generate 2048-bit RSA private key
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)

    # Build and sign CSR
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(
            x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, record_name)])
        )
        .add_extension(
            x509.SubjectAlternativeName([x509.DNSName(record_name)]), critical=False
        )
        .sign(key, hashes.SHA256())
    )
    csr_pem = csr.public_bytes(serialization.Encoding.PEM).decode()

    # POST to Cloudflare Origin CA API
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json",
    }
    payload = {
        "csr": csr_pem,
        "hostnames": [record_name],
        "request_type": "origin-rsa",
        "requested_validity": 5475,
    }

    async with session.post(
        "https://api.cloudflare.com/client/v4/certificates",
        headers=headers,
        json=payload,
    ) as resp:
        if resp.status == 401:
            _LOGGER.error(
                "Origin CA request unauthorized (401) — ensure the API token has "
                "'Zone > SSL and Certificates > Edit' permission"
            )
            return
        if resp.content_type != "application/json":
            text = await resp.text()
            _LOGGER.error("Unexpected response from Cloudflare (%s): %s", resp.status, text)
            return
        data = await resp.json()

    if not data.get("success"):
        _LOGGER.error("Failed to issue Origin CA certificate: %s", data)
        return

    certificate = data["result"]["certificate"]

    key_pem = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption(),
    )

    import os

    def _write_certs():
        ssl_dir = hass.config.path("ssl")
        os.makedirs(ssl_dir, exist_ok=True)
        with open(os.path.join(ssl_dir, "fullchain.pem"), "w") as f:
            f.write(certificate)
        with open(os.path.join(ssl_dir, "privkey.pem"), "wb") as f:
            f.write(key_pem)

    await hass.async_add_executor_job(_write_certs)

    await hass.services.async_call(
        "persistent_notification",
        "create",
        {
            "title": "Cloudflare DynDNS",
            "message": (
                "Origin CA certificate installed to /config/ssl/. "
                "Ensure configuration.yaml points ssl_certificate and ssl_key there, "
                "then restart Home Assistant to enable HTTPS."
            ),
            "notification_id": "cloudflare_dyndns_cert",
        },
    )

    _LOGGER.info("Origin CA certificate issued and written to %s for %s", hass.config.path("ssl"), record_name)


async def async_migrate_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Migrate v1 config entries to v2 by injecting defaults for new fields."""
    if entry.version == 1:
        new_data = {**entry.data}
        new_data.setdefault(CONF_ENABLE_PROXY, False)
        new_data.setdefault(CONF_IP_MODE, "dynamic")
        hass.config_entries.async_update_entry(entry, data=new_data, version=2)
        _LOGGER.info("Migrated cloudflare_dyndns entry %s to version 2", entry.title)
    return True


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    hass.data.setdefault(DOMAIN, {})

    api_token = entry.data[CONF_API_TOKEN]
    zone_id = entry.data[CONF_ZONE_ID]
    record_name = entry.data[CONF_RECORD_NAME]
    enable_proxy = entry.data.get(CONF_ENABLE_PROXY, False)
    ip_mode = entry.data.get(CONF_IP_MODE, "dynamic")
    static_ip = entry.data.get(CONF_STATIC_IP)
    session = async_get_clientsession(hass)

    # Issue Origin CA certificate when proxy is enabled
    if enable_proxy:
        await async_issue_origin_ca_cert(hass, session, api_token, record_name)

    async def update_cloudflare(now=None):
        try:
            # 1. Determine IP address based on mode
            if ip_mode == IP_MODE_STATIC:
                public_ip = static_ip
            else:
                # Fetch current public IP
                async with session.get("https://api64.ipify.org") as resp:
                    public_ip = await resp.text()

            headers = {
                "Authorization": f"Bearer {api_token}",
                "Content-Type": "application/json",
            }

            # 2. Check if the DNS record already exists
            search_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?name={record_name}&type=A"
            async with session.get(search_url, headers=headers) as resp:
                cf_data = await resp.json()

            if not cf_data.get("success"):
                _LOGGER.error("Failed to authenticate with Cloudflare.")
                return

            results = cf_data.get("result", [])

            payload = {
                "content": public_ip,
                "name": record_name,
                "proxied": enable_proxy,
                "type": "A",
            }

            # 3. Create or Update Record
            if len(results) == 0:
                # Record does not exist, create it
                create_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
                async with session.post(
                    create_url, headers=headers, json=payload
                ) as resp:
                    data = await resp.json()
                    if data.get("success"):
                        _LOGGER.info(
                            f"Created new A-record for {record_name} -> {public_ip}"
                        )
                    else:
                        _LOGGER.error(f"Failed to create record: {data}")
            else:
                # Record exists, check if IP changed
                record_id = results[0]["id"]
                current_ip = results[0]["content"]

                if public_ip != current_ip:
                    update_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"
                    async with session.put(
                        update_url, headers=headers, json=payload
                    ) as resp:
                        data = await resp.json()
                        if data.get("success"):
                            _LOGGER.info(
                                f"Updated {record_name} from {current_ip} to {public_ip}"
                            )
                        else:
                            _LOGGER.error(f"Failed to update record: {data}")

        except Exception as e:
            _LOGGER.error(f"Cloudflare DynDNS encountered an error: {e}")

    # Run the check immediately on startup
    hass.async_create_task(update_cloudflare())

    # Schedule the check to run every 5 minutes
    entry.async_on_unload(
        async_track_time_interval(hass, update_cloudflare, timedelta(minutes=5))
    )

    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Unload a config entry."""
    return True
