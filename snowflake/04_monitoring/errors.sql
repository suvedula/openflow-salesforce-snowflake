-- Real errors/warnings from the Openflow runtime, known noise filtered out.
-- Noise: snowflake-jdbc "ec2-imds-probe" / "Stop retrying" / "Returning null" = the JDBC
-- driver checking whether it runs on AWS EC2. Harmless.
-- Note: routine INFO activity is generally not written here - empty result = no errors.
use role accountadmin;

select timestamp,
       record:severity_text::string as severity,
       value:loggerName::string     as logger,
       left(value:formattedMessage::string, 500) as message
from ingest_sandbox.openflow_control.openflow_events_sv
where record_type = 'LOG'
  and timestamp > dateadd(hour, -2, current_timestamp())
  and record:severity_text::string in ('ERROR','WARN')
  and value:threadName::string not ilike '%imds%'
  and value:formattedMessage::string not ilike '%retrying%'
  and value:formattedMessage::string not ilike '%Returning null%'
order by timestamp desc
limit 50;
