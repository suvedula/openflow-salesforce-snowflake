# Controller services

Right-click the **Salesforce Bulk API** process group (the box, not the empty canvas) → **Controller services**.

| Service | Expected | Action |
|---|---|---|
| Web Client Service Provider | Disabled → **Enabled** | ⋮ → Enable (1st) |
| Salesforce Private Key Service | Disabled → **Enabled** | ⋮ → Edit → ✓ Verify (optional) → ⋮ → Enable (2nd) |
| JWT Bearer OAuth2 Access Token Provider | Invalid → Disabled → **Enabled** | becomes valid after the two above; ⋮ → Edit → ✓ Verify (tests Salesforce login) → Enable (3rd) |
| Salesforce Client Service | Invalid → Disabled | enabled by "Enable all" |
| Salesforce Bulk Jobs State, Snowflake Connection Service, CSV Reader, JSON Readers, JSON Writer | Disabled | enabled by "Enable all" |
| Reader Lookup | Invalid → valid | fixes itself once readers are enabled |
| **Snowflake Private Key Service** | **Invalid — stays invalid** | **Ignore.** Only used on BYOC deployments; this setup uses `SNOWFLAKE_MANAGED` |

Notes
- An Invalid service has no *Enable* in its ⋮ menu (only Edit / Delete / View documentation) — enable its dependencies first.
- *Verify* lives in **⋮ → Edit → Properties → ✓ (top right)**.
- Both private key services have the same type name. The Snowflake one shows Key File `#{Snowflake Private Key File}` — that's how to tell them apart.

Then: **Back to process group → right-click the box → Enable all controller services → Start.**
