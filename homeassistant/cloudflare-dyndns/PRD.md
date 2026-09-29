# Cloudflare DynDNS Integration — PRD v2.0

## Purpose

The `cloudflare_dyndns` integration keeps a Cloudflare DNS A record in sync with the home network's dynamic public IP address, enabling reliable external access to a Home Assistant instance without a static IP. It runs as a Home Assistant OS custom integration and updates the record on a 5-minute interval.

The v2.0 scope extends this to support Cloudflare proxy (orange cloud) with automated TLS certificate provisioning, a configurable IP mode for static LAN records, and a strict two-record model covering both external and internal access patterns.

---

## Goals

- Maintain a Cloudflare A record that tracks the home public IP (dynamic mode)
- Support static IP records for internal LAN hostnames
- Enable Cloudflare proxy on the external record to provide HTTPS without manual certificate management
- Automatically provision a Cloudflare Origin CA certificate when proxy is enabled
- Enforce a clear two-entry model: one proxied external record, one non-proxied internal record

## Non-Goals

- General-purpose Cloudflare DNS management
- Let's Encrypt / ACME certificate lifecycle
- Automatic Home Assistant restarts
- Internal LAN DNS resolution (handled by Pi-hole, out of scope)
- Support for record types other than A

---

## Users

Single-user home lab setup. The operator is the same person who configures and maintains the integration.

---

## User Stories

- As a user, I want my Home Assistant to be reachable externally over HTTPS without managing certificates manually
- As a user, I want my Home Assistant to be reachable internally via a clean hostname without leaving my network
- As a user, I want the integration to tell me when action is required (e.g. restart) rather than acting on my behalf
- As a user, I want to be warned before the integration overwrites an existing certificate

---

## API Token Requirements

The Cloudflare API token requires:
- Zone: Zone: Read (all zones)
- Zone: DNS: Edit (all zones)
- Account: SSL and Certificates: Write

Full setup guide in README.md under the How-To section.

---

## Version

`2.0.0` — breaking config change; existing entries must be removed and re-added.
