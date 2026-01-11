select
  event_date,
  campaign_id,
  division,
  count(*) as n
from {{ ref('fct_email_events_daily') }}
group by 1,2,3
having count(*) > 1

