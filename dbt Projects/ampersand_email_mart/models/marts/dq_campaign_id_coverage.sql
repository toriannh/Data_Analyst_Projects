with e as (
  select campaign_id
  from {{ ref('stg_marketing_cloud_events') }}
),
c as (
  select campaign_id
  from {{ ref('stg_campaigns') }}
)

select
  current_date() as as_of_date,
  count(*) as total_events,
  count_if(e.campaign_id is null) as null_campaign_id_events,
  count_if(e.campaign_id is not null and c.campaign_id is null) as orphan_campaign_id_events,
  round(100 * count_if(e.campaign_id is null) / nullif(count(*), 0), 2) as pct_null_campaign_id,
  round(
    100 * count_if(e.campaign_id is not null and c.campaign_id is null) / nullif(count(*), 0),
    2
  ) as pct_orphan_campaign_id
from e
left join c
  on e.campaign_id = c.campaign_id

