## **Financial Analysis**
# **Task** :-

# Description
**As a Product owner, I want to generate a report of individual product sales (aggregated
on a monthly basis at the product level) for Chroma India Customer for FY = 2021 so
that I can track individual product sales and run further product analysis on it in excel.
The report should be in following fields :-**
1. Months
2. Product Name and Variant
3. Sold Quantity
4. Gross Price Per Item
5. Gross Price Total
6. Variants

**1.) Create a User Defined function that Generates FY from 1-Sep to 31 Aug.FY of Atliq is Sep to Aug**
```sql
CREATE FUNCTION `get_fiscal_year` ( calendar_date date )
RETURNS INTEGER
DETERMINISTIC
BEGIN
DECLARE fiscal_year int;
SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
RETURN fiscal_year;
END
```

**2.) Retrieve the Monthly Sales of Chroma Store in FY=2021?**
```sql
SELECT
*
FROM gdb0041.fact_sales_monthly
where customer_code = 90002002 and
get_fiscal_year(date) = 2021
order by date desc;
```
**3.)Develop a function to determine the fiscal quarter for any given month, based on the fiscal year.**
**FY of Atliq is Sep to Aug**
```sql
CREATE FUNCTION `get_fiscal_quarter` ( calendar_date date )
RETURNS CHAR(2)
DETERMINISTIC
BEGIN
DECLARE qtr CHAR(2);
Case
when MONTH(calendar_date) in (9,10,11) then Set qtr = "Q1";
 WHEN MONTH(calendar_date) in (12,1,2) then set qtr = "Q2";
 WHEN MONTH(calendar_date) in (3,4,5) then set qtr = "Q3";
 Else set qtr = "Q4";
 end case;
RETURN qtr ;
END
```
**4.) Generate the Total Gross Price of Chroma store in FY = 2021?**
```sql
SELECT
s.date, s.product_code,
 p.product, p.variant, s.sold_quantity,
 g.gross_price,
 round((s.sold_quantity*g.gross_price),2) as gross_price_total

FROM gdb0041.fact_sales_monthly s
JOIN dim_product p
on s.product_code = p.product_code
JOIN fact_gross_price g
on g.product_code = s.product_code and
 get_fiscal_year(s.date)=g.fiscal_year
WHERE
s.customer_code = 90002002 and
 get_fiscal_year(s.date) = 2021
order by s.date
limit 1000000 ;
```
**5.) Generate Monthly total gross price of Chroma Store ?**
```sql
SELECT
s.date,
 sum(g.gross_price*s.sold_quantity) as gross_price_total
FROM gdb0041.fact_sales_monthly s
JOIN fact_gross_price g
on
s.product_code = g.product_code and
 get_fiscal_year(s.date) = g.fiscal_year
WHERE
s.customer_code = 90002002
GROUP BY s.date
order by s.date;
```
**6.) Create a Store Procedure to retrieve monthly gross sales for a costumer.**
```sql
CREATE PROCEDURE `get_monthly_gross_sales_for_customer` ( customer_code int )
BEGIN
SELECT
s.date,
sum(g.gross_price*s.sold_quantity) as gross_price_total
FROM gdb0041.fact_sales_monthly s
JOIN fact_gross_price g
on
s.product_code = g.product_code and
get_fiscal_year(s.date) = g.fiscal_year
WHERE
s.customer_code = customer_code
GROUP BY s.date
order by s.date;
END
```
**7.) Create a Stored Procedure that retrieve the FY Total Gross sale for a customer.**
```sql
SELECT
get_fiscal_year(s.date) as FY,
 sum(g.gross_price*s.sold_quantity) as gross_price_total
FROM gdb0041.fact_sales_monthly s
JOIN fact_gross_price g
on
s.product_code = g.product_code and
 get_fiscal_year(s.date) = g.fiscal_year
WHERE
s.customer_code = 90002002
GROUP BY get_fiscal_year(s.date)
```

**8.) Create a Stored Procedure that can determine the market badge based on the following logic**
    **If Total sold quantity > 5 million than it’s a Gold market else its Silver**
        **My input value should  be :-
           • Market
           • Fiscal year**
```sql
CREATE PROCEDURE `get_market_badge` (
in in_market text,
 in in_fiscal_year year,
 out out_badge varchar(7)
)
BEGIN
declare qty int ;

# retrieve total quantity of given market and fy
SELECT
sum(s.sold_quantity) into qty
FROM gdb0041.fact_sales_monthly s
join dim_customer c
on
s.customer_code = c.customer_code
where
get_fiscal_year(s.date)=in_fiscal_year and
c.market = in_market
group by c.market;

 # determine market badge
 if qty > 5000000 then
set out_badge = "Gold";
 else
set out_badge = "Silver";
 end if;
END
```

## Market Analysis

# Query

**1. View for Gross Sales?**
```sql
CREATE VIEW `gross_sales` AS
 SELECT
s.date, s.fiscal_year,
s.customer_code, c.customer,
c.market, s.product_code,
p.product, p.variant,
s.sold_quantity,
g.gross_price as gross_price_per_item,
round(s.sold_quantity*g.gross_price,2) as gross_price_total
from fact_sales_monthly s
join dim_product p
on
s.product_code=p.product_code
join dim_customer c
on
s.customer_code=c.customer_code
join fact_gross_price g
on
g.fiscal_year=s.fiscal_year and
g.product_code=s.product_code;
```
**2. View for pre invoice discount deduction.**
```sql
CREATE VIEW `sales_preinvoice_dis` AS
Select
s.date, s.fiscal_year,
s.customer_code, c.market,
s.product_code,
s.sold_quantity, g.gross_price,
(s.sold_quantity*g.gross_price) as gross_price_total,
pre.pre_invoice_discount_pct
from gdb0041.fact_sales_monthly s
JOIN dim_customer c
on
c.customer_code = s.customer_code
JOIN fact_gross_price g
on
s.product_code = g.product_code and
s.fiscal_year = g.fiscal_year
join fact_pre_invoice_deductions pre
on
s.customer_code = pre.customer_code and
s.fiscal_year = pre.fiscal_year;
```
**3. View for post invoice discount deduction.**
```sql
CREATE VIEW `sales_post_invoice_dis` AS
select
pr.date, pr.fiscal_year, pr.customer_code, pr.market,
 pr.product_code,p.product,p.variant, pr.sold_quantity,
pr.gross_price,
 pr.gross_price_total, pr.pre_invoice_discount_pct,
 (1-pr.pre_invoice_discount_pct)*pr.gross_price_total as
net_invoice_sale,
 (po.discounts_pct + po.other_deductions_pct) as
total_discount
from sales_preinvoice_dis pr
join dim_product p
on
pr.product_code = p.product_code
join fact_post_invoice_deductions po
on
pr.date = po.date and
 pr.customer_code = po.customer_code and
 pr.product_code = po.product_code;
```
**4. View for Net Sales.**
```sql
 SELECT
 *,
 ( (1-total_discount)* net_invoice_sale) as net_sales
 FROM gdb0041.sales_post_invoice_dis;
```
**5. Top 5 Market net sales.**
```sql
SELECT
market,
 round((sum(net_sales)/1000000),2) as net_sales_mln
FROM gdb0041.net_sales
where fiscal_year = 2021
Group by market
order by net_sales_mln desc
limit 5 ;
```
**6. Stored procedure that return top n market in given fiscal year.**
```sql
CREATE PROCEDURE `top_n_market_by_net_sales_and_fiscal_year` (
in_fiscal_year int,
 in_top_n int
)
BEGIN
SELECT
market,
 round((sum(net_sales)/1000000),2) as net_sales_mln
FROM gdb0041.net_sales
where fiscal_year = in_fiscal_year
Group by market
order by net_sales_mln desc
limit in_top_n ;
END
```
**7. Stored procedure that return top n customer by given fiscal year and market.**
```sql
CREATE PROCEDURE `get_top_n_customer_by_net_sales`(
in_market varchar(45),
in_fiscal_year int,
 in_top_n int
)
BEGIN
SELECT
c.customer,
 round(sum(n.net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
join dim_customer c
on
n.customer_code = c.customer_code
where
fiscal_year = in_fiscal_year and
 n.market = in_market
group by c.customer
order by net_sales_mln desc
limit in_top_n
;
END
```
**8. Stored Procedure of Top n product by given fiscal year.**
```sql
CREATE PROCEDURE `top_n_product_by_fiscal_year` (
in_fiscal_year int,
 in_top_n int
)
BEGIN
SELECT
product,
 round(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales
where
fiscal_year = in_fiscal_year
group by product
order by net_sales_mln
limit in_top_n;
END
```
**9. Query for the market share percentage of customer net sales in the fiscal year 2021.**
```sql
With cte as (SELECT
c.customer,
 round(sum(n.net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
join dim_customer c
on
n.customer_code = c.customer_code
where
fiscal_year = 2021
group by c.customer
)
select
*, net_sales_mln/sum(net_sales_mln) over() *100 as pct
from cte
order by net_sales_mln desc
```
**10. Query for Breakdown of net sales percentages by customer in each region (APAC, NA, EU, LATAM).**
```sql
with cte as (select
c.customer,
 c.region,
 round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on
s.customer_code = c.customer_code
where fiscal_year = 2021
group by c.customer , c.region)
select
*,
net_sales_mln*100/sum(net_sales_mln) over(partition by
region) as pct_share_region
from cte
order by region , net_sales_mln desc
```
**11. Stored procedure for retrieving the top N products by quantity sold per division.**
```sql
CREATE PROCEDURE `get_top_n_product_per_division_by_qty_sold`
(
in_fiscal_year int,
 in_top_n int
)
BEGIN
with cte as (select
p.division,
 p.product,
sum(s.sold_quantity) as total_qty
 from fact_sales_monthly s
 join dim_product p
 on s.product_code = p.product_code
 where fiscal_year = in_fiscal_year
 group by p.product,p.division),
cte2 as (select
*,
dense_rank() over(partition by division order by
total_qty desc) as drnk
from cte)
select * from cte2 where drnk <= in_top_n;
END
```
**12. Retrieve the top 2 markets in every region by their gross sales amount in FY=2021.**
```sql
with cte as (SELECT
c.market,
 c.region,
 round(sum(s.gross_price_total)/1000000,2) as gross_sale_mln
FROM gdb0041.gross_sales s
join dim_customer c
on s.customer_code = c.customer_code
where fiscal_year = 2021
group by c.market , c.region),
cte2 as
(select
*, dense_rank() over(partition by region order by gross_sale_mln
desc) as rnk
from cte )
select * from cte2 where rnk <=2;
```
