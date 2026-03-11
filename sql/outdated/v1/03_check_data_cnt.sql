-- 查詢 staging_sales 表格的欄位數與行數
SELECT  
  (SELECT COUNT(*) 
   FROM information_schema.columns 
   WHERE table_schema = 'superstore_db'        -- 指定資料庫名稱
     AND table_name = 'staging_sales')  -- 指定表格名稱
   AS column_count,                         -- 回傳欄位數
  (SELECT COUNT(*) 
   FROM superstore_db.staging_sales)       -- 計算表格的資料筆數
   AS row_count;                            -- 回傳行數

-- 顯示 staging_sales 表格的前 10 筆資料，用來檢查匯入是否正確
SELECT *
FROM superstore_db.staging_sales
LIMIT 10;