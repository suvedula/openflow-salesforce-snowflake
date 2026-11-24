-- What the connector ran in Snowflake - look for FAILED MERGE / COPY
use role accountadmin;

select start_time, query_type, execution_status, error_message,
       left(query_text, 150) as query
from table(ingest_sandbox.information_schema.query_history_by_warehouse(
       warehouse_name => 'OPENFLOW_WH_SV', result_limit => 200))
order by start_time desc;
