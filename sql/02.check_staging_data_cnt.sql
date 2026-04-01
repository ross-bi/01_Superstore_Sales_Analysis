-- 查詢欄位數與行數
SELECT  
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_schema = 'superstore_db'
       AND table_name   = 'staging_sales') AS column_count,
    (SELECT COUNT(*) 
     FROM superstore_db.staging_sales)     AS row_count;

-- 前 10 筆預覽
SELECT *
FROM superstore_db.staging_sales
LIMIT 10;


-- Row Count 與唯一性
SELECT 
    COUNT(*)                                                                      AS total_rows,
    COUNT(DISTINCT order_id)                                                      AS distinct_orders
FROM staging_sales;

-- 完全重複 Row 檢查
SELECT 
    order_id, order_date,      
    product_id, product_name,   
    customer_name, state, country, market, region,
    sales, quantity, discount, profit, shipping_cost,
    COUNT(*) AS cnt
FROM staging_sales
GROUP BY 
    order_id, order_date,       
    product_id, product_name,   
    customer_name, state, country, market, region,
    sales, quantity, discount, profit, shipping_cost
HAVING COUNT(*) > 1
ORDER BY cnt DESC;