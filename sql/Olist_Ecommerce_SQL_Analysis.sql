USE olist_ecommerce;
-- ==========================================
-- OLIST E-COMMERCE SQL ANALYSIS
-- ==========================================

USE olist_ecommerce;

-- ==========================================
-- SECTION 1: KPI ANALYSIS
-- ==========================================

-- 1. Total Orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2. Total Revenue
SELECT ROUND(SUM(payment_value), 2) AS total_revenue
FROM order_payments;

-- 3. Average Order Value
SELECT ROUND(
    SUM(payment_value) / COUNT(DISTINCT order_id),
    2
) AS avg_order_value
FROM order_payments;

-- 4. Average Review Score
SELECT ROUND(AVG(review_score), 2) AS avg_review_score
FROM order_reviews;

-- 5. Total Unique Customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers;


-- ==========================================
-- SECTION 2: SALES TREND ANALYSIS
-- ==========================================

-- 6. Monthly Order Trend
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY month;

-- 7. Top 10 Product Categories by Revenue
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

-- 8. Payment Method Analysis
SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- ==========================================
-- SECTION 3: CUSTOMER & ORDER ANALYSIS
-- ==========================================

-- 9. Order Status Analysis
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM orders),
        2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- 10. Top 10 Customer States by Orders
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- 11. Review Score Distribution
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM order_reviews),
        2
    ) AS percentage
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 12. Repeat Customer Analysis
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS total_customers
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) AS customer_orders
GROUP BY customer_type;

-- 13. Orders by Day of Week
SELECT
    DAYNAME(order_purchase_timestamp) AS day_name,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    DAYOFWEEK(order_purchase_timestamp),
    DAYNAME(order_purchase_timestamp)
ORDER BY DAYOFWEEK(order_purchase_timestamp);

-- 14. Orders by Hour of Day
SELECT
    HOUR(order_purchase_timestamp) AS order_hour,
    COUNT(*) AS total_orders
FROM orders
GROUP BY HOUR(order_purchase_timestamp)
ORDER BY order_hour;


-- ==========================================
-- SECTION 4: OPERATIONS ANALYSIS
-- ==========================================

-- 15. Top 10 Sellers by Revenue
SELECT
    oi.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- 16. Delivery Performance
SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days,
    ROUND(
        AVG(
            DATEDIFF(
                order_estimated_delivery_date,
                order_delivered_customer_date
            )
        ),
        2
    ) AS avg_days_early_or_late
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- 17. Freight Analysis
SELECT
    ROUND(AVG(freight_value), 2) AS avg_freight_value,
    ROUND(SUM(freight_value), 2) AS total_freight_value,
    ROUND(AVG(price), 2) AS avg_product_price
FROM order_items;

-- 18. Late Delivery Percentage
SELECT
    COUNT(*) AS delivered_orders,
    SUM(
        CASE
            WHEN order_delivered_customer_date >
                 order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        SUM(
            CASE
                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- 19. Cancellation Rate
SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'canceled'
            THEN 1
            ELSE 0
        END
    ) AS canceled_orders,
    ROUND(
        SUM(
            CASE
                WHEN order_status = 'canceled'
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM orders;


-- ==========================================
-- SECTION 5: BUSINESS INSIGHTS
-- ==========================================

-- 20. Top 10 Customer Cities by Orders
SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_city,
    c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- 21. Top Categories by Average Review Score
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT r.review_id) AS total_reviews
FROM order_reviews r
JOIN order_items oi
    ON r.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
HAVING COUNT(DISTINCT r.review_id) >= 100
ORDER BY
    avg_review_score DESC,
    total_reviews DESC
LIMIT 10;

-- 22. Revenue by Customer State
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- 23. Top 10 High-Value Customers
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.payment_value), 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- 24. Average Delivery Time by State
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- 25. Category Performance Summary
SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
LEFT JOIN order_reviews r
    ON oi.order_id = r.order_id
GROUP BY category
ORDER BY product_revenue DESC
LIMIT 15;