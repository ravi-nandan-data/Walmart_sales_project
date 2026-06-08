select * from walmart

-- Business Problems

-- Project Question #2
-- Find different payment method and number of transactions, number of qty sold
select payment_method, sum(quantity) as number_of_quantity,
count(payment_method) as number_of_payment from walmart
group by payment_method


-- Project Question #2

-- Identify the heighest-rated category in each branch, display the branch, category, avg rating

select * 
from (select category, branch, avg(rating) avg_rating,
rank () over (partition by branch order by avg(rating) desc) as rank
from walmart
group by branch, category)

where rank = 1

-- or

select * 
from (
select branch, category, avg(rating) as avg_rating,
rank () over (partition by branch order by avg(rating) desc) as rank
from walmart
group by 1,2
)
where rank = 1


-- 3 Identify the busiest day for each branch on the number of transactions.
select * 
from
(select branch, to_char(to_date(date, 'DD/MM/YY'), 'day') as day_name, 
count(*) as no_transactions,
rank() over(partition by branch order by count(*) desc) as rank
from walmart
group by 1,2)
where rank =1

-- or
select * 
from
(select branch, to_char(to_date(date, 'DD/MM/YY'), 'day') as day_name, 
count(branch) as no_transactions,
rank() over(partition by branch order by count(*) desc) as rank
from walmart
group by branch, day_name)
where rank =1

-- question> 4 Calculate the total number of  items sold per payment method. List payment_method and total_quantity

select * from walmart
select payment_method, sum(quantity),
count(payment_method) from walmart
group by payment_method


-- 5 Determine the average, minimum and maximum rating  of category for each city, list the city, avg_rating, min_rating and max_rating.
select * from walmart

select category, city, avg(rating) as avg_rating, min(rating) as min_rating, max(rating) as max_rating from walmart
group by category, city

-- -- 6 Calculate the total_profit for each category by considering total_profit as(unit_price * quanity * profit_margin)
-- List category and total_profit, ordered from highest to lowest proft.

select category, sum(total) as total_revenue,
sum (total * profit_margin) as profit
from walmart
group by 1

-- or

SELECT category,
       ROUND(SUM(unit_price * quantity * profit_margin)::numeric, 2) AS total_profit
FROM walmart
GROUP BY category;

-- 
-- 7. Determine the most payment method for each branch. Display branch and preferred_payment_method.
with cte
as
(
select branch, payment_method, count (payment_method) as times,
rank() over (partition by branch order by count(*) desc) as rank
from walmart
group by branch, payment_method)
Select * from cte  
where rank = 1 


-- Question: 8: Categorize sales into 3 group Morning, Afternoon, Evening.
-- Find out which of the shift and number of invoices.

select branch, case 
				when extract(Hour From(time::time)) < 12 then 'Morning'
				when extract(Hour from (time::time)) Between 12 and 17 then 'Afternoon'
				else 'Evening'
		end day_time,
		count(*)
from walmart
group by 1,2
order by 1,3 desc


-- question 9: Identify 5 branch with heighest decrease ratio in revenue compare
-- to last year(current year 2023 and last year 2022

-- rdr ==last_rev-cr_rev/ls_rev*100
SELECT *,
EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) as formated_date
FROM walmart

-- 2022 sales
WITH revenue_2022
AS
(
	SELECT 
		branch,
		SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022 -- psql
	-- WHERE YEAR(TO_DATE(date, 'DD/MM/YY')) = 2022 -- mysql
	GROUP BY 1
),
revenue_2023
AS
(

	SELECT 
		branch,
		SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)
SELECT 
	ls.branch,
	ls.revenue as last_year_revenue,
	cs.revenue as cr_year_revenue,
	ROUND(
		(ls.revenue - cs.revenue)::numeric/
		ls.revenue::numeric * 100, 
		2) as rev_dec_ratio
FROM revenue_2022 as ls
JOIN
revenue_2023 as cs
ON ls.branch = cs.branch
WHERE 
	ls.revenue > cs.revenue
ORDER BY 4 DESC
LIMIT 5

-- QUESTION 10 Which product categories contribute the highest percentage of total company revenue, 
-- helping management identify the most financially important product lines?
SELECT
    category,
    ROUND(SUM(unit_price * quantity)::numeric, 2) AS revenue,
    ROUND(
        (SUM(unit_price * quantity) * 100.0 /
        SUM(SUM(unit_price * quantity)) OVER ())::numeric,
        2
    ) AS revenue_percentage
FROM walmart
GROUP BY category
ORDER BY revenue DESC;


-- Question 11:

-- Which city generates the highest average transaction value, indicating stronger customer purchasing power and higher spending behavior?

SELECT
    city,
    ROUND(AVG(unit_price * quantity)::numeric, 2) AS avg_transaction_value
FROM walmart
GROUP BY city
ORDER BY avg_transaction_value DESC;

-- Question 12:

-- Identify the top three product categories by revenue within each city to understand regional demand patterns and customer purchasing preferences.
WITH category_revenue AS (
    SELECT
        city,
        category,
        ROUND(SUM(unit_price * quantity)::numeric,2) AS revenue,
        RANK() OVER(
            PARTITION BY city
            ORDER BY SUM(unit_price * quantity) DESC
        ) AS rank_no
    FROM walmart
    GROUP BY city, category
)
SELECT *
FROM category_revenue
WHERE rank_no <= 3;

-- Question 13:

-- Which branch maintains the highest average customer rating across all transactions and demonstrates the strongest customer satisfaction performance?

SELECT
    branch,
    ROUND(AVG(rating)::numeric,2) AS avg_rating
FROM walmart
GROUP BY branch
ORDER BY avg_rating DESC;


-- Question 14:
-- Which product category generates the highest total profit contribution and should receive greater investment and management focus?

SELECT
    category,
    ROUND(SUM(unit_price * quantity * profit_margin)::numeric,2) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;


-- Question 15:

-- Which product categories have customer ratings below the company-wide average and may require quality or service improvements?

SELECT
    category,
    ROUND(AVG(rating)::numeric,2) AS avg_rating
FROM walmart
GROUP BY category
HAVING AVG(rating) < (SELECT AVG(rating) FROM walmart)
ORDER BY avg_rating;

-- Question 16:

-- Which payment method generates the highest average revenue per transaction and attracts the most valuable customers?

SELECT
    payment_method,
    ROUND(
        (SUM(unit_price * quantity) / COUNT(*))::numeric,
        2
    ) AS revenue_per_transaction
FROM walmart
GROUP BY payment_method
ORDER BY revenue_per_transaction DESC;

-- Question 17:

-- Which month generated the highest overall revenue and contributed most significantly to annual sales performance?

SELECT
    TO_CHAR(TO_DATE(date,'DD/MM/YY'),'Month') AS month_name,
    ROUND(SUM(unit_price * quantity)::numeric,2) AS revenue
FROM walmart
GROUP BY month_name
ORDER BY revenue DESC;

-- Question 18:

-- Which product category sold the highest quantity of units within each branch regardless of revenue generated?

WITH category_qty AS (
    SELECT
        branch,
        category,
        SUM(quantity) AS total_quantity,
        RANK() OVER(
            PARTITION BY branch
            ORDER BY SUM(quantity) DESC
        ) AS rank_no
    FROM walmart
    GROUP BY branch, category
)
SELECT *
FROM category_qty
WHERE rank_no = 1;


-- Question 19:

-- Which city records the highest average quantity purchased per transaction, indicating stronger bulk-purchasing behavior among customers?

SELECT
    city,
    ROUND(AVG(quantity)::numeric,2) AS avg_quantity
FROM walmart
GROUP BY city
ORDER BY avg_quantity DESC;


-- Question 20:

-- Which product category receives the greatest number of highly rated transactions with customer ratings exceeding eight points?


SELECT
    category,
    COUNT(*) AS high_rating_transactions
FROM walmart
WHERE rating > 8
GROUP BY category
ORDER BY high_rating_transactions DESC;

-- Question 21:

-- Which branch generates the highest average revenue per transaction, indicating superior customer spending behavior and sales effectiveness?
SELECT
    branch,
    ROUND(AVG(unit_price * quantity)::numeric, 2) AS avg_transaction_revenue
FROM walmart
GROUP BY branch
ORDER BY avg_transaction_revenue DESC;

-- Question 22:

-- Which product categories contribute more than the average category revenue and should be prioritized for future growth strategies?

WITH category_sales AS (
    SELECT
        category,
        SUM(unit_price * quantity) AS revenue
    FROM walmart
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue::numeric,2) AS revenue
FROM category_sales
WHERE revenue > (SELECT AVG(revenue) FROM category_sales)
ORDER BY revenue DESC;


-- Question 23:
-- Which cities generate the highest customer ratings while maintaining strong sales performance across all product categories?

SELECT
    city,
    ROUND(AVG(rating)::numeric,2) AS avg_rating,
    ROUND(SUM(unit_price * quantity)::numeric,2) AS revenue
FROM walmart
GROUP BY city
ORDER BY avg_rating DESC, revenue DESC;

-- -- Question 24:
-- What percentage of total company transactions is contributed by each branch, helping evaluate branch-level market importance?
SELECT
    branch,
    COUNT(*) AS transactions,
    ROUND(
        (COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER())::numeric,
        2
    ) AS transaction_percentage
FROM walmart
GROUP BY branch
ORDER BY transaction_percentage DESC;

-- Question 25:

-- Which product category demonstrates the highest average customer rating while maintaining substantial sales volume across all locations?

SELECT
    category,
    ROUND(AVG(rating)::numeric,2) AS avg_rating,
    SUM(quantity) AS total_units_sold
FROM walmart
GROUP BY category
ORDER BY avg_rating DESC, total_units_sold DESC;


-- Question 26:
-- Which payment method is preferred most frequently by customers across branches, indicating dominant payment behavior patterns?
SELECT
    payment_method,
    COUNT(*) AS total_transactions
FROM walmart
GROUP BY payment_method
ORDER BY total_transactions DESC;

-- Question 27:

-- Which branch has the highest sales concentration in a single category, potentially indicating overdependence on specific product segments?

WITH category_sales AS (
    SELECT
        branch,
        category,
        SUM(unit_price * quantity) AS revenue,
        RANK() OVER(
            PARTITION BY branch
            ORDER BY SUM(unit_price * quantity) DESC
        ) AS rank_no
    FROM walmart
    GROUP BY branch, category
)
SELECT
    branch,
    category,
    ROUND(revenue::numeric,2) AS revenue
FROM category_sales
WHERE rank_no = 1;


-- Question 28:

-- During which hour does Walmart experience the highest transaction count, helping management optimize workforce scheduling decisions?

SELECT
    EXTRACT(HOUR FROM time::time) AS sales_hour,
    COUNT(*) AS total_transactions
FROM walmart
GROUP BY sales_hour
ORDER BY total_transactions DESC;


-- -- Question 29:

-- Which city achieves the highest revenue per unit sold, indicating stronger pricing efficiency and customer willingness to spend?

SELECT
    city,
    ROUND(
        (SUM(unit_price * quantity) /
        SUM(quantity))::numeric,
        2
    ) AS revenue_per_unit
FROM walmart
GROUP BY city
ORDER BY revenue_per_unit DESC;


-- Question 30:

-- Which categories consistently perform well across multiple branches and represent the most reliable sources of business revenue?

WITH category_branch_revenue AS (
    SELECT
        category,
        branch,
        SUM(unit_price * quantity) AS revenue
    FROM walmart
    GROUP BY category, branch
)
SELECT
    category,
    ROUND(AVG(revenue)::numeric,2) AS avg_branch_revenue,
    ROUND(MIN(revenue)::numeric,2) AS min_branch_revenue,
    ROUND(MAX(revenue)::numeric,2) AS max_branch_revenue
FROM category_branch_revenue
GROUP BY category
ORDER BY avg_branch_revenue DESC;























































