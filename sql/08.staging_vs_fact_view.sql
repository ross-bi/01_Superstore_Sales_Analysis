SELECT
    '誤差 (staging - fact)'                               AS source,
    s.row_count          - f.row_count                    AS row_count,
    s.total_sales        - f.total_sales                  AS total_sales,
    s.total_quantity     - f.total_quantity               AS total_quantity,
    s.total_profit       - f.total_profit                 AS total_profit,
    s.order_products     - f.order_products               AS order_products
FROM (
    SELECT
        COUNT(*)      AS row_count,
        SUM(sales)    AS total_sales,
        SUM(quantity) AS total_quantity,
        SUM(profit)   AS total_profit,
        COUNT(DISTINCT CONCAT(order_id, '-', product_id)) AS order_products
    FROM staging_sales
) s,
(
    SELECT
        COUNT(*)      AS row_count,
        SUM(sales)    AS total_sales,
        SUM(quantity) AS total_quantity,
        SUM(profit)   AS total_profit,
        COUNT(DISTINCT CONCAT(f.order_id, '-', dp.raw_product_id)) AS order_products
    FROM fact_sales f
    JOIN dim_product dp ON f.product_id = dp.product_id
) f

UNION ALL

SELECT '誤差 (staging - view)'                            AS source,
    s.row_count          - v.row_count                    AS row_count,
    s.total_sales        - v.total_sales                  AS total_sales,
    s.total_quantity     - v.total_quantity               AS total_quantity,
    s.total_profit       - v.total_profit                 AS total_profit,
    s.order_products     - v.order_products               AS order_products
FROM (
    SELECT
        COUNT(*)      AS row_count,
        SUM(sales)    AS total_sales,
        SUM(quantity) AS total_quantity,
        SUM(profit)   AS total_profit,
        COUNT(DISTINCT CONCAT(order_id, '-', product_id)) AS order_products
    FROM staging_sales
) s,
(
    SELECT
        COUNT(*)      AS row_count,
        SUM(sales)    AS total_sales,
        SUM(quantity) AS total_quantity,
        SUM(profit)   AS total_profit,
        COUNT(DISTINCT CONCAT(order_id, '-', raw_product_id)) AS order_products
    FROM vw_sales_full
) v

UNION ALL

SELECT 'staging_sales'                                    AS source,
    COUNT(*)                                              AS row_count,
    SUM(sales)                                            AS total_sales,
    SUM(quantity)                                         AS total_quantity,
    SUM(profit)                                           AS total_profit,
    COUNT(DISTINCT CONCAT(order_id, '-', product_id))     AS order_products
FROM staging_sales

UNION ALL

SELECT 'fact_sales'                                       AS source,
    COUNT(*)                                              AS row_count,
    SUM(f.sales)                                          AS total_sales,
    SUM(f.quantity)                                       AS total_quantity,
    SUM(f.profit)                                         AS total_profit,
    COUNT(DISTINCT CONCAT(f.order_id, '-', dp.raw_product_id)) AS order_products
FROM fact_sales f
JOIN dim_product dp ON f.product_id = dp.product_id

UNION ALL

SELECT 'vw_sales_full'                                    AS source,
    COUNT(*)                                              AS row_count,
    SUM(sales)                                            AS total_sales,
    SUM(quantity)                                         AS total_quantity,
    SUM(profit)                                           AS total_profit,
    COUNT(DISTINCT CONCAT(order_id, '-', raw_product_id)) AS order_products
FROM vw_sales_full

ORDER BY FIELD(source,
    'staging_sales', 'fact_sales', 'vw_sales_full',
    '誤差 (staging - fact)', '誤差 (staging - view)');