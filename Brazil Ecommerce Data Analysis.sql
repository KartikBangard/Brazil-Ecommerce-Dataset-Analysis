Use Ecommerce

Select * from olist_customers_dataset

Select * from olist_order_items_dataset 

Select * from olist_orders_dataset 

Select * from olist_order_reviews_dataset

Select * from olist_order_payments_dataset

Select * from olist_products_dataset

Select * from olist_sellers_dataset

Select * from product_category_name_translation

Select * from olist_geolocation_dataset

-- Finding Unique Customers per City --

	SELECT 
		customer_city,
	COUNT(customer_unique_id)
		AS Number_of_Customers 
	FROM 
		olist_customers_dataset
	GROUP BY 
		customer_city
	ORDER BY
		Number_of_Customers DESC

-- Finding No. of delivered orders per Unique Customer(Top 100) --

SELECT 
	TOP 100 c.customer_unique_id,
COUNT
	(o.order_id) Number_of_orders
FROM 
	olist_customers_dataset c
JOIN
	olist_orders_dataset o ON c.customer_id = o.customer_id
WHERE 
	o.order_status = 'delivered'
GROUP BY 
	c.customer_unique_id
ORDER BY
	Number_of_orders DESC



-- Total Sales Vs Average Order Value per city --

SELECT
	c.customer_city,
ROUND
	(SUM(p.payment_value),2) AS Total_Sales,
ROUND
	(AVG(p.payment_value),2) AS Avg_order_value
FROM 
	olist_customers_dataset c
JOIN 
	olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN 
	olist_order_payments_dataset p ON p.order_id = o.order_id
GROUP BY 
	c.customer_city
ORDER BY
	Total_Sales DESC

-- Most Sold product per City --

WITH Product_city_rank AS (
    SELECT
        c.customer_city,
        i.product_id,
        ROW_NUMBER() OVER (PARTITION BY c.customer_city ORDER BY i.product_id DESC) AS City_rank
    FROM
        olist_customers_dataset c
        JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
        JOIN olist_order_items_dataset i ON o.order_id = i.order_id
)

SELECT
    customer_city,
    product_id,
    City_rank
FROM
    Product_city_rank
WHERE
    City_rank = 1;



-- Average Customer Rating per City( Min. 100 ratings) --

SELECT
    customer_city,
    AVG(review_score) AS Average_Rating,
    COUNT(review_score) AS Total_Ratings
FROM
    olist_customers_dataset c
JOIN
    olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN
    olist_order_reviews_dataset r ON o.order_id = r.order_id
GROUP BY
    customer_city
HAVING
    COUNT(review_score) > 100
ORDER BY
	Total_Ratings


-- Average Delivery Days per City --

SELECT
    customer_city,
    AVG(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS Average_delivery_days
FROM
    olist_customers_dataset c
JOIN
    olist_orders_dataset o ON c.customer_id = o.customer_id
GROUP BY
    customer_city
HAVING
    AVG(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) IS NOT NULL
ORDER BY
    Average_delivery_days;


-- No. of orders placed in each product category --

SELECT
    UPPER(c.column2) AS Category,
    COUNT(o.order_id) AS Number_of_orders
FROM
    olist_products_dataset p
JOIN
    olist_order_items_dataset o ON p.product_id = o.product_id
JOIN
    product_category_name_translation c ON p.product_category_name = c.column1
GROUP BY
    UPPER(c.column2)
ORDER BY
    Number_of_orders DESC;


-- Customers buying from different sellers --

SELECT
    c.customer_id,
    c.customer_city,
    COUNT(s.seller_id) AS Total_Sellers_visited
FROM
    olist_customers_dataset c
JOIN
    olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN
    olist_order_items_dataset i ON i.order_id = o.order_id
JOIN
    olist_sellers_dataset s ON s.seller_id = i.seller_id
GROUP BY
    c.customer_id,
    c.customer_city
ORDER BY
    Total_Sellers_visited DESC;


-- Sellers making the most revenue(Top 50) --

SELECT
    s.seller_id,
    ROUND(SUM(o.price), 2) AS Total_revenue
FROM
    olist_sellers_dataset s
JOIN
    olist_order_items_dataset o ON s.seller_id = o.seller_id
GROUP BY
    s.seller_id
ORDER BY
    Total_revenue DESC;


-- Payment method used by different customers --

SELECT
    payment_type,
    COUNT(DISTINCT c.customer_unique_id) AS Number_of_users
FROM
    olist_order_payments_dataset p
JOIN
    olist_order_items_dataset i ON i.order_id = p.order_id
JOIN
    olist_orders_dataset o ON o.order_id = i.order_id
JOIN
    olist_customers_dataset c ON c.customer_id = o.customer_id
GROUP BY
    payment_type
ORDER BY
    Number_of_users DESC;


-- Revenue per City per Year --

WITH CTE AS
(
    SELECT
        o.order_id,
        order_status,
        order_purchase_timestamp,
        (price + freight_value) AS revenue,
        customer_city
    FROM
        olist_orders_dataset o
    JOIN
        olist_order_items_dataset i ON i.order_id = o.order_id
    JOIN
        olist_customers_dataset c ON o.customer_id = c.customer_id
)

SELECT
    customer_city,
    ROUND(SUM(CASE WHEN YEAR(order_purchase_timestamp) = 2016 THEN revenue ELSE 0 END), 2) AS revenue_2016,
    ROUND(SUM(CASE WHEN YEAR(order_purchase_timestamp) = 2017 THEN revenue ELSE 0 END), 2) AS revenue_2017,
    ROUND(SUM(CASE WHEN YEAR(order_purchase_timestamp) = 2018 THEN revenue ELSE 0 END), 2) AS revenue_2018
FROM
    CTE
GROUP BY
    customer_city
ORDER BY
    revenue_2018 DESC;



-- Quarterwise Top 5 Grossing product categories in 'Rio de Janeiro' in 2017 --

WITH CategoryRevenue AS (
    SELECT
        c.customer_city,
        n.column2 AS product_category,
        ROUND(Sum(price + freight_value), 2) AS revenue,
        YEAR(o.order_purchase_timestamp) AS order_year,
        DATEPART(QUARTER, o.order_purchase_timestamp) AS qtr
    FROM
        olist_order_items_dataset i
    JOIN
        olist_orders_dataset o ON o.order_id = i.order_id
    JOIN
        olist_customers_dataset c ON c.customer_id = o.customer_id
    JOIN
        olist_products_dataset p ON p.product_id = i.product_id
    JOIN
        product_category_name_translation n ON p.product_category_name = n.column1
    GROUP BY 
        c.customer_city,
        n.column2,
        YEAR(o.order_purchase_timestamp),
        DATEPART(QUARTER, o.order_purchase_timestamp)
    HAVING
        c.customer_city = 'rio de janeiro'
),
RankedCategories AS (
    SELECT
        product_category,
        order_year,
        qtr,
        ROW_NUMBER() OVER (PARTITION BY qtr ORDER BY revenue DESC) AS Category_Rank
    FROM
        CategoryRevenue
    WHERE
        order_year = 2017
)
SELECT
    order_year,
    qtr,
    MAX(CASE WHEN Category_Rank = 1 THEN product_category END) AS Rank1,
    MAX(CASE WHEN Category_Rank = 2 THEN product_category END) AS Rank2,
    MAX(CASE WHEN Category_Rank = 3 THEN product_category END) AS Rank3,
    MAX(CASE WHEN Category_Rank = 4 THEN product_category END) AS Rank4,
    MAX(CASE WHEN Category_Rank = 5 THEN product_category END) AS Rank5
FROM
    RankedCategories
GROUP BY
    order_year,
    qtr

-----------------------------------------------------------------------
-- Quarterwise Least Selling product categories in 'Sao Paulo' in 2017 on the basis of No. of times product was ordered --

WITH Categoryp AS (
    SELECT
        c.customer_city,
        n.column2 AS product_category,
        COUNT(n.column2) AS times_ordered,
        ROUND(SUM(price + freight_value), 2) AS revenue,
        YEAR(o.order_purchase_timestamp) AS order_year,
        DATEPART(QUARTER, o.order_purchase_timestamp) AS qtr
    FROM
        olist_order_items_dataset i
    JOIN
        olist_orders_dataset o ON o.order_id = i.order_id
    JOIN
        olist_customers_dataset c ON c.customer_id = o.customer_id
    JOIN
        olist_products_dataset p ON p.product_id = i.product_id
    JOIN
        product_category_name_translation n ON p.product_category_name = n.column1
    WHERE
        c.customer_city = 'sao paulo'
        AND YEAR(o.order_purchase_timestamp) = 2017
    GROUP BY 
        c.customer_city,
        n.column2,
        YEAR(o.order_purchase_timestamp),
        DATEPART(QUARTER, o.order_purchase_timestamp)
),
Ranked_times_ordered AS (
    SELECT
        product_category,
        order_year,
        qtr,
        ROW_NUMBER() OVER (PARTITION BY qtr ORDER BY times_ordered DESC) AS Category_Rank
    FROM
        Categoryp
)
SELECT
    order_year,
    qtr,
    MAX(CASE WHEN Category_Rank = 1 THEN product_category END) AS Rank1,
    MAX(CASE WHEN Category_Rank = 2 THEN product_category END) AS Rank2,
    MAX(CASE WHEN Category_Rank = 3 THEN product_category END) AS Rank3,
    MAX(CASE WHEN Category_Rank = 4 THEN product_category END) AS Rank4,
    MAX(CASE WHEN Category_Rank = 5 THEN product_category END) AS Rank5
FROM
    Ranked_times_ordered
GROUP BY
    order_year,
    qtr;
