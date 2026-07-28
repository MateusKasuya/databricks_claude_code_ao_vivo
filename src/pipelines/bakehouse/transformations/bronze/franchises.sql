-- Bronze: raw ingestion of samples.bakehouse.sales_franchises
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.franchises
COMMENT 'Raw franchise directory ingested from samples.bakehouse.sales_franchises'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_franchises' AS _source_table
FROM STREAM(samples.bakehouse.sales_franchises);
