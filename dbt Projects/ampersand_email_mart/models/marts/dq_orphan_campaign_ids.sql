with e as (
  select campaign_id
  from {{ ref('stg_marketing_cloud_events') }}
  where campaign_id is not null
),
c as (
  select campaign_id
  from {{ ref('stg_campaigns') }}
)

select
  e.campaign_id,
  count(*) as orphan_event_count
from e
left join c
  on e.campaign_id = c.campaign_id
where c.campaign_id is null
group by 1
order by orphan_event_count desc
limit 500

