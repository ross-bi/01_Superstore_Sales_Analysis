CREATE DATABASE superstore_db;
USE superstore_db;

CREATE TABLE staging_sales (
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    state VARCHAR(100),
    country VARCHAR(100),
    market VARCHAR(50),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(200),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,5),
    profit DECIMAL(10,5),
    shipping_cost DECIMAL(10,2),
    order_priority VARCHAR(50)
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 匯入 CSV 檔案到 staging_superstore 表格
LOAD DATA LOCAL INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Data\\01_Superstore_Project\\data\\superstore_clean_20251229.csv'

INTO TABLE staging_sales
FIELDS TERMINATED BY ','           -- 欄位以逗號分隔
ENCLOSED BY '"'                    -- 欄位值用雙引號包住
LINES TERMINATED BY '\n'           -- 每一行以換行符號結束
IGNORE 1 ROWS                      -- 忽略第一列 (通常是標題列)
(order_id, order_date, ship_date, ship_mode, customer_name, segment, state, country,
 market, region, product_id, category, sub_category, product_name,
 sales, quantity, discount, profit, shipping_cost, order_priority, @dummy);
-- 上面最後的 @dummy 用來丟掉多餘的欄位，不匯入到表格

-- 顯示匯入過程的警告訊息 (例如重複主鍵、資料截斷等)
SHOW WARNINGS;