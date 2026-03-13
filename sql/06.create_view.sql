-- 建議用 VIEW，方便之後重複使用
CREATE OR REPLACE VIEW vw_sales_full AS
SELECT
    f.sales_id,
    f.order_id,
    f.order_date_id,
    od.year          AS order_year,
    od.quarter       AS order_quarter,
    od.month         AS order_month,
    od.month_name    AS order_month_name,
    f.ship_date_id,
    sd.year          AS ship_year,
    sd.quarter       AS ship_quarter,
    sd.month         AS ship_month,
    sd.month_name    AS ship_month_name,
    f.ship_mode,
    f.customer_id,
    c.customer_name,
    c.segment,
    f.state_id,
    s.state_name,
    s.country_id,
    co.country_name,
    co.market_id,
    m.market_name,
    r.region_id,
    r.region_name,           
    f.product_id,
    p.raw_product_id,        -- Power BI 用這個做真正單號
    p.product_name,
    p.sub_category_id,
    sc.sub_category_name,
    sc.category_id,
    cat.category_name,
    f.sales,
    f.quantity,
    f.discount,
    f.profit,
    f.shipping_cost,
    f.order_priority,
    f.order_year              AS fact_year
FROM fact_sales       AS f
LEFT JOIN dim_date    AS od  ON f.order_date_id = od.date_id
LEFT JOIN dim_date    AS sd  ON f.ship_date_id  = sd.date_id
LEFT JOIN dim_customer AS c  ON f.customer_id   = c.customer_id
LEFT JOIN dim_state    AS s  ON f.state_id      = s.state_id
LEFT JOIN dim_country  AS co ON s.country_id    = co.country_id
LEFT JOIN dim_market   AS m  ON co.market_id    = m.market_id
LEFT JOIN dim_region   AS r  ON m.region_id     = r.region_id     
LEFT JOIN dim_product  AS p  ON f.product_id    = p.product_id
LEFT JOIN dim_sub_category AS sc
       ON p.sub_category_id = sc.sub_category_id
LEFT JOIN dim_category AS cat
       ON sc.category_id    = cat.category_id;
