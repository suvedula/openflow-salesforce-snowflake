-- Run after the connector has completed a run
use role openflow_sf_rl_sv;
use warehouse openflow_wh_sv;

-- Tables appear first (0 rows); data follows a few minutes later.
-- STAGING_<OBJECT> tables appear transiently during merges - never touch them.
show tables in schema ingest_sandbox.bronze_salesforce_test;

-- Row counts
select 'ACCOUNT' obj, count(*) n from ingest_sandbox.bronze_salesforce_test.account
union all select 'CONTACT', count(*) from ingest_sandbox.bronze_salesforce_test.contact
union all select 'LEAD', count(*) from ingest_sandbox.bronze_salesforce_test.lead
union all select 'OPPORTUNITY', count(*) from ingest_sandbox.bronze_salesforce_test.opportunity;

-- Freshness / watermark
select max(systemmodstamp) as latest_sf_change,
       count_if(isdeleted)  as deleted_rows
from ingest_sandbox.bronze_salesforce_test.contact;

-- Sample records via silver views
select * from ingest_sandbox.silver_salesforce_test.v_contact limit 20;
select * from ingest_sandbox.silver_salesforce_test.v_account limit 20;

-- Incremental test: edit a Contact in Salesforce, wait for the next run (15 min),
-- re-run the freshness query - latest_sf_change should move forward.
