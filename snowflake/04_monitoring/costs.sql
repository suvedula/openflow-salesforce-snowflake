-- Credits by service (account_usage lags a few hours - check the next day)
use role accountadmin;

select usage_date, service_type, round(sum(credits_used), 3) as credits
from snowflake.account_usage.metering_daily_history
where usage_date >= dateadd(day, -7, current_date())
group by 1, 2
order by 1 desc, 3 desc;

-- What's still running
show openflow deployments;
show compute pools;      -- built-in SYSTEM_COMPUTE_POOL_* should be SUSPENDED
show warehouses like 'OPENFLOW_WH_SV';
