# Runtime settings

Openflow → **Runtimes → Create runtime** (after deployment `OPENFLOW_SV` is **Active**)

| Field | Value |
|---|---|
| Deployment | Openflow test (SV) |
| Runtime location | `INGEST_SANDBOX` / `OPENFLOW_CONTROL` |
| Runtime name | `SF_RUNTIME_SV` |
| Node type tier | Small – S1 |
| Min nodes / Max nodes | 1 / 1 (default max is 50 — change it) |
| Execute-as role | `OPENFLOW_SF_RL_SV` |
| Usage / Operate / Monitor roles | leave empty |
| External access integrations | `SALESFORCE_EAI_SV` |

Takes ~5–10 min to become **Active**. Bills the whole time it is Active.
The runtime does not ask for Salesforce credentials — those go in the connector parameters.
