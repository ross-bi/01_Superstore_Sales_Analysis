-- 按月份 × raw_product_id
SELECT
    order_year,
    order_month,
    order_month_name,
    raw_product_id,
    product_name,
    SUM(sales)      AS total_sales,
    SUM(quantity)   AS total_quantity,
    SUM(discount)   AS total_discount,
    SUM(profit)     AS total_profit
FROM vw_sales_full
GROUP BY
    order_year,
    order_month,
    order_month_name,
    raw_product_id,
    product_name
ORDER BY
    order_year,
    order_month,
    raw_product_id;
