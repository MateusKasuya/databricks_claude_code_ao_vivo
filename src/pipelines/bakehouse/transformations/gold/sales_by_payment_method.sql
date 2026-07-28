-- Gold: order and revenue mix by payment method (feeds the AI/BI dashboard's payment mix widget).
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_payment_method
COMMENT 'Order and revenue mix by payment method'
AS
SELECT
  payment_method,
  COUNT(DISTINCT transactionID) AS total_orders,
  SUM(total_price) AS total_revenue,
  ROUND(SUM(total_price) / COUNT(DISTINCT transactionID), 2) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY payment_method;
