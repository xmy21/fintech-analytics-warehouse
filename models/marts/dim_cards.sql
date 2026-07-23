select
    card_id,
    account_id,
    card_type,
    issued_at,
    status

from {{ ref('stg_cards') }}