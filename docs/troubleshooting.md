# Troubleshooting

Debug order: **canvas → controller services → event table → query history → Salesforce**.

| Symptom | Cause / fix |
|---|---|
| Can't open Openflow, "Invalid consent request" / "TOTP Invalid" | Default role is ACCOUNTADMIN. Set a non-admin default role and log out and back in. |
| `invalid_grant` on Verify | JWT Bearer Flow not enabled, wrong Consumer Key or username, or the profile isn't pre-authorized |
| `401 INVALID_SESSION_ID` | IP Relaxation not set to "Relax IP restrictions" |
| Private Key Service invalid | Wrong passphrase, BEGIN/END lines missing, or Key File not "No value set" |
| "Private Key not configured" with Key File `#{Snowflake Private Key File}` | You opened the **Snowflake** Private Key Service (same type name). Expected to be invalid; open the **Salesforce** one. |
| No *Enable* in a service's ⋮ menu | It's Invalid. Enable its dependencies first. |
| No *Verify* in the ⋮ menu | It's inside **⋮ → Edit → Properties → ✓** |
| Integration missing from the runtime dropdown | Grant usage to both roles, refresh the page, pick the execute-as role first |
| Right-click menu has no *Parameters* | You clicked the empty canvas. Right-click the process group box. |
| Tables created but 0 rows, no errors | **The Salesforce org has no records** (check list view *All …*) |
| Many ERRORs from `snowflake-jdbc-ec2-imds-probe` | Harmless noise (JDBC checking for AWS EC2). Filter it out. |
| Events table has many rows but data tables are empty | The events table is runtime logs/metrics, not Salesforce data |
| `syntax error ... unexpected 'role'` | The previous statement in the worksheet is missing `;`. Use a fresh worksheet. |
| Runtime can't reach Salesforce | Wrong host in the network rule, or the integration isn't attached to the runtime |
| Changed the network rule and it broke | Recreated with CREATE OR REPLACE. Use ALTER and re-attach. |

## Where to look

**Canvas** (process group box): ▶ running · ■ stopped · ⚠ invalid · red bulletin = error (hover to read).
Queued growing while Out stays 0 means data is stuck. Double-click to go inside; right-click a processor → *View data provenance*.

**Snowflake**: [`../snowflake/04_monitoring/`](../snowflake/04_monitoring/)

**Salesforce Setup** (Quick Find):
- *Login History*: did the user log in via OAuth? Success or failure, with the reason.
- *System Overview*: API requests in the last 24 hours.
- *Bulk Data Load Jobs*: mainly ingest jobs; Bulk API 2.0 *query* jobs may not appear here.
