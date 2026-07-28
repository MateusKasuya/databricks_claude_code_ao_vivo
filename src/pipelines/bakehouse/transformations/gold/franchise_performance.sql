-- Gold: franchise performance with geography, for ranking and map visuals.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.franchise_performance
COMMENT 'Franchise revenue/orders/ticket performance with city, country and coordinates'
AS
SELECT
  franchiseID,
  franchise_name,
  franchise_city AS city,
  franchise_country AS country,
  latitude,
  longitude,
  COUNT(DISTINCT transactionID) AS total_orders,
  SUM(total_price) AS total_revenue,
  ROUND(SUM(total_price) / COUNT(DISTINCT transactionID), 2) AS avg_ticket,
  RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY franchiseID, franchise_name, franchise_city, franchise_country, latitude, longitude;
