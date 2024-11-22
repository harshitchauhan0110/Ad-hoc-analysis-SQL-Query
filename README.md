# **SQL Query Task**
#**Task** :-

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
# 1.) Create a User Defined function that Generates FY from 1-Sep to 31 Aug.FY of Atliq is Sep to Aug
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
