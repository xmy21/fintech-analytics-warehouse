select
    id as user_id,
    first_name,
    last_name,
    email,
    country,
    cast(signup_date as date) as signup_date

from {{ source('fintech_raw', 'users') }}