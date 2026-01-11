with src as (
    select * from {{ source('raw', 'marketing_cloud_events') }}
)

select
    event_id,
    upper(event_type) as event_type,
    try_to_timestamp_ntz(event_ts::varchar) as event_ts,
    subscriber_key,
    lower(email) as email,
    nullif(campaign_id, '') as campaign_id,
    division,
    message_id,
    send_id,
    url,
    device_type,
    try_to_boolean(is_unique::varchar) as is_unique,
    bounce_category,
    bounce_reason,
    journey_name
from src


