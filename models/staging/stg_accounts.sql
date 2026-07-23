select
    id as account_id,
    user_id,
    account_type,
    currency,
    cast(opened_at as date) as opened_at,
    status

from {{ source('fintech_raw', 'accounts') }}