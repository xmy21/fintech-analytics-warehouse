{% snapshot accounts_snapshot %}

{{
    config(
        target_schema='fintech_dbt',
        unique_key='account_id',
        strategy='check',
        check_cols=['account_type', 'currency', 'status']
    )
}}

select
    id as account_id,
    user_id,
    account_type,
    currency,
    status

from {{ source('fintech_raw', 'accounts') }}

{% endsnapshot %}