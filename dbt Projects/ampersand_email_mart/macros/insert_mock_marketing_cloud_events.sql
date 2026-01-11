{% macro insert_mock_marketing_cloud_events(
    rowcount=500,
    orphan_rate=0.03,
    null_campaign_rate=0.05
) %}

  {% if target.name not in ['dev', 'default'] %}
    {{ exceptions.raise_compiler_error("Refusing to insert mock data outside dev/default target.") }}
  {% endif %}

  {% set campaign_cnt_sql %}
    select count(*) as cnt
    from {{ source('raw', 'campaigns') }}
    where campaign_id is not null
  {% endset %}

  {% if execute %}
    {% set res = run_query(campaign_cnt_sql) %}
    {% set cnt = (res.columns[0].values() | first) | int %}
    {% if cnt == 0 %}
      {{ exceptions.raise_compiler_error("No campaign_ids found in RAW.CAMPAIGNS. Seed/load campaigns first.") }}
    {% endif %}
  {% endif %}

  {% set insert_sql %}

    insert into {{ source('raw','marketing_cloud_events') }} (
      event_id,
      event_type,
      event_ts,
      subscriber_key,
      campaign_id,
      division,
      message_id,
      is_unique
    )

    with campaigns as (
      select
        campaign_id,
        row_number() over (order by campaign_id) as rn
      from {{ source('raw', 'campaigns') }}
      where campaign_id is not null
    ),
    campaign_count as (
      select count(*) as cnt from campaigns
    ),

    gen as (
      select
        uniform(0, 10000, random()) as r_event,
        uniform(0, 10000, random()) as r_camp,
        uniform(0, 24 * 60, random()) as minutes_ago,
        uniform(1, 12000, random()) as sub_n,
        uniform(1, 5000, random())  as msg_n,
        uniform(0, 3, random())     as div_n,
        uuid_string()               as pick_key
      from table(generator(rowcount => {{ rowcount }}))
    ),
    picks as (
      /* For each generated row, pick ONE random campaign_id */
      select
        g.pick_key,
        c.campaign_id
      from gen g
      join campaigns c on 1=1
      qualify row_number() over (partition by g.pick_key order by random()) = 1
    ),
    typed as (
      select
        uuid_string() as event_id,

        case
          when r_event < 2000 then 'SEND'
          when r_event < 4000 then 'DELIVERED'
          when r_event < 6500 then 'OPEN'
          when r_event < 8500 then 'CLICK'
          when r_event < 9500 then 'BOUNCE'
          else 'UNSUBSCRIBE'
        end as event_type,

        dateadd('minute', -minutes_ago, current_timestamp())::timestamp_ntz as event_ts,

        'sub_' || sub_n::varchar as subscriber_key,

        case
          when r_camp < ({{ null_campaign_rate }} * 10000) then null
          when r_camp < (({{ null_campaign_rate }} + {{ orphan_rate }}) * 10000)
            then 'ORPHAN_' || substr(uuid_string(), 1, 8)
          else p.campaign_id
        end as campaign_id,

        case div_n
          when 0 then 'North'
          when 1 then 'South'
          when 2 then 'East'
          else 'West'
        end as division,

        'msg_' || msg_n::varchar as message_id

      from gen
      left join picks p
        on p.pick_key = gen.pick_key
    )

    select
      event_id,
      event_type,
      event_ts,
      subscriber_key,
      campaign_id,
      division,
      message_id,
      case
        when event_type in ('OPEN','CLICK')
          and uniform(0, 10000, random()) < 6000
          then true
        else false
      end as is_unique
    from typed

  {% endset %}

  {% do log("Inserting " ~ rowcount ~ " mock Marketing Cloud events into RAW.MARKETING_CLOUD_EVENTS", info=true) %}
  {% do run_query(insert_sql) %}

{% endmacro %}

