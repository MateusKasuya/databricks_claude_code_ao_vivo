-- Gold: daily revenue, orders and average ticket per franchise.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.daily_sales_by_franchise
CLUSTER BY (transaction_date, franchiseID)
COMMENT 'Daily revenue, orders and average ticket per franchise'
AS
SELECT
  transaction_date,
  franchiseID,
  franchise_name,
  franchise_country,
  COUNT(DISTINCT transactionID) AS total_orders,
  SUM(total_price) AS total_revenue,
  ROUND(SUM(total_price) / COUNT(DISTINCT transactionID), 2) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY transaction_date, franchiseID, franchise_name, franchise_country;
