with src as (
    select * from {{ source('raw', 'campaigns') }}
)

select
    campaign_id,
    campaign_name,
    division,
    campaign_type,

    try_to_date(start_date::varchar) as start_date,
    try_to_date(end_date::varchar)   as end_date,

    status,

    try_to_timestamp_ntz(created_at::varchar) as created_at,
    try_to_timestamp_ntz(updated_at::varchar) as updated_at,

    utm_source,
    utm_medium,
    utm_campaign,
    journey_name
from src

