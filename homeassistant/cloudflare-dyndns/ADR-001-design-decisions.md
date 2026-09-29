# ADR-001: Cloudflare DynDNS v2.0 Design Decisions

## Status
Accepted

## Context

The existing `cloudflare_dyndns` integration hardcodes `proxied: False` and has no SSL support. The operator wants to extend it with Cloudflare proxy, automated TLS, and a two-record model for external and internal access. Decisions below were reached through a structured design review.

---

## Decisions

### ADR-001-1: Cloudflare Proxy Enabled on External Record

**Decision:** Enable Cloudflare proxy (`proxied: True`) on the external record.

**Reasoning:** Hides the home public IP behind Cloudflare's edge. Provides free HTTPS on the browser→CF leg automatically. Accepted tradeoff: Cloudflare terminates and re-encrypts (not end-to-end in the cryptographic sense), which is acceptable for a home assistant use case.

---

### ADR-001-2: SSL via Cloudflare Origin CA, Not Let's Encrypt

**Decision:** Use Cloudflare Origin CA certificates for the CF→HA leg. Let's Encrypt is not used.

**Reasoning:** Origin CA certs are valid for 15 years, require no renewal automation, and are trusted by Cloudflare's proxy in Full (Strict) mode. The added complexity of ACME/Let's Encrypt is not justified. The operator sets Cloudflare SSL mode to Full (Strict) in the dashboard manually.

---

### ADR-001-3: Certificate Provisioned Automatically by the Integration

**Decision:** When proxy is enabled, the integration generates a private key and CSR, calls the Cloudflare Origin CA API, and writes the cert and key to `/ssl/fullchain.pem` and `/ssl/privkey.pem`.

**Reasoning:** Keeps the setup fully self-contained. The operator does not need to touch the cert files manually. A persistent HA notification is fired after cert write instructing the user to restart HA — the integration does not trigger the restart automatically.

---

### ADR-001-4: Confirmation Step Before Overwriting Existing Certificate

**Decision:** If `/ssl/fullchain.pem` already exists at setup time, the config flow pauses with a confirmation step warning the user before overwriting.

**Reasoning:** Overwriting a valid cert is destructive. The operator must explicitly acknowledge this before the integration proceeds.

---

### ADR-001-5: Two-Record Model, One Entry Per Type

**Decision:** The integration supports exactly two config entries: one proxied external record and one non-proxied internal record. A second proxied or second non-proxied entry is rejected in the config flow.

**Reasoning:** The integration is not a general DNS manager. A strict two-entry model avoids cert conflicts (only one `/ssl/fullchain.pem` exists in HA OS), keeps scope narrow, and matches the operator's stated use case. The two intended records are `ext-ha.bagend.lynggaardjensen.com` (external, proxied) and `ha.bagend.lynggaardjensen.com` (internal, non-proxied).

---

### ADR-001-6: Configurable IP Mode (Dynamic vs Static)

**Decision:** The config flow exposes an explicit IP mode dropdown — Dynamic (auto-detect public IP) and Static (manual entry). These are independent of the proxy toggle.

**Reasoning:** Coupling IP mode to proxy state would be an implicit assumption. The internal record uses a static LAN IP (`192.168.1.11`) and proxy off. The external record uses dynamic IP detection and proxy on. Keeping them independent avoids surprising behavior if the configuration intent changes.

---

### ADR-001-7: Proxy Toggle is User-Configurable, Not Hardcoded

**Decision:** `enable_proxy` is a boolean field in the config flow rather than a hardcoded value.

**Reasoning:** Allows the operator to configure the non-proxied internal record using the same integration without a code change. The field includes helper text explaining that proxy is required for SSL.

---

### ADR-001-8: Per-Hostname Cert, Not Wildcard

**Decision:** The Origin CA cert is issued for the specific external hostname, not a wildcard.

**Reasoning:** The two-entry enforcement (ADR-001-5) means only one proxied entry can ever exist, so cert conflicts across entries cannot occur. A wildcard is unnecessary complexity.

---

### ADR-001-9: Version Bumped to 2.0.0

**Decision:** `manifest.json` version is set to `2.0.0` and `cryptography` is added to `requirements`.

**Reasoning:** The config entry schema gains required new fields (`enable_proxy`, `ip_mode`, `static_ip`). Existing entries are incompatible and must be removed and re-added. The `cryptography` library is used for CSR generation and must be declared as a dependency.

---

### ADR-001-10: Internal DNS Resolution Out of Scope

**Decision:** The integration does not configure internal DNS resolution for the `ha.` record. Pi-hole handles `ha.bagend.lynggaardjensen.com` → `192.168.1.11` separately.

**Reasoning:** HA integrations should not reach into network infrastructure. The integration creates the public DNS record; the operator configures Pi-hole independently.
