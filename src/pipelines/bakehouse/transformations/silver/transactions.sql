-- Silver: transactions enriched with franchise and customer dimensions, with
-- derived date parts and data-quality expectations. Streaming table + stream-static
-- joins: the fact stream (bronze transactions) is joined against the current
-- snapshot of the (batch) customer/franchise dimensions.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.transactions (
  CONSTRAINT valid_transaction_id EXPECT (transactionID IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity EXPECT (quantity > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_total_price EXPECT (total_price >= 0) ON VIOLATION DROP ROW,
  CONSTRAINT known_franchise EXPECT (franchiseID IS NOT NULL),
  CONSTRAINT known_customer EXPECT (customerID IS NOT NULL)
)
COMMENT 'Sales transactions enriched with franchise and customer attributes'
AS
SELECT
  t.transactionID,
  t.dateTime AS transaction_ts,
  DATE(t.dateTime) AS transaction_date,
  DAY(t.dateTime) AS transaction_day,
  MONTH(t.dateTime) AS transaction_month,
  YEAR(t.dateTime) AS transaction_year,
  t.product,
  t.quantity,
  t.unitPrice AS unit_price,
  t.totalPrice AS total_price,
  t.paymentMethod AS payment_method,
  t.customerID,
  c.full_name AS customer_name,
  c.country AS customer_country,
  t.franchiseID,
  f.franchise_name,
  f.city AS franchise_city,
  f.country AS franchise_country,
  f.latitude,
  f.longitude
FROM STREAM(${medallion_catalog}.${bronze_schema}.transactions) t
LEFT JOIN ${medallion_catalog}.${silver_schema}.customers c ON t.customerID = c.customerID
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f ON t.franchiseID = f.franchiseID;
