									
									     -- CONSUMER GOODS AD_HOC INSIGHTS


-- PROBLEM STATEMENT :- 
/*The management noticed that they do not get enough insights to make quick and smart data-informed decisions.
There are 10 ad hoc requests for which the business needs insights. */




-- AD_HOC REQUEST AND INSIGHTS :- 
/* Run a SQL query to answer these ad_hoc requests and convert these query to visualization so that it can easily understood.
   The target audience of this insights is top-level management.
   Present this insight to Top-level management of the company. */




-- Ad_hoc Request :- 

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region ?
SELECT 
DISTINCT(market) 
FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = 'APAC' ;



/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg ? */
WITH unique_products AS 
(SELECT 
fiscal_year, count(DISTINCT product_code) AS unique_products
FROM fact_sales_monthly
GROUP BY fiscal_year
)
SELECT 
uq_pr_2020.unique_products as unique_products_2020,
uq_pr_2021.unique_products as unique_products_2021,
round((uq_pr_2021.unique_products - uq_pr_2020.unique_products) / uq_pr_2020.unique_products * 100,2)
AS percentage_change
FROM 
unique_products uq_pr_2020
inner join
unique_products uq_pr_2021
WHERE 
uq_pr_2020.fiscal_year = 2020 
AND 
uq_pr_2021.fiscal_year = 2021;
       
       
       
/* 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains 2 fields,
segment
product_count ? */
SELECT 
segment,
COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;



/* 4. Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference ? */
WITH Product_counts AS
(SELECT
 p.segment ,
s.fiscal_year, count(DISTINCT p.product_code) AS product_count
FROM fact_sales_monthly s 
JOIN dim_product p  
ON p.product_code=s.product_code
GROUP BY p.segment,s.fiscal_year
)
SELECT 
 uq_pd_2020.segment,
 uq_pd_2020.product_count AS product_count_2020,
 uq_pd_2021.product_count AS product_count_2021,
 uq_pd_2021.product_count - uq_pd_2020.product_count AS difference
FROM 
 Product_counts AS uq_pd_2020
JOIN 
 Product_counts AS uq_pd_2021
ON
 uq_pd_2020.segment=uq_pd_2021.segment
AND uq_pd_2020.fiscal_year = 2020
AND uq_pd_2021.fiscal_year = 2021 
ORDER BY difference DESC;



/* 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost ? */
WITH RankedProducts  AS(
SELECT 
dp.product_code,
dp.product,
fmc.manufacturing_cost,
ROW_NUMBER() OVER(ORDER BY manufacturing_cost ASC) as min_cost,
ROW_NUMBER() OVER(ORDER BY manufacturing_cost DESC) as max_cost
FROM dim_product as dp
INNER JOIN fact_manufacturing_cost as fmc
ON dp.product_code = fmc.product_code
)
SELECT 
product_code,
product,
manufacturing_cost
FROM RankedProducts 
WHERE min_cost = 1 OR max_cost = 1;



/* 6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage? */
WITH top_Customers AS(
SELECT  
dc.customer_code,
dc.customer,
i.pre_invoice_discount_pct
FROM 
dim_customer as dc
INNER JOIN
fact_pre_invoice_deductions AS i
ON dc.customer_code = i.customer_code
WHERE fiscal_year = 2021 AND market = 'India'
)
SELECT 
customer_code,
customer,
AVG(pre_invoice_discount_pct) AS avg_pre_invoice_discount_pct
FROM top_Customers
GROUP BY customer_code
ORDER BY avg_pre_invoice_discount_pct DESC LIMIT 5;



/* 7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount ? */
WITH Gross_sales as (
SELECT
monthname(DATE) AS month_name,
extract(YEAR FROM DATE) AS YEAR,
(gp.gross_price * sm.sold_quantity) AS gross_sales_amount
FROM 
fact_gross_price AS gp
JOIN 
fact_sales_monthly AS sm
ON gp.product_code = sm.product_code
JOIN dim_customer AS dc
ON dc.customer_code = sm.customer_code
WHERE dc.customer = 'Atliq Exclusive'
)
SELECT 
month_name,
YEAR,
round(sum(gross_sales_amount)/1000000,2) AS gross_sales_in_millions
FROM Gross_sales
GROUP BY month_name, year
ORDER BY year;



/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the 
total_sold_quantity,
Quarter
total_sold_quantity ? */
WITH quater_2022 AS(
 SELECT 
 date, 
 month(date_add(date,interval 4 month)) AS period, 
 -- month(date) as period,
 sold_quantity 
 FROM fact_sales_monthly where fiscal_year= 2020
 )
SELECT CASE
   when (period/3) <= 1 then "Q1"
   when (period/3) <= 2 and period/3 > 1 then "Q2"
   when (period/3) <=3 and period/3 > 2 then "Q3"
   when (period/3) <=4 and period/3 > 3 then "Q4" 
end as quarter,
round((SUM(sold_quantity)/1000000),2) as total_sold_quantity_in_millions  
FROM quater_2022 
GROUP BY quarter 
ORDER BY total_sold_quantity_in_millions DESC;



/* 9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage ? */
WITH channel_contribution AS(
SELECT  
dc.channel,
sum(sm.sold_quantity * gp.gross_price) AS gross_sales
FROM 
fact_sales_monthly AS sm
INNER JOIN
fact_gross_price AS gp
ON sm.product_code = gp.product_code
INNER JOIN
dim_customer AS dc
ON
dc.customer_code = sm.customer_code
WHERE sm.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales DESC
)
SELECT channel,
round(gross_sales/1000000,2) as gross_sales_in_millions,
round(gross_sales / (sum(gross_sales) over()) *100,2) AS percentage
FROM channel_contribution;



/* 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order ? */
WITH top_3_product AS(
SELECT 
dp.division,
dp.product_code,
dp.product,
sum(sm.sold_quantity) AS total_sold_quantity,
RANK() OVER(PARTITION BY dp.division ORDER BY sum(sold_quantity) DESC) as rank_order
FROM 
dim_product AS dp
INNER JOIN
fact_sales_monthly AS sm
ON dp.product_code = sm.product_code
WHERE sm.fiscal_year = 2021
GROUP BY dp.product_code

)
SELECT * 
FROM top_3_product
WHERE rank_order IN (1,2,3);







