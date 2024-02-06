 /* DBMS II_Mini Project */                  # Submission by _ Group 7- Prajakta A, Prtiksha C, Himanshu K., Abdealisuratwala,Vinay J, , Shantanu T                               

create database miniproject;
USE miniproject;
select *from shipping_dimen;

# Q.1 Join all the tables and create a new table called combined_table.  Prajakta Adhav SIS ID-KE5VXB1NF4
create table combined_table as
SELECT *
FROM market_fact 
NATURAL JOIN cust_dimen  
NATURAL JOIN orders_dimen 
NATURAL JOIN prod_dimen 
NATURAL JOIN shipping_dimen;
select *from combined_table; 

# Q. 2 Find the top 3 customers who have the maximum number of orders
select* from combined_table;
select * from (select *,dense_rank() over(order by Max_orders desc) rnk
 from (select Customer_Name, count(distinct Order_ID) Max_orders from combined_table group by Customer_Name)t)t1 
 where rnk in (1,2,3);

# Q.3 Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
alter table combined_table add column Days_taken_for_delivery int;
update combined_table set Days_taken_for_delivery=datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y'));
select* from combined_table;

create table temp as
select *, datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y')) as daystakenfordelivery from orders_dimen o 
join shipping_dimen s using (order_id);
select *from temp;
select *from orders_dimen;


# Q. 4  Find the customer whose order took the maximum time to get delivered.

select *from cust_dimen where cust_id =
(select cust_id from
(select cd.cust_id, datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y')) timefordelivery_days
from cust_dimen cd join market_fact mf using (cust_id)
join orders_dimen od using (ord_id) join shipping_dimen sd using (order_id))t
order by timefordelivery_days desc limit 1);



select Customer_Name,Days_taken_for_delivery from combined_table where 
Days_taken_for_delivery =(select max(Days_taken_for_delivery) from combined_table);



-- Q.5 Retrieve total sales made by each product from the data (use Windows function)   # understand Que

select distinct Prod_id, round(sum(sales)over(partition by prod_id order by prod_id),2) total_sales from market_fact;

-- Q.6 Retrieve total profit made from each product from the data (use windows function)
select *from market_fact;
select distinct prod_id, round(sum(profit)over(partition by prod_id order by prod_id),2) total_profit from market_fact;

-- Q. 7 Count the total number of unique customers in January and how many of 
-- them came back every month over the entire year in 2011
## Method 1
create view customers as 
select cd.cust_id, str_to_date(od.order_date,'%d-%m-%Y') date_ from cust_dimen cd join market_fact mf using (cust_id)
join orders_dimen od using (ord_id);

select month(date_) Month_, year(date_) year_, count(distinct cust_id) Numberof_customers from customers 
where month(date_)=1 and year(date_)= 2011 group by month(date_), year(date_);

## MEthod --2
select month_, Year_, count(distinct cust_id) from
(select Cust_id,month(str_to_date(order_date,'%d-%m-%Y')) month_ , year(str_to_date(order_date,'%d-%m-%Y')) year_
from combined_table)t
where month_ = 1 and Year_ = 2011 group by month_, Year_ ;


-- how many of them came back every month over the entire year in 2011    

SELECT COUNT(cust_id) AS returning_customers_count
FROM (SELECT cust_id FROM customers WHERE YEAR(date_) = 2011 GROUP BY cust_id
HAVING COUNT(DISTINCT MONTH(date_)) = 12) AS returning_customers;


-- 8.	Retrieve month-by-month customer retention rate since the start of the business.(using views)
-- 1). Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred
-- over multiple # years since whenever business started operations

create view customer_visit as
select distinct cust_id,str_to_date(order_date,"%d-%m-%Y") cust_visit 
from combined_table order by cust_id desc, cust_visit ;


select *from customer_visit;
drop view customer_visit;

# Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
create view customer_visit_timelapse as
select cust_id,cust_visit, lag(cust_visit) over(partition by cust_id 
order by cust_visit) previous_visit_month
from customer_visit;

select * from customer_visit_timelapse;
drop view customer_visit_timelapse;

-- 3. Calculate the time gaps between visits
create view visit_time_gaps as
select distinct cust_id, cust_visit, previous_visit_month,
round(datediff(cust_visit,previous_visit_month)/30,2) difference 
from customer_monthly_visit_timelamp;

select *from visit_time_gaps;
drop view visit_time_gaps;

-- Q. 4 categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
create view Customer_categories as
select distinct*, case when difference is null then 'churned' when 
difference>1 then 'irregular' 
else 'retained' end
as Categories from visit_time_gaps;

select * from Customer_categories;


drop view Customer_categories;


-- Q.5 calculate the retention month wise
create View MonthWise_retention as
SELECT
    YEAR(cust_visit) AS retention_year,
    MONTH(cust_visit) AS retention_month,
    COUNT(cust_id) AS retained_cust
FROM Customer_categories
WHERE Categories = 'retained'
GROUP BY retention_year, retention_month
order by retention_year, retention_month;

select *from MonthWise_retention;
drop view MonthWise_retention;

-- Retrieve month-by-month customer retention rate
-- Calculate and retrieve the month-by-month customer retention rate
CREATE VIEW Month_by_month_retention_rate as
SELECT
    a.retention_year,
    a.retention_month,
    a.retained_cust,
    (a.retained_cust / b.total_customers) * 100 AS retention_rate
FROM MonthWise_retention a
LEFT JOIN (
    SELECT
        YEAR(cust_visit) AS retention_year,
        MONTH(cust_visit) AS retention_month,
        COUNT(cust_id) AS total_customers
    FROM Customer_categories
    GROUP BY retention_year, retention_month
) b
ON a.retention_year = b.retention_year AND a.retention_month = b.retention_month
ORDER BY a.retention_year, a.retention_month;

select *from Month_by_month_retention_rate;

  # Submission by _ Group 7- Prajakta A, Prtiksha C, Himanshu K., Abdealisuratwala,Vinay J, , Shantanu T
