-- Silver: cleaned franchise dimension.
-- Country is standardized: the bronze source uses the ISO-ish short code 'US'.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.franchises (
  CONSTRAINT valid_franchise_id EXPECT (franchiseID IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_coordinates EXPECT (
    latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180
  )
)
COMMENT 'Cleaned and conformed franchise directory with standardized country names'
AS
SELECT
  franchiseID,
  name AS franchise_name,
  city,
  district,
  zipcode,
  CASE WHEN country = 'US' THEN 'United States' ELSE country END AS country,
  size AS franchise_size,
  CAST(longitude AS DOUBLE) AS longitude,
  CAST(latitude AS DOUBLE) AS latitude,
  supplierID
FROM ${medallion_catalog}.${bronze_schema}.franchises;
