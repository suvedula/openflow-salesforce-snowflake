# Walkthrough: every step, in the order I did it

What I did, what I saw on screen, and what tripped me up. Values in `<ANGLE_BRACKETS>` are
placeholders; real domains, usernames and keys are deliberately not in this repo.

Total time the first time: about 3 hours, including waits and debugging.

---

## Step 1: Understand the moving parts

```
Salesforce org ── External Client App (OAuth + JWT, holds public.crt)
      ▲
      │  OAuth 2.0 JWT Bearer: Openflow signs a JWT with private.key,
      │  Salesforce verifies it with public.crt, returns an access token
      │
Openflow deployment (control plane) ── runtime (compute) ── connector (Salesforce Bulk API)
      │
      │  SNOWFLAKE_MANAGED: the runtime writes as its execute-as role
      ▼
Snowflake  INGEST_SANDBOX.BRONZE_SALESFORCE_TEST.{ACCOUNT, CONTACT, LEAD, OPPORTUNITY}
```

Three separate logins:
| Who | To | How |
|---|---|---|
| Me | Snowflake / Openflow UI | Normal login |
| Openflow | Salesforce | **JWT Bearer**, the only flow this connector supports. Key pair + Consumer Key are required. |
| Openflow | Snowflake | **SNOWFLAKE_MANAGED**: no credentials, uses the runtime's role |

---

## Step 2: Create a Salesforce Developer org
1. Signed up at developer.salesforce.com/signup with my real email.
2. Activated via email and set a password. I'm **System Administrator** of my own org.
3. The username was auto-generated: `<name.xxxx>@agentforce.com`. This becomes the **OAuth2 Subject**.
4. Setup → Quick Find **My Domain** → copied the *Current My Domain URL*, minus `https://`, for example
   `<orgfarm-xxxx-dev-ed>.develop.my.salesforce.com`. That's `<SF_MY_DOMAIN>` everywhere.

> ⚠ The org turned out to be **empty** (no Accounts or Contacts). See step 12.

---

## Step 3: Generate the key pair
In Git Bash / MSYS2, in a dedicated folder **outside any Git repo**:

```bash
mkdir -p /c/Users/<you>/keys/sf_openflow && cd /c/Users/<you>/keys/sf_openflow
openssl genpkey -algorithm RSA -out private.key -aes256
openssl req -new -x509 -key private.key -out public.crt -days 365
```
(or `bash scripts/make_keys.sh`)

- First command: *Enter PEM pass phrase* twice. **Nothing shows while typing**; that's normal.
- Second command: the passphrase once more, then certificate questions (anything is fine).
- That's 3 passphrase prompts in total.

> ⚠ My terminal was **MSYS2 UCRT64**, where `~` is **not** `C:\Users\<you>`, so I couldn't find the files
> at first. `pwd -W` prints the real Windows path, and `explorer .` opens the folder.
> Fix: generate directly in `/c/Users/<you>/...`.

Why two files: `private.key` **signs** each login and never leaves my side; `public.crt` is uploaded
to Salesforce, which can only **verify** signatures with it. They're mathematically linked when created.

---

## Step 4: Salesforce External Client App
Setup → Quick Find **External Client App Manager** → **New External Client App**.
Exact settings: [`../salesforce/external_client_app.md`](../salesforce/external_client_app.md)

Key points:
- Contact email = a **real** mailbox, not the @agentforce username.
- **Enable OAuth** *and* **Enable JWT Bearer Flow** (OAuth is the framework; JWT Bearer is the flow).
- Upload `public.crt`.
- Policies: *Admin approved users are pre-authorized* + **System Administrator** profile + **Relax IP restrictions**.
- Settings → **Consumer Key** copied. That's the app's ID (OAuth Client ID), not a secret on its own.
  The Consumer Secret isn't needed.

---

## Step 5: Snowflake setup (SQL)
1. Replaced `<SF_MY_DOMAIN>` in [`../RUN_ALL.sql`](../RUN_ALL.sql) (one place: the network rule).
2. Snowsight → new worksheet → paste → **Run All**.

What it creates:
| Object | Why |
|---|---|
| `OPENFLOW_ROLE_SV` | Manages Openflow. Needed because **Openflow rejects ACCOUNTADMIN as the default role**. |
| `OPENFLOW_SF_RL_SV` | The connector's execute-as role, which can only write to one schema |
| `OPENFLOW_WH_SV` | X-Small warehouse for the connector's MERGEs |
| `OPENFLOW_CONTROL` schema | Network rule + event table (Openflow logs) |
| `BRONZE_SALESFORCE_TEST` schema | Where Salesforce data lands. **Tables are created by the connector**, not by me. |
| `SILVER_SALESFORCE_TEST` schema | Clean views (step 13) |
| Network rule + external access integration | Snowflake blocks outbound traffic by default. This allowlists `<SF_MY_DOMAIN>:443` and `login.salesforce.com:443`. |
| Deployment `OPENFLOW_SV` | Openflow control plane |

3. Result of `show openflow deployments;`: **OPENFLOW_SV = PROVISIONING**. After about 10–20 minutes it became **ACTIVE**.
   It also appeared in Openflow → **Deployments** (I only see mine because of the role I use).
4. **Logged out and back in**, so the new default role applied.

> Lessons: `create openflow deployment` has no `IF NOT EXISTS`, so run it once only.
> Never `CREATE OR REPLACE` the network rule or integration later (it detaches them from the runtime); use `ALTER`.
> All my objects end in `_SV` so they can't clash with anyone else's.

---

## Step 6: Create the runtime
Openflow → **Runtimes → Create runtime**. Settings: [`../openflow/runtime.md`](../openflow/runtime.md)

- Picked **my** deployment (not any other listed).
- Changed **Max nodes from 50 to 1**.
- `SALESFORCE_EAI_SV` appeared in the dropdown after making sure both roles had USAGE on it.
- The runtime form **doesn't ask for Salesforce credentials**. That surprised me; they go in step 8.
- About 5–10 minutes later: **Active**.

Why a runtime: it's the **compute that executes** the connector. Scheduling isn't here.
Compared with the code approach: runtime ≈ warehouse, connector ≈ stored procedure, Run Schedule ≈ Task.

---

## Step 7: Install the connector
Openflow → **Connector library** → search *salesforce* → **Salesforce Bulk API → Install** → runtime `SF_RUNTIME_SV`.

What I saw: a canvas with one blue box, **Salesforce Bulk API**, showing **▶ 0 · ■ 67 · ⚠ 33 · ⊘ 2**:
| Icon | Meaning |
|---|---|
| ■ 67 | 67 processors (steps), all stopped |
| ⚠ 33 | Invalid, because parameters weren't filled in yet (**expected**) |
| ⊘ 2 | Disabled on purpose |

> Installing asks for nothing. Right-clicking the **empty canvas** shows a menu without *Parameters*.
> You have to right-click **the box**.

---

## Step 8: Fill in the parameters
**⌄ next to my name → Parameter Contexts**. There are three contexts: Source, Destination, Ingestion.
Values: [`../openflow/parameters.md`](../openflow/parameters.md)

How editing works:
- **⋮ → Edit → paste → OK** per parameter, then **Apply**.
- Rows with **↴** are inherited. They show in Ingestion but belong to Source or Destination.
- *Show inherited parameters* is only a view filter.
- **Grey Apply = nothing changed.** That isn't an error.
- `private.key`: open it in Notepad → Ctrl+A → Ctrl+C, so **all of it** including the BEGIN/END lines.
- **Connected App Key File** stays at *No value set*.

After applying Source, a dialog showed five green ticks (stop processors → disable services → update →
re-enable → restart) and listed the 7 parameters updated. That confirmed it was saved.

Ingestion **Filter** = `Account, Contact, Opportunity, Lead` (comma list or regex; empty means every object).

---

## Step 9: Controller services
Right-click the box → **Controller services**. Details: [`../openflow/controller_services.md`](../openflow/controller_services.md)

What happened:
1. Several were **Invalid**, including the JWT provider. Its ⋮ menu had **no Enable**, only Edit / Delete / View docs,
   because invalid services can't be enabled.
2. Enabled **Web Client Service Provider** ✅
3. I first opened the wrong private key service and got *"'Key' is invalid because Private Key not configured"*. That was the
   **Snowflake** Private Key Service (Key File `#{Snowflake Private Key File}`). It's expected to stay invalid on a
   Snowflake-hosted deployment, so I ignored it.
4. Enabled **Salesforce Private Key Service** ✅
5. **JWT Bearer OAuth2 Access Token Provider** went from Invalid to Disabled. Verified it (⋮ → Edit → ✓), then enabled it ✅
   That proved the **Salesforce login works**.
6. **Salesforce Client Service** went from Invalid to Disabled (now valid).

---

## Step 10: Start
Back to process group → right-click the box → **Enable all controller services** → **Start**.

It now runs **automatically every 15 minutes**, pulling only records changed since the last run (watermark
`SystemModstamp`). No manual runs needed. **Stop → Start** only to force an immediate run while testing.

---

## Step 11: First check: tables but no data
```sql
show tables in schema ingest_sandbox.bronze_salesforce_test;
```
**ACCOUNT, CONTACT, LEAD, OPPORTUNITY were created, owned by OPENFLOW_SF_RL_SV, with 0 rows.**

That already proved: Salesforce login ✅, object metadata read ✅, Snowflake write permissions ✅.

Debugging the 0 rows:
- The **event table had about 99k rows**. Those are runtime logs and metrics, **not data**.
- The error query showed many ERRORs from `snowflake-jdbc-ec2-imds-probe` ("Stop retrying", "Returning null").
  That's **harmless noise**: the JDBC driver checks whether it's on AWS EC2 and moves on.
- With the noise filtered out ([`../snowflake/04_monitoring/errors.sql`](../snowflake/04_monitoring/errors.sql)): **no results**, so no real errors.
- A `syntax error ... unexpected 'role'` came from pasting into a worksheet where the previous statement lacked `;`.
  A fresh worksheet fixed it.

---

## Step 12: Root cause: the Salesforce org was empty
App Launcher → Contacts → list view **All Contacts** said "No items to display". Same for Accounts.
(*Recently Viewed* is always empty in a new org, so check **All**.)

Fix: created an Account (`Tennis Incorporated`) and a Contact linked to it.
Then **Stop → Start** on the canvas and waited about 10 minutes.

---

## Step 13: Data landed ✅
```sql
-- snowflake/03_verify/verify.sql
ACCOUNT 1 · CONTACT 1 · LEAD 0 · OPPORTUNITY 0
```
End to end: **Salesforce → Openflow (JWT) → Snowflake**.

Optional silver layer: [`../snowflake/02_views/silver_views.sql`](../snowflake/02_views/silver_views.sql)
(clean column names, deleted records excluded, contacts joined to account names).

Incremental test: edit the Contact, wait 15 minutes, and `max(systemmodstamp)` moves forward.

---

## Step 14: Stop the costs

| Piece | Bills | What I did |
|---|---|---|
| Runtime | The whole time it's Active (doesn't auto-suspend) | Canvas **Stop**, then Runtimes → ⋮ → **Suspend** → **Suspended** |
| Warehouse | Only while queries run | Auto-suspends after 60s |
| Deployment | Continuously while it exists, **can't be suspended** (it's the control plane that lets you resume) | Kept for now; drop it when done |
| Tables, roles, network rule | ~$0 | Kept |

> ⚠ Suspending the warehouse with SQL did **not** suspend the runtime. They're separate. The runtime
> stayed *Active* until I suspended it in the UI.
> `show compute pools` showed only the built-in `SYSTEM_COMPUTE_POOL_CPU/GPU` (suspended, not mine).
> Openflow-managed compute doesn't appear there, so the Openflow UI is the source of truth.

Scripts: [`../snowflake/05_pause/pause.sql`](../snowflake/05_pause/pause.sql) (keep setup) ·
[`../snowflake/99_teardown/teardown.sql`](../snowflake/99_teardown/teardown.sql) (zero cost).
Before tearing down: right-click the box → **Download flow definition** to keep a config backup (no secrets).

---

## What I'd do differently next time
1. Check the Salesforce org has data **before** starting.
2. Generate the keys straight into a known Windows path.
3. Fill in the parameters via **Parameter Contexts**, Source → Destination → Ingestion.
4. Enable services in order: Web Client → Salesforce Private Key → verify JWT → enable all.
5. Tear down the same day if I'm not continuing, because the deployment keeps billing.
