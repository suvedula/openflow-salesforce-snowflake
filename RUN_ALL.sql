/* =====================================================================
   RUN_ALL.sql  -  Openflow: Salesforce -> Snowflake  (Snowflake side)

   HOW TO USE
   1. Replace <SF_MY_DOMAIN> (one place, section 03) with your Salesforce
      My Domain host, e.g. orgfarm-xxxx-dev-ed.develop.my.salesforce.com
   2. Snowsight > new SQL worksheet > paste > Run All
   3. Re-run "show openflow deployments;" until OPENFLOW_SV = ACTIVE
   4. Log out and back in, then continue with docs/walkthrough.md step 6

   Run once. On re-runs, delete section 04 (deployment) first.
   ===================================================================== */

-- ---------------------------------------------------------------
-- FROM: snowflake/01_setup/01_roles_warehouse.sql
-- ---------------------------------------------------------------
-- 01: Roles + warehouse (run as ACCOUNTADMIN)
use role accountadmin;
set my_user = current_user();

-- Role that manages Openflow (owns deployment, runtime, network rule, integration)
create role if not exists openflow_role_sv;
grant role openflow_role_sv to user identifier($my_user);
grant create openflow deployment on account to role openflow_role_sv;
grant create integration         on account to role openflow_role_sv;
grant create compute pool        on account to role openflow_role_sv;

-- Role the connector runs as (execute-as role of the runtime)
create role if not exists openflow_sf_rl_sv;
grant role openflow_sf_rl_sv to role openflow_role_sv;
grant role openflow_sf_rl_sv to user identifier($my_user);

-- Small warehouse used by the connector for its MERGE statements
create warehouse if not exists openflow_wh_sv
  warehouse_size = xsmall
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true
  comment = 'Openflow Salesforce connector';
grant usage, operate on warehouse openflow_wh_sv to role openflow_sf_rl_sv;

-- Openflow rejects ACCOUNTADMIN as a default role
alter user identifier($my_user) set default_role = openflow_role_sv;
alter user identifier($my_user) set default_secondary_roles = ('ALL');

-- ---------------------------------------------------------------
-- FROM: snowflake/01_setup/02_schemas.sql
-- ---------------------------------------------------------------
-- 02: Database + schemas (run as ACCOUNTADMIN)
use role accountadmin;

create database if not exists ingest_sandbox;   -- or use an existing database

create schema if not exists ingest_sandbox.openflow_control
  comment = 'Openflow network rule + event table (logs)';
create schema if not exists ingest_sandbox.bronze_salesforce_test
  comment = 'Raw Salesforce data written by the Openflow connector';
create schema if not exists ingest_sandbox.silver_salesforce_test
  comment = 'Clean views over the bronze Salesforce tables';

-- Openflow admin role manages the control schema
grant usage on database ingest_sandbox to role openflow_role_sv;
grant all privileges on schema ingest_sandbox.openflow_control to role openflow_role_sv;

-- Connector role writes bronze (it creates the tables itself) and builds silver views
grant usage on database ingest_sandbox to role openflow_sf_rl_sv;
grant usage on schema ingest_sandbox.bronze_salesforce_test to role openflow_sf_rl_sv;
grant create table, create pipe on schema ingest_sandbox.bronze_salesforce_test to role openflow_sf_rl_sv;
grant usage, create view on schema ingest_sandbox.silver_salesforce_test to role openflow_sf_rl_sv;

-- ---------------------------------------------------------------
-- FROM: snowflake/01_setup/03_network_integration.sql
-- ---------------------------------------------------------------
-- 03: Outbound access to Salesforce (run as OPENFLOW_ROLE_SV)
-- Replace <SF_MY_DOMAIN> with your Salesforce My Domain host (no https://)
-- After the runtime uses these, change them with ALTER - never CREATE OR REPLACE
-- (replacing silently detaches them from the runtime).
use role openflow_role_sv;
use schema ingest_sandbox.openflow_control;

create network rule if not exists salesforce_network_rule_sv
  mode = egress
  type = host_port
  value_list = ('<SF_MY_DOMAIN>:443',
                'login.salesforce.com:443');   -- sandbox orgs: test.salesforce.com:443

create external access integration if not exists salesforce_eai_sv
  allowed_network_rules = (ingest_sandbox.openflow_control.salesforce_network_rule_sv)
  enabled = true
  comment = 'Openflow runtime egress to Salesforce';

grant usage on integration salesforce_eai_sv to role openflow_sf_rl_sv;

-- ---------------------------------------------------------------
-- FROM: snowflake/01_setup/04_deployment.sql
-- ---------------------------------------------------------------
-- 04: Openflow deployment (run as OPENFLOW_ROLE_SV) - RUN ONCE ONLY
-- CREATE OPENFLOW DEPLOYMENT has no IF NOT EXISTS; skip this file on re-runs.
use role openflow_role_sv;

create event table if not exists ingest_sandbox.openflow_control.openflow_events_sv;

create openflow deployment openflow_sv
  deployment_type = snowflake
  display_name = 'Openflow test (SV)';

alter openflow deployment openflow_sv
  set event_table = 'INGEST_SANDBOX.OPENFLOW_CONTROL.OPENFLOW_EVENTS_SV';

show openflow deployments;
-- State goes PROVISIONING -> ACTIVE in ~10-20 min. Then log out and back in.

