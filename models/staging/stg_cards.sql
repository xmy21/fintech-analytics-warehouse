select
    id as card_id,
    account_id,
    card_type,
    cast(issued_at as date) as issued_at,
    status

from {{ source('fintech_raw', 'cards') }}