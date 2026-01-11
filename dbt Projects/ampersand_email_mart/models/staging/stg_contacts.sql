with src as (
  select * from {{ source('raw', 'contacts') }}
)

select
  contact_id,
  account_id,

  lower(nullif(email, '')) as email,
  regexp_replace(nullif(phone, ''), '[^0-9]', '') as phone_digits,

  nullif(first_name, '') as first_name,
  nullif(last_name, '')  as last_name,

  lifecycle_stage,
  opt_in_status,
  unsubscribed_at::timestamp_ntz as unsubscribed_at,

  created_at::timestamp_ntz as created_at,
  updated_at::timestamp_ntz as updated_at,

  case when unsubscribed_at is not null then true else false end as is_unsubscribed

from src

