-- 顧客維度
INSERT INTO dim_customer (customer_name, segment)
SELECT DISTINCT customer_name, segment
FROM staging_sales AS st_cus
ON DUPLICATE KEY UPDATE
    segment = st_cus.segment;

-- 商品維度
INSERT INTO dim_product (product_id, category, sub_category, product_name)
SELECT DISTINCT product_id, category, sub_category, product_name
FROM staging_sales AS st_pro
ON DUPLICATE KEY UPDATE
    category = st_pro.category,
    sub_category = st_pro.sub_category,
    product_name = st_pro.product_name;

-- 地區維度
INSERT INTO dim_region (state, country, market, region)
SELECT DISTINCT state, country, market, region
FROM staging_sales AS st_reg
ON DUPLICATE KEY UPDATE
    country = st_reg.country,
    market = st_reg.market,
    region = st_reg.region;

-- 插入事實表
INSERT INTO fact_sales (
    order_id, order_date, ship_date, ship_mode, order_priority,
    product_id, customer_id, region_id, date_id,
    sales, quantity, discount, profit, shipping_cost
)
SELECT s.order_id, s.order_date, s.ship_date, s.ship_mode, s.order_priority,
       s.product_id,
       c.customer_id,
       r.region_id,
       s.order_date,
       s.sales, s.quantity, s.discount, s.profit, s.shipping_cost
FROM staging_sales s
JOIN dim_customer c ON s.customer_name = c.customer_name AND s.segment = c.segment
JOIN dim_product p ON s.product_id = p.product_id
JOIN dim_region r ON s.state = r.state AND s.country = r.country
JOIN dim_date d ON s.order_date = d.date_id;