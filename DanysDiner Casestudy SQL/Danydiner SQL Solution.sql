CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


  select * from menu;
  select * from sales;
  select * from members;

--Query 1 What is the total amount each customer spent at the restaurant.
  select s.customer_id, sum(m.price)
  from sales s 
  join menu m 
  on m.product_id= s.product_id
  group by s.customer_id;

--Query 2 How many days has each customer visited the restaurant.
 select customer_id, count(distinct order_date)
 from sales
 group by customer_id;

 --Query 3 what was the first item from the menu purchased by each customer.
  with ranked_purchases as (
select s.customer_id, s.order_date, m.product_name,
row_number() over (partition by s.customer_id order by s.order_date) as rn
from sales s
join menu m on s.product_id=m.product_id
)
select customer_id,product_name as first_product_purchased
from ranked_purchases
where rn=1;

--Query 4 What is the most purchased item on the menu and how many times was it purchased by all customers.
select m.product_name, count(s.product_id) as times_ordered
from sales s
join menu m on s.product_id=m.product_id
group by m.product_name
order by times_ordered desc
limit 1;

--Query 5 Which item was the most popular for each customer.
with item_count as (
select s.customer_id, m.product_name,count(s.product_id) as order_count,
row_number() over(partition by s.customer_id order by count(s.product_id) Desc) as rn
from sales s
join menu m on s.product_id=m.product_id
group by s.customer_id,m.product_name
)
select customer_id,product_name as popular_item,order_count
from item_count
where rn=1;

--Query 6 Which item was purchased first by the customer after they became a member?
with ranked_purchases as (
select s.customer_id,s.order_date,m.product_name,
row_number() over(partition by s.customer_id order by s.order_date) as rn
from sales s
join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where s.order_date>mb.join_date
)
select customer_id, product_name as first_ordered_item_after_membership
from ranked_purchases
where rn =1;

--Query 7 Which item was purchased just before the customer became a member?
with ranked_purchases as (
select s.customer_id,s.order_date,m.product_name,
row_number() over(partition by s.customer_id order by s.order_date desc) as rn
from sales s
join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where s.order_date<mb.join_date
)
select customer_id, product_name as last_ordered_item_before_membership
from ranked_purchases
where rn =1;

--Query 8 What is the total items and amount spent for each member before they became a member?
select s.customer_id, m.product_name, count(s.product_id) as total_item, sum(m.price) as total_amount_spent
from sales s
join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where mb.join_date>s.order_date
group by s.customer_id, m.product_name;

--Query 9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id, m.product_name, count(s.product_id) as total_item, sum(m.price) as total_amount_spent,
sum( case when m.product_name = 'sushi' then m.price * 10 * 2
          else m.price * 10
          end ) as total_points
from sales s
join menu m on s.product_id=m.product_id
join members mb on s.customer_id=mb.customer_id
where mb.join_date>s.order_date
group by s.customer_id,m.product_name;

--Query 10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi -how many points do customer A and B have at the end of January?
select s.customer_id,sum(case 
               when s.order_date between mb.join_date and mb.join_date + INTERVAL '6 days' then m.price * 10 * 2
               when m.product_name = 'sushi' then m.price * 10 * 2
               when m.price * 10
           end
       ) as total_points_in_january
from sales s
join menu m on s.product_id = m.product_id
join members mb on s.customer_id = mb.customer_id
where s.customer_id in ('A', 'B') and s.order_date <= '2021-01-31'
group by s.customer_id;