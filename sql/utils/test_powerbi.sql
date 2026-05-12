-- 在 MySQL 先確認數字合理
SELECT 
    '總銷售額' as KPI, FORMAT(SUM(total_sales), 0) as value
FROM vw_sales_summary
UNION ALL
SELECT '總利潤', FORMAT(SUM(total_profit), 0)
FROM vw_sales_summary
UNION ALL  
SELECT '平均利潤率', CONCAT(ROUND(AVG(profit_margin_pct), 1), '%')
FROM vw_sales_summary;
