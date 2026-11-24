# Salesforce setup

## Org
- developer.salesforce.com/signup → activation email → set password. You are **System Administrator**.
- Username is auto-generated (e.g. `name.xxxx@agentforce.com`) — it's the **OAuth2 Subject**.
- **My Domain**: Setup → Quick Find *My Domain* → Current My Domain URL (use without https://).

## Data
New Agentforce developer orgs can be **empty**. Check with list view **All …** (not *Recently Viewed*):
App Launcher → Accounts / Contacts / Leads / Opportunities. Create a few records if empty
(e.g. Account `Tennis Incorporated`, Contact with that Account).

## External Client App
Setup → Quick Find **External Client App Manager** → **New External Client App**

| Field | Value |
|---|---|
| Name | `Snowflake Openflow Test` |
| Contact Email | your real email (not the @agentforce username) |
| Distribution State | Local |
| Enable OAuth | ✔ |
| Callback URL | `https://login.salesforce.com/services/oauth2/callback` (required, unused by JWT) |
| OAuth Scopes | **Manage user data via APIs (api)**, **Perform requests at any time (refresh_token, offline_access)** |
| Enable JWT Bearer Flow | ✔ + upload `public.crt` |

**Policies → Edit**
| Setting | Value |
|---|---|
| Permitted Users | Admin approved users are pre-authorized |
| Select Profiles | System Administrator |
| IP Relaxation | Relax IP restrictions (else `401 INVALID_SESSION_ID`) |

**Settings → OAuth Settings → Consumer Key and Secret** (may email a code) → copy **Consumer Key**.
Consumer Secret is not used by JWT.

## Useful Setup pages for debugging
- *Login History* — OAuth logins by the user (success / failure reason)
- *System Overview* — API requests last 24h
- *Bulk Data Load Jobs* — mostly ingest jobs; Bulk API 2.0 query jobs may not appear
