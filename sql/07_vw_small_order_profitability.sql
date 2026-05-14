USE portfolio;

CREATE OR REPLACE VIEW vw_small_order_profitability AS
WITH order_totals AS (
    SELECT
        order_id,
        customer_id,
        customer_name,
        segment,
        region,
        state,
        ship_mode,
        DATE_FORMAT(order_date, '%Y-%m-01')             AS order_month,
        SUM(sales)                                      AS order_value,
        SUM(profit)                                     AS order_profit,
        SUM(quantity)                                   AS order_units,
        COUNT(row_id)                                   AS order_lines,
        AVG(discount)                                   AS avg_discount,
        SUM(profit) / NULLIF(SUM(sales), 0)             AS order_margin
    FROM portfolio.orders
    WHERE sales > 0
    GROUP BY
        order_id, customer_id, customer_name, segment, region,
        state, ship_mode, DATE_FORMAT(order_date, '%Y-%m-01')
),
banded AS (
    SELECT
        *,
        CASE
            WHEN order_value < 50    THEN '1_micro_under_50'
            WHEN order_value < 200   THEN '2_small_50_200'
            WHEN order_value < 500   THEN '3_medium_200_500'
            WHEN order_value < 1000  THEN '4_large_500_1000'
            ELSE                          '5_enterprise_1000_plus'
        END AS order_size_band,
        CASE
            WHEN order_value < 50    THEN 'Under $50'
            WHEN order_value < 200   THEN '$50-$200'
            WHEN order_value < 500   THEN '$200-$500'
            WHEN order_value < 1000  THEN '$500-$1,000'
            ELSE                          '$1,000+'
        END AS order_size_label,
        order_profit / NULLIF(order_units, 0)           AS profit_per_unit,
        order_profit / NULLIF(order_lines, 0)           AS profit_per_line,
        8.00                                            AS fixed_processing_cost,
        (order_profit - 8.00) / NULLIF(order_value, 0) AS margin_after_fixed_cost
    FROM order_totals
)
SELECT
    order_size_band,
    order_size_label,
    segment,
    region,
    ship_mode,
    order_month,
    COUNT(order_id)                                     AS order_count,
    SUM(order_value)                                    AS total_sales,
    SUM(order_profit)                                   AS total_profit,
    SUM(order_profit - fixed_processing_cost)          AS total_profit_after_fixed,
    AVG(order_margin)                                   AS avg_order_margin,
    AVG(margin_after_fixed_cost)                        AS avg_margin_after_fixed,
    AVG(order_value)                                    AS avg_order_value,
    AVG(avg_discount)                                   AS avg_discount_rate,
    AVG(order_units)                                    AS avg_units_per_order,
    AVG(profit_per_unit)                                AS avg_profit_per_unit,
    SUM(fixed_processing_cost)                          AS total_fixed_cost_exposure,
    SUM(CASE WHEN margin_after_fixed_cost < 0
             THEN 1 ELSE 0 END)                         AS loss_order_count,
    SUM(CASE WHEN margin_after_fixed_cost < 0
             THEN 1 ELSE 0 END)
        / NULLIF(COUNT(order_id), 0)                    AS loss_order_rate,
    SUM(CASE WHEN margin_after_fixed_cost < 0
             THEN order_profit - fixed_processing_cost
             ELSE 0 END)                                AS total_loss_exposure
FROM banded
GROUP BY
    order_size_band, order_size_label, segment, region,
    ship_mode, order_month
ORDER BY order_size_band, order_month;