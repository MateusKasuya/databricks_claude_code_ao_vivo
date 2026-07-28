-- Gold: revenue and franchise footprint per country.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_country
COMMENT 'Revenue, orders and franchise count per country'
AS
SELECT
  franchise_country AS country,
  COUNT(DISTINCT franchiseID) AS total_franchises,
  COUNT(DISTINCT transactionID) AS total_orders,
  SUM(total_price) AS total_revenue,
  ROUND(SUM(total_price) / COUNT(DISTINCT transactionID), 2) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY franchise_country;
