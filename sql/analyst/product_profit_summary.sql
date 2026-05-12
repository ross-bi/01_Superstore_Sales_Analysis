-- 每個 raw_product_id 的銷售 & 利潤
SELECT
    raw_product_id,
    product_name,
    SUM(sales)        AS total_sales,
    SUM(quantity)     AS total_quantity,
    SUM(profit)       AS total_profit,
    SUM(shipping_cost) AS total_shipping_cost
FROM vw_sales_full
GROUP BY
    raw_product_id,
    product_name
ORDER BY
    total_sales DESC;
