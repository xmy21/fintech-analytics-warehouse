select
    id as transaction_id,
    account_id,
    `timestamp` as transaction_at,
    coalesce(category, 'uncategorized') as category,
    merchant,
    amount,
    currency,
    status

from {{ source('fintech_raw', 'transactions') }}
qualify row_number() over (partition by id order by `timestamp`) = 1