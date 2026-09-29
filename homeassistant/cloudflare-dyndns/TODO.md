# Cloudflare DynDNS v2.0 — TODO

## Context for the Developer

The integration lives on a Home Assistant OS server. SSH access:
- Host: `192.168.1.11`, port `2222`
- Key: `~/.ssh/home-assistant`
- User: `root`
- Integration path: `/homeassistant/custom_components/cloudflare_dyndns/`

Read the existing source before writing anything:
```
ssh -i ~/.ssh/home-assistant -p 2222 root@192.168.1.11 \
  "cat /homeassistant/custom_components/cloudflare_dyndns/__init__.py"
```
Repeat for `config_flow.py`, `const.py`, `strings.json`, `manifest.json`.

The full design intent and rationale is in `ADR-001-design-decisions.md`. The PRD describes the overall purpose. This TODO is the actionable checklist.

---

## Known HA Config Flow Constraint

Voluptuous schemas in a single config flow step cannot conditionally show or hide fields based on another field's value in the same step. To show a `static_ip` text field only when `ip_mode=static` is selected, split the flow into a separate step:

- `async_step_zone_selection`: zone, record name, ip_mode, enable_proxy
- `async_step_static_ip`: shown only when ip_mode=static; collects the static IP address
- `async_step_cert_confirmation`: shown only when enable_proxy=True and `/ssl/fullchain.pem` exists

Branch logic goes in `async_step_zone_selection`'s `user_input` handler.

---

## const.py
- [ ] Add `CONF_ENABLE_PROXY = "enable_proxy"`
- [ ] Add `CONF_IP_MODE = "ip_mode"`
- [ ] Add `CONF_STATIC_IP = "static_ip"`
- [ ] Add `CONF_CONFIRM_OVERWRITE = "confirm_overwrite"`
- [ ] Add `IP_MODE_DYNAMIC = "dynamic"` and `IP_MODE_STATIC = "static"`

---

## config_flow.py
- [ ] In `async_step_zone_selection`: add `ip_mode` selector (use `homeassistant.helpers.selector.SelectSelector` with options `dynamic`/`static`)
- [ ] In `async_step_zone_selection`: add `enable_proxy` boolean selector with description key referencing `strings.json`
- [ ] In `async_step_zone_selection` user_input handler: if `ip_mode=static` → call `async_step_static_ip`; else proceed to cert confirmation check or entry creation
- [ ] Add `async_step_static_ip`: single text field for `static_ip`; on submit proceed to cert confirmation check or entry creation
- [ ] Add single-entry enforcement in `async_step_user` or `async_step_zone_selection`: iterate `self.hass.config_entries.async_entries(DOMAIN)`; if a proxied entry already exists and new entry is proxied → `errors["base"] = "proxy_entry_exists"`; same for non-proxied → `errors["base"] = "nonproxy_entry_exists"`
- [ ] Add `async_step_cert_confirmation`: shown only when `enable_proxy=True` and `os.path.exists("/ssl/fullchain.pem")`; schema has single boolean `confirm_overwrite` (required, must be True to proceed); on valid submit → create entry
- [ ] Store intermediate data across steps in `self._form_data: dict` on the flow instance

---

## __init__.py
- [ ] Read `CONF_ENABLE_PROXY`, `CONF_IP_MODE`, `CONF_STATIC_IP` from `entry.data`
- [ ] In `update_cloudflare`: when `ip_mode=static` skip `api64.ipify.org` fetch and use `static_ip` directly
- [ ] In DNS payload: set `"proxied": entry.data[CONF_ENABLE_PROXY]`
- [ ] In `async_setup_entry`: when `enable_proxy=True` call `await async_issue_origin_ca_cert(hass, session, api_token, record_name)`
- [ ] Implement `async_issue_origin_ca_cert(hass, session, api_token, record_name)`:
  - [ ] Generate 2048-bit RSA private key:
    ```python
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.x509.oid import NameOID
    from cryptography import x509
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    ```
  - [ ] Build and sign CSR:
    ```python
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, record_name)]))
        .add_extension(x509.SubjectAlternativeName([x509.DNSName(record_name)]), critical=False)
        .sign(key, hashes.SHA256())
    )
    csr_pem = csr.public_bytes(serialization.Encoding.PEM).decode()
    ```
  - [ ] POST to Cloudflare Origin CA API:
    ```
    POST https://api.cloudflare.com/client/v4/certificates
    Authorization: Bearer <api_token>
    Content-Type: application/json

    {
      "csr": "<pem string>",
      "hostnames": ["<record_name>"],
      "request_type": "origin-rsa",
      "requested_validity": 5475
    }
    ```
    `requested_validity` is days (5475 = 15 years). Response `result.certificate` is the cert PEM.
  - [ ] Write cert: `open("/ssl/fullchain.pem", "w").write(result["certificate"])`
  - [ ] Write key:
    ```python
    key_pem = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption()
    )
    open("/ssl/privkey.pem", "wb").write(key_pem)
    ```
  - [ ] Fire persistent notification:
    ```python
    await hass.services.async_call("persistent_notification", "create", {
        "title": "Cloudflare DynDNS",
        "message": "Origin CA certificate installed. Restart Home Assistant to enable HTTPS.",
        "notification_id": "cloudflare_dyndns_cert"
    })
    ```
  - [ ] Add code comment: cert write only runs on initial setup when proxy is enabled; overwrite of existing cert is intentional and gated by the confirmation step in the config flow
- [ ] Do not touch `/ssl/` when `enable_proxy=False`

---

## strings.json
- [ ] Add to `zone_selection` step data:
  - `ip_mode`: "IP Mode"
  - `enable_proxy`: "Enable Cloudflare Proxy"
- [ ] Add `enable_proxy` field description: `"Enables Cloudflare's orange-cloud proxy. Required for SSL. Without this, the integration only manages your DNS record."`
- [ ] Add `static_ip` step: title "Internal IP Address", data field `static_ip`: "Static IP Address"
- [ ] Add `cert_confirmation` step: title "Certificate Already Exists", description "A certificate already exists at /ssl/fullchain.pem. Continuing will replace it.", data field `confirm_overwrite`: "I understand, replace the existing certificate"
- [ ] Add error keys: `proxy_entry_exists`, `nonproxy_entry_exists`

---

## manifest.json
- [ ] Bump `version` to `"2.0.0"`
- [ ] Add `"cryptography"` to `requirements` array

---

## README.md (new file)
- [ ] Overview section: what the integration does
- [ ] How-To section:
  - [ ] Step-by-step Cloudflare API token creation with required permissions:
    - Zone: Zone: Read (all zones)
    - Zone: DNS: Edit (all zones)
    - Account: SSL and Certificates: Write
  - [ ] Guide for setting up the external record (proxy on, dynamic IP)
  - [ ] Guide for setting up the internal record (proxy off, static IP)
  - [ ] Cloudflare dashboard: set SSL/TLS mode to Full (Strict)
  - [ ] Restart HA after first proxy-on setup to activate HTTPS

---

## Deployment
- [ ] Copy updated files to the server:
  ```
  scp -i ~/.ssh/home-assistant -P 2222 \
    __init__.py config_flow.py const.py strings.json manifest.json README.md \
    root@192.168.1.11:/homeassistant/custom_components/cloudflare_dyndns/
  ```
- [ ] In HA UI (Settings → Integrations): remove both existing Cloudflare DynDNS entries
- [ ] Re-add entry 1: `ext-ha.bagend.lynggaardjensen.com`, proxy on, dynamic IP
- [ ] Re-add entry 2: `ha.bagend.lynggaardjensen.com`, proxy off, static IP `192.168.1.11`
- [ ] Restart HA after cert is written (prompted by persistent notification)
- [ ] Verify HTTPS is live on `https://ext-ha.bagend.lynggaardjensen.com`
- [ ] Configure Pi-hole: add DNS record `ha.bagend.lynggaardjensen.com` → `192.168.1.11`
