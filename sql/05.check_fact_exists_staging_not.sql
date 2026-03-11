/* 核對資料 staging_sales 匯入，fact_sales 有，但 staging_sales 沒有 */
SELECT f.order_id,
       f.product_id,   -- 代理鍵
       f.sales,
       f.quantity,
       f.discount,
       f.profit,
       f.shipping_cost
FROM fact_sales f
JOIN dim_product p
  ON f.product_id = p.product_id
WHERE NOT EXISTS (
    SELECT 1
    FROM staging_sales s
    WHERE s.order_id = f.order_id
      AND s.product_id = p.raw_product_id   -- 對應回原始 product_id
      AND s.sales = f.sales
      AND s.quantity = f.quantity
      AND s.discount = f.discount
      AND s.profit = f.profit
      AND s.shipping_cost = f.shipping_cost
);