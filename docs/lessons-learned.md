# Lessons learned

1. **New developer orgs can be empty.** Tables get created, but with 0 rows. Always check the list view **All …**, not *Recently Viewed*.
2. **Nothing prompts you for credentials.** Install asks for nothing, and neither does the runtime. Keys go into **Parameter Contexts**.
3. **Inherited parameters (↴)** must be edited in their own context (Source / Destination / Ingestion).
4. **A grey Apply** means nothing changed. The *Show inherited parameters* checkbox only changes the view.
5. **Two "StandardPrivateKeyService"s** exist. Only the Salesforce one matters; the Snowflake one stays invalid on Snowflake-hosted deployments.
6. **Enable controller services bottom-up.** Invalid services have no *Enable* option.
7. **Tables first, data later.** The connector creates tables, then runs Bulk API jobs; data lands minutes later.
8. **The events table ≠ data.** It fills with runtime logs regardless.
9. **The runtime doesn't auto-suspend** like a warehouse. Suspend it when done.
10. **Deployments can't be suspended.** Delete the runtime, then drop the deployment, to get to zero cost.
11. **MSYS2/UCRT64 home ≠ Windows home.** Use `pwd -W` or `explorer .`.
12. **Isolation:** suffix everything (`_SV`) and keep test objects in their own schemas.
