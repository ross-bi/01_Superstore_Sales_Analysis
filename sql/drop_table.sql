-- 1. 先刪事實表
DROP TABLE IF EXISTS fact_sales;

-- 2. 刪產品層（最底層先）
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_sub_category;
DROP TABLE IF EXISTS dim_category;

-- 3. 刪地理層
DROP TABLE IF EXISTS dim_state;
DROP TABLE IF EXISTS dim_country;
DROP TABLE IF EXISTS dim_region;
DROP TABLE IF EXISTS dim_market;


-- 4. 其他維度
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_date;
