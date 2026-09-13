/* ===========================================================================
   Performance Analysis
   ===========================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
============================================================================ */

-- Analyze the yearly performance of products by comparing each product's sales to both it's average sales performance and the previous year's sales.
WITH yearly_product_sales AS (
SELECT
	YEAR(f.order_date) AS order_years,
	p.product_name AS product_name,
	SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
	order_years,
	product_name,
	current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales, -- Average sales across all years
	current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg, -- Differnce from the product's all years
	CASE
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
		WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END avg_change,
	-- Year-Over-Year Analysis
	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_years) AS py_sales, -- Previos year's sales using LAG()
	current_sales - LAG(current_sales) OVER ( PARTITION BY product_name ORDER BY order_years) AS diff_py, -- Difference from previous year's sales
	CASE
		WHEN current_sales - LAG(current_sales) OVER ( PARTITION BY product_name ORDER BY order_years) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER ( PARTITION BY product_name ORDER BY order_years) < 0 THEN 'Decrease'
		ELSE 'No Change'
	END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_years;
