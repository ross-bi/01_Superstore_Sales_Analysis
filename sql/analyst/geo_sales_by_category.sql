-- 市場 / 地區 × 類別
SELECT
    market_name,
    country_name,
    state_name,
    category_name,
    sub_category_name,
    SUM(sales)    AS total_sales,
    SUM(quantity) AS total_quantity,
    SUM(profit)   AS total_profit
FROM vw_sales_full
GROUP BY
    market_name,
    country_name,
    state_name,
    category_name,
    sub_category_name
ORDER BY
    market_name,
    country_name,
    category_name,
    sub_category_name;
