select
  campaign_id,
  member_type,
  status,

  count(*) as members,
  count_if(has_responded) as responded_members,
  round(100 * count_if(has_responded) / nullif(count(*), 0), 2) as responded_rate_pct,

  count_if(has_both_contact_and_lead) as dq_both_contact_and_lead

from {{ ref('stg_campaign_members') }}
group by 1,2,3

