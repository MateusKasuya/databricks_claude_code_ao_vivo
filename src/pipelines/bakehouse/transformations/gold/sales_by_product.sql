-- Gold: revenue and mix by product.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_product
COMMENT 'Revenue, quantity and order mix by product'
AS
SELECT
  product,
  COUNT(DISTINCT transactionID) AS total_orders,
  SUM(quantity) AS total_quantity,
  SUM(total_price) AS total_revenue,
  ROUND(SUM(total_price) / COUNT(DISTINCT transactionID), 2) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY product;
