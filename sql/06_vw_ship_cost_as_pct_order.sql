USE portfolio;

CREATE OR REPLACE VIEW vw_ship_cost_as_pct_order AS
WITH cost_proxy AS (
    SELECT
        order_id,
        customer_id,
        segment,
        region,
        state,
        sub_category,
        category,
        ship_mode,
        order_date,
        ship_date,
        DATEDIFF(ship_date, order_date)                 AS days_to_ship,
        sales,
        profit,
        quantity,
        discount,
        CASE ship_mode
            WHEN 'Same Day'       THEN sales * 0.18
            WHEN 'First Class'    THEN sales * 0.12
            WHEN 'Second Class'   THEN sales * 0.07
            WHEN 'Standard Class' THEN sales * 0.03
            ELSE                       sales * 0.05
        END AS estimated_ship_cost,
        CASE ship_mode
            WHEN 'Same Day'       THEN 0.18
            WHEN 'First Class'    THEN 0.12
            WHEN 'Second Class'   THEN 0.07
            WHEN 'Standard Class' THEN 0.03
            ELSE                       0.05
        END AS ship_cost_rate
    FROM portfolio.orders
    WHERE sales > 0
),
order_level AS (
    SELECT
        order_id,
        customer_id,
        segment,
        region,
        state,
        ship_mode,
        DATE_FORMAT(order_date, '%Y-%m-01')             AS order_month,
        days_to_ship,
        SUM(sales)                                      AS order_sales,
        SUM(profit)                                     AS order_profit,
        SUM(estimated_ship_cost)                        AS order_ship_cost,
        SUM(quantity)                                   AS order_quantity,
        AVG(discount)                                   AS avg_discount,
        MAX(ship_cost_rate)                             AS ship_cost_rate,
        SUM(profit) / NULLIF(SUM(sales), 0)             AS gross_margin,
        (SUM(profit) - SUM(estimated_ship_cost))
            / NULLIF(SUM(sales), 0)                     AS net_margin_after_ship,
        SUM(estimated_ship_cost)
            / NULLIF(SUM(sales), 0)                     AS ship_cost_pct_of_sales,
        CASE
            WHEN (SUM(profit) - SUM(estimated_ship_cost)) < 0     THEN 'Loss after ship'
            WHEN (SUM(profit) - SUM(estimated_ship_cost))
                / NULLIF(SUM(sales), 0) < 0.05                     THEN 'Marginal'
            ELSE                                                         'Profitable'
        END AS post_ship_status,
        CASE
            WHEN ship_mode IN ('Same Day', 'First Class')
                AND SUM(sales) < 50                                THEN 'Overshipped'
            ELSE                                                        'Normal'
        END AS ship_appropriateness
    FROM cost_proxy
    GROUP BY
        order_id, customer_id, segment, region, state,
        ship_mode, DATE_FORMAT(order_date, '%Y-%m-01'),
        days_to_ship
)
SELECT
    ship_mode,
    segment,
    region,
    state,
    order_month,
    post_ship_status,
    ship_appropriateness,
    COUNT(order_id)                                     AS order_count,
    SUM(order_sales)                                    AS total_sales,
    SUM(order_profit)                                   AS total_gross_profit,
    SUM(order_ship_cost)                                AS total_ship_cost,
    SUM(order_profit - order_ship_cost)                AS total_net_profit,
    AVG(gross_margin)                                   AS avg_gross_margin,
    AVG(net_margin_after_ship)                          AS avg_net_margin,
    AVG(ship_cost_pct_of_sales)                        AS avg_ship_cost_pct,
    AVG(avg_discount)                                   AS avg_discount_rate,
    AVG(order_sales)                                    AS avg_order_value,
    AVG(days_to_ship)                                   AS avg_days_to_ship,
    SUM(CASE WHEN post_ship_status = 'Loss after ship'
             THEN 1 ELSE 0 END)                         AS loss_orders_count,
    SUM(CASE WHEN ship_appropriateness = 'Overshipped'
             THEN 1 ELSE 0 END)                         AS overshipped_order_count,
    SUM(CASE WHEN ship_appropriateness = 'Overshipped'
             THEN order_ship_cost ELSE 0 END)           AS overship_cost_exposure
FROM order_level
GROUP BY
    ship_mode, segment, region, state, order_month,
    post_ship_status, ship_appropriateness
ORDER BY ship_mode, order_month;