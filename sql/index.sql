-- ========================================
-- 1. 安全建立索引（檢查後才建立）
-- ========================================
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fact_sales' AND INDEX_NAME = 'idx_fact_year';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_fact_year ON fact_sales(year)', 
    'SELECT "idx_fact_year 已存在" AS status');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fact_sales' AND INDEX_NAME = 'idx_fact_profit';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_fact_profit ON fact_sales(profit)', 
    'SELECT "idx_fact_profit 已存在" AS status');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fact_sales' AND INDEX_NAME = 'idx_fact_region';

SET @sql = IF(@index_exists = 0, 
    'CREATE INDEX idx_fact_region ON fact_sales(state_id)', 
    'SELECT "idx_fact_region 已存在" AS status');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ========================================
-- 2. 銷售總覽視圖
-- ========================================
CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT 
    dd.year, dd.quarter, dd.month, dd.month_name,
    dc.segment,
    ds.state_name,
    dr.region_name,
    dp.category_name, 
    dsc.sub_category_name,
    SUM(fs.sales) as total_sales,
    SUM(fs.quantity) as total_qty,
    SUM(fs.profit) as total_profit,
    COUNT(DISTINCT fs.order_id) as order_count,
    ROUND(AVG(COALESCE(fs.profit / fs.sales, 0)) * 100, 2) as profit_margin_pct
FROM fact_sales fs
JOIN dim_date dd ON fs.order_date_id = dd.date_id
JOIN dim_customer dc ON fs.customer_id = dc.customer_id
JOIN dim_state ds ON fs.state_id = ds.state_id
JOIN dim_country dcn ON ds.country_id = dcn.country_id
JOIN dim_market dm ON dcn.market_id = dm.market_id
JOIN dim_region dr ON dm.region_id = dr.region_id
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_sub_category dsc ON p.sub_category_id = dsc.sub_category_id
JOIN dim_category dp ON dsc.category_id = dp.category_id
GROUP BY 
    dd.year, dd.quarter, dd.month, dd.month_name,
    dc.segment, dc.customer_name,
    ds.state_name, dr.region_name,
    dp.category_name, dsc.sub_category_name;

-- ========================================
-- 3. 驗證視圖（立即測試）
-- ========================================
SELECT 
    category_name,
    ROUND(SUM(total_sales), 0) as sales_million,
    ROUND(SUM(total_profit), 0) as profit_k,
    ROUND(AVG(profit_margin_pct), 1) as avg_margin_pct,
    SUM(order_count) as total_orders
FROM vw_sales_summary 
GROUP BY category_name 
ORDER BY sales_million DESC LIMIT 5;