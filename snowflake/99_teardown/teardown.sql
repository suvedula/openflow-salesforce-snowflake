/* Remove everything -> zero cost.
   FIRST in the Openflow UI:
     1. Canvas: right-click process group > Stop, then Disable all controller services
     2. Optional: right-click process group > Download flow definition (config backup, no secrets)
     3. Runtimes: (...) on SF_RUNTIME_SV > Delete   (deployment can't drop while a runtime exists) */

-- A. Openflow objects - as their owner
use role openflow_role_sv;
drop openflow deployment if exists openflow_sv;
drop integration  if exists salesforce_eai_sv;
drop network rule if exists ingest_sandbox.openflow_control.salesforce_network_rule_sv;
drop table        if exists ingest_sandbox.openflow_control.openflow_events_sv;

-- B. Schemas, warehouse, roles
use role accountadmin;
set my_user = current_user();

drop schema    if exists ingest_sandbox.silver_salesforce_test;
drop schema    if exists ingest_sandbox.bronze_salesforce_test;   -- remove to keep the data
drop schema    if exists ingest_sandbox.openflow_control;
drop warehouse if exists openflow_wh_sv;

-- Reset default role BEFORE dropping the role it points to (use your previous default)
alter user identifier($my_user) set default_role = accountadmin;
alter user identifier($my_user) unset default_secondary_roles;

drop role if exists openflow_sf_rl_sv;
drop role if exists openflow_role_sv;

-- C. Verify
show openflow deployments;
show integrations like 'SALESFORCE_EAI_SV';
show warehouses   like 'OPENFLOW_WH_SV';
show roles        like 'OPENFLOW%_SV';
