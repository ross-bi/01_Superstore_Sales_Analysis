-- 匯入 CSV 檔案到 staging_superstore 表格
LOAD DATA LOCAL INFILE 'C:\\Users\\User\\Desktop\\Analytics\\01_Superstore_Project\\data\\superstore_clean_20251229.csv'
INTO TABLE staging_superstore
FIELDS TERMINATED BY ','           -- 欄位以逗號分隔
ENCLOSED BY '"'                    -- 欄位值用雙引號包住
LINES TERMINATED BY '\n'           -- 每一行以換行符號結束
IGNORE 1 ROWS                      -- 忽略第一列 (通常是標題列)
(order_id, order_date, ship_date, ship_mode, customer_name, segment, state, country,
 market, region, product_id, category, sub_category, product_name,
 sales, quantity, discount, profit, shipping_cost, order_priority, @dummy, order_year);
-- 上面最後的 @dummy 用來丟掉多餘的欄位，不匯入到表格

-- 顯示匯入過程的警告訊息 (例如重複主鍵、資料截斷等)
SHOW WARNINGS;