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
