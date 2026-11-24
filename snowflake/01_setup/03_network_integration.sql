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
