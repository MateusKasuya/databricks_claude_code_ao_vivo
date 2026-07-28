-- Silver: customer reviews with AI-derived sentiment.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.reviews_sentiment (
  CONSTRAINT valid_review_text EXPECT (review IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT known_franchise EXPECT (franchiseID IS NOT NULL)
)
COMMENT 'Customer reviews enriched with sentiment via ai_analyze_sentiment'
AS
SELECT
  new_id AS review_id,
  franchiseID,
  review_date,
  DATE(review_date) AS review_date_day,
  MONTH(review_date) AS review_month,
  review,
  ai_analyze_sentiment(review) AS sentiment
FROM STREAM(${medallion_catalog}.${bronze_schema}.reviews);
