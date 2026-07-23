{{
    config(
        materialized='table',
        partition_by={
            "field": "transaction_date",
            "data_type": "date"
        },
        cluster_by=["account_id"]
    )
}}
select
    t.transaction_id,
    t.account_id,
    a.user_id,
    t.transaction_at,
    cast(t.transaction_at as date) as transaction_date,
    t.category,
    t.merchant,
    t.amount,
    t.currency,
    t.status

from {{ ref('stg_transactions') }} t
left join {{ ref('stg_accounts') }} a
    on t.account_id = a.account_id