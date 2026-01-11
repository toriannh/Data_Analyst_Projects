select
  campaign_id,
  campaign_name,
  division,
  campaign_type,
  status,
  utm_source,
  utm_medium,
  journey_name
from {{ ref('stg_campaigns') }}

