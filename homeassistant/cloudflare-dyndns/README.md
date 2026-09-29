# Cloudflare DynDNS v2.0

A Home Assistant custom integration that keeps Cloudflare DNS A records in sync with your network's IP address. Supports a two-record model: one proxied external record (with automated Origin CA TLS) and one non-proxied internal record.

## Features

- Automatic public IP detection and DNS record updates (every 5 minutes)
- Cloudflare proxy (orange cloud) toggle per entry
- Automated TLS certificate provisioning via Cloudflare Origin CA when proxy is enabled
- Configurable IP mode: dynamic (auto-detect public IP) or static (manual IP)
- Strict two-record model enforcement: one proxied entry, one non-proxied entry

## Prerequisites

- A Cloudflare account with at least one zone (domain)
- A Cloudflare API token with the required permissions (see below)

## Creating the Cloudflare API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Create Custom Token"
4. Set the following permissions:
   - **Zone : Zone : Read** (all zones)
   - **Zone : DNS : Edit** (all zones)
   - **Account : SSL and Certificates : Write**
5. Click "Continue to summary" and "Create Token"
6. Copy the token value — you will need it during setup

The "SSL and Certificates: Write" permission is required for the Origin CA certificate provisioning when proxy is enabled.

## Setup Guide

### External Record (proxy on, dynamic IP)

This record is for accessing Home Assistant from the internet. Cloudflare's proxy hides your home IP.

1. In Home Assistant, go to Settings > Devices & Services > Add Integration
2. Search for "Cloudflare DynDNS"
3. Enter your Cloudflare API token
4. Select your domain (zone)
5. Enter the external record name (e.g., `ext-ha.yourdomain.com`)
6. Set IP Mode to **Dynamic**
7. Enable **Cloudflare Proxy**
8. If an existing certificate is detected at `/ssl/fullchain.pem`, confirm overwrite
9. The integration will create the DNS record and provision an Origin CA certificate

### Internal Record (proxy off, static IP)

This record is for LAN access via a static IP. The DNS record is managed in Cloudflare but not proxied.

1. In Home Assistant, go to Settings > Devices & Services > Add Integration
2. Search for "Cloudflare DynDNS"
3. Enter your Cloudflare API token
4. Select your domain (zone)
5. Enter the internal record name (e.g., `ha.yourdomain.com`)
6. Set IP Mode to **Static**
7. Enter your Home Assistant's LAN IP (e.g., `192.168.1.11`)
8. Leave **Cloudflare Proxy** disabled
9. The integration will create/update the DNS A record with your static IP

### Cloudflare Dashboard: SSL/TLS Mode

After the external (proxied) entry is set up:

1. Go to the Cloudflare dashboard for your domain
2. Navigate to SSL/TLS > Overview
3. Set the encryption mode to **Full (Strict)**

This ensures Cloudflare validates the Origin CA certificate on the connection back to your Home Assistant instance.

### Restart Home Assistant

After the first proxy-on setup, restart Home Assistant to activate HTTPS using the newly provisioned certificate. The integration fires a persistent notification reminding you to do this.

## How It Works

- **Dynamic IP mode**: The integration queries `api64.ipify.org` every 5 minutes to detect your public IP and updates the Cloudflare DNS record if it changes.
- **Static IP mode**: The integration sets the DNS record to the configured static IP address. It still checks every 5 minutes in case the record was changed externally.
- **Proxy enabled**: The DNS record is set to proxied (orange cloud). On first setup, a private key and CSR are generated, an Origin CA certificate is requested from Cloudflare (valid for 15 years), and both are written to `/ssl/fullchain.pem` and `/ssl/privkey.pem`.
- **Proxy disabled**: The DNS record is set to DNS-only (grey cloud). No certificate operations are performed.

## Limitations

- Only one proxied entry and one non-proxied entry are allowed
- The Origin CA certificate is only valid when accessed through Cloudflare's proxy (not directly)
- Internal DNS resolution (e.g., via Pi-hole) must be configured separately
- The integration does not restart Home Assistant automatically after certificate provisioning
