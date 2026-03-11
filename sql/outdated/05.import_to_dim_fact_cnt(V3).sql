-- ========================================
-- ✅ 最終完美版 - 移除不必要唯一性約束，直接貼上執行
-- ========================================

-- ========================================
-- CREATE TABLE（移除事實表唯一性約束）
-- ========================================

-- 日期維度
CREATE TABLE IF NOT EXISTS dim_date (
    date_id DATE PRIMARY KEY,
    year INT, quarter INT, month INT, month_name VARCHAR(20),
    day INT, day_of_week VARCHAR(20), week_of_year INT, is_weekend TINYINT,
    INDEX idx_year (year), INDEX idx_month (month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 客戶維度
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(20),
    UNIQUE KEY uk_customer_segment (customer_name, segment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 地理維度（完整層級）
CREATE TABLE IF NOT EXISTS dim_region (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(20),
    UNIQUE KEY uk_region_name (region_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_market (
    market_id INT AUTO_INCREMENT PRIMARY KEY,
    market_name VARCHAR(20),
    region_id INT,
    UNIQUE KEY uk_market_region (market_name, region_id),
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_country (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(50),
    market_id INT,
    UNIQUE KEY uk_country_market (country_name, market_id),
    FOREIGN KEY (market_id) REFERENCES dim_market(market_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_state (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    state_name VARCHAR(50),
    country_id INT,
    UNIQUE KEY uk_state_country (state_name, country_id),
    FOREIGN KEY (country_id) REFERENCES dim_country(country_id),
    INDEX idx_state_name (state_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 產品維度
CREATE TABLE IF NOT EXISTS dim_category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50),
    UNIQUE KEY uk_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_sub_category (
    sub_category_id INT AUTO_INCREMENT PRIMARY KEY,
    sub_category_name VARCHAR(50),
    category_id INT,
    UNIQUE KEY uk_subcat_category (sub_category_name, category_id),
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

-- 事實表（✅ 移除唯一性約束，允許訂單拆分）
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
    -- ✅ 移除 uk_order_product_date 約束，允許分批出貨
    FOREIGN KEY (order_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (ship_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    INDEX idx_order_date (order_date_id),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- DATA LOADING（正常執行，無警告）
-- ========================================

-- 1. 日期維度（10年完整）

INSERT INTO dim_date (date_id, year, quarter, month, month_name, day, day_of_week, week_of_year, is_weekend)
SELECT 
    DATE_ADD('2011-01-01', INTERVAL seq.n DAY),
    YEAR(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    QUARTER(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    MONTH(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    MONTHNAME(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    DAY(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    DAYNAME(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    WEEKOFYEAR(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)),
    CASE WHEN DAYOFWEEK(DATE_ADD('2011-01-01', INTERVAL seq.n DAY)) IN (1,7) THEN 1 ELSE 0 END
FROM (
    SELECT a.N + b.N * 10 + c.N * 100 + d.N * 1000 AS n
    FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
         (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
         (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
         (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) d
    WHERE a.N + b.N * 10 + c.N * 100 + d.N * 1000 < 3653
) seq;

-- 2. 客戶維度

INSERT IGNORE INTO dim_customer (customer_name, segment)
SELECT DISTINCT customer_name, segment FROM staging_sales;

-- 3. 地理維度（層級依賴）

INSERT IGNORE INTO dim_region (region_name) SELECT DISTINCT region FROM staging_sales;
INSERT IGNORE INTO dim_market (market_name, region_id) 
SELECT DISTINCT s.market, r.region_id FROM staging_sales s JOIN dim_region r ON s.region = r.region_name;
INSERT IGNORE INTO dim_country (country_name, market_id) 
SELECT DISTINCT s.country, m.market_id FROM staging_sales s JOIN dim_market m ON s.market = m.market_name;
INSERT IGNORE INTO dim_state (state_name, country_id) 
SELECT DISTINCT s.state, c.country_id FROM staging_sales s JOIN dim_country c ON s.country = c.country_name;

-- 4. 產品維度（層級依賴）

INSERT IGNORE INTO dim_category (category_name) SELECT DISTINCT category FROM staging_sales;
INSERT IGNORE INTO dim_sub_category (sub_category_name, category_id)
SELECT DISTINCT s.sub_category, c.category_id FROM staging_sales s JOIN dim_category c ON s.category = c.category_name;
INSERT IGNORE INTO dim_product (raw_product_id, product_name, sub_category_id)
SELECT DISTINCT s.product_id, s.product_name, sc.sub_category_id
FROM staging_sales s JOIN dim_sub_category sc ON s.sub_category = sc.sub_category_name;

-- 5. 事實表（✅ 完整資料，無唯一性限制）

INSERT INTO fact_sales (
    order_id, order_date_id, ship_date_id, ship_mode, customer_id, state_id, 
    product_id, sales, quantity, discount, profit, shipping_cost, order_priority, year
)
SELECT
    s.order_id, s.order_date, s.ship_date, s.ship_mode,
    c.customer_id, st.state_id, p.product_id,
    s.sales, s.quantity, s.discount, s.profit, s.shipping_cost, s.order_priority, YEAR(s.order_date)
FROM staging_sales s
-- ✅ 完整地理層級JOIN
JOIN dim_region r ON s.region = r.region_name
JOIN dim_market m ON s.market = m.market_name AND m.region_id = r.region_id
JOIN dim_country dc ON s.country = dc.country_name AND dc.market_id = m.market_id
JOIN dim_state st ON s.state = st.state_name AND st.country_id = dc.country_id
JOIN dim_customer c ON s.customer_name = c.customer_name AND s.segment = c.segment
JOIN dim_product p ON s.product_id = p.raw_product_id
WHERE s.order_date BETWEEN '2011-01-01' AND '2020-12-31';

-- ========================================
-- ✅ 最終驗證報告
-- ========================================
SELECT '總覽統計' AS 報告類型, 
       'staging_sales' AS 表名, COUNT(*) AS 筆數 FROM staging_sales
UNION ALL SELECT '總覽統計', 'fact_sales', COUNT(*) FROM fact_sales
UNION ALL SELECT '維度統計', 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT '維度統計', 'dim_state', COUNT(*) FROM dim_state
UNION ALL SELECT '維度統計', 'dim_product', COUNT(*) FROM dim_product
UNION ALL SELECT '日期範圍', CONCAT(MIN(date_id), ' ~ ', MAX(date_id)), COUNT(*) FROM dim_date;

-- 檢查匹配成功率
SELECT 
    CONCAT(ROUND(100.0 * COUNT(f.sales_id) / COUNT(s.order_id), 2), '%') AS '成功匹配率',
    COUNT(f.sales_id) AS '事實表筆數',
    COUNT(s.order_id) AS '原始筆數'
FROM staging_sales s
LEFT JOIN fact_sales f ON s.order_id = f.order_id;

-- 檢查重複訂單業務合理性
SELECT 
    '重複訂單明細' as 檢查項目,
    order_id, product_id, order_date_id,
    COUNT(*) as 明細行數,
    SUM(sales) as 總銷售額,
    SUM(quantity) as 總數量,
    GROUP_CONCAT(DISTINCT ship_mode) as 出貨方式
FROM fact_sales 
GROUP BY order_id, product_id, order_date_id
HAVING COUNT(*) > 1
LIMIT 10;
