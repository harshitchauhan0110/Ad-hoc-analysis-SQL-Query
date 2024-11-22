# **SQL Query Task**
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
