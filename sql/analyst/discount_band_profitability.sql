SELECT
    CASE WHEN discount = 0       THEN 'No Discount'
         WHEN discount <= 0.10   THEN 'Low (0–10%)'
         WHEN discount <= 0.30   THEN 'Medium (11–30%)'
         ELSE                         'High (>30%)'
    END AS discount_band,
    SUM(sales)   AS total_sales,
    SUM(profit)  AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM vw_sales_full            -- ← 用 vw_sales_full
GROUP BY discount_band
ORDER BY profit_margin_pct DESC;