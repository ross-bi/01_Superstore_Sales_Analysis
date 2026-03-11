ALTER TABLE staging_sales 
MODIFY profit DECIMAL(10,5),
MODIFY discount DECIMAL(5,5);
ALTER TABLE fact_sales
MODIFY profit DECIMAL(10,5),
MODIFY discount DECIMAL(5,5);