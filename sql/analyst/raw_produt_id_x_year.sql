-- raw_product_id × 年份（用 dim_date 的 year）
SELECT
    raw_product_id,
    product_name,
    order_year,
    SUM(sales)    AS total_sales,
    SUM(quantity) AS total_quantity,
    SUM(profit)   AS total_profit
FROM vw_sales_full
GROUP BY
    raw_product_id,
    product_name,
    order_year
ORDER BY
    raw_product_id,
    order_year;
