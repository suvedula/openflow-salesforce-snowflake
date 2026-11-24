/* Stop costs but KEEP the setup.
   FIRST in the Openflow UI:
     1. Canvas: right-click the Salesforce Bulk API process group > Stop
     2. Runtimes: (...) on SF_RUNTIME_SV > Suspend -> refresh until "Suspended"
   A suspended runtime costs $0. The DEPLOYMENT can't be suspended - it keeps a
   small ongoing cost while it exists (drop it via 99_teardown when done).
   Resume: Runtimes > (...) > Resume, then Start on the canvas. */
use role accountadmin;
alter warehouse openflow_wh_sv suspend;

show openflow deployments;
show compute pools;
