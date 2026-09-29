import os
import voluptuous as vol
from homeassistant import config_entries
from homeassistant.helpers.aiohttp_client import async_get_clientsession
from homeassistant.helpers.selector import (
    SelectSelector,
    SelectSelectorConfig,
    SelectSelectorMode,
    BooleanSelector,
    TextSelector,
)
from .const import (
    DOMAIN,
    CONF_API_TOKEN,
    CONF_ZONE_ID,
    CONF_RECORD_NAME,
    CONF_ENABLE_PROXY,
    CONF_IP_MODE,
    CONF_STATIC_IP,
    CONF_CONFIRM_OVERWRITE,
    IP_MODE_DYNAMIC,
    IP_MODE_STATIC,
)


class CloudflareDynDNSConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    VERSION = 2

    def __init__(self):
        """Initialize the config flow."""
        self.api_token = None
        self.zones = {}
        self._form_data: dict = {}

    async def async_step_user(self, user_input=None):
        """Step 1: Ask for API Token and fetch Zones."""
        errors = {}

        if user_input is not None:
            self.api_token = user_input[CONF_API_TOKEN]
            session = async_get_clientsession(self.hass)

            headers = {
                "Authorization": f"Bearer {self.api_token}",
                "Content-Type": "application/json",
            }

            try:
                # Fetch available zones from Cloudflare
                async with session.get(
                    "https://api.cloudflare.com/client/v4/zones", headers=headers
                ) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        if data.get("success"):
                            # Create a dictionary mapping Zone IDs to Zone Names for the dropdown
                            self.zones = {
                                zone["id"]: zone["name"]
                                for zone in data.get("result", [])
                            }

                            if not self.zones:
                                errors["base"] = "no_zones"
                            else:
                                # Move to step 2 if successful
                                return await self.async_step_zone_selection()
                        else:
                            errors["base"] = "auth_failed"
                    else:
                        errors["base"] = "auth_failed"
            except Exception:
                errors["base"] = "cannot_connect"

        return self.async_show_form(
            step_id="user",
            data_schema=vol.Schema(
                {
                    vol.Required(CONF_API_TOKEN): str,
                }
            ),
            errors=errors,
        )

    async def async_step_zone_selection(self, user_input=None):
        """Step 2: Select Zone from dropdown, enter Record Name, IP mode, and proxy toggle."""
        errors = {}

        if user_input is not None:
            enable_proxy = user_input[CONF_ENABLE_PROXY]

            # Single-entry enforcement: check existing entries
            existing_entries = self.hass.config_entries.async_entries(DOMAIN)
            for entry in existing_entries:
                if entry.data.get(CONF_ENABLE_PROXY, False) and enable_proxy:
                    errors["base"] = "proxy_entry_exists"
                    break
                if not entry.data.get(CONF_ENABLE_PROXY, False) and not enable_proxy:
                    errors["base"] = "nonproxy_entry_exists"
                    break

            if not errors:
                # Store intermediate data for subsequent steps
                self._form_data = {
                    CONF_API_TOKEN: self.api_token,
                    CONF_ZONE_ID: user_input[CONF_ZONE_ID],
                    CONF_RECORD_NAME: user_input[CONF_RECORD_NAME],
                    CONF_IP_MODE: user_input[CONF_IP_MODE],
                    CONF_ENABLE_PROXY: enable_proxy,
                }

                # Branch based on ip_mode
                if user_input[CONF_IP_MODE] == IP_MODE_STATIC:
                    return await self.async_step_static_ip()

                # Dynamic IP mode: check if cert confirmation is needed
                if enable_proxy and os.path.exists("/ssl/fullchain.pem"):
                    return await self.async_step_cert_confirmation()

                # Create entry directly
                return self.async_create_entry(
                    title=self._form_data[CONF_RECORD_NAME], data=self._form_data
                )

        # Build schema with zone dropdown, record name, ip_mode selector, and proxy toggle
        schema = vol.Schema(
            {
                vol.Required(CONF_ZONE_ID): vol.In(self.zones),
                vol.Required(CONF_RECORD_NAME): str,
                vol.Required(CONF_IP_MODE, default=IP_MODE_DYNAMIC): SelectSelector(
                    SelectSelectorConfig(
                        options=[
                            {"value": IP_MODE_DYNAMIC, "label": "Dynamic"},
                            {"value": IP_MODE_STATIC, "label": "Static"},
                        ],
                        mode=SelectSelectorMode.DROPDOWN,
                    )
                ),
                vol.Required(CONF_ENABLE_PROXY, default=False): BooleanSelector(),
            }
        )

        return self.async_show_form(
            step_id="zone_selection",
            data_schema=schema,
            errors=errors,
        )

    async def async_step_static_ip(self, user_input=None):
        """Step 3 (conditional): Collect static IP address."""
        errors = {}

        if user_input is not None:
            self._form_data[CONF_STATIC_IP] = user_input[CONF_STATIC_IP]

            # Check if cert confirmation is needed
            if self._form_data[CONF_ENABLE_PROXY] and os.path.exists(
                "/ssl/fullchain.pem"
            ):
                return await self.async_step_cert_confirmation()

            # Create entry directly
            return self.async_create_entry(
                title=self._form_data[CONF_RECORD_NAME], data=self._form_data
            )

        schema = vol.Schema(
            {
                vol.Required(CONF_STATIC_IP): TextSelector(),
            }
        )

        return self.async_show_form(
            step_id="static_ip",
            data_schema=schema,
            errors=errors,
        )

    async def async_step_cert_confirmation(self, user_input=None):
        """Step 4 (conditional): Confirm overwriting existing SSL certificate."""
        errors = {}

        if user_input is not None:
            if user_input.get(CONF_CONFIRM_OVERWRITE):
                return self.async_create_entry(
                    title=self._form_data[CONF_RECORD_NAME], data=self._form_data
                )
            else:
                errors["base"] = "confirm_required"

        schema = vol.Schema(
            {
                vol.Required(CONF_CONFIRM_OVERWRITE): BooleanSelector(),
            }
        )

        return self.async_show_form(
            step_id="cert_confirmation",
            data_schema=schema,
            errors=errors,
        )
