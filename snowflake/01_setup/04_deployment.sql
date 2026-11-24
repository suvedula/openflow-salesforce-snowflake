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
