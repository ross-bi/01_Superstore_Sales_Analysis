-- 全局總數 (staging_sales)
SELECT
    COUNT(*)      AS row_count,
    SUM(sales)    AS total_sales,
    SUM(quantity) AS total_quantity,
    SUM(profit)   AS total_profit,
    COUNT(DISTINCT CONCAT(order_id, '-', product_id)) AS staging_order_products
FROM staging_sales;

-- 全局總數 (fact_sales)
SELECT
    COUNT(*)      AS row_count,
    SUM(sales)    AS f_total_sales,
    SUM(quantity) AS f_total_quantity,
    SUM(profit)   AS f_total_profit,
    COUNT(DISTINCT CONCAT(order_id, '-', dp.raw_product_id)) AS f_order_products
FROM fact_sales f
JOIN dim_product dp 
    ON f.product_id = dp.product_id;


-- 對比使用 view（確保 join 後數據一致）
SELECT
    COUNT(*)      AS row_count,
    SUM(sales)    AS vw_total_sales,
    SUM(quantity) AS vw_total_quantity,
    SUM(profit)   AS vw_total_profit,
    COUNT(DISTINCT CONCAT(order_id, '-', raw_product_id )) AS vw_order_products
FROM vw_sales_full;




