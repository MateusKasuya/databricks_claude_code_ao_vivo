-- Gold: review sentiment distribution per franchise.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sentiment_by_franchise
COMMENT 'Review sentiment distribution and positive ratio per franchise'
AS
SELECT
  r.franchiseID,
  f.franchise_name,
  f.country,
  COUNT(*) AS total_reviews,
  SUM(CASE WHEN r.sentiment = 'positive' THEN 1 ELSE 0 END) AS positive_reviews,
  SUM(CASE WHEN r.sentiment = 'neutral' THEN 1 ELSE 0 END) AS neutral_reviews,
  SUM(CASE WHEN r.sentiment = 'negative' THEN 1 ELSE 0 END) AS negative_reviews,
  SUM(CASE WHEN r.sentiment = 'mixed' THEN 1 ELSE 0 END) AS mixed_reviews,
  ROUND(SUM(CASE WHEN r.sentiment = 'positive' THEN 1 ELSE 0 END) / COUNT(*), 2) AS positive_ratio
FROM ${medallion_catalog}.${silver_schema}.reviews_sentiment r
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f ON r.franchiseID = f.franchiseID
GROUP BY r.franchiseID, f.franchise_name, f.country;
