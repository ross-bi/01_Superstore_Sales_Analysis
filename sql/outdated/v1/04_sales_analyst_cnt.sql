-- 各 Category 總銷售額
SELECT category,
       SUM(sales) AS total_sales
FROM staging_superstore
GROUP BY category
ORDER BY total_sales DESC;

-- 每個 Category 中取前 5 Sub-Category
WITH sub_sales AS (
    SELECT category,
           sub_category,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category
)
SELECT category, sub_category, total_sales
FROM sub_sales
WHERE rn <= 5
ORDER BY category, total_sales DESC;

-- 每個 Category → Sub-Category (TOP5) → Product Name (TOP10)
WITH sub_sales AS (
    SELECT category,
           sub_category,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category
),
prod_sales AS (
    SELECT category,
           sub_category,
           product_name,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category, sub_category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category, product_name
)
SELECT p.category, p.sub_category, p.product_name, p.total_sales
FROM prod_sales p
JOIN sub_sales s
  ON p.category = s.category AND p.sub_category = s.sub_category
WHERE s.rn <= 5   -- 只取每個 Category 的前 5 Sub-Category
  AND p.rn <= 10  -- 每個 Sub-Category 的前 10 Product
ORDER BY p.category, s.total_sales DESC, p.total_sales DESC;

-- 各 Category 的利潤率
SELECT category,
       SUM(profit) AS total_profit,
       SUM(sales) AS total_sales,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY category
ORDER BY profit_margin_percent DESC;

-- 每個 Category 中取前 5 Sub-Category 的利潤率
WITH sub_sales AS (
    SELECT category,
           sub_category,
           SUM(profit) AS total_profit,
           SUM(sales) AS total_sales,
           ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category
)
SELECT category, sub_category, total_sales, total_profit, profit_margin_percent
FROM sub_sales
WHERE rn <= 5
ORDER BY category, total_sales DESC;

-- 每個 Category → Sub-Category (TOP5) → Product Name (TOP10) 的利潤率
WITH sub_sales AS (
    SELECT category,
           sub_category,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category
),
prod_sales AS (
    SELECT category,
           sub_category,
           product_name,
           SUM(profit) AS total_profit,
           SUM(sales) AS total_sales,
           ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent,
           ROW_NUMBER() OVER (PARTITION BY category, sub_category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category, product_name
)
SELECT p.category, p.sub_category, p.product_name,
       p.total_sales, p.total_profit, p.profit_margin_percent
FROM prod_sales p
JOIN sub_sales s
  ON p.category = s.category AND p.sub_category = s.sub_category
WHERE s.rn <= 5   -- 每個 Category 的前 5 Sub-Category
  AND p.rn <= 10  -- 每個 Sub-Category 的前 10 Product
ORDER BY p.category, s.total_sales DESC, p.total_sales DESC;

-- 按折扣區間 + 分析利潤率
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount BETWEEN 0.01 AND 0.10 THEN 'Low (0-10%)'
        WHEN discount BETWEEN 0.11 AND 0.30 THEN 'Medium (11-30%)'
        ELSE 'High (>30%)'
    END AS discount_range,
    COUNT(*) AS order_count,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY discount_range
ORDER BY discount_range;

-- 按折扣區間 + Category 分析利潤率
SELECT category,
       CASE 
           WHEN discount = 0 THEN 'No Discount'
           WHEN discount BETWEEN 0.01 AND 0.10 THEN 'Low (0-10%)'
           WHEN discount BETWEEN 0.11 AND 0.30 THEN 'Medium (11-30%)'
           ELSE 'High (>30%)'
       END AS discount_range,
       SUM(profit) AS total_profit,
       SUM(sales) AS total_sales,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY category, discount_range
ORDER BY category, discount_range;

-- 按折扣區間 + Sub-Category (TOP5) 分析利潤率
WITH sub_sales AS (
    SELECT category, sub_category,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category
)
SELECT s.category, s.sub_category,
       CASE 
           WHEN o.discount = 0 THEN 'No Discount'
           WHEN o.discount BETWEEN 0.01 AND 0.10 THEN 'Low (0-10%)'
           WHEN o.discount BETWEEN 0.11 AND 0.30 THEN 'Medium (11-30%)'
           ELSE 'High (>30%)'
       END AS discount_range,
       SUM(o.profit) AS total_profit,
       SUM(o.sales) AS total_sales,
       ROUND(SUM(o.profit) / SUM(o.sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore o
JOIN sub_sales s
  ON o.category = s.category AND o.sub_category = s.sub_category
WHERE s.rn <= 5
GROUP BY s.category, s.sub_category, discount_range
ORDER BY s.category, s.total_sales DESC, discount_range;

-- 按折扣區間 + Product Name (TOP10) 分析利潤率
WITH sub_sales AS (
    SELECT category, sub_category,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category
),
prod_sales AS (
    SELECT category, sub_category, product_name,
           SUM(sales) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category, sub_category ORDER BY SUM(sales) DESC) AS rn
    FROM staging_superstore
    GROUP BY category, sub_category, product_name
)
SELECT p.category, p.sub_category, p.product_name,
       CASE 
           WHEN o.discount = 0 THEN 'No Discount'
           WHEN o.discount BETWEEN 0.01 AND 0.10 THEN 'Low (0-10%)'
           WHEN o.discount BETWEEN 0.11 AND 0.30 THEN 'Medium (11-30%)'
           ELSE 'High (>30%)'
       END AS discount_range,
       SUM(o.profit) AS total_profit,
       SUM(o.sales) AS total_sales,
       ROUND(SUM(o.profit) / SUM(o.sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore o
JOIN prod_sales p
  ON o.category = p.category AND o.sub_category = p.sub_category AND o.product_name = p.product_name
JOIN sub_sales s
  ON p.category = s.category AND p.sub_category = s.sub_category
WHERE s.rn <= 5   -- 每個 Category 的前 5 Sub-Category
  AND p.rn <= 10  -- 每個 Sub-Category 的前 10 Product
GROUP BY p.category, p.sub_category, p.product_name, discount_range
ORDER BY p.category, s.total_sales DESC, p.total_sales DESC, discount_range;

-- Segment 分析
SELECT segment,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY segment
ORDER BY total_sales DESC;

-- State 分析
SELECT state,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY state
ORDER BY total_sales DESC
LIMIT 20;

-- Country 分析
SELECT country,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY country
ORDER BY total_sales DESC;

-- Market 分析
SELECT market,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY market
ORDER BY total_sales DESC;

-- Region 分析
SELECT region,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY region
ORDER BY total_sales DESC;

-- 運費影響分析
SELECT category,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       SUM(shipping_cost) AS total_shipping_cost,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent,
       ROUND(SUM(shipping_cost) / SUM(sales) * 100, 2) AS shipping_cost_ratio
FROM staging_superstore
GROUP BY category
ORDER BY shipping_cost_ratio DESC;

-- Ship Mode 分析
SELECT ship_mode,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY ship_mode
ORDER BY total_sales DESC;

-- Order Priority 分析
SELECT order_priority,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_percent
FROM staging_superstore
GROUP BY order_priority
ORDER BY total_sales DESC;