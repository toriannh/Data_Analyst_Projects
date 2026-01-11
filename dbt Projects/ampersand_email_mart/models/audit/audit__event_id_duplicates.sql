select
  event_id,
  count(*) as n
from {{ ref('fct_email_events') }}
group by 1
having count(*) > 1

