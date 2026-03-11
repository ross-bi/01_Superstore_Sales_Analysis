CREATE DATABASE superstore_db;
USE superstore_db;

-- 維度表
-- 顧客維度
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50)
);

-- 商品維度
CREATE TABLE IF NOT EXISTS dim_product (
    product_id VARCHAR(50) PRIMARY KEY,
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(200)
);

-- 地區維度
CREATE TABLE IF NOT EXISTS dim_region (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    state VARCHAR(100),
    country VARCHAR(100),
    market VARCHAR(50),
    region VARCHAR(50)
);

-- 日期維度
CREATE TABLE IF NOT EXISTS dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_of_week VARCHAR(20),
    week_of_year INT,
    is_weekend TINYINT(1),
    INDEX idx_year (year),
    INDEX idx_month (month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET SESSION cte_max_recursion_depth = 100000;

INSERT INTO dim_date (
    date_id, year, quarter, month, month_name,
    day, day_of_week, week_of_year, is_weekend
)
WITH RECURSIVE date_range AS (
    SELECT DATE('1900-01-01') AS start_date, DATE('2125-12-31') AS end_date
),
dates AS (
    SELECT start_date AS dt, end_date FROM date_range
    UNION ALL
    SELECT DATE_ADD(dt, INTERVAL 1 DAY), end_date
    FROM dates
    WHERE dt < end_date
)
SELECT
    dt,
    YEAR(dt),
    QUARTER(dt),
    MONTH(dt),
    MONTHNAME(dt),
    DAY(dt),
    DAYNAME(dt),
    WEEK(dt, 1),  -- Mode 1: ISO week
    CASE WHEN DAYOFWEEK(dt) IN (1, 7) THEN 1 ELSE 0 END  -- 1=Sun,7=Sat
FROM dates
ON DUPLICATE KEY UPDATE
    year = VALUES(year),
    quarter = VALUES(quarter),
    month = VALUES(month),
    month_name = VALUES(month_name),
    day = VALUES(day),
    day_of_week = VALUES(day_of_week),
    week_of_year = VALUES(week_of_year),
    is_weekend = VALUES(is_weekend);




-- 事實表
CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    order_priority VARCHAR(50),
    product_id VARCHAR(50),
    customer_id INT,
    region_id INT,
    date_id DATE,
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,5),
    profit DECIMAL(10,5),
    shipping_cost DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id)
);