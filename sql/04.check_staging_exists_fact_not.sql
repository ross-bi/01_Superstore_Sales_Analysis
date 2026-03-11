/*核對資料 staging_sales 匯入，staging_sales 有，但 fact_sales 沒有*/
SELECT s.order_id,
       s.product_id   AS raw_product_id,
       s.sales,
       s.quantity,
       s.discount,
       s.profit,
       s.shipping_cost
FROM staging_sales s
JOIN dim_product p
  ON s.product_id = p.raw_product_id
WHERE NOT EXISTS (
    SELECT 1
    FROM fact_sales f
    WHERE f.order_id = s.order_id
      AND f.product_id = p.product_id   -- 使用代理鍵比對
      AND f.sales = s.sales
      AND f.quantity = s.quantity
      AND f.discount = s.discount
      AND f.profit = s.profit
      AND f.shipping_cost = s.shipping_cost
);