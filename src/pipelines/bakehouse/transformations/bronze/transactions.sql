-- Bronze: raw ingestion of samples.bakehouse.sales_transactions
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.transactions
COMMENT 'Raw sales transactions ingested from samples.bakehouse.sales_transactions'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_transactions' AS _source_table
FROM STREAM(samples.bakehouse.sales_transactions);
