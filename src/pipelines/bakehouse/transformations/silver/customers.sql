-- Silver: cleaned customer dimension.
-- Country is standardized: the bronze source uses 'USA' here (vs. 'US' in franchises),
-- so both are conformed to the same canonical value.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.customers (
  CONSTRAINT valid_customer_id EXPECT (customerID IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_email EXPECT (email_address LIKE '%@%')
)
COMMENT 'Cleaned and conformed customer directory with standardized country names'
AS
SELECT
  customerID,
  first_name,
  last_name,
  concat(first_name, ' ', last_name) AS full_name,
  email_address,
  phone_number,
  address,
  city,
  state,
  CASE WHEN country = 'USA' THEN 'United States' ELSE country END AS country,
  continent,
  CAST(postal_zip_code AS STRING) AS postal_zip_code,
  gender
FROM ${medallion_catalog}.${bronze_schema}.customers;
