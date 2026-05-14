USE portfolio;

CREATE OR REPLACE VIEW vw_subcategory_margin_trend AS
WITH monthly_base AS (
    SELECT
        sub_category,
        category,
        DATE_FORMAT(order_date, '%Y-%m-01')               AS order_month,
        SUM(sales)                                        AS monthly_sales,
        SUM(profit)                                       AS monthly_profit,
        SUM(profit) / NULLIF(SUM(sales), 0)              AS monthly_margin,
        AVG(discount)                                     AS avg_discount,
        COUNT(DISTINCT order_id)                          AS order_count
    FROM portfolio.orders
    WHERE sales > 0
    GROUP BY sub_category, category, DATE_FORMAT(order_date, '%Y-%m-01')
),
with_rolling AS (
    SELECT
        *,
        SUM(monthly_profit) OVER (
            PARTITION BY sub_category
            ORDER BY order_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) / NULLIF(
            SUM(monthly_sales) OVER (
                PARTITION BY sub_category
                ORDER BY order_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ), 0
        )                                                 AS rolling_3m_margin,
        (monthly_profit / NULLIF(monthly_sales, 0)) -
        LAG(monthly_profit / NULLIF(monthly_sales, 0))
            OVER (PARTITION BY sub_category ORDER BY order_month)
                                                          AS mom_margin_delta,
        (monthly_profit / NULLIF(monthly_sales, 0)) -
        LAG(monthly_profit / NULLIF(monthly_sales, 0), 12)
            OVER (PARTITION BY sub_category ORDER BY order_month)
                                                          AS yoy_margin_delta,
        SUM(monthly_sales) OVER (
            PARTITION BY sub_category, LEFT(order_month, 4)
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                 AS ytd_sales
    FROM monthly_base
)
SELECT
    sub_category,
    category,
    order_month,
    monthly_sales,
    monthly_profit,
    monthly_margin,
    avg_discount,
    order_count,
    rolling_3m_margin,
    mom_margin_delta,
    yoy_margin_delta,
    ytd_sales,
    CASE
        WHEN rolling_3m_margin IS NULL THEN 'Insufficient data'
        WHEN mom_margin_delta >  0.02  THEN 'Improving'
        WHEN mom_margin_delta < -0.02  THEN 'Declining'
        ELSE                                'Stable'
    END AS margin_trend_signal
FROM with_rolling
ORDER BY sub_category, order_month;