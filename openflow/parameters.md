# Connector parameters

Openflow canvas → **⌄ next to your name → Parameter Contexts**. Three contexts:

- **Salesforce Bulk API Source Parameters** – Salesforce login
- **Salesforce Bulk API Destination Parameters** – Snowflake target
- **Salesforce Bulk API Ingestion Parameters** – what/when (inherits the other two)

For each: **⋮ → Edit → value → OK**, then **Apply**.
Rows with **↴** are inherited — edit them in their own context.
*Show inherited parameters* is a view filter only. Grey **Apply** = nothing changed.

## Source
| Parameter | Value |
|---|---|
| Salesforce Instance | `<SF_MY_DOMAIN>` (no https://) |
| Connected App Key | full contents of `private.key` incl. `-----BEGIN/END ENCRYPTED PRIVATE KEY-----` |
| Connected App Key File | **No value set** (never "Empty string set") |
| Connected App Key Password | key passphrase |
| OAuth2 Client ID | Consumer Key |
| OAuth2 Subject | Salesforce username |
| OAuth2 Audience | `https://login.salesforce.com` |
| OAuth2 Token Endpoint URL | `https://<SF_MY_DOMAIN>/services/oauth2/token` |

## Destination
| Parameter | Value |
|---|---|
| Destination Database | `INGEST_SANDBOX` |
| Destination Schema | `BRONZE_SALESFORCE_TEST` |
| Snowflake Authentication Strategy | `SNOWFLAKE_MANAGED` |
| Snowflake Role | `OPENFLOW_SF_RL_SV` |
| Snowflake Warehouse | `OPENFLOW_WH_SV` |

## Ingestion
| Parameter | Value |
|---|---|
| Filter | `Account, Contact, Opportunity, Lead` |
| Incremental Offload | `true` |
| Initial Load Chunking | `NONE` |
| Run Schedule | `15 min` |
| Enable Journal Tables | `false` |
| Others (Column Removal Strategy, Destination Table Type, Blob/Merge Metrics/Views) | defaults |

Filter = comma list or regex, case-insensitive. **Empty = every object** (thousands) — never leave empty.
Objects can be added while running; they replicate on the next run.
