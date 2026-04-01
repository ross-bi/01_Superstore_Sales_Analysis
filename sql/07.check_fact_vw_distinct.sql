-- fact_sales vs vw_sales_full 對比 + 誤差
SELECT
    '誤差 (fact - view)'             AS source,
    f.total_rows        - v.total_rows        AS total_rows,
    f.uniq_sales_id     - v.uniq_sales_id     AS uniq_sales_id,
    f.uniq_order_id     - v.uniq_order_id     AS uniq_order_id,
    f.uniq_order_date_id- v.uniq_order_date_id AS uniq_order_date_id,
    f.uniq_ship_date_id - v.uniq_ship_date_id  AS uniq_ship_date_id,
    f.uniq_ship_mode    - v.uniq_ship_mode     AS uniq_ship_mode,
    f.uniq_customer_id  - v.uniq_customer_id   AS uniq_customer_id,
    f.uniq_state_id     - v.uniq_state_id      AS uniq_state_id,
    f.uniq_product_id   - v.uniq_product_id    AS uniq_product_id,
    f.uniq_order_priority - v.uniq_order_priority AS uniq_order_priority

FROM (
    SELECT
        COUNT(*)                       AS total_rows,
        COUNT(DISTINCT sales_id)       AS uniq_sales_id,
        COUNT(DISTINCT order_id)       AS uniq_order_id,
        COUNT(DISTINCT order_date_id)  AS uniq_order_date_id,
        COUNT(DISTINCT ship_date_id)   AS uniq_ship_date_id,
        COUNT(DISTINCT ship_mode)      AS uniq_ship_mode,
        COUNT(DISTINCT customer_id)    AS uniq_customer_id,
        COUNT(DISTINCT state_id)       AS uniq_state_id,
        COUNT(DISTINCT product_id)     AS uniq_product_id,
        COUNT(DISTINCT order_priority) AS uniq_order_priority
    FROM `superstore_db`.`fact_sales`
) f,
(
    SELECT
        COUNT(*)                                         AS total_rows,
        COUNT(DISTINCT `vw_sales_full`.`sales_id`)       AS uniq_sales_id,
        COUNT(DISTINCT `vw_sales_full`.`order_id`)       AS uniq_order_id,
        COUNT(DISTINCT `vw_sales_full`.`order_date_id`)  AS uniq_order_date_id,
        COUNT(DISTINCT `vw_sales_full`.`ship_date_id`)   AS uniq_ship_date_id,
        COUNT(DISTINCT `vw_sales_full`.`ship_mode`)      AS uniq_ship_mode,
        COUNT(DISTINCT `vw_sales_full`.`customer_id`)    AS uniq_customer_id,
        COUNT(DISTINCT `vw_sales_full`.`state_id`)       AS uniq_state_id,
        COUNT(DISTINCT `vw_sales_full`.`product_id`)     AS uniq_product_id,
        COUNT(DISTINCT `vw_sales_full`.`order_priority`) AS uniq_order_priority
    FROM `superstore_db`.`vw_sales_full`
) v

UNION ALL

SELECT 'fact_sales' AS source,
    f.total_rows, f.uniq_sales_id, f.uniq_order_id, f.uniq_order_date_id,
    f.uniq_ship_date_id, f.uniq_ship_mode, f.uniq_customer_id,
    f.uniq_state_id, f.uniq_product_id, f.uniq_order_priority
FROM (
    SELECT
        COUNT(*)                       AS total_rows,
        COUNT(DISTINCT sales_id)       AS uniq_sales_id,
        COUNT(DISTINCT order_id)       AS uniq_order_id,
        COUNT(DISTINCT order_date_id)  AS uniq_order_date_id,
        COUNT(DISTINCT ship_date_id)   AS uniq_ship_date_id,
        COUNT(DISTINCT ship_mode)      AS uniq_ship_mode,
        COUNT(DISTINCT customer_id)    AS uniq_customer_id,
        COUNT(DISTINCT state_id)       AS uniq_state_id,
        COUNT(DISTINCT product_id)     AS uniq_product_id,
        COUNT(DISTINCT order_priority) AS uniq_order_priority
    FROM `superstore_db`.`fact_sales`
) f

UNION ALL

SELECT 'vw_sales_full' AS source,
    v.total_rows, v.uniq_sales_id, v.uniq_order_id, v.uniq_order_date_id,
    v.uniq_ship_date_id, v.uniq_ship_mode, v.uniq_customer_id,
    v.uniq_state_id, v.uniq_product_id, v.uniq_order_priority
FROM (
    SELECT
        COUNT(*)                                         AS total_rows,
        COUNT(DISTINCT `vw_sales_full`.`sales_id`)       AS uniq_sales_id,
        COUNT(DISTINCT `vw_sales_full`.`order_id`)       AS uniq_order_id,
        COUNT(DISTINCT `vw_sales_full`.`order_date_id`)  AS uniq_order_date_id,
        COUNT(DISTINCT `vw_sales_full`.`ship_date_id`)   AS uniq_ship_date_id,
        COUNT(DISTINCT `vw_sales_full`.`ship_mode`)      AS uniq_ship_mode,
        COUNT(DISTINCT `vw_sales_full`.`customer_id`)    AS uniq_customer_id,
        COUNT(DISTINCT `vw_sales_full`.`state_id`)       AS uniq_state_id,
        COUNT(DISTINCT `vw_sales_full`.`product_id`)     AS uniq_product_id,
        COUNT(DISTINCT `vw_sales_full`.`order_priority`) AS uniq_order_priority
    FROM `superstore_db`.`vw_sales_full`
) v

ORDER BY FIELD(source, 'fact_sales', 'vw_sales_full', '誤差 (fact - view)');