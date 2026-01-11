with src as (
  select * from {{ source('raw', 'campaign_members') }}
)

select
  campaign_member_id,
  campaign_id,

  upper(member_type) as member_type,
  lead_id,
  contact_id,

  status,
  has_responded,

  created_at::timestamp_ntz as created_at,
  updated_at::timestamp_ntz as updated_at,

  case
    when contact_id is not null then contact_id
    else lead_id
  end as person_id,

  case
    when contact_id is not null and lead_id is not null then true
    else false
  end as has_both_contact_and_lead

from src

