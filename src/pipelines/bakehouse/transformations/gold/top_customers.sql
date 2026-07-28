-- Gold: customer ranking by spend.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.top_customers
COMMENT 'Customers ranked by total spend, orders and average ticket'
AS
SELECT
  customerID,
  customer_name,
  customer_country,
  COUNT(DISTINCT transactionID) AS total_orders,
  SUM(total_price) AS total_revenue,
  ROUND(SUM(total_price) / COUNT(DISTINCT transactionID), 2) AS avg_ticket,
  RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY customerID, customer_name, customer_country;
