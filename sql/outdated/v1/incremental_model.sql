-- 更新新進來的訂單
INSERT INTO fact_sales (order_id, order_date_id, ship_date_id, customer_id, product_id, state_id, sales, quantity, discount, profit, shipping_cost)
SELECT 
    s.order_id,
    d1.order_date_id,
    d2.ship_date_id,
    c.customer_id,
    p.product_id,
    st.state_id,
    s.sales,
    s.quantity,
    s.discount,
    s.profit,
    s.shipping_cost
FROM staging_superstore s
JOIN dim_orderdate d1 ON s.order_date = d1.order_date
JOIN dim_shipdate d2 ON s.ship_date = d2.ship_date
JOIN dim_customer c ON s.customer_name = c.customer_name
JOIN dim_product p ON s.product_id = p.product_code
JOIN dim_state st ON s.state = st.state
WHERE s.order_date > (SELECT MAX(d1.order_date) FROM fact_sales fs JOIN dim_orderdate d1 ON fs.order_date_id = d1.order_date);