USE portfolio;

CREATE OR REPLACE VIEW vw_new_vs_returning_margin AS
WITH customer_order_sequence AS (
    SELECT
        order_id,
        customer_id,
        customer_name,
        segment,
        region,
        sub_category,
        category,
        order_date,
        sales,
        profit,
        discount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS customer_order_seq,
        MIN(order_date) OVER (
            PARTITION BY customer_id
        ) AS acquisition_date
    FROM portfolio.orders
    WHERE sales > 0
),
classified AS (
    SELECT
        *,
        CASE
            WHEN customer_order_seq = 1 THEN 'New'
            ELSE                             'Returning'
        END AS customer_type
    FROM customer_order_sequence
)
SELECT
    customer_type,
    segment,
    region,
    sub_category,
    category,
    DATE_FORMAT(acquisition_date, '%Y-%m-01')          AS acquisition_cohort,
    DATE_FORMAT(order_date, '%Y-%m-01')                AS order_month,
    COUNT(DISTINCT order_id)                           AS order_count,
    COUNT(DISTINCT customer_id)                        AS customer_count,
    SUM(sales)                                         AS total_sales,
    SUM(profit)                                        AS total_profit,
    SUM(profit) / NULLIF(SUM(sales), 0)               AS profit_margin,
    AVG(discount)                                      AS avg_discount_rate,
    SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0)  AS avg_order_value,
    SUM(sales) / NULLIF(COUNT(DISTINCT customer_id), 0) AS revenue_per_customer
FROM classified
GROUP BY
    customer_type, segment, region, sub_category, category,
    DATE_FORMAT(acquisition_date, '%Y-%m-01'),
    DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY order_month, customer_type;