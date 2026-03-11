SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT sales_id) AS uniq_sales_id,
    COUNT(DISTINCT order_id) AS uniq_order_id,
    COUNT(DISTINCT order_date_id) AS uniq_order_date_id,
    COUNT(DISTINCT ship_date_id) AS uniq_ship_date_id,
    COUNT(DISTINCT ship_mode) AS uniq_ship_mode,
    COUNT(DISTINCT customer_id) AS uniq_customer_id,
    COUNT(DISTINCT state_id) AS uniq_state_id,
    COUNT(DISTINCT product_id) AS uniq_product_id,
    COUNT(DISTINCT order_priority) AS uniq_order_priority,
    COUNT(DISTINCT order_year) AS uniq_year
FROM fact_sales;

SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT `vw_sales_full`.`sales_id`) AS uniq_sales_id,
	COUNT(DISTINCT `vw_sales_full`.`order_id`) AS uniq_order_id,
	COUNT(DISTINCT  `vw_sales_full`.`order_date_id`) AS uniq_order_date_id,
	COUNT(DISTINCT  `vw_sales_full`.`ship_date_id`) AS uniq_ship_date_id,
	COUNT(DISTINCT  `vw_sales_full`.`ship_mode`) AS uniq_ship_mode,
	COUNT(DISTINCT  `vw_sales_full`.`customer_id`) AS uniq_customer_id,
	COUNT(DISTINCT  `vw_sales_full`.`segment`) AS uniq_segment,
    COUNT(DISTINCT  `vw_sales_full`.`state_name`) AS uniq_state_name,
	COUNT(DISTINCT  `vw_sales_full`.`country_name`) AS uniq_country_name,
	COUNT(DISTINCT  `vw_sales_full`.`market_name`) AS uniq_market_name,
    COUNT(DISTINCT  `vw_sales_full`.`region_name`) AS uniq_region_name,
	COUNT(DISTINCT  `vw_sales_full`.`product_id`) AS uniq_product_id,
	COUNT(DISTINCT  `vw_sales_full`.`raw_product_id`) AS uniq_raw_product_id,
	COUNT(DISTINCT  `vw_sales_full`.`product_name`) AS uniq_product_name,
	COUNT(DISTINCT  `vw_sales_full`.`sub_category_id`) AS uniq_sub_category_id,
	COUNT(DISTINCT  `vw_sales_full`.`category_id`) AS uniq_category_id
FROM `superstore_db`.`vw_sales_full`;
