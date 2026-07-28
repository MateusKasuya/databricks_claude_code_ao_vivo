-- Bronze: raw ingestion of samples.bakehouse.sales_customers
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.customers
COMMENT 'Raw customer directory ingested from samples.bakehouse.sales_customers'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_customers' AS _source_table
FROM STREAM(samples.bakehouse.sales_customers);
