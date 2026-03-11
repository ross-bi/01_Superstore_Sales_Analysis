-- 建立 superstore 資料庫
CREATE DATABASE superstore;

-- 使用 superstore 資料庫
USE superstore;

-- 建立 superstore_orders 表格
CREATE TABLE staging_superstore (
    order_id        VARCHAR(50) PRIMARY KEY,   -- 訂單編號（原本設為主鍵）
    order_date      DATE,                      -- 訂單日期
    ship_date       DATE,                      -- 出貨日期
    ship_mode       VARCHAR(50),               -- 出貨方式
    customer_name   VARCHAR(100),              -- 客戶名稱
    segment         VARCHAR(50),               -- 客戶群組（市場區隔）
    state           VARCHAR(100),              -- 州/省
    country         VARCHAR(100),              -- 國家
    market          VARCHAR(50),               -- 市場
    region          VARCHAR(50),               -- 地區
    product_id      VARCHAR(20),               -- 產品編號
    category        VARCHAR(50),               -- 產品類別
    sub_category    VARCHAR(50),               -- 產品子類別
    product_name    VARCHAR(200),              -- 產品名稱
    sales           DECIMAL(12,2),             -- 銷售金額
    quantity        INT,                       -- 銷售數量
    discount        DECIMAL(5,5),              -- 折扣
    profit          DECIMAL(12,5),             -- 利潤
    shipping_cost   DECIMAL(12,2),             -- 運費
    order_priority  VARCHAR(50),               -- 訂單優先級
    order_year      INT                        -- 訂單年份
);

-- 移除原本的主鍵 (order_id)
ALTER TABLE staging_superstore DROP PRIMARY KEY;

-- 新增流水號主鍵 id，自動遞增
ALTER TABLE staging_superstore ADD id INT AUTO_INCREMENT PRIMARY KEY;