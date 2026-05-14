USE portfolio;

CREATE OR REPLACE VIEW vw_margin_by_discount_band AS
WITH order_lines AS (
    SELECT
        order_id,
        row_id,
        sub_category,
        category,
        segment,
        region,
        sales,
        profit,
        discount,
        CASE
            WHEN discount = 0     THEN '1_no_discount'
            WHEN discount <= 0.10 THEN '2_low_1_10'
            WHEN discount <= 0.20 THEN '3_medium_11_20'
            ELSE                       '4_high_20_plus'
        END AS discount_band,
        CASE
            WHEN discount = 0     THEN '0%'
            WHEN discount <= 0.10 THEN '1-10%'
            WHEN discount <= 0.20 THEN '11-20%'
            ELSE                       '20%+'
        END AS discount_band_label
    FROM portfolio.orders
    WHERE sales > 0
),
aggregated AS (
    SELECT
        discount_band,
        discount_band_label,
        sub_category,
        category,
        segment,
        region,
        COUNT(DISTINCT order_id)                          AS order_count,
        COUNT(row_id)                                     AS line_count,
        SUM(sales)                                        AS total_sales,
        SUM(profit)                                       AS total_profit,
        SUM(profit) / NULLIF(SUM(sales), 0)              AS profit_margin,
        AVG(discount)                                     AS avg_discount_rate,
        SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0) AS avg_order_value,
        SUM(SUM(sales))  OVER ()                         AS grand_total_sales,
        SUM(SUM(profit)) OVER ()                         AS grand_total_profit
    FROM order_lines
    GROUP BY
        discount_band, discount_band_label,
        sub_category, category, segment, region
)
SELECT
    discount_band,
    discount_band_label,
    sub_category,
    category,
    segment,
    region,
    order_count,
    line_count,
    total_sales,
    total_profit,
    profit_margin,
    avg_discount_rate,
    avg_order_value,
    total_sales  / NULLIF(grand_total_sales, 0)  AS pct_of_total_sales,
    total_profit / NULLIF(grand_total_profit, 0) AS pct_of_total_profit,
    profit_margin - (
        grand_total_profit / NULLIF(grand_total_sales, 0)
    )                                             AS margin_vs_portfolio_avg
FROM aggregated
ORDER BY discount_band, sub_category;