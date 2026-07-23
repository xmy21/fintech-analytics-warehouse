select
    account_id,
    user_id,
    account_type,
    currency,
    opened_at,
    status

from {{ ref('stg_accounts') }}