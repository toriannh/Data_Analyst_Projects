with src as (
    select
        event_id,
        event_type,
        event_ts,
        subscriber_key,
        campaign_id,
        division,
        message_id,
        is_unique
    from {{ ref('stg_marketing_cloud_events') }}

    {% if is_incremental() %}
      -- lookback window for late-arriving events (adjust 1–7 days as needed)
      where event_ts >= (
        select dateadd(day, -3, max(event_ts))
        from {{ this }}
      )
    {% endif %}
)

select * from src

