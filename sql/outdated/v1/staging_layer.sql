-- 維度表
-- 顧客維度
CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50)
);

-- 產品維度
CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(50),
    product_name VARCHAR(200),
    sub_category VARCHAR(50)
);

-- 地理維度
CREATE TABLE dim_state (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    state VARCHAR(100),
    country VARCHAR(100),
    region VARCHAR(50),
    market VARCHAR(50)
);

-- 時間維度
CREATE TABLE dim_orderdate (
    order_date_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE,
    order_year INT
);

CREATE TABLE dim_shipdate (
    ship_date_id INT AUTO_INCREMENT PRIMARY KEY,
    ship_date DATE,
    order_year INT
);

-- 事實表
CREATE TABLE fact_sales (
    order_id VARCHAR(50) PRIMARY KEY,
    order_date_id INT,
    ship_date_id INT,
    customer_id INT,
    product_id INT,
    state_id INT,
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,5),
    profit DECIMAL(10,5),
    shipping_cost DECIMAL(10,2),
    FOREIGN KEY (order_date_id) REFERENCES dim_orderdate(order_date_id),
    FOREIGN KEY (ship_date_id) REFERENCES dim_shipdate(ship_date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id)
);