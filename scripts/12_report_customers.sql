/*
===============================================================================
Customer Report
===============================================================================
Purpose :
	- This report consolidates key customer metrics and behaviors

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- Total Orders
		- Total Sales
		- Total Quantity Purchased
		- Total Products
		- Lifespan (In months)
	4. Calculates valuable KPIs:
		- Recency (months since last order)
		- Average Order Value
		- Average Monthly Spend
================================================================================
*/
-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS (
/* -----------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
----------------------------------------------------------------------------- */
SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL)

, customer_aggregation AS (
/* -----------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
----------------------------------------------------------------------------- */
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY customer_key,
		 customer_number,
		 customer_name,
		 age
)
/* -----------------------------------------------------------------------------
  3) Final Query: Combines all customer results into one output
----------------------------------------------------------------------------- */
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE
		WHEN age < 30 THEN 'Under 30'
		WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
		WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
		WHEN age BETWEEN 50 AND 59 THEN '50 - 59'
		ELSE '60 and Above'
	END AS age_group,
	CASE
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_sement,
	last_order_date,
	DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	-- Compuate Average Order Value (AVO)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_value,
	-- Compuate Average Monthly Spend
	CASE
		WHEN lifespan = 0 THEN 0
		ELSE total_sales / lifespan
	END AS avg_monthly_spend
FROM customer_aggregation;
