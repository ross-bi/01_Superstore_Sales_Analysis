-- ============================================================
-- Superstore Repo 結構理解 SQL
-- 目的：確認所有 table 存在、欄位結構、FK 關係、資料筆數
-- ============================================================

-- ① 確認 database 裡有哪些 table 和 view
SELECT 
    TABLE_NAME,
    TABLE_TYPE,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_TYPE, TABLE_NAME;


-- ② 確認每張 table 的欄位清單（PK / FK 一目了然）
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION  AS col_order,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY        AS key_type    -- PRI / MUL / UNI
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ③ 確認每張 table 的實際筆數（與 staging 核對用）
SELECT 'staging_sales'    AS tbl, COUNT(*) AS row_cnt FROM staging_sales
UNION ALL
SELECT 'fact_sales',               COUNT(*) FROM fact_sales
UNION ALL
SELECT 'dim_date',                 COUNT(*) FROM dim_date
UNION ALL
SELECT 'dim_customer',             COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_product',              COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_sub_category',         COUNT(*) FROM dim_sub_category
UNION ALL
SELECT 'dim_category',             COUNT(*) FROM dim_category
UNION ALL
SELECT 'dim_state',                COUNT(*) FROM dim_state
UNION ALL
SELECT 'dim_country',              COUNT(*) FROM dim_country
UNION ALL
SELECT 'dim_market',               COUNT(*) FROM dim_market
UNION ALL
SELECT 'dim_region',               COUNT(*) FROM dim_region;


-- ④ 確認地理層級鏈是否完整：region → market → country → state
SELECT
    r.region_name,
    m.market_name,
    co.country_name,
    s.state_name
FROM dim_region   r
JOIN dim_market   m  ON r.region_id  = m.region_id
JOIN dim_country  co ON m.market_id  = co.market_id
JOIN dim_state    s  ON co.country_id = s.country_id
ORDER BY r.region_name, m.market_name, co.country_name
LIMIT 20;


-- ⑤ 確認產品層級鏈是否完整：category → sub_category → product
SELECT
    cat.category_name,
    sc.sub_category_name,
    p.product_id,
    p.raw_product_id,
    p.product_name
FROM dim_category     cat
JOIN dim_sub_category sc ON cat.category_id    = sc.category_id
JOIN dim_product      p  ON sc.sub_category_id = p.sub_category_id
ORDER BY cat.category_name, sc.sub_category_name
LIMIT 20;


-- ⑥ 確認 fact_sales 的 FK 都能正常 JOIN（孤兒記錄偵測）
SELECT
    'order_date 孤兒'  AS check_name, COUNT(*) AS orphan_cnt
FROM fact_sales f
LEFT JOIN dim_date d ON f.order_date_id = d.date_id
WHERE d.date_id IS NULL
UNION ALL
SELECT 'ship_date 孤兒',   COUNT(*)
FROM fact_sales f
LEFT JOIN dim_date d ON f.ship_date_id = d.date_id
WHERE d.date_id IS NULL
UNION ALL
SELECT 'customer 孤兒',    COUNT(*)
FROM fact_sales f
LEFT JOIN dim_customer c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'state 孤兒',       COUNT(*)
FROM fact_sales f
LEFT JOIN dim_state s ON f.state_id = s.state_id
WHERE s.state_id IS NULL
UNION ALL
SELECT 'product 孤兒',     COUNT(*)
FROM fact_sales f
LEFT JOIN dim_product p ON f.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ⑦ 確認 vw_sales_full 和 vw_sales_summary 存在且可查
SELECT COUNT(*) AS vw_full_row_cnt    FROM vw_sales_full;
SELECT COUNT(*) AS vw_summary_row_cnt FROM vw_sales_summary;


-- ⑧ fact_sales 基本 KPI 快速核對
SELECT
    MIN(order_date_id)  AS earliest_order,
    MAX(order_date_id)  AS latest_order,
    COUNT(*)            AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(sales), 0)     AS total_sales,
    ROUND(SUM(profit), 0)    AS total_profit
FROM fact_sales;