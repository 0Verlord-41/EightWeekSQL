/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as total_spend
from sales
join menu
on sales.product_id = menu.product_id
group by customer_id
order by total_spend desc

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct(order_date)) from sales
group by customer_id
order by customer_id

-- 3. What was the first item from the menu purchased by each customer?

With FirstPurchase as (
	select customer_id, min(order_date) as first_date
	from sales
	group by customer_id
)

select distinct on (fp.customer_id) fp.customer_id, s.order_date, m.product_name
from FirstPurchase fp
join sales s on s.order_date = fp.first_date and s.customer_id = fp.customer_id
join menu m on m.product_id = s.product_id
order by fp.customer_id, s.order_date

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?



-- 5. Which item was the most popular for each customer?

with prodFreq as (
	select customer_id, product_id, count(product_id) as freq
	from sales
	group by customer_id, product_id
	order by customer_id
),
	rest as (
	select customer_id, product_id, freq,
	row_number() over (partition by customer_id order by freq desc ) as rn
	from prodFreq
)

select r.customer_id, m.product_name
from rest r
join menu m on r.product_id = m.product_id
where r.rn = 1

-- 6. Which item was purchased first by the customer after they became a member?

with sorted as (
	select s.customer_id, s.order_date, s.product_id,
	row_number() over (partition by s.customer_id order by order_date ) as rn
	from sales s
	join members m
	on s.order_date >= m.join_date
	order by s.customer_id, s.order_date
)

select  s.customer_id, m.product_name, s.order_date
from sorted s
join menu m
on s.product_id = m.product_id
where rn=1

-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


/* select menu.product_name, count(sales.product_id) as total_serves
from dannys_diner.sales
join dannys_diner.menu
on sales.product_id = menu.product_id
group by menu.product_name
order by total_serves desc
limit 1 */