CREATE DATABASE IF NOT EXISTS portfolio;
USE portfolio;

CREATE TABLE IF NOT EXISTS orders (
    row_id          INT,
    order_id        VARCHAR(20),
    order_date      DATE,
    ship_date       DATE,
    ship_mode       VARCHAR(30),
    customer_id     VARCHAR(20),
    customer_name   VARCHAR(100),
    segment         VARCHAR(30),
    country         VARCHAR(50),
    city            VARCHAR(100),
    state           VARCHAR(50),
    postal_code     VARCHAR(20),
    region          VARCHAR(20),
    product_id      VARCHAR(20),
    category        VARCHAR(50),
    sub_category    VARCHAR(50),
    product_name    VARCHAR(200),
    sales           DECIMAL(10,4),
    quantity        INT,
    discount        DECIMAL(5,4),
    profit          DECIMAL(10,4),

    PRIMARY KEY (row_id),
    INDEX idx_order_id      (order_id),
    INDEX idx_customer_id   (customer_id),
    INDEX idx_order_date    (order_date),
    INDEX idx_sub_category  (sub_category),
    INDEX idx_region        (region)
);