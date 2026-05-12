-- category_profit_summary.sql
-- Which categories generate the highest sales and profit?
SELECT
    category_name,
    ROUND(SUM(total_sales), 0)   AS sales,
    ROUND(SUM(total_profit), 0)  AS profit,
    ROUND(
        SUM(total_profit) / NULLIF(SUM(total_sales), 0) * 100
    , 1)                          AS margin_pct
FROM vw_sales_summary
GROUP BY category_name
ORDER BY sales DESC;