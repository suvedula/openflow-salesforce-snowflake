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
