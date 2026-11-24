-- Silver layer: clean, current-record views over the bronze tables.
-- Run AFTER the connector has created the bronze tables (first run).
-- Column names = Salesforce field API names (upper case).
use role openflow_sf_rl_sv;
use warehouse openflow_wh_sv;

create or replace view ingest_sandbox.silver_salesforce_test.v_account as
select id            as account_id,
       name          as account_name,
       createddate   as created_at,
       systemmodstamp as last_changed_at
from ingest_sandbox.bronze_salesforce_test.account
where not isdeleted;

create or replace view ingest_sandbox.silver_salesforce_test.v_contact as
select c.id          as contact_id,
       c.firstname   as first_name,
       c.lastname    as last_name,
       c.email,
       c.phone,
       c.accountid   as account_id,
       a.name        as account_name,
       c.systemmodstamp as last_changed_at
from ingest_sandbox.bronze_salesforce_test.contact c
left join ingest_sandbox.bronze_salesforce_test.account a
       on a.id = c.accountid and not a.isdeleted
where not c.isdeleted;

create or replace view ingest_sandbox.silver_salesforce_test.v_lead as
select id as lead_id, firstname as first_name, lastname as last_name,
       company, status, email, systemmodstamp as last_changed_at
from ingest_sandbox.bronze_salesforce_test.lead
where not isdeleted;

create or replace view ingest_sandbox.silver_salesforce_test.v_opportunity as
select o.id as opportunity_id, o.name as opportunity_name,
       o.accountid as account_id, a.name as account_name,
       o.stagename as stage, o.amount, o.closedate as close_date,
       o.systemmodstamp as last_changed_at
from ingest_sandbox.bronze_salesforce_test.opportunity o
left join ingest_sandbox.bronze_salesforce_test.account a
       on a.id = o.accountid and not a.isdeleted
where not o.isdeleted;
