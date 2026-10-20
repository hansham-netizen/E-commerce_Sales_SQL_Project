-- Overall Sales Perfromace
-- total number of records in the dataset, total recorded sales amount, total quantity of items sold, total number of unique order IDs ,
-- distribution of order statuses

select count(*) as Total_records, Round(sum(amount),2) as Total_recorded_sales_amount, count(distinct order_id) as Unique_order_id, sum(qty) as Total_qty_sold
from amazon_sale_report_clean;

select count(*) as total_records, status
from amazon_sale_report_clean
group by status
order by total_records DESC;

-- Q2: How do recorded sales amounts change by month?

with Monthly_sales as (select  month(date_new) as Month, Year(date_new) as Year, Round(sum(amount),2) as Total_recorded_sales_amount
from amazon_sale_report_clean
group by month, year),

Growth_ratio as (select Month, year, Total_recorded_sales_amount as Current_month_sales, LAG(Total_recorded_sales_amount,1) OVER(order by Month, year)  as Previous_month_sales
from Monthly_sales)
select Month, year, Current_month_sales, Previous_month_sales, Round(100.0 * (current_month_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0),
        2) AS percent_change
FROM Growth_ratio
ORDER BY year, month;

-- Q3: How do recorded sales amounts change by date?

With Daily_sales as (select  date(date_new) as Sales_date, Round(sum(amount),2) as Total_recorded_sales_amount
from amazon_sale_report_clean
group by Sales_date),

Growth_ratio as (select Sales_date, Total_recorded_sales_amount as Current_day_sales, LAG(Total_recorded_sales_amount,1) OVER(order by sales_date)  as Previous_day_sales
from daily_sales)
select Sales_date, Current_day_sales, Previous_day_sales, Round(100.0 * (current_day_sales - previous_day_sales)
        / NULLIF(previous_day_sales, 0),
        2) AS percent_change
FROM Growth_ratio
ORDER BY Sales_date;

-- Q4: Which month has the highest quantity sold?

select month(date_new) as sales_month, year(date_new) as sales_year, Sum(qty) as Quantity_sold
from amazon_sale_report_clean
WHERE date_new IS NOT NULL
group by sales_month, sales_year
order by Quantity_sold DESC
limit 1;

-- Q5: How does order volume change over time?

with Orders_details as (select date(date_new) as order_date, count(distinct order_id) as Order_placed
from amazon_sale_report_clean
WHERE date_new IS NOT NULL
group by order_date),

Growth_ratio as (select order_date, order_placed as Current_orders, LAG(order_placed,1) OVER(ORDER BY order_date) as Previous_orders
from Orders_details)

select order_date, current_orders, Previous_orders, Round(100*(Current_orders-Previous_orders)/Nullif(Previous_orders,0),2) as Percent_Change
from Growth_ratio;

-- Q6: Which product categories generate the highest recorded sales amount?

select category, Round(sum(amount),2) as Total_sales 
from amazon_sale_report_clean
group by category
order by Total_sales DESC
limit 1;

-- Q7: Which categories have the highest quantity sold?
select category, sum(Qty) as Qty_Sold
from amazon_sale_report_clean
WHERE category IS NOT NULL
group by category
order by Qty_sold DESC;

-- Q8: Which categories have the most records and unique orders?
select category, count(*) as Most_orders, count(distinct order_id) as Unique_orders
from amazon_sale_report_clean
WHERE category IS NOT NULL
group by category
order by Unique_orders DESC;

-- Q9: Which products or SKUs contribute most to recorded sales, if product-level identifiers are available?
select Distinct sku, Round(sum(amount),2) as Total_sales
from amazon_sale_report_clean
WHERE sku IS NOT NULL
group by sku
order by Total_sales DESC
limit 1;

-- Q10: How does average recorded amount vary by category?
select category, Round(avg(amount),2) as Average_sales
from amazon_sale_report_clean
group by category
order by Average_sales DESC;

-- Q11: How are records distributed across fulfillment methods?
select fulfilment, count(*) as Orders
from amazon_sale_report_clean
group by fulfilment
order by Orders DESC;

-- Q12:	How do order statuses vary by fulfillment method?
select status, fulfilment, count(*) as Orders
from amazon_sale_report_clean
group by status, fulfilment;

-- Q13: Which fulfillment methods have the highest cancellation counts or rates, if applicable?
select fulfilment, count(*) as cancellation_records
from amazon_sale_report_clean
where status='Cancelled'
group by fulfilment
order by cancellation_records DESC;

-- Q14: How do shipping service levels relate to order status?

select ship_service_level, status, count(*) as Orders
from amazon_sale_report_clean
group by ship_service_level, status
order by Orders DESC;

-- Q15: Which states have the highest order volume?

select ship_state, count(*) as Order_volumes
from amazon_sale_report_clean
group by ship_state
Order by Order_volumes DESC;

-- Q16: Which states have the highest total recorded sales amount?
Select ship_state, Round(sum(amount),2) as Total_recorded_sales
from amazon_sale_report_clean
group by ship_state
order by Total_recorded_sales DESC;

-- Q16: How does quantity sold vary by state or city?
select ship_state, ship_city, sum(qty) as Qty_sold
from amazon_sale_report_clean
group by ship_city, ship_state
order by Qty_sold DESC;

-- Q17: How many unique customers can be identified from the available fields?

select distinct customer
from international_sales_clean;

-- Q18: What is the distribution of quantities per record or order?

WITH Order_Quantities AS (SELECT order_id, SUM(qty) AS total_qty
    FROM amazon_sale_report_clean
    GROUP BY order_id
)
SELECT
    total_qty,
    COUNT(*) AS number_of_orders
FROM Order_Quantities
GROUP BY total_qty
ORDER BY total_qty;

-- Q19: Do order patterns differ by available shipping or customer attributes?

select ship_service_level, count(*) as Orders, sum(qty) as Total_recorded_Quantity, ROUND(SUM(amount), 2) AS total_recorded_sales,
    ROUND(AVG(amount), 2) AS average_recorded_amount
from amazon_sale_report_clean
GROUP BY ship_service_level
ORDER BY orders DESC;

-- Q20: What share of records contain gift-wrap or promotion-related indicators, if available?

SELECT COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN promotion_ids IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS records_with_promotion,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN promotion_ids IS NOT NULL THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS promotion_record_share_pct
FROM amazon_sale_report_clean;


-- Q21: What are the counts and percentages for each order status?

with status_count as (select status, count(*) as Orders
from amazon_sale_report_clean
group by status),

Total_count as (select sum(orders) as Total_orders
from status_count)

select sc.status, sc.Orders, Round((100*sc.orders/tc.total_orders),2) as Percentage
from status_count as sc
cross join  total_count as tc
order by Percentage DESC;

-- Q22: How does cancellation rate vary by category?
With Category_orders as (select category, count(Distinct order_id) as Orders, COUNT(DISTINCT CASE
																						WHEN status = 'Cancelled' THEN order_id
																						END) AS cancelled_orders
from amazon_sale_report_clean
group by category)

select category, Orders, cancelled_orders, Round(100*(cancelled_orders/Nullif(orders,0)),2) as Cancellation_rate
from Category_orders;

-- Q23: How does cancellation rate vary by state or fulfillment method?

With Order_status as (select ship_state, count(Distinct order_id) as Total_orders, Count(Distinct CAse
																	when status ='Cancelled' THEN order_id
																						END) AS cancelled_orders
from amazon_sale_report_clean
group by ship_state)

select Ship_state, Total_orders, Cancelled_orders, Round(100*Cancelled_orders/Nullif(Total_orders,0),2) as Cancellation_rate
from Order_status
order by Cancellation_rate DESC;

-- Q24: Which sizes are most frequently ordered?
select size, count(*) as Total_orders
from amazon_sale_report_clean
group by size
order by Total_orders DESC;

-- Q25: Which sizes have the highest total recorded sales amount?
select size, count(*) as Total_orders, Round(sum(amount),2) as Recorded_sales
from amazon_sale_report_clean
group by size
order by Recorded_sales DESC;

-- Q26: Which product styles or SKUs are most frequently ordered, if available?

select sku, count(*) as Total_Orders
from amazon_sale_report_clean
group by sku
order by Total_orders DESC;

-- Q27: How does quantity vary by size or other product attributes?

select size, sum(qty) as Order_qty
from amazon_sale_report_clean
group by size
order by Order_qty DESC;

-- Q28: Which categories or states contribute the most to recorded sales?
select category, ship_state, Round(sum(amount),2) as Recorded_sales
from amazon_sale_report_clean
group by category, ship_state
order by Recorded_sales DESC;

-- Q29: 