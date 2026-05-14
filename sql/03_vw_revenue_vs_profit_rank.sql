USE portfolio;

CREATE OR REPLACE VIEW vw_revenue_vs_profit_rank AS
WITH customer_totals AS (
    SELECT
        customer_id,
        customer_name,
        segment,
        region,
        COUNT(DISTINCT order_id)                          AS order_count,
        SUM(sales)                                        AS total_sales,
        SUM(profit)                                       AS total_profit,
        SUM(profit) / NULLIF(SUM(sales), 0)              AS profit_margin,
        AVG(discount)                                     AS avg_discount_rate,
        MIN(order_date)                                   AS first_order_date,
        MAX(order_date)                                   AS last_order_date,
        DATEDIFF(MAX(order_date), MIN(order_date))        AS customer_lifespan_days
    FROM portfolio.orders
    WHERE sales > 0
    GROUP BY customer_id, customer_name, segment, region
),
ranked AS (
    SELECT
        *,
        RANK()   OVER (ORDER BY total_sales   DESC) AS revenue_rank,
        RANK()   OVER (ORDER BY total_profit  DESC) AS profit_rank,
        RANK()   OVER (ORDER BY profit_margin DESC) AS margin_rank,
        NTILE(4) OVER (ORDER BY total_sales   DESC) AS revenue_quartile,
        NTILE(4) OVER (ORDER BY total_profit  DESC) AS profit_quartile
    FROM customer_totals
)
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    order_count,
    total_sales,
    total_profit,
    profit_margin,
    avg_discount_rate,
    first_order_date,
    last_order_date,
    customer_lifespan_days,
    revenue_rank,
    profit_rank,
    margin_rank,
    revenue_quartile,
    profit_quartile,
    CAST(profit_rank AS SIGNED) - CAST(revenue_rank AS SIGNED) AS rank_divergence,
    CASE
        WHEN revenue_quartile = 1 AND profit_quartile = 1  THEN 'Core'
        WHEN revenue_quartile = 1 AND profit_quartile >= 3 THEN 'At risk'
        WHEN revenue_quartile >= 3 AND profit_quartile = 1 THEN 'Hidden gem'
        ELSE                                                    'Standard'
    END AS customer_quadrant
FROM ranked
ORDER BY revenue_rank;