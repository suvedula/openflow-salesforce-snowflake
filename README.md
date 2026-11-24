# Openflow: Salesforce → Snowflake

Replicate Salesforce **Account, Contact, Lead, Opportunity** into Snowflake with the
**Openflow connector for Salesforce Bulk API**: OAuth 2.0 JWT authentication, incremental
loads every 15 minutes, bronze tables plus silver views. Tested end to end.

```
Salesforce ──(OAuth 2.0 JWT Bearer)──► Openflow runtime ──(SNOWFLAKE_MANAGED)──► INGEST_SANDBOX
                                                                                   ├─ BRONZE_SALESFORCE_TEST  (connector-created tables)
                                                                                   └─ SILVER_SALESFORCE_TEST  (clean views)
```

📖 **Full step-by-step of what I did, what I saw, and what broke: [docs/walkthrough.md](docs/walkthrough.md)**

## Quick start

| # | Do | Where | Detail |
|---|---|---|---|
| 1 | Create a Developer org, note username + My Domain, **make sure it has records** | Salesforce | [salesforce/external_client_app.md](salesforce/external_client_app.md) |
| 2 | `bash scripts/make_keys.sh` | Git Bash | creates `keys/private.key` + `keys/public.crt` |
| 3 | External Client App: OAuth + JWT Bearer, upload `public.crt`, policies, copy Consumer Key | Salesforce | [salesforce/external_client_app.md](salesforce/external_client_app.md) |
| 4 | Replace `<SF_MY_DOMAIN>` in `RUN_ALL.sql` → Run All → wait for deployment **ACTIVE** → log out and back in | Snowsight | [RUN_ALL.sql](RUN_ALL.sql) |
| 5 | Create runtime `SF_RUNTIME_SV` | Openflow | [openflow/runtime.md](openflow/runtime.md) |
| 6 | Install the Salesforce Bulk API connector on it | Openflow | – |
| 7 | Fill Source / Destination / Ingestion parameters | Openflow | [openflow/parameters.md](openflow/parameters.md) |
| 8 | Enable controller services in order, verify JWT | Openflow | [openflow/controller_services.md](openflow/controller_services.md) |
| 9 | Enable all controller services → **Start** | Openflow | – |
| 10 | Verify, then create silver views | Snowsight | [snowflake/03_verify](snowflake/03_verify/verify.sql), [snowflake/02_views](snowflake/02_views/silver_views.sql) |
| 11 | **Suspend the runtime / tear down** | Openflow + Snowsight | [snowflake/05_pause](snowflake/05_pause/pause.sql), [snowflake/99_teardown](snowflake/99_teardown/teardown.sql) |

## Repo layout

| Path | What |
|---|---|
| `RUN_ALL.sql` | Snowflake setup in one paste (01_setup files combined) |
| `snowflake/01_setup/` | Roles + warehouse · schemas · network rule + integration · deployment |
| `snowflake/02_views/` | Silver views (clean columns, no deleted rows, joins) |
| `snowflake/03_verify/` | Row counts, freshness/watermark, samples |
| `snowflake/04_monitoring/` | Real errors (noise filtered) · connector queries · costs |
| `snowflake/05_pause/` | Stop costs, keep setup |
| `snowflake/99_teardown/` | Remove everything (zero cost) |
| `openflow/` | Runtime settings · parameter values · controller service order |
| `salesforce/` | Org, data, External Client App settings |
| `scripts/make_keys.sh` | JWT key pair → `keys/` (git-ignored) |
| `scripts/render_sql.sh` | Fills `<SF_MY_DOMAIN>` into the SQL → `build/` |
| `.github/workflows/deploy.yml` | Optional: deploy setup + views from GitHub (manual trigger) |
| `docs/` | Walkthrough · concepts · troubleshooting · lessons learned |

The ingestion logic isn't code. It's the Openflow connector, configured in the UI.
The repo holds the Snowflake objects around it and documents the UI configuration.

## Docs
- [Walkthrough](docs/walkthrough.md): every step as performed
- [Concepts](docs/concepts.md): OAuth vs JWT, key pair, Consumer Key, deployment vs runtime vs connector, role vs service account, Openflow vs code
- [Troubleshooting](docs/troubleshooting.md): symptoms → causes → fixes
- [Lessons learned](docs/lessons-learned.md)

## Cost
| Piece | Bills | Stop |
|---|---|---|
| Runtime | Whole time it's Active | Suspend or delete (UI) |
| Deployment | Continuously, **can't be suspended** | Drop (after deleting the runtime) |
| Warehouse | Only while queries run | Auto-suspends |

## Security
- `.gitignore` blocks `keys/`, `*.key`, `*.crt`, `.env`. **Never commit the private key or passphrase.**
- Real domains, usernames, Consumer Keys and account identifiers are `<PLACEHOLDERS>`.
- The private key lives in Openflow (encrypted sensitive parameter). Keep a backup in a password manager or vault, not in Git.
- Production: dedicated read-only Salesforce integration user, vaulted keys, yearly certificate renewal owner.
