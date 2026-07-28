-- Bronze: raw ingestion of samples.bakehouse.sales_suppliers
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.suppliers
COMMENT 'Raw supplier directory ingested from samples.bakehouse.sales_suppliers'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_suppliers' AS _source_table
FROM STREAM(samples.bakehouse.sales_suppliers);
