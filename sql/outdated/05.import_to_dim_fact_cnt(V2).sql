
-- ========================================
-- CREATE TABLE（新增唯一性約束）
-- ========================================

-- 日期維度（✅ 已完美）
CREATE TABLE IF NOT EXISTS dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_of_week VARCHAR(20),
    week_of_year INT,
    is_weekend TINYINT,
    INDEX idx_year (year),
    INDEX idx_month (month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 客戶維度（✅ 新增唯一性）
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(20),
    UNIQUE KEY uk_customer_segment (customer_name, segment)  -- 👈 防止重覆
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 地理維度（✅ 全新增唯一性約束）
CREATE TABLE IF NOT EXISTS dim_region (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(20),
    UNIQUE KEY uk_region_name (region_name)  -- 👈 防止重覆
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_market (
    market_id INT AUTO_INCREMENT PRIMARY KEY,
    market_name VARCHAR(20),
    region_id INT,
    UNIQUE KEY uk_market_region (market_name, region_id),  -- 👈 防止同地區重覆市場
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_country (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(50),
    market_id INT,
    UNIQUE KEY uk_country_market (country_name, market_id),  -- 👈 防止同市場重覆國家
    FOREIGN KEY (market_id) REFERENCES dim_market(market_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_state (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    state_name VARCHAR(50),
    country_id INT,
    UNIQUE KEY uk_state_country (state_name, country_id),  -- 👈 關鍵！解決膨脹
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id),
    INDEX idx_state_name (state_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 產品維度（✅ 已完美）
CREATE TABLE IF NOT EXISTS dim_category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50),
    UNIQUE KEY uk_category_name (category_name)  -- 👈 新增
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_sub_category (
    sub_category_id INT AUTO_INCREMENT PRIMARY KEY,
    sub_category_name VARCHAR(50),
    category_id INT,
    UNIQUE KEY uk_subcat_category (sub_category_name, category_id),  -- 👈 新增
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    raw_product_id VARCHAR(20) UNIQUE NOT NULL,
    product_name VARCHAR(255),
    sub_category_id INT,
    FOREIGN KEY (sub_category_id) REFERENCES dim_sub_category(sub_category_id),
    INDEX idx_raw_product_id (raw_product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 事實表（✅ 新增業務唯一性）
CREATE TABLE IF NOT EXISTS fact_sales (
    sales_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(20),
    order_date_id DATE NOT NULL,
    ship_date_id DATE NOT NULL,
    ship_mode VARCHAR(20),
    customer_id INT NOT NULL,
    state_id INT NOT NULL,
    product_id INT NOT NULL,
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,5),
    profit DECIMAL(10,5),
    shipping_cost DECIMAL(10,2),
    order_priority VARCHAR(10),
    year INT,
    
    -- 👈 關鍵業務唯一性約束
    UNIQUE KEY uk_order_product_date (order_id, product_id, order_date_id),
    
    FOREIGN KEY (order_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (ship_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    
    INDEX idx_order_date (order_date_id),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- IMPORT TABLE（修正 JOIN + 防重覆）
-- ========================================

-- 1. 日期維度（✅ 不變）
INSERT INTO dim_date (date_id, year, quarter, month, month_name, day, day_of_week, week_of_year, is_weekend)
SELECT DISTINCT d AS date_id, YEAR(d), QUARTER(d), MONTH(d), MONTHNAME(d),
       DAY(d), DAYNAME(d), WEEKOFYEAR(d), CASE WHEN DAYOFWEEK(d) IN (1,7) THEN 1 ELSE 0 END
FROM (SELECT order_date AS d FROM staging_sales UNION SELECT ship_date AS d FROM staging_sales) t
WHERE NOT EXISTS (SELECT 1 FROM dim_date dd WHERE dd.date_id = t.d);

-- 2. 客戶維度（✅ 用 INSERT IGNORE）
INSERT IGNORE INTO dim_customer (customer_name, segment)
SELECT DISTINCT s.customer_name, s.segment FROM staging_sales s;

-- 3. 地理維度（✅ 層級載入 + INSERT IGNORE）
INSERT IGNORE INTO dim_region (region_name) SELECT DISTINCT region FROM staging_sales;
INSERT IGNORE INTO dim_market (market_name, region_id)
SELECT DISTINCT s.market, r.region_id FROM staging_sales s JOIN dim_region r ON s.region = r.region_name;
INSERT IGNORE INTO dim_country (country_name, market_id)
SELECT DISTINCT s.country, m.market_id FROM staging_sales s JOIN dim_market m ON s.market = m.market_name;
INSERT IGNORE INTO dim_state (state_name, country_id)
SELECT DISTINCT s.state, c.country_id FROM staging_sales s JOIN dim_country c ON s.country = c.country_name;

-- 4. 產品維度（✅ 修正為 INSERT IGNORE）
INSERT IGNORE INTO dim_category (category_name) SELECT DISTINCT category FROM staging_sales;
INSERT IGNORE INTO dim_sub_category (sub_category_name, category_id)
SELECT DISTINCT s.sub_category, c.category_id 
FROM staging_sales s JOIN dim_category c ON s.category = c.category_name;
INSERT IGNORE INTO dim_product (raw_product_id, product_name, sub_category_id)
SELECT DISTINCT s.product_id, s.product_name, sc.sub_category_id
FROM staging_sales s JOIN dim_sub_category sc ON s.sub_category = sc.sub_category_name;

-- 5. 事實表（✅ 標準 TRUNCATE + INSERT IGNORE，絕對安全）
TRUNCATE TABLE fact_sales;
INSERT IGNORE INTO fact_sales (
    order_id, order_date_id, ship_date_id, ship_mode,
    customer_id, state_id, product_id, sales, quantity, discount, 
    profit, shipping_cost, order_priority, year
)
SELECT
    s.order_id, s.order_date, s.ship_date, s.ship_mode,
    c.customer_id, 
    st.state_id, 
    p.product_id,
    s.sales, s.quantity, s.discount, s.profit, s.shipping_cost,
    s.order_priority, YEAR(s.order_date)
FROM staging_sales s
JOIN dim_customer c ON s.customer_name = c.customer_name AND s.segment = c.segment
JOIN dim_country dc ON s.country = dc.country_name                           -- 👈 先國家
JOIN dim_state st ON s.state = st.state_name AND st.country_id = dc.country_id  -- 👈 雙條件 JOIN
JOIN dim_product p ON s.product_id = p.raw_product_id;

-- ========================================
-- 驗證（執行後檢查）
-- ========================================
SELECT 'staging_rows' src, COUNT(*) cnt FROM staging_sales
UNION ALL SELECT 'fact_rows' src, COUNT(*) FROM fact_sales;

-- 檢查 dim_state 重覆
SELECT state_name, country_id, COUNT(*) FROM dim_state GROUP BY state_name, country_id HAVING COUNT(*) > 1;