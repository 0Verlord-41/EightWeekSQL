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
with ProdCount as (
	select s.product_id, m.product_name, count(s.product_id) as freq
	from sales s
	join menu m 
	on s.product_id = m.product_id
	group by s.product_id, m.product_name
	order by freq desc
	limit 1
)
select s.customer_id,p.product_name, count(s.product_id) as NumberOfOrders
from sales s
join ProdCount p
on s.product_id = p.product_id
group by s.customer_id, p.product_name
order by s.customer_id

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

With sorted as (
	select s.customer_id, s.order_date, s.product_id
	from sales s 
	join members m on s.customer_id = m.customer_id
	where s.order_date < m.join_date
	order by s.customer_id, s.order_date desc
), rest as(
	select st.customer_id, st.order_date, m.product_name, 
	row_number() over (partition by st.customer_id order by st.customer_id) as rn
	from sorted st
	join menu m
	on st.product_id = m.product_id
)
	select customer_id, order_date, product_name 
	from rest
	where rn =1

-- 8. What is the total items and amount spent for each member before they became a member?

with Rset as (
	select s.customer_id, s.order_date, s.product_id
	from sales s
	join members m on s.customer_id = m.customer_id
	where s.order_date < m.join_date
)
	
select r.customer_id, count(r.product_id), sum(m.price)
from Rset r
join menu m on r.product_id = m.product_id
group by r.customer_id

-- Subquery method	
select r.customer_id, count(r.product_id), sum(m.price)
from (
	select s.customer_id, s.order_date, s.product_id
	from sales s
	join members m on s.customer_id = m.customer_id
	where s.order_date < m.join_date
	) r
join menu m on r.product_id = m.product_id
group by r.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- method 1
with ActualCount as ( 
	select customer_id, product_id,
	case
		when product_id = 1 then 2*count(product_id)
		else count(product_id)
	end as newCount
	from sales
	group by customer_id, product_id
	order by customer_id, product_id
)

select a.customer_id, sum(m.price * a.newcount)*10 
from ActualCount a
join menu m
on a.product_id = m.product_id
group by a.customer_id

-- method 2

with Purchasepoints as (
	select s.customer_id, s.product_id, m.product_name,
	case
		when s.product_id=1 then m.price*2*10
		else m.price*10
	end as purchasepoints
	from sales s
	join menu m
	on s.product_id = m.product_id
	order  by s.customer_id, s.product_id
)

select  p.customer_id, sum(p.purchasepoints) as TotalPoints
from Purchasepoints p
group by p.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with Timeframe as (
	select s.customer_id, s.order_date, m.join_date, s.product_id
	from sales s
	join members m
	on s.customer_id= m.customer_id
	where s.order_date < '2021-02-01'
),Purchasepoints as (
	select tf.customer_id, tf.product_id, tf.order_date, tf.join_date, m.product_name,
	case
		when tf.order_date between tf.join_date and tf.join_date + interval '6 day' then m.price*2*10 
		else m.price*10
	end as purchasepoints
	from Timeframe tf
	join menu m
	on tf.product_id = m.product_id
	order  by tf.customer_id, tf.product_id
)

select customer_id, sum(purchasepoints)
from Purchasepoints
group by customer_id
order by customer_id

/* select menu.product_name, count(sales.product_id) as total_serves
from dannys_diner.sales
join dannys_diner.menu
on sales.product_id = menu.product_id
group by menu.product_name
order by total_serves desc
limit 1 */