with leads as (
  select
    lead_id as person_id,
    'LEAD' as person_type,
    account_id,
    email,
    phone_digits,
    first_name,
    last_name,
    lead_source,
    status as person_status,
    opt_in_status,
    unsubscribed_at,
    is_unsubscribed,
    is_converted,
    converted_contact_id,
    created_at,
    updated_at
  from {{ ref('stg_leads') }}
),

contacts as (
  select
    contact_id as person_id,
    'CONTACT' as person_type,
    account_id,
    email,
    phone_digits,
    first_name,
    last_name,
    null as lead_source,
    lifecycle_stage as person_status,
    opt_in_status,
    unsubscribed_at,
    is_unsubscribed,
    null as is_converted,
    null as converted_contact_id,
    created_at,
    updated_at
  from {{ ref('stg_contacts') }}
)

select * from contacts
union all
select * from leads

