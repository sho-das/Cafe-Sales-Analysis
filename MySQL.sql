DROP DATABASE IF EXISTS coffee_shop_sales_db;
CREATE DATABASE coffee_shop_sales_db;
USE coffee_shop_sales_db;

-- checking data

SELECT *
FROM coffee_sales;

-- checking no. of rows & columns imported

SELECT COUNT(*)
FROM coffee_sales;

-- 149116 rows

SELECT
	count(*) as No_of_Columns
FROM
	information_schema.columns WHERE table_name ='coffee_sales';

-- 11 columns
-- finding more of the table

DESCRIBE coffee_sales;

-- DATA CLEANING
-- 1. correcting data types
-- updating transaction date (imported as text)

UPDATE coffee_sales
SET transaction_date = STR_TO_DATE(transaction_date,'%d-%m-%Y');

ALTER TABLE coffee_sales
MODIFY COLUMN transaction_date DATE;

-- updating transaction time (imported as text)

UPDATE coffee_sales
SET transaction_time = STR_TO_DATE(transaction_time,'%H:%i:%s');

ALTER TABLE coffee_sales
MODIFY COLUMN transaction_time TIME;

-- verifying conversion

DESCRIBE coffee_sales;

-- 2. cleaning transaction id name

-- cleaning transaction id name

ALTER TABLE coffee_sales
RENAME COLUMN ï»¿transaction_id TO transaction_id;

-- 3. checiking for duplicates

WITH CTE AS
(SELECT transaction_id, ROW_NUMBER() OVER (PARTITION BY transaction_id, transaction_date, transaction_time,
											transaction_qty, store_id, store_location, product_id, unit_price,
											product_category, product_type, product_detail) AS rownumber
FROM coffee_sales)
SELECT transaction_id, rownumber
FROM CTE
ORDER BY rownumber DESC;

-- no duplicates found

-- adding a serving_size column for future analysis
-- based on the column product_detail
-- creating column

ALTER TABLE coffee_sales ADD serving_size VARCHAR(100);

-- inserting values

UPDATE coffee_sales
SET serving_size = 
  CASE 
    WHEN RIGHT(RTRIM(product_detail), 2) = 'Lg' THEN 'Large'
    WHEN RIGHT(RTRIM(product_detail), 2) = 'Rg' THEN 'Regular'
    WHEN RIGHT(RTRIM(product_detail), 2) = 'Sm' THEN 'Small'
    ELSE 'Not Specified'
  END;

-- verifying result

SELECT 
	product_detail,
    product_name,
    serving_size
FROM
	coffee_sales;

-- data (table) is prepared now for EDA

-- 1. Calculating total sales for each respective month

SELECT 
	MONTHNAME(transaction_date) as month,
    ROUND(SUM(unit_price * transaction_qty),2) AS total_monthly_sales
FROM 
	coffee_sales
GROUP BY 
	MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY 
	MONTH(transaction_date);

-- 2. Calculating month-on-month increase/ decrease in sales and the month-on-month percentage of it

SELECT 
	MONTHNAME(transaction_date) as month,
    ROUND((SUM(unit_price * transaction_qty)),2) AS monthly_sales,
    ROUND((SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty)) OVER (ORDER BY MONTH(transaction_date))),2) AS mom_sales_increase,
																		-- (current month total sales - previous month total sales)
    CONCAT(ROUND(((
    (
    SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty)) OVER (ORDER BY MONTH(transaction_date))
    ) 																						-- (current month total sales - previous month total sales)
    / LAG(SUM(unit_price * transaction_qty)) OVER (ORDER BY MONTH(transaction_date)))	-- divided by previous month total sales
    *100),2),"%") AS mom_percentage_increase_sales 											
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- 3. Calculating total number of orders purchased for each respective month

SELECT 
	MONTHNAME(transaction_date) as month,
    COUNT(transaction_id) AS total_monthly_orders
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- 4. Calculating month-on-month increase/ decrease in orders and the month-on-month percentage of it

SELECT 
	MONTHNAME(transaction_date) as month,
    COUNT(transaction_id) AS total_monthly_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id)) OVER (ORDER BY MONTH(transaction_date))) AS mom_orders_increase,
																		-- (current month total orders - previous month total orders)
    CONCAT(ROUND(((
    (
    COUNT(transaction_id) - LAG(COUNT(transaction_id)) OVER (ORDER BY MONTH(transaction_date))
    ) 																						-- (current month total orders - previous month total orders)
    / LAG(COUNT(transaction_id)) OVER (ORDER BY MONTH(transaction_date))) -- divided by previous month total orders
    *100),2),"%") AS mom_percentage_increase_order_numbers
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- 5. Calculating total number of quantities sold for each respective month

SELECT 
	MONTHNAME(transaction_date) as month,
    SUM(transaction_qty) AS total_monthly_order_qty
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- 6. Calculating month-on-month increase/ decrease in quantities sold and the month-on-month percentage of it

SELECT 
	MONTHNAME(transaction_date) as month,
    SUM(transaction_qty) AS total_monthly_order_qty,
    ROUND((SUM(transaction_qty) - LAG(SUM(transaction_qty)) OVER (ORDER BY MONTH(transaction_date))),2) AS mom_qty_increase,
																		-- (current month total quantity size - previous month total quantity size)
    CONCAT(ROUND(((
    (
    SUM(transaction_qty) - LAG(SUM(transaction_qty)) OVER (ORDER BY MONTH(transaction_date))
    ) 																						-- (current month total quantity size - previous month total quantity size)
    / LAG(SUM(transaction_qty)) OVER (ORDER BY MONTH(transaction_date)))	-- divided by previous month total quantity size
    *100),2),"%") AS mom_percentage_increase_qty 											
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date)
ORDER BY
	MONTH(transaction_date);
    
-- 7. Total Sales in the period:

SELECT CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') as total_sales
FROM coffee_sales;

SELECT store_location, CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') as total_sales
FROM coffee_sales
GROUP BY store_location
ORDER BY total_sales DESC;

-- FOR CHART BASED REQUIREMENTS

-- 1. Total Sales, Orders and Quantity over different dates (daily metrics)

SELECT
	transaction_date,
    CONCAT(ROUND((SUM(transaction_qty * unit_price)/1000),2),"K") as sales_per_day,
    COUNT(transaction_id) as orders_per_day,
    SUM(transaction_qty) as quantities_sold_per_day
FROM
	coffee_sales
GROUP BY
	transaction_date
ORDER BY
	transaction_date;

-- 2. Total Sales, Orders and Quantity over specific dates

SELECT
	transaction_date,
    CONCAT(ROUND((SUM(transaction_qty * unit_price)/1000),2),"K") as sales_per_day,
    COUNT(transaction_id) as orders_per_day,
    SUM(transaction_qty) as quantities_sold_per_day
FROM
	coffee_sales
WHERE
	transaction_date = '2023-01-01'
GROUP BY
	transaction_date;

-- 3. Sales on basis of weekdays (mon - fri) vs. weekends (sat-sun)

SELECT
	CASE
		WHEN DAYOFWEEK(transaction_date) IN (1,7) -- sunday == 1, saturday == 7
		THEN 'Weekends'
		ELSE 'Weekdays'
	END AS day_type,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),"K") AS total_sales
FROM
	coffee_sales
GROUP BY
	CASE
		WHEN DAYOFWEEK(transaction_date) IN (1,7) -- sunday == 1, saturday == 7
		THEN "Weekends"
		ELSE "Weekdays"
	END;
        
-- 4. Sales on basis of weekdays (mon - fri) vs. weekends (sat-sun) for specific months

SELECT
	MONTHNAME(transaction_date) AS month,
	CASE
		WHEN DAYOFWEEK(transaction_date) IN (1,7) -- sunday == 1, saturday == 7
		THEN 'Weekends'
		ELSE 'Weekdays'
	END AS day_type,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),"K") AS total_sales
FROM
	coffee_sales
GROUP BY
	MONTHNAME(transaction_date),
    MONTH(transaction_date),
	CASE
		WHEN DAYOFWEEK(transaction_date) IN (1,7) -- sunday == 1, saturday == 7
		THEN "Weekends"
		ELSE "Weekdays"
	END
ORDER BY
	MONTH(transaction_date);

-- 5. Sales data by different store locations

SELECT
	MONTHNAME(transaction_date) AS month,
    store_id,
    store_location,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),"K") AS total_sales
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date),
    store_id,
    store_location
ORDER BY
	store_id,
    MONTH(transaction_date);

-- 6. mom increase/ decrease in sales per store location along with percentage of it

SELECT
	MONTHNAME(transaction_date) AS month,
    store_id,
    store_location,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') AS curr_month_sales, 	-- current month sales
    CONCAT(ROUND(LAG(SUM(transaction_qty * unit_price)) OVER(PARTITION BY store_id ORDER BY MONTH(transaction_date))/1000,2),'K') AS prev_month_sales, -- previous month sales
    
    ROUND((SUM(transaction_qty * unit_price) - LAG(SUM(transaction_qty * unit_price)) OVER(PARTITION BY store_id ORDER BY MONTH(transaction_date))),2)
    AS mom_sales_increase, 																-- current month sales - pervious month sales
    
    CONCAT(ROUND((((SUM(transaction_qty * unit_price) - LAG(SUM(transaction_qty * unit_price)) OVER(PARTITION BY store_id ORDER BY MONTH(transaction_date)))
    / LAG(SUM(transaction_qty * unit_price)) OVER(PARTITION BY store_id ORDER BY MONTH(transaction_date)))*100),2),'%')
    AS mom_sales_increase_in_percentage -- mom increase = ((curr. month - prtev. month)/ prev. month) *100 %
FROM
	coffee_sales
GROUP BY
	MONTH(transaction_date),
    MONTHNAME(transaction_date),
    store_id,
    store_location
ORDER BY
	store_id,
    MONTH(transaction_date);
    
-- 7. Average daily sales per month

WITH sales AS
(
SELECT
	transaction_date,
	MONTHNAME(transaction_date) AS month,
    SUM(transaction_qty * unit_price) AS daily_sales
FROM
	coffee_sales
GROUP BY
	transaction_date,
    MONTH(transaction_date),
    MONTHNAME(transaction_date)
)
SELECT
	month,
    CONCAT(ROUND((SUM(daily_sales)/1000),2),"K") AS monthly_sales,
    CONCAT(ROUND((AVG(daily_sales)/1000),1),"K") AS avg_daily_sales_per_month
FROM
	sales
GROUP BY 
    month,
	MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
-- 8. daily_average | avg_monthly_sales

WITH day_sales AS (
	SELECT
		transaction_date,
        MONTHNAME(transaction_date) AS month,
        SUM(transaction_qty * unit_price) AS daily_sales
	FROM
		coffee_sales
	GROUP BY
		transaction_date,
        MONTHNAME(transaction_date)
)
SELECT
	d.month,
    d.transaction_date,
    CONCAT(ROUND((d.daily_sales/1000),2),'K') AS avg_daily_sales,
	CONCAT(ROUND((m.avg_sales/1000),2),'K') AS avg_daily_sales_per_month,
    CASE
		WHEN d.daily_sales > m.avg_sales THEN "Above Average"
        WHEN d.daily_sales < m.avg_sales THEN "Below Average"
        ELSE "Equal to Average"
	END AS sales_status
FROM
	day_sales d
    JOIN
    (SELECT
		month,
        AVG(daily_sales) AS avg_sales
	FROM
		day_sales
	GROUP BY
		month
	) AS m
    ON
		d.month = m.month
GROUP BY
	MONTH(transaction_date),
    transaction_date,
    d.daily_sales,
    m.avg_sales
ORDER BY
	MONTH(transaction_date),
    transaction_date;
    
-- 9. sales performance across different categories

SELECT
	product_category,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') AS product_sales
FROM
	coffee_sales
GROUP BY
	product_category
ORDER BY
	SUM(transaction_qty * unit_price) DESC;
    
-- 10. sales performance across different categories for a specific month

SELECT
	product_category,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') AS product_sales
FROM
	coffee_sales
WHERE
	MONTH(transaction_date) = 5 -- January = 1, May = 5
GROUP BY
    product_category
ORDER BY
	SUM(transaction_qty * unit_price) DESC;
    
-- 11. top 10 products

SELECT
	product_type,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') AS product_sales
FROM
	coffee_sales
GROUP BY
	product_type
ORDER BY
	SUM(transaction_qty * unit_price) DESC
    LIMIT 10;
    
-- 12. top 10 products for a specific month

SELECT
	product_type,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') AS product_sales
FROM
	coffee_sales
WHERE
	MONTH(transaction_date) = 5 -- January = 1, May = 5
GROUP BY
    product_type
ORDER BY
	SUM(transaction_qty * unit_price) DESC
LIMIT 10;

-- 13. top 10 products for a specific month in a specific category

SELECT
	product_type,
	CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') AS product_sales
FROM
	coffee_sales
WHERE
	MONTH(transaction_date) = 5 AND product_category = 'Coffee' -- January = 1, May = 5
GROUP BY
    product_type
ORDER BY
	SUM(transaction_qty * unit_price) DESC
LIMIT 10;

-- 14. total sales, orders, quantity for a specific day-hour

SELECT
    ROUND(SUM(transaction_qty * unit_price),2) AS total_sales,
    COUNT(transaction_id) AS total_orders,
    SUM(transaction_qty) AS total_quantities_sold
FROM
	coffee_sales
WHERE
	HOUR(transaction_time) = 8 -- hour of the day is 0800 hrs (24-hour clock 8am)
    AND DAYOFWEEK(transaction_date) = 2 -- Day is Monday, Sunday is 1
    AND MONTH(transaction_date) = 5; -- Month is May

-- 15. finding peak hours of sales in a month

SELECT
	HOUR(transaction_time) as hour_of_day,
    CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') as total_sales
FROM
	coffee_sales
WHERE
	MONTH(transaction_date) = 5 -- month = May
GROUP BY
	HOUR(transaction_time)
ORDER BY
	hour_of_day;
    
-- 16. finding peak days of sales in a month

SELECT
    CASE
		WHEN DAYOFWEEK(transaction_date) = 2 THEN "Monday"
        WHEN DAYOFWEEK(transaction_date) = 3 THEN "Tuesday"
        WHEN DAYOFWEEK(transaction_date) = 4 THEN "Wednesday"
        WHEN DAYOFWEEK(transaction_date) = 5 THEN "Thursday"
        WHEN DAYOFWEEK(transaction_date) = 6 THEN "Friday"
        WHEN DAYOFWEEK(transaction_date) = 7 THEN "Saturday"
        ELSE "Sunday"
	END AS "day_of_week",
    CONCAT(ROUND(SUM(transaction_qty * unit_price)/1000,2),'K') as total_sales
FROM
	coffee_sales
WHERE
	MONTH(transaction_date) = 5 -- month = May
GROUP BY
	CASE
		WHEN DAYOFWEEK(transaction_date) = 2 THEN "Monday"
        WHEN DAYOFWEEK(transaction_date) = 3 THEN "Tuesday"
        WHEN DAYOFWEEK(transaction_date) = 4 THEN "Wednesday"
        WHEN DAYOFWEEK(transaction_date) = 5 THEN "Thursday"
        WHEN DAYOFWEEK(transaction_date) = 6 THEN "Friday"
        WHEN DAYOFWEEK(transaction_date) = 7 THEN "Saturday"
        ELSE "Sunday"
	END;
    
-- 17. top preferred serving_size of a product

SELECT
	product_type,
    COUNT(serving_size) AS total_orders,
    MAX(serving_size) AS top_selling_size
FROM
	coffee_sales
GROUP BY
	product_type
ORDER BY
	total_orders DESC;

-- 18. most preferred products on different days of the week and total no. of times ordered in the day
 
SELECT
    day_of_week,
    product_type AS most_purchased_product,
    total_orders_in_the_day
FROM (
    SELECT
        CASE
            WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
            WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
            WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
            WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
            WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
            WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
            ELSE 'Sunday'
        END AS day_of_week,
        product_type,
        COUNT(*) AS total_orders_in_the_day,
        ROW_NUMBER() OVER(PARTITION BY
            CASE
                WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
                WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
                WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
                WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
                WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
                WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
                ELSE 'Sunday'
            END
            ORDER BY COUNT(*) DESC) AS row_num
    FROM
        coffee_sales
    GROUP BY
        day_of_week,
        product_type
) AS ranked
WHERE
    row_num = 1
ORDER BY
    FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');
    
-- This brings to the end of DATA CLEANING and ANALYSIS on MySQL
-- We did the following:
-- 1. Cleaned and Standardized the data
-- 2. Analyzed our data on various metrices provided by the client
-- 3. Prepared particular results to be verified with charts in Power BI

-- Additionally, exporting as csv for future use

SELECT 
    'transaction_id' AS transaction_id, 
    'transaction_date' AS transaction_date,
    'transaction_time' AS transaction_time,
    'transaction_qty' AS transaction_qty,
    'store_id' AS store_id,
    'store_location' AS store_location,
    'product_id' AS product_id,
    'unit_price' AS unit_price,
    'product_category' AS product_category,
    'product_type' AS product_type,
    'product_detail' AS product_detail,
    'product_name' AS product_name,
    'serving_size' AS serving_size
UNION ALL
SELECT 
    COALESCE(transaction_id, 'NULL'),
    COALESCE(transaction_date, 'NULL'),
    COALESCE(transaction_time, 'NULL'),
    COALESCE(transaction_qty, 'NULL'),
    COALESCE(store_id, 'NULL'),
    COALESCE(store_location, 'NULL'),
    COALESCE(product_id, 'NULL'),
    COALESCE(unit_price, 'NULL'),
    COALESCE(product_category, 'NULL'),
    COALESCE(product_type, 'NULL'),
    COALESCE(product_detail, 'NULL'),
    COALESCE(product_name, 'NULL'),
    COALESCE(serving_size, 'NULL')
FROM 
    coffee_sales
INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\cleaned_data.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

-- ---------------------- THANK YOU -----------------------------