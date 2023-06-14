-- 1.1 Figure out which ads types generate high website traffic, plenty of orders and high conversion rate?

SELECT
w.utm_content,
COUNT(w.website_session_id) AS session_count,
COUNT(o.order_id) AS order_count,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
GROUP BY w.utm_content
HAVING w.utm_content IS NOT NULL
ORDER BY session_to_order_cvr_rate DESC;

-- 1.2 Explore what kind of combination of source and campaign create high website traffic, plenty of orders and high conversion rate?

SELECT
w.utm_source,
w.utm_campaign,
COUNT(w.website_session_id) AS session_count,
COUNT(o.order_id) AS order_count,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
GROUP BY utm_source,utm_campaign
HAVING utm_source IS NOT NULL AND utm_campaign IS NOT NULL
ORDER BY session_to_order_cvr_rate DESC;

-- 1.3 Identify what type of device contributes to high conversion rate?

SELECT
w.device_type,
COUNT(w.website_session_id) AS session_count,
COUNT(o.order_id) AS order_count,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
GROUP BY w.device_type
ORDER BY session_to_order_cvr_rate DESC;

-- 1.4 Examine the business results of adjusting bid strategies on source, campaign, content and device

-- 1.4.1 Examine the business result of improving bids on the content of 'b_ad_2' 

SELECT
MIN(DATE(w.created_at)) AS week_started_at,
COUNT(w.website_session_id) AS sessions,
COUNT(o.order_id) AS orders,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
WHERE utm_content='b_ad_2' 
GROUP BY 
YEAR(w.created_at),
WEEK(w.created_at);

-- 1.4.2 Examine the business result of improving bids on the content of 'g_ad_1'

SELECT
MIN(DATE(w.created_at)) AS week_started_at,
COUNT(w.website_session_id) AS sessions,
COUNT(o.order_id) AS orders,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
WHERE utm_content='g_ad_1' 
GROUP BY 
YEAR(w.created_at),
WEEK(w.created_at);


-- 1.4.3 Examine the business result of improving bids on source and campaign of ‘gsearch nonbrand’

SELECT
MIN(DATE(w.created_at)) AS week_started_at,
COUNT(w.website_session_id) AS sessions,
COUNT(o.order_id) AS orders,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
WHERE utm_source='gsearch' AND utm_campaign='nonbrand'
GROUP BY 
YEAR(w.created_at),
WEEK(w.created_at);

-- 1.4.4 Examine the business result of improving bids on source and campaign of ‘bsearch brand’

SELECT
MIN(DATE(w.created_at)) AS week_started_at,
COUNT(w.website_session_id) AS sessions,
COUNT(o.order_id) AS orders,
CONCAT(FORMAT(COUNT(o.order_id)/COUNT(w.website_session_id)*100,2),'%') AS session_to_order_cvr_rate
FROM website_sessions w
LEFT JOIN orders o
ON w.website_session_id=o.website_session_id
WHERE utm_source='bsearch' AND utm_campaign='brand'
GROUP BY 
YEAR(w.created_at),
WEEK(w.created_at);

-- 1.4.5 Examine the business result of improving bids on device of 'desktop'

SELECT
MIN(DATE(created_at)) AS week_start_date,
COUNT(CASE WHEN device_type='desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
COUNT(CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
WHERE (utm_source='gsearch' AND utm_campaign='nonbrand') OR (utm_source='bsearch' AND utm_campaign='brand')
GROUP BY
YEAR (created_at),
WEEK( created_at);

-- 2.1 Identify the most-viewed pages 

SELECT pageview_url,
COUNT(website_pageview_id) AS pageview_count
FROM website_pageviews
GROUP BY pageview_url
ORDER BY pageview_count DESC ;

-- 2.2 Identify the top entry pages (landing pages) and rank them by entry volume

WITH first_page_view AS (
SELECT 
website_session_id,
MIN(website_pageview_id) AS first_pv
FROM website_pageviews
GROUP BY website_session_id
) SELECT 
wp.pageview_url AS landing_page_url,
COUNT(DISTINCT fp.website_session_id) AS session_visiting_page
FROM first_page_view fp 
JOIN 
website_pageviews wp ON fp.first_pv=wp.website_pageview_id
GROUP BY wp.pageview_url
ORDER BY session_visiting_page DESC;

-- 2.3 Calculate bounce rate for traffic landing on the landing page

CREATE TEMPORARY TABLE first_pageviews
SELECT 
website_session_id,
MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
GROUP BY website_session_id;

-- 把每次访问网站，最早访问home--select出来了
CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT
wp.pageview_url AS landing_page,
fp.website_session_id
FROM first_pageviews fp 
LEFT JOIN 
website_pageviews wp ON fp.min_pageview_id=wp.website_pageview_id
WHERE wp.pageview_url='/home';

CREATE TEMPORARY TABLE bounced_sessions 
SELECT 
swp.website_session_id,
swp.landing_page,
COUNT(wp.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_home_landing_page swp
LEFT JOIN website_pageviews wp ON wp.website_session_id=swp.website_session_id 
GROUP BY swp.website_session_id,
swp.landing_page
HAVING 
COUNT(wp.website_pageview_id) = 1;

SELECT 
COUNT(swproductsp.website_session_id) AS sessions ,
COUNT(bs.website_session_id) AS bounced_sessions,
CONCAT(FORMAT(COUNT(bs.website_session_id) /COUNT(swp.website_session_id)*100,2),'%') AS bounce_rate
FROM sessions_w_home_landing_page swp
LEFT JOIN bounced_sessions bs ON swp.website_session_id=bs.website_session_id;

-- 2.4 launch a new landing homepage ( need to compare the bounce rate between the old and new landing homepage)

-- Firstly, identify when the new landing homepage start to be open to public

SELECT 
MIN(created_at) AS first_created_at,
MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url='/lander-1'
AND created_at IS NOT NULL;

CREATE TEMPORARY TABLE first_test_pageviews
SELECT
website_pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id=website_pageviews.website_session_id
AND website_pageviews.website_pageview_id > 23504
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
GROUP BY website_pageviews.website_session_id;

CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_page
SELECT
first_test_pageviews.website_session_id,
website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews ON website_pageviews.website_pageview_id=first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1');

CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT
nonbrand_test_sessions_w_landing_page.website_session_id,
nonbrand_test_sessions_w_landing_page.landing_page,
COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM nonbrand_test_sessions_w_landing_page
LEFT JOIN website_pageviews 
ON website_pageviews.website_session_id=nonbrand_test_sessions_w_landing_page.website_session_id
GROUP BY 
nonbrand_test_sessions_w_landing_page.website_session_id,
nonbrand_test_sessions_w_landing_page.landing_page
HAVING 
COUNT(website_pageviews.website_pageview_id)=1;

SELECT 
nonbrand_test_sessions_w_landing_page.landing_page,
COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS sessions,
COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id)/COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS bounce_rate
FROM nonbrand_test_sessions_w_landing_page
LEFT JOIN nonbrand_test_bounced_sessions
ON nonbrand_test_sessions_w_landing_page.website_session_id=nonbrand_test_bounced_sessions.website_session_id 
GROUP BY 
nonbrand_test_sessions_w_landing_page.landing_page;

-- 2.5 Pull the volume of paid search nonbrand traffic landing on /home and /lander-1,trended weekly.

CREATE TEMPORARY TABLE session_w_min_pv_id_and_view_count
SELECT
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) AS first_pageview_id,
COUNT(website_pageviews.website_pageview_id) AS count_pageviews
FROM website_sessions
LEFT JOIN website_pageviews 
ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
GROUP BY website_sessions.website_session_id;

CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT session_w_min_pv_id_and_view_count.website_session_id,
session_w_min_pv_id_and_view_count.first_pageview_id,
session_w_min_pv_id_and_view_count.count_pageviews,
website_pageviews.pageview_url AS landing_page,
website_pageviews.created_at AS session_created_at
FROM session_w_min_pv_id_and_view_count
LEFT JOIN website_pageviews
ON session_w_min_pv_id_and_view_count.first_pageview_id=website_pageviews.website_pageview_id;

SELECT
MIN(DATE(session_created_at))AS week_start_date,
COUNT(CASE WHEN count_pageviews=1 THEN website_session_id ELSE NULL END) *1.0/COUNT(website_session_id) AS bounce_rate,
COUNT(CASE WHEN landing_page='/home' THEN website_session_id ELSE NULL END) AS home_sessions,
COUNT(CASE WHEN landing_page='/lander-1'THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_w_counts_lander_and_created_at
GROUP BY YEARWEEK(session_created_at);


-- 2.6 Build up full conversion funnel and execute conversion funnel analysis 

SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
ON
website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
AND website_sessions.created_at > '2012-08-05'
AND website_sessions.created_at < '2012-09-05'
ORDER BY website_sessions.website_session_id,
website_pageviews.created_at;

SELECT
website_session_id,
MAX(products_page) AS product_made_it,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
ON
website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
AND website_sessions.created_at > '2012-08-05'
AND website_sessions.created_at < '2012-09-05'
ORDER BY website_sessions.website_session_id,
website_pageviews.created_at
) AS pageview_level
GROUP BY
website_session_id;

SELECT
COUNT(website_session_id) AS sessions,
COUNT(CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) AS to_products,
COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS to_cart,
COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS to_shipping,
COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS to_billing,
COUNT(CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM(
SELECT
website_session_id,
MAX(products_page) AS product_made_it,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
ON
website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
AND website_sessions.created_at > '2012-08-05'
AND website_sessions.created_at < '2012-09-05'
ORDER BY website_sessions.website_session_id,
website_pageviews.created_at
) AS pageview_level
GROUP BY
website_session_id
) AS session_level_made_it_flags;

SELECT
CONCAT(FORMAT(COUNT(CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) /COUNT( website_session_id) *100,2),'%') AS homepage_click_rate,
CONCAT(FORMAT(COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) /COUNT(CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END)*100,2),'%')
AS product_click_rate,
CONCAT(FORMAT(COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) /COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END)*100,2),'%')
AS cart_click_rate,
CONCAT(FORMAT(COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) /COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END)*100,2),'%')
AS shipping_click_rate,
CONCAT(FORMAT(COUNT(CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) /COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) *100,2),'%')
AS billing_click_rate
FROM(
SELECT
website_session_id,
MAX(products_page) AS product_made_it,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
ON
website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
AND website_sessions.created_at > '2012-08-05'
AND website_sessions.created_at < '2012-09-05'
ORDER BY website_sessions.website_session_id,
website_pageviews.created_at
) as pageview_level
GROUP BY
website_session_id
) AS session_level_made_it_flags;

-- 2.7 Optimization testing between old and new webpages

SELECT
MIN(website_pageviews.website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url='/billing-2';         -- first_pv_id: 53550

SELECT 
website_pageviews.website_session_id,
website_pageviews.pageview_url AS billing_version_seen,
orders.order_id
FROM website_pageviews
LEFT JOIN orders
ON orders.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >=53550 -- old and new pages should be in the same time start point
AND website_pageviews.pageview_url IN ('/billing','/billing-2');

SELECT 
billing_version_seen,
COUNT( website_session_id) AS sessions,
COUNT(order_id) AS orders,
CONCAT(FORMAT(COUNT( order_id)/COUNT( website_session_id)*100,2),'%') AS billing_to_order_rt
FROM(
SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url AS billing_version_seen,
orders.order_id
FROM website_pageviews
LEFT JOIN orders
ON orders.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >=53550
AND website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_sessions_w_orders
GROUP BY billing_version_seen;

/*3.1 Gsearch seems to be the biggest driver of our business.
 Could you pull monthly trends for gsearch sessions and orders so that we can showcase the growth there?  
 */
 
 SELECT
 YEAR(website_sessions.created_at) AS yr,
 MONTH(website_sessions.created_at) AS mo,
 COUNT( website_sessions.website_session_id) AS sessions,
 COUNT(orders.order_id) AS orders,
 CONCAT(FORMAT(COUNT(orders.order_id)/COUNT( website_sessions.website_session_id)*100,2),'%' )AS conversion_rate
 FROM website_sessions
 LEFT JOIN orders
 ON orders.website_session_id=website_sessions.website_session_id
 AND website_sessions.utm_source='gsearch'
 GROUP BY YEAR(website_sessions.created_at),
 MONTH(website_sessions.created_at);
 
 /* 3.2 next, it would be great to see a similar monthly trend for gsearch, but this time splitting out nonbrand and brand campaigns separately. 
 I am wondering if brand is picking up at all. If so ,this is a good story to tell. 
 */
 
 SELECT
 YEAR(website_sessions.created_at) AS yr,
 MONTH(website_sessions.created_at) AS mo,
 COUNT(CASE WHEN utm_campaign='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
 COUNT(CASE WHEN utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders,
 CONCAT(FORMAT(COUNT(CASE WHEN utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END)
 /COUNT(CASE WHEN utm_campaign='nonbrand' THEN website_sessions.website_session_id ELSE NULL END)*100,2),'%' ) 
 AS nonbrand_conversion_rate,
 COUNT(CASE WHEN utm_campaign='brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
 COUNT(CASE WHEN utm_campaign='brand' THEN orders.order_id ELSE NULL END) AS brand_orders,
CONCAT(FORMAT(COUNT(CASE WHEN utm_campaign='brand' THEN orders.order_id ELSE NULL END)
 /COUNT(CASE WHEN utm_campaign='brand' THEN website_sessions.website_session_id ELSE NULL END)*100,2),'%' ) 
 AS brand_conversion_rate
 FROM website_sessions
 LEFT JOIN orders
 ON orders.website_session_id=website_sessions.website_session_id
 AND website_sessions.utm_source='gsearch'
 GROUP BY YEAR(website_sessions.created_at),
 MONTH(website_sessions.created_at);
 
  /* 3.3 while we are on gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
  I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
 */
 
 SELECT
 YEAR(website_sessions.created_at) AS yr,
 MONTH(website_sessions.created_at) AS mo,
 COUNT(CASE WHEN device_type='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
 COUNT(CASE WHEN device_type='desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders,
 CONCAT(FORMAT(COUNT(CASE WHEN device_type='desktop' THEN orders.order_id ELSE NULL END)
 /COUNT(CASE WHEN device_type='desktop' THEN website_sessions.website_session_id ELSE NULL END)*100,2),'%' ) 
 AS desktop_conversion_rate,
 COUNT(CASE WHEN device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
 COUNT(CASE WHEN device_type='mobile' THEN orders.order_id ELSE NULL END) AS brand_orders,
CONCAT(FORMAT(COUNT(CASE WHEN device_type='mobile' THEN orders.order_id ELSE NULL END)
 /COUNT(CASE WHEN device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END)*100,2),'%' ) 
 AS mobile_conversion_rate
 FROM website_sessions
 LEFT JOIN orders
 ON orders.website_session_id=website_sessions.website_session_id
 AND website_sessions.utm_source='gsearch'
 AND website_sessions.utm_campaign='nonbrand'
 GROUP BY YEAR(website_sessions.created_at),
 MONTH(website_sessions.created_at);
 
  /* 3.4 I am worried that one of our more pessimistic board members may be concerned about the large percentage of traffic from gsearch.
  Can you pull monthly trends for gsearch, alongside monthly trends for each of our other channels? 
 */
 
 SELECT 
 utm_source,
 utm_campaign,
 http_referer
 FROM website_sessions;

SELECT
 YEAR(website_sessions.created_at) AS yr,
 MONTH(website_sessions.created_at) AS mo,
 COUNT(CASE WHEN utm_source='gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
 COUNT(CASE WHEN utm_source='bsearch' THEN orders.order_id ELSE NULL END) AS bsearch_paid_sessions,
 COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) 
 AS organic_search_sessions,
 COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) 
 AS direct_type_in_sessions
 FROM website_sessions
 LEFT JOIN orders
 ON orders.website_session_id=website_sessions.website_session_id
 GROUP BY 
 YEAR(website_sessions.created_at),
 MONTH(website_sessions.created_at);
 
  /* 3.5 I'd like to tell the story of out website performance improvements over the course of the first 8 months,
  could you pull sessions to order conversion rate, by month?
 */
 
 SELECT
 YEAR(website_sessions.created_at) AS yr,
 MONTH(website_sessions.created_at) AS mo,
 COUNT( website_sessions.website_session_id) AS sessions,
 COUNT(orders.order_id) AS orders,
 CONCAT(FORMAT(COUNT(orders.order_id)/COUNT( website_sessions.website_session_id)*100,2),'%' )AS conversion_rate
 FROM website_sessions
 LEFT JOIN orders
 ON orders.website_session_id=website_sessions.website_session_id
 GROUP BY YEAR(website_sessions.created_at),
 MONTH(website_sessions.created_at);
 
 /* 3.6 for the gsearch lander test, please estimate the revenue that test earned us(hint: look at the increase in conversion rate from the teat period,
 and use nonbrand sessions and revenue since then to calculate incremental value)
 */
 
SELECT
MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url='/lander-1';      
 
SELECT 
website_pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id=website_pageviews.website_session_id
AND website_pageviews.website_pageview_id >=23504 -- first page_view
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
GROUP BY website_pageviews.website_session_id;

CREATE TEMPORARY TABLE first_test_pageviews
SELECT website_pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id=website_pageviews.website_session_id
AND website_pageviews.website_pageview_id >=23504 -- first page_view
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
GROUP BY website_pageviews.website_session_id;

WITH nonbrand_test_sessions_w_landing_pages AS(
SELECT
first_test_pageviews.website_session_id,
website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews
ON first_test_pageviews.min_pageview_id=website_pageviews.website_pageview_id
AND website_pageviews.pageview_url IN ('/home','/lander-1')
)
SELECT
landing_page,
COUNT( website_session_id) AS sessions,
COUNT( order_id) AS orders,
CONCAT(FORMAT(COUNT( order_id) / COUNT( website_session_id) *100,2),'%') AS conversion_rate
FROM(
SELECT
nonbrand_test_sessions_w_landing_pages.website_session_id,
nonbrand_test_sessions_w_landing_pages.landing_page,
orders.order_id AS order_id
FROM nonbrand_test_sessions_w_landing_pages
LEFT JOIN orders
ON orders.website_session_id=nonbrand_test_sessions_w_landing_pages.website_session_id
)  AS nonbrand_test_sessions_w_orders
GROUP BY landing_page;

SELECT
MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM website_sessions
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=website_sessions.website_session_id
WHERE utm_source='gsearch'
AND utm_campaign='nonbrand'
AND pageview_url='/home';

SELECT 
COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE website_session_id > 17145
AND utm_source='gsearch'
AND utm_campaign='nonbrand';

/* 3.7 for the landing page test you analyzed previously, it would be great to show a full conversion funnel from each of the two pages to orders. 
You can use the same time period. 
*/

CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT
website_session_id,
MAX(homepage) AS saw_homepage,
MAX(customer_lander) AS saw_customer_lander,
MAX(products_page) AS product_made_it,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/home' THEN 1 ELSE 0 END AS homepage,
CASE WHEN pageview_url='/lander-1' THEN 1 ELSE 0 END AS customer_lander,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS products_page,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
ON
website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
ORDER BY website_sessions.website_session_id,
website_pageviews.created_at
) AS pageview_level
GROUP BY
website_session_id;

SELECT
CASE 
WHEN saw_homepage=1 THEN 'saw_homepage'
WHEN saw_customer_lander=1 THEN 'saw_customer_lander'
ELSE 'uh oh...check logic'
END AS segment,
COUNT(website_session_id) AS sessions,
COUNT(CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) AS to_products,
COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS to_cart,
COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS to_shipping,
COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS to_billing,
COUNT(CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flagged
GROUP BY 1;


SELECT
CASE 
WHEN saw_homepage=1 THEN 'saw_homepage'
WHEN saw_customer_lander=1 THEN 'saw_customer_lander'
ELSE 'uh oh...check logic'
END AS segment,
COUNT(CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(website_session_id) AS lander_click_rate,
COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) product_click_rate,
COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) /COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS cart_click_rate,
COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS shipping_click_rate,
COUNT(CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS billing_click_rate
FROM session_level_made_it_flagged
GROUP BY 1;

/* 3.8 I’d love for you to quantify the impact of our billing test, as well,
please analyze the lift generated from the test, in terms of revenue per bulling page session, 
and then pull the number of billing page sessions for the past month to understand the monthly impact.
*/

SELECT 
billing_version_seen,
COUNT(website_session_id) AS sessions,
SUM(price_usd)/COUNT(website_session_id) AS revenue_per_billing_page_seen
FROM(
SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url as billing_version_seen,
orders.order_id,
orders.price_usd
FROM website_pageviews
LEFT JOIN orders
ON orders.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_pageviews_and_order_data
GROUP BY 1;

SELECT
COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews
WHERE website_pageviews.pageview_url IN ('/billing','billing-2');

/* 4.1 pull weekly trended session volume and 
compare to gsearch nonbrand so manager can ger a sense for how important this will be for the business. 
*/

SELECT
YEARWEEK(created_at) AS yrwk,
MIN(DATE(created_at)) AS week_start_date,
COUNT(website_session_id) AS total_sessions,
COUNT(CASE WHEN utm_source='gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
COUNT(CASE WHEN utm_source='bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM  website_sessions
WHERE utm_campaign='nonbrand'
GROUP BY YEARWEEK(created_at);

-- 4.2 pull the percentage of traffic coming on mobile, compare that to gsearch

SELECT
utm_source,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(CASE WHEN device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(CASE WHEN device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END) / COUNT(website_sessions.website_session_id) 
AS percentage_mobile
FROM  website_sessions
WHERE utm_campaign='nonbrand'
GROUP BY utm_source;

-- 4.3 Cross-channel bid optimization  

SELECT
website_sessions.device_type,
website_sessions.utm_source,
COUNT(website_sessions .website_session_id) AS sessions,
COUNT(orders.order_id) AS orders,
CONCAT(FORMAT(COUNT(orders.order_id)/COUNT(website_sessions.website_session_id)*100,2),'%') AS conversion_rate
FROM website_sessions 
LEFT JOIN orders 
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.utm_campaign='nonbrand'
GROUP BY 
website_sessions.device_type,
website_sessions.utm_source;

-- 4.4 Analyze the channel portfolio trends 

SELECT
YEARWEEK(created_at) AS yrwk,
MIN(DATE(created_at)) AS week_start_date,
COUNT(CASE WHEN utm_source='gsearch' AND device_type='desktop' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
COUNT(CASE WHEN utm_source='bsearch' AND device_type='desktop' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
COUNT(CASE WHEN utm_source='bsearch' AND device_type='desktop' THEN website_session_id ELSE NULL END) / 
COUNT(CASE WHEN utm_source='gsearch' AND device_type='desktop' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
COUNT(CASE WHEN utm_source='gsearch' AND device_type='mobile' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
COUNT(CASE WHEN utm_source='bsearch' AND device_type='mobile' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
COUNT(CASE WHEN utm_source='bsearch' AND device_type='mobile' THEN website_session_id ELSE NULL END) / 
COUNT(CASE WHEN utm_source='gsearch' AND device_type='mobile' THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM  website_sessions
WHERE utm_campaign='nonbrand'
GROUP BY YEARWEEK(created_at);

-- 4.5 Analyze direct, brand-driven traffic 

SELECT
YEAR(created_at) AS yr,
MONTH(created_at) AS mo,
COUNT(CASE WHEN channel_group='paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
COUNT(CASE WHEN channel_group='paid_brand' THEN website_session_id ELSE NULL END) AS brand,
COUNT(CASE WHEN channel_group='paid_brand' THEN website_session_id ELSE NULL END)/ 
COUNT(CASE WHEN channel_group='paid_nonbrand' THEN website_session_id ELSE NULL END)  AS brand_pct_of_nonbrand,
COUNT(CASE WHEN channel_group='direct_type_in' THEN website_session_id ELSE NULL END) AS direct,
COUNT(CASE WHEN channel_group='direct_type_in' THEN website_session_id ELSE NULL END) /
COUNT(CASE WHEN channel_group='paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
COUNT(CASE WHEN channel_group='organic_search' THEN website_session_id ELSE NULL END) AS organic,
COUNT(CASE WHEN channel_group='organic_search' THEN website_session_id ELSE NULL END) /
COUNT(CASE WHEN channel_group='paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM(
SELECT
website_session_id,
created_at,
CASE
 WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
 WHEN utm_campaign='nonbrand' THEN 'paid_nonbrand'
 WHEN utm_campaign='brand' THEN 'paid_brand'
 WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
END AS channel_group
FROM website_sessions
) AS sessions_w_channel_group
GROUP BY 
YEAR(created_at),
MONTH(created_at);

-- 5.1 Analyze seasonality 

SELECT
YEAR (website_sessions.created_at) AS yr,
WEEK(website_sessions.created_at) AS wk,
MIN(DATE(website_sessions.created_at)) as week_start,
COUNT(website_sessions. website_session_id) AS sessions,
COUNT(orders.order_id) AS orders
FROM website_sessions
 LEFT JOIN orders
 ON website_sessions.website_session_id=orders.website_session_id
 GROUP BY YEAR (website_sessions.created_at),
WEEK(website_sessions.created_at);

-- 5.2 analyze business patterns

SELECT
hr,
ROUND(AVG(website_sessions),1) AS avg_sessions,
ROUND(AVG(CASE WHEN wkday=0 THEN website_sessions ELSE NULL END),1) as mon,
ROUND(AVG(CASE WHEN wkday=1 THEN website_sessions ELSE NULL END),1) as tues,
ROUND(AVG(CASE WHEN wkday=2 THEN website_sessions ELSE NULL END),1) as weds,
ROUND(AVG(CASE WHEN wkday=3 THEN website_sessions ELSE NULL END),1) as thurs,
ROUND(AVG(CASE WHEN wkday=4 THEN website_sessions ELSE NULL END),1) as fri,
ROUND(AVG(CASE WHEN wkday=5 THEN website_sessions ELSE NULL END),1) as sat,
ROUND(AVG(CASE WHEN wkday=6 THEN website_sessions ELSE NULL END),1) as sun
FROM (
SELECT
DATE(created_at) as created_date,
WEEKDAY(created_at) AS wkday,
HOUR(created_at) AS hr,
COUNT(website_session_id) AS website_sessions
FROM website_sessions
GROUP BY DATE(created_at) ,
WEEKDAY(created_at),
HOUR(created_at)
) AS daily_hourly_sessions
GROUP BY hr
ORDER BY hr;

-- 6.1 Product-level sales analysis

SELECT
YEAR(created_at) AS yr,
MONTH(created_at) AS mo,
COUNT(order_id) AS number_of_sales,
SUM(price_usd) AS total_revenue,
SUM(price_usd-cogs_usd) AS total_margin
FROM ORDERS
GROUP BY YEAR(created_at),
MONTH(created_at);

-- 6.2 Product launch sales analysis

SELECT
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mo,
COUNT(website_sessions .website_session_id) AS sessions,
COUNT(orders.order_id) AS orders,
CONCAT(FORMAT(COUNT(orders.order_id)/COUNT(website_sessions.website_session_id)*100,2),'%') AS conversion_rate,
SUM(orders.price_usd)/ COUNT(website_sessions.website_session_id) AS revenue_per_session,
COUNT(CASE WHEN primary_product_id=1 THEN order_id ELSE NULL END) as product_one_orders,
COUNT(CASE WHEN primary_product_id=2 THEN order_id ELSE NULL END) as product_two_orders
FROM website_sessions 
LEFT JOIN orders 
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.utm_campaign='nonbrand'
GROUP BY 
YEAR(website_sessions.created_at),
MONTH(website_sessions.created_at);

-- 6.3 Product-level website pathing

-- step 1: find the relevant /products pageviews with website_session_id
-- step 2: find thenext pageview id that occurs after the product pageview
-- step 3: find the pageview_url associated with any applicabe next pageview id
-- step 4: summarize the data and analyze the pre va post periods

-- step 1:
CREATE TEMPORARY TABLE products_pageviews
SELECT
website_session_id,
website_pageview_id,
created_at,
CASE 
WHEN created_at < '2013-01-06'THEN 'A.Pre_Product_2'
WHEN created_at >= '2013-01-06'THEN 'B.Pre_Product_2'
ELSE 'uh oh...check logic'
END AS time_period
FROM website_pageviews
WHERE created_at< '2013-04-06' -- the date of request
AND created_at > '2012-10-06' -- start of 3 mo before product 2 launch
AND pageview_url='/products';

-- step 2:
CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT
products_pageviews.time_period,
products_pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=products_pageviews.website_session_id
AND website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
GROUP BY 1,2;

-- step 3:

CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT
sessions_w_next_pageview_id.time_period,
sessions_w_next_pageview_id.website_session_id,
website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = sessions_w_next_pageview_id.min_next_pageview_id;

-- step 04:

SELECT
time_period,
COUNT( website_session_id) AS sessions,
COUNT(CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
COUNT(CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) /
COUNT( website_session_id) AS pct_w_next_pg,
COUNT(CASE WHEN next_pageview_url ='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
COUNT(CASE WHEN next_pageview_url ='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) /
COUNT( website_session_id) AS pct_to_mrfuzzy ,
COUNT(CASE WHEN next_pageview_url ='/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
COUNT(CASE WHEN next_pageview_url ='/the-forever-love-bear' THEN website_session_id ELSE NULL END) /
COUNT( website_session_id) AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY time_period;

-- 6.4 build product-level conversion funnel

-- step 1: select all pageviews for relevant sessions
-- step 2: figure out which pageview urls to look for
-- step 3: pull all pageviews and identify the funnel steps
-- step 4: create the session-level conversion funnel view
-- step 5: aggregate the data to assess funnel performance 

-- step 1:
CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT
website_session_id,
website_pageview_id,
pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at < '2013-04-10'-- date of assignment
AND  created_at > '2013-01-06' -- product 2 launch
AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear');

-- step 2:
SELECT
website_pageviews.pageview_url
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;

-- step 3:
SELECT
sessions_seeing_product_pages.website_session_id,
sessions_seeing_product_pages.product_page_seen,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing-2' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY 
sessions_seeing_product_pages.website_session_id,
website_pageviews.created_at;

-- step 4:
CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT
website_session_id,
CASE 
WHEN product_page_seen='/the-original-mr-fuzzy' THEN 'mrfuzzy'
WHEN product_page_seen='/the-forever-love-bear' THEN 'lovebear'
ELSE 'uh oh...check logic'
END AS product_seen,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thankyou_page) AS thankyou_made_it
FROM(
SELECT
sessions_seeing_product_pages.website_session_id,
sessions_seeing_product_pages.product_page_seen,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing-2' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY 
sessions_seeing_product_pages.website_session_id,
website_pageviews.created_at
) AS pageview_level
GROUP BY 
website_session_id,
CASE 
WHEN product_page_seen='/the-original-mr-fuzzy' THEN 'mrfuzzy'
WHEN product_page_seen='/the-forever-love-bear' THEN 'lovebear'
ELSE 'uh oh...check logic'
END;

-- step 5:

SELECT 
product_seen,
COUNT(website_session_id) AS sessions,
COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS to_cart,
COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS to_shipping,
COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS to_billing,
COUNT(CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;

SELECT 
product_seen,
COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(website_session_id) AS product_page_click_rate,
COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) /COUNT(CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS cart_click_rate,
COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS shipping_click_rate,
COUNT(CASE WHEN thankyou_made_it=1 THEN website_session_id ELSE NULL END) / COUNT(CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS billing_click_rate
FROM session_product_level_made_it_flags
GROUP BY product_seen;

-- 6.5 cross-level analysis

-- step 1: indentify the relevant /cart page views and their sessions
-- step 2: see which of those  /cart sessions clicked through to the shipping page
-- step 3: find the orders associated with the /cart sessions. Analyze products purchased, AOV
-- step 4: aggregate and analyze a summary of our findings

-- step 1: 
CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
CASE 
WHEN created_at < '2013-09-25' THEN 'A.Pre_Cross_Sell'
WHEN created_at >= '2013-01-06' THEN 'B.Post_Cross_Sell'
ELSE'uh oh...check logic'
END AS time_period,
website_session_id AS cart_session_id,
website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url='/cart';

-- step 2:
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
sessions_seeing_cart.time_period,
sessions_seeing_cart.cart_session_id,
MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=sessions_seeing_cart.cart_session_id
AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
GROUP BY 
sessions_seeing_cart.time_period,
sessions_seeing_cart.cart_session_id
HAVING 
MIN(website_pageviews.website_pageview_id) IS NOT NULL;

-- step 3:
CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
time_period,
cart_session_id,
order_id,
items_purchased,
price_usd
FROM sessions_seeing_cart
INNER JOIN orders
ON sessions_seeing_cart.cart_session_id=orders.website_session_id;

-- step 4:

SELECT
time_period,
COUNT(cart_session_id) AS cart_sessions,
SUM(clicked_to_another_page) AS clickthrough,
SUM(clicked_to_another_page) / COUNT(cart_session_id) AS cart_ctr,
SUM(placed_order) AS orders_placed,
SUM(items_purchased) AS products_purchased,
SUM(items_purchased)/SUM(placed_order) AS products_per_order,
SUM(price_usd) AS revenue,
SUM(price_usd)/ SUM(placed_order) AS aov,
SUM(price_usd)/ COUNT(cart_session_id) AS rev_per_cart_session
FROM (
SELECT
sessions_seeing_cart.time_period,
sessions_seeing_cart.cart_session_id,
CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NOT NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
pre_post_sessions_orders.items_purchased,
pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
LEFT JOIN cart_sessions_seeing_another_page
ON sessions_seeing_cart.cart_session_id= cart_sessions_seeing_another_page.cart_session_id
LEFT JOIN pre_post_sessions_orders
ON sessions_seeing_cart.cart_session_id= pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id
) as full_data
GROUP BY time_period;

-- 6.6 product portfolio expansion

SELECT
CASE 
WHEN website_sessions.created_at < '2013-12-12'THEN 'A.Pre_Birthday_Bear'
WHEN website_sessions.created_at >= '2013-12-12'THEN 'B.Post_Birthday_Bear'
ELSE 'uh oh...check logic'
END AS time_period,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(orders.order_id) AS orders,
CONCAT(FORMAT(COUNT(orders.order_id)/COUNT(website_sessions.website_session_id)*100,2),'%') AS conv_rate,
SUM(orders.price_usd) AS TOTAL_revenue,
SUM(orders.items_purchased) AS total_products_sold,
SUM(orders.price_usd) / COUNT(orders.order_id) AS average_order_value,
SUM(items_purchased)/COUNT(orders.order_id)  AS products_per_order,
SUM(orders.price_usd)/ COUNT(website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN'2013-11-12' AND '2014-01-12'
GROUP BY 1;

-- 6.7 product refund analysis
SELECT
YEAR(order_items.created_at) AS yr,
MONTH(order_items.created_at) AS mo,
COUNT(CASE WHEN product_id=1 THEN order_items.order_item_id ELSE NULL END) AS pl_orders,
COUNT(CASE WHEN product_id=1 THEN order_item_refunds.order_item_id ELSE NULL END) /
COUNT(CASE WHEN product_id=1 THEN order_items.order_item_id ELSE NULL END) AS pl_refund_rt,
COUNT(CASE WHEN product_id=2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
COUNT(CASE WHEN product_id=2 THEN order_item_refunds.order_item_id ELSE NULL END) /
COUNT(CASE WHEN product_id=2 THEN order_items.order_item_id ELSE NULL END) AS p2_refund_rt,
COUNT(CASE WHEN product_id=3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
COUNT(CASE WHEN product_id=3 THEN order_item_refunds.order_item_id ELSE NULL END) /
COUNT(CASE WHEN product_id=3 THEN order_items.order_item_id ELSE NULL END) AS p3_refund_rt,
COUNT(CASE WHEN product_id=4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
COUNT(CASE WHEN product_id=4 THEN order_item_refunds.order_item_id ELSE NULL END) /
COUNT(CASE WHEN product_id=4 THEN order_items.order_item_id ELSE NULL END) AS p4_refund_rt
FROM order_items
LEFT JOIN order_item_refunds
ON order_items.order_item_id=order_item_refunds.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;


-- 7.1 Identify repeat visitors

CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
new_sessions.user_id,
new_sessions.website_session_id AS new_session_id,
website_sessions.website_session_id AS repeat_session_id
FROM
(
SELECT
user_id,
website_session_id
FROM website_sessions
WHERE is_repeat_session = 0
) AS new_sessions
LEFT JOIN website_sessions
ON website_sessions.user_id=new_sessions.user_id
AND website_sessions.is_repeat_session=1
AND website_sessions.website_session_id > new_sessions.website_session_id;

SELECT
repeat_sessions,
COUNT(user_id) AS users
FROM
(
SELECT
user_id,
COUNT(new_session_id) AS new_sessions,
COUNT(repeat_session_id) AS repeat_sessions
FROM sessions_w_repeats
GROUP BY 1
ORDER BY 3 DESC
) AS user_level
GROUP BY 1;

-- 7.2 Analyze time to repeat

CREATE TEMPORARY TABLE sessions_w_repeats_for_time_diff
SELECT
new_sessions.user_id,
new_sessions.website_session_id AS new_session_id,
new_sessions.created_at AS new_session_created_at,
website_sessions.website_session_id AS repeat_session_id,
website_sessions.created_at AS repeat_session_created_at
FROM
(
SELECT
user_id,
website_session_id,
created_at
FROM website_sessions
WHERE is_repeat_session = 0
) AS new_sessions
LEFT JOIN website_sessions
ON website_sessions.user_id=new_sessions.user_id
AND website_sessions.is_repeat_session=1
AND website_sessions.website_session_id > new_sessions.website_session_id;

CREATE TEMPORARY TABLE users_first_to_second
SELECT
user_id,
DATEDIFF(second_session_created_at, new_session_created_at) AS days_first_to_second_session
FROM
(
SELECT
user_id,
new_session_id,
new_session_created_at,
MIN(repeat_session_id) AS second_session_id,
MIN(repeat_session_created_at) AS second_session_created_at
FROM sessions_w_repeats_for_time_diff
WHERE repeat_session_id IS NOT NULL
GROUP BY 1,2,3
) AS first_second;

SELECT
AVG(days_first_to_second_session) AS avg_days_first_to_second,
MIN(days_first_to_second_session) AS min_days_first_to_second,
MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_second;

-- 7.3 Analyze repeat channel behavior

SELECT 
utm_source,
utm_campaign,
http_referer,
COUNT(CASE WHEN is_repeat_session=0 THEN website_session_id ELSE NULL END)  AS new_sessions,
COUNT(CASE WHEN is_repeat_session=1 THEN website_session_id ELSE NULL END)  AS repeat_sessions
FROM website_sessions
GROUP BY 1,2,3
ORDER BY 5 DESC;

SELECT
CASE 
 WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
 WHEN utm_campaign='nonbrand' THEN 'paid_nonbrand'
 WHEN utm_campaign='brand' THEN 'paid_brand'
 WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
 WHEN utm_source = 'socialbook' THEN 'paid_social'
 END AS channel_group,
-- utm_source,
-- utm_campaign,
-- http_referer,
COUNT(CASE WHEN is_repeat_session=0 THEN website_session_id ELSE NULL END)  AS new_sessions,
COUNT(CASE WHEN is_repeat_session=1 THEN website_session_id ELSE NULL END)  AS repeat_sessions
FROM website_sessions
GROUP BY 1;
 
-- 7.4 Analyze new and repeat conversion rate

SELECT
is_repeat_session,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(orders.order_id) AS orders,
COUNT(orders.order_id)/ COUNT(website_sessions.website_session_id) AS conversion_rate,
SUM(price_usd) AS total_revenue,
SUM(price_usd)/ COUNT(website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id=website_sessions.website_session_id
GROUP BY 1;

/*8.1 show volume growth. pull overall session and order volume, trended by quarter for the life of the business? 
Since the most recent quarter is incomplete.
*/

SELECT
YEAR (website_sessions.created_at) AS yr,
QUARTER(website_sessions.created_at) AS qtr,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

/* 8.2 showcase all of our efficiency improvements. show quarterly figures since launched, 
for session-to-order conversion rate, revenue per order and revenue per session. 
*/

SELECT
YEAR (website_sessions.created_at) AS yr,
QUARTER(website_sessions.created_at) AS qtr,
COUNT(orders.order_id) / COUNT(website_sessions.website_session_id) AS session_to_order_conv_rate,
SUM(price_usd)/ COUNT(orders.order_id) AS revenue_per_order,
SUM(price_usd)/COUNT(website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

/* 8.3 show how we have grown specific channels. 
Could you pull a quarterly view of orders from Gsearch nonbrand, bsearch nonbrand, 
brand search overall, organic search and direct type-in?
*/

SELECT
YEAR(website_sessions.created_at) AS yr,
QUARTER(website_sessions.created_at) AS qtr,
COUNT(CASE WHEN utm_source='gsearch' AND utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) AS gsearch_nonbrand_orders,
COUNT(CASE WHEN utm_source='bsearch' AND utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) AS bsearch_nonbrand_orders,
COUNT(CASE WHEN utm_campaign='brand'  THEN orders.order_id ELSE NULL END) AS brand_search_orders,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS organic_search_orders,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS direct_type_in_orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

/* 8.4 show the overall session-to-order conversion rate trends for those same channels,by quarter.
 Please also make a note of any periods where we made major improvements or optimizations. 
 */
 
 SELECT
 YEAR(website_sessions.created_at) AS yr,
 QUARTER(website_sessions.created_at) AS qtr,
 COUNT(CASE WHEN utm_source='gsearch' AND utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) /
COUNT(CASE WHEN utm_source='gsearch' AND utm_campaign='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt,
COUNT(CASE WHEN utm_source='bsearch' AND utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) /
COUNT(CASE WHEN utm_source='bsearch' AND utm_campaign='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rt,
COUNT(CASE WHEN utm_campaign='brand'  THEN orders.order_id ELSE NULL END) /
COUNT(CASE WHEN utm_campaign='brand'  THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rt,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) /
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END)
AS organic_search_conv_rt,
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) /
COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END)
AS direct_type_conv_rt
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

/* 8.5 pull monthly trending for revenue and margin by product,
along with total sales and revenue.(seasonality) 
*/

SELECT
YEAR(created_at) AS yr,
MONTH(created_at) AS mo,
SUM(CASE WHEN product_id=1 THEN price_usd ELSE NULL END) AS mr_rev,
SUM(CASE WHEN product_id=1 THEN price_usd -cogs_usd ELSE NULL END) AS mr_marg,
SUM(CASE WHEN product_id=2 THEN price_usd ELSE NULL END) AS love_rev,
SUM(CASE WHEN product_id=2 THEN price_usd -cogs_usd ELSE NULL END) AS love_marg,
SUM(CASE WHEN product_id=3 THEN price_usd ELSE NULL END) AS birthday_rev,
SUM(CASE WHEN product_id=3 THEN price_usd -cogs_usd ELSE NULL END) AS birthday_marg,
SUM(CASE WHEN product_id=4 THEN price_usd ELSE NULL END) AS mini_rev,
SUM(CASE WHEN product_id=4 THEN price_usd -cogs_usd ELSE NULL END) AS mini_marg,
SUM(price_usd) AS total_revenue,
SUM(price_usd-cogs_usd) AS total_margin
FROM order_items
GROUP BY 1,2
ORDER BY 1,2;


/* 8.6 dive deeper into the impact of introducing new products.
Please pull monthly sessions to the / products page and show how the % of those sessions clicking through another page has changed over time, 
along with a view of how the conversion from /products to placing an order has improved.
*/

CREATE TEMPORARY TABLE product_pageviews
SELECT
website_session_id,
website_pageview_id,
created_at AS saw_product_page_at
FROM website_pageviews
WHERE pageview_url='/products';

SELECT
YEAR(saw_product_page_at) AS yr,
MONTH(saw_product_page_at) AS mo,
COUNT(product_pageviews.website_session_id) AS sessions_to_product_page,
COUNT(website_pageviews.website_session_id) AS clicked_to_next_page,
COUNT(website_pageviews.website_session_id) / COUNT(product_pageviews.website_session_id) AS clickthrough_rt,
COUNT(orders.order_id) AS orders,
COUNT(orders.order_id) / COUNT(product_pageviews.website_session_id) AS products_to_order_rt
FROM product_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=product_pageviews.website_session_id
AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
LEFT JOIN orders
ON orders.website_session_id=product_pageviews.website_session_id
GROUP BY 1,2;


/* 8.7 we made a 4th product available as a primary product on sometime (it was previously only a cross-sell item). 
Could you pull sales data since then, and show how well each products cross-sells from one another?  
*/

CREATE TEMPORARY TABLE primary_products
SELECT
order_id,
primary_product_id,
created_at AS orderede_at
FROM orders
WHERE created_at > '2014-12-05';

SELECT
primary_product_id,
COUNT(order_id) AS total_orders,
COUNT(CASE WHEN cross_sell_product_id=1 THEN order_id ELSE NULL END) AS _xsold_p1,
COUNT(CASE WHEN cross_sell_product_id=2 THEN order_id ELSE NULL END) AS _xsold_p2,
COUNT(CASE WHEN cross_sell_product_id=3 THEN order_id ELSE NULL END) AS _xsold_p3,
COUNT(CASE WHEN cross_sell_product_id=4 THEN order_id ELSE NULL END) AS _xsold_p4,
COUNT(CASE WHEN cross_sell_product_id=1 THEN order_id ELSE NULL END) /
COUNT(order_id) AS p1_xsell_rt,
COUNT(CASE WHEN cross_sell_product_id=2 THEN order_id ELSE NULL END) /
COUNT(order_id)AS p2_xsell_rt,
COUNT(CASE WHEN cross_sell_product_id=3 THEN order_id ELSE NULL END) /
COUNT(order_id)AS p3_xsell_rt,
COUNT(CASE WHEN cross_sell_product_id=4 THEN order_id ELSE NULL END) /
COUNT(order_id)AS p4_xsell_rt
FROM (
SELECT
primary_products.*,
order_items.product_id AS cross_sell_product_id
FROM primary_products
LEFT JOIN order_items
ON order_items.order_id=primary_products.order_id
AND order_items.is_primary_item=0
) AS primary_w_cross_sell
GROUP BY 1;


