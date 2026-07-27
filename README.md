# Fintech Analytics Warehouse

A portfolio project simulating an analytics engineering workflow for a neobank: synthetic transaction data generated in Python, loaded into BigQuery, and modeled into a tested, optimized star schema using dbt.

## Why this project

Built to demonstrate the core responsibilities of an analytics engineering role: building data models downstream of source data, testing/data quality practices, and warehouse cost/performance optimization (partitioning, clustering, incremental processing).

## Architecture

generate_data.py (Python/Faker)
↓
BigQuery raw tables (fintech_raw dataset)
↓
dbt staging models (1:1 cleanup, type casting, dedup)
↓
dbt mart models (star schema: fact + dimensions)
↓
BI layer (Data Studio)

## Data

Synthetic data for a neobank, generated with Python (`faker`, `numpy`, `pandas`):
- `users` — 20,000 customers
- `accounts` — ~24,000 accounts (personal/joint/business/teen)
- `cards` — ~36,000 debit/credit cards
- `transactions` — 800,000 transactions with realistic category/merchant/amount distributions

Intentional data quality issues were injected (duplicate transaction rows, missing categories) to give the test suite something real to catch.

## Staging layer

One staging model per raw source table (`stg_users`, `stg_accounts`, `stg_cards`, `stg_transactions`). Staging models do light, non-lossy cleanup only: renaming columns to consistent conventions, casting types, deduplicating exact-duplicate rows, and coalescing nulls where appropriate. No business logic or joins at this layer.

Example: `stg_transactions` deduplicates on `transaction_id` and replaces null categories with `'uncategorized'` rather than dropping rows, preserving revenue-relevant transactions even when a dimension value is missing.

## Data model (star schema)

- **Fact table**: `fct_transactions` — grain is one row per transaction. Contains both `account_id` (natural foreign key) and `user_id` (denormalized from `dim_accounts`) so downstream queries don't need an extra join to get to the user level.
- **Dimension tables**: `dim_users`, `dim_accounts`, `dim_cards`

## Testing

Tests applied at both the source level (`sources.yml`) and the model level (staging + marts): `unique` and `not_null` on all primary keys, `relationships` tests validating foreign key integrity between transactions → accounts → users. Source-level tests intentionally fail against the raw data (catching the injected duplicates/nulls); staging-level tests pass, proving the cleanup logic actually works.

## Warehouse optimization

`fct_transactions` is partitioned by `transaction_date` and clustered by `account_id`. Measured impact: a query filtering to a recent date range went from scanning **12.22 MB to 1.42 MB** (88.4% reduction) after partitioning, since BigQuery skips non-matching partitions entirely instead of scanning the full 800k-row table.

Along the way, hit and diagnosed a real BigQuery gotcha: the dataset's default table expiration (60 days) was being applied *per partition* (based on each partition's own date, not the table's creation date), silently deleting ~87% of historical data on every build. Fixed by enabling billing (required to disable sandbox mode's forced 60-day expiration) and clearing the dataset's default expiration.

`fct_transactions` also uses **incremental materialization** (`merge` strategy, keyed on `transaction_id`) instead of a full rebuild on every run — after the initial full build, subsequent runs only process rows newer than what's already in the table via dbt's `is_incremental()` macro.

## BI Dashboard

Live dashboard built in Data Studio on top of `fct_transactions`: [https://datastudio.google.com/reporting/eea8bd79-0da1-4fbf-a3ac-7a331944f43a]

- Time series: transaction volume over time (note: volume artificially skews toward recent dates due to how synthetic transaction timestamps were generated — see limitations below)
- Bar chart: spending by category

## What I'd do with more time

- Optimize the incremental filter to use a partition-based lookback window on the source side, rather than a `max()` subquery against the target.
- The current approach still rescans full source history on every incremental run even when 0 rows ultimately merge.
- Add SCD Type 2 handling on `dim_accounts` to track historical changes (e.g. account type, status changes over time) rather than only reflecting current state.
- generate transactions via a constant-rate process per account rather than uniform-to-today, to avoid an artificial recency skew

## Stack

Python (data generation) → BigQuery (warehouse) → dbt-core + dbt-bigquery (transformation, testing) → Data Studio (BI)