-- date to financial year

select year(date_add("2020-10-01", interval 4 month));

select * from gdb0041.fact_sales_monthly
WHERE customer_code = 90002002 and 
year(date_add(date, interval 4 month))=2021
order by date desc;

-- SQL user define function for financial year get_fiscal_year

select * from gdb0041.fact_sales_monthly
WHERE customer_code = 90002002 and 
get_fiscal_year(date)=2021
order by date desc;

select * from gdb0041.fact_sales_monthly
WHERE customer_code = 90002002 and 
get_fiscal_year(date)=2021 and 
get_fiscal_quarter(date) = "Q4"
order by date desc;

select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code = s.product_code
WHERE customer_code = 90002002 and get_fiscal_year(date)=2021
order by date desc
limit 1000000;

select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity,
    g.gross_price ,
    round(g.gross_price*s.sold_quantity, 2) as gross_price_total
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code = s.product_code
JOIN fact_gross_price g
ON g.product_code = s.product_code 
and g.fiscal_year = get_fiscal_year(s.date)
WHERE customer_code = 90002002 and get_fiscal_year(date)=2021
order by date desc
limit 1000000;

select 
	s.date , 
    sum(g.gross_price* s.sold_quantity)as gross_price_total
from 
	fact_sales_monthly s
JOIN fact_gross_price g
ON 
	g.product_code = s.product_code and 
	g.fiscal_year=get_fiscal_year(s.date)
where customer_code = 
	(select customer_code from dim_customer 
	where customer like "%Croma%" and market = "india")
group by s.date
order by s.date asc;


select g.fiscal_year,
	sum(m.sold_quantity * g.gross_price)as gross_sells_total
from fact_sales_monthly m
join fact_gross_price g  
on m.product_code = g.product_code and  g.fiscal_year = get_fiscal_year(m.date)
where customer_code = 
	(select customer_code from dim_customer 
	where customer like "%Croma%" and market = "india")
group by g.fiscal_year
order by g.fiscal_year;

select
	get_fiscal_year(date) as fiscal_year,
	sum(round(sold_quantity*g.gross_price,2)) as yearly_sales
from fact_sales_monthly s
join fact_gross_price g
on 
	g.fiscal_year=get_fiscal_year(s.date) and
	g.product_code=s.product_code
where
	customer_code=90002002
group by get_fiscal_year(date)
order by fiscal_year;

-- stored procedure
call gdb0041.get_monthly_gross_sales_for_customer(90002002);

-- top market top product top customer
select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity,
    g.gross_price ,
    round(g.gross_price*s.sold_quantity, 2) as gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code = s.product_code
JOIN fact_gross_price g
ON g.product_code = s.product_code 
and g.fiscal_year = get_fiscal_year(s.date)
JOIN fact_pre_invoice_deductions pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=get_fiscal_year(s.date)
WHERE 
get_fiscal_year(s.date)=2021
order by date desc
limit 1000000;

-- optimisation
Explain analyze
select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity,
    g.gross_price ,
    round(g.gross_price*s.sold_quantity, 2) as gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code = s.product_code
JOIN fact_gross_price g
ON g.product_code = s.product_code 
and g.fiscal_year = get_fiscal_year(s.date)
JOIN fact_pre_invoice_deductions pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=get_fiscal_year(s.date)
WHERE 
get_fiscal_year(s.date)=2021
order by date desc
limit 1000000;

-- optimization
-- create dim_date table for optimisation 
Explain analyze
select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity,
    g.gross_price ,
    round(g.gross_price*s.sold_quantity, 2) as gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code = s.product_code
JOIN dim_date dt
ON dt.calendar_date = s.date
JOIN fact_gross_price g
ON g.product_code = s.product_code 
and g.fiscal_year = dt.fiscal_year
JOIN fact_pre_invoice_deductions pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=dt.fiscal_year
WHERE 
get_fiscal_year(s.date)=2021
order by date desc
limit 1000000;

-- sloution 2
Explain analyze
 select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity,
    g.gross_price ,
    round(g.gross_price*s.sold_quantity, 2) as gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON p.product_code = s.product_code
JOIN fact_gross_price g
ON g.product_code = s.product_code 
and g.fiscal_year = s.fiscal_year
JOIN fact_pre_invoice_deductions pre
ON pre.customer_code = s.customer_code AND
pre.fiscal_year=s.fiscal_year
WHERE 
get_fiscal_year(s.date)=2021
order by date desc
limit 1000000;

-- net sales
 
 with cte1 as (
 select 
	s.date, s.product_code, 
    p.product, p.variant, s.sold_quantity,
    g.gross_price ,
    round(g.gross_price*s.sold_quantity, 2) as gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	JOIN fact_gross_price g
	ON g.product_code = s.product_code 
	and g.fiscal_year = s.fiscal_year
	JOIN fact_pre_invoice_deductions pre
	ON pre.customer_code = s.customer_code AND
	pre.fiscal_year=s.fiscal_year
WHERE 
	get_fiscal_year(s.date)=2021
order by date desc
limit 1000000)
select * , (gross_price_total-gross_price_total*pre_invoice_discount_pct) as net_invoice_sales 
from cte1;

-- view
select * , (gross_price_total-gross_price_total*pre_invoice_discount_pct) as net_invoice_sales 
from  sales_preinv_discount;

select 
	* , 
	(1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales ,
	(po.discounts_pct + po.other_deductions_pct) as post_invoice_discount_pct
from  sales_preinv_discount s
JOIN fact_post_invoice_deductions po
ON
	s.date = po.date AND
	s.customer_code=po.customer_code AND
	s.product_code = po.product_code;

-- adding discount columns and creating new view for net sales 

SELECT
	* ,
	(1-post_invoice_discount_pct)*net_invoice_sales as net_sales
 FROM gdb0041.sales_postinv_discount;
 
SELECT 
	s.date,
	s.fiscal_year,
	s.customer_code,
	c.customer,
	c.market,
	s.product_code,
	p.product, p.variant,
	s.sold_quantity,
	g.gross_price as gross_price_per_item,
	round(s.sold_quantity*g.gross_price,2) as gross_price_total
from fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
join dim_customer c
on s.customer_code=c.customer_code
join fact_gross_price g
on g.fiscal_year=s.fiscal_year
and g.product_code=s.product_code;

-- top market by net sales
SELECT market, 
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales
where fiscal_year = 2021 
group by market
order by net_sales_mln desc 
limit 5;

-- top customers by net sales
SELECT customer, 
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
join dim_customer c
on n.customer_code = c.customer_code 
where fiscal_year = 2021 
group by customer
order by net_sales_mln desc 
limit 5;

-- top n product by net sales
SELECT c.product, 
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
join dim_product c
on n.product_code = c.product_code 
where fiscal_year = 2021 
group by product
order by net_sales_mln desc 
limit 5;

-- percentage
with cte1 as (
SELECT customer, 
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
join dim_customer c
on n.customer_code = c.customer_code 
where fiscal_year = 2021 
group by customer )
select * , net_sales_mln*100/sum(net_sales_mln) over() as pct
from cte1
order by net_sales_mln desc;


-- region wise contribution
with cte1 as (
SELECT c.customer, c.region,
round(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
join dim_customer c
on n.customer_code = c.customer_code 
where fiscal_year = 2021 
group by c.customer , c.region )
select * , net_sales_mln*100/sum(net_sales_mln) over(partition by region) as pct_region
from cte1
order by region, net_sales_mln desc;

-- top 3 product
with cte1 as (SELECT
		p.division,
		p.product,
		SUM(sold_quantity) AS total_qty
	FROM fact_sales_monthly s
	JOIN dim_product p
		ON p.product_code = s.product_code
	WHERE fiscal_year = 2021
	GROUP BY 
		p.division,  
		p.product
	ORDER BY 
		total_qty),
cte2 as 
(select 
	*, 
    dense_rank () over (partition by division order by total_qty desc) as drnk
	from cte1)
select * from cte2 where drnk<=3;

-- supply chain analysis

-- create new table with sold and forcast qty in on table

select max(date) from fact_forecast_monthly;
select count(*) from fact_forecast_monthly;
select max(date) from fact_sales_monthly;
select count(*) from fact_sales_monthly;

SET SESSION wait_timeout=600;
SET SESSION net_read_timeout=600;
SET SESSION net_write_timeout=600;
SET GLOBAL max_allowed_packet=1073741824;

create table fact_act_est
(select 
	s.date as date,
    f.fiscal_year as fiscal_year,
    s.product_code as Product_code,
    s.customer_code as customer_code,
    s.sold_quantity as sold_quantity,
    f.forecast_quantity as forecast_quantity
from 
	fact_sales_monthly s
left join 
	fact_forecast_monthly f 
using (date , customer_code , product_code)
UNION
select 
	s.date as date,
    f.fiscal_year as fiscal_year,
    s.product_code as Product_code,
    s.customer_code as customer_code,
    s.sold_quantity as sold_quantity,
    f.forecast_quantity as forecast_quantity
from 
	fact_forecast_monthly f 
left join 
	fact_sales_monthly s 
using (date , customer_code , product_code));

select * from fact_act_est;
UPDATE fact_act_est 
SET sold_quantity = 0
WHERE sold_quantity IS NULL;

