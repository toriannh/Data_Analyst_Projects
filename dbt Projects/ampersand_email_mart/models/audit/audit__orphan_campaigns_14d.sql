with base as (
  select
    event_date,
    count(*) as row_ct,
    count_if(is_orphan_campaign_id) as orphan_row_ct
  from {{ ref('fct_email_events_daily') }}
  where event_date >= dateadd('day', -14, current_date)
  group by 1
)

select
  event_date,
  row_ct,
  orphan_row_ct,
  round(100 * orphan_row_ct / nullif(row_ct, 0), 2) as orphan_pct
from base
order by event_date desc

