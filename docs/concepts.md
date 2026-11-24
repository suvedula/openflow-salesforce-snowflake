# Concepts

## OAuth vs JWT
They aren't alternatives. **OAuth 2.0** is the framework that ends with an *access token*.
It has several **flows** (ways to prove who you are before getting the token):

| Flow | Proof | Used for |
|---|---|---|
| Authorization Code | A person logs in and clicks "Allow" | Apps used by people |
| Client Credentials | Client ID + client secret | Many system-to-system APIs |
| **JWT Bearer** | A note **signed with a private key** | System-to-system, no person (this connector) |

That's why Salesforce needs both **Enable OAuth** and **Enable JWT Bearer Flow**.

## Public / private key
- `openssl genpkey` creates the **private key**. `openssl req -x509 -key private.key` **derives** the public cert from it, so the two are linked from creation.
- `public.crt` → uploaded to Salesforce (can only *verify* signatures).
- `private.key` → pasted into Openflow (stored encrypted as a sensitive parameter). It *signs* the JWT.
- Every login: Openflow signs "app X, user Y, valid 3 min" → Salesforce verifies it with the cert in that app → returns an access token.
- The private key never leaves your side, and nothing secret goes over the network.
- After setup the laptop copy isn't needed. Move it to a vault or delete it, and **never commit it**.

## Consumer Key
- OAuth's **Client ID**. Generated when the External Client App is created with OAuth enabled, independently of the certificate.
- It's an *ID*, not a secret. It's useless without the private key's signature.
- The Consumer **Secret** is a secret, but JWT doesn't use it.
- Consumer Key, uploaded cert and pasted private key must all come from **the same app and the same key pair**.

## Network rule + external access integration
Snowflake blocks outbound traffic by default. A network rule is an **allowlist** of `host:port`
(443 = HTTPS). The integration wraps it and is attached to the runtime.

## Openflow layers

| Layer | What | Analogy | Cost |
|---|---|---|---|
| Deployment | Control plane: UI, stores flows, manages runtimes | The building | Always on; can't be suspended |
| Runtime | Compute nodes that execute flows | A machine | Bills while running; can suspend |
| Connector | The job (Salesforce → Snowflake) | The program | – |
| Parameters | Settings (Source / Destination / Ingestion) | Config | – |
| Controller services | Shared helpers (key service, token provider, readers) | Plugins | – |

Scheduling is a connector parameter (**Run Schedule**), not the runtime.
Compared with the code approach: runtime ≈ warehouse, connector ≈ stored procedure, Run Schedule ≈ Snowflake Task.
Unlike a warehouse, a runtime does **not** auto-suspend.

## Role vs service account
- **Role** = a set of permissions. **Service account** = a non-human user that is given a role.
- In this test: no service accounts. Salesforce login = your admin user; Snowflake = the runtime's role.
- In production: a **Salesforce integration user** is required. A **Snowflake service user** (`TYPE = SERVICE`, key-pair) is needed only for BYOC Openflow or external tools (Python, CI/CD).

## Openflow vs code
| | Openflow connector | Python procedure + Task |
|---|---|---|
| Logic lives in | Openflow canvas | GitHub |
| Best for | Sources with prebuilt connectors | Custom APIs with no connector |
| Monitoring | Bulletins, queues, provenance, event table | Build your own log table |
| Cost | Runtime + deployment always on | Only when the task runs |
