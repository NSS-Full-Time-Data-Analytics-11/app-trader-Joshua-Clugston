-- 1.
SELECT *
FROM app_store_apps
ORDER BY size_bytes DESC;

SELECT *
FROM play_store_apps;



-- 2. Assumptions Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase the rights to apps for 10,000 times the list price of the app on the Apple App Store/Google Play 
-- Store, however the minimum price to purchase the rights to an app is $25,000. For example, a $3 app would cost $30,000 
-- (10,000 x the price) and a free app would cost $25,000 (The minimum price). NO APP WILL EVER COST LESS THEN $25,000 TO PURCHASE.

-- b. Apps earn $5000 per month on average from in-app advertising and in-app purchases regardless of the price of the app.

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader
-- owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.

-- d. For every quarter-point that an app gains in rating, its projected lifespan increases by 6 months, in other words, an app 
-- with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and 
-- an app with a rating of 4.0 can be expected to last 9 years. Ratings should be rounded to the nearest 0.25 to evaluate an 
-- app's likely longevity.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market 
-- both for the same $1000 per month.






-- 3. Deliverables 

-- a. Develop some general recommendations about the price range, genre, content rating, or any other app characteristics that 
-- the company should target.

WITH all_apps_data AS (
	SELECT name, rating, review_count, price::money, category, 		   
			CASE WHEN content_rating LIKE '%17%' THEN '17+'
		 		 ELSE content_rating END AS content_rating,
		  size, 'Android' AS store
	FROM play_store_apps
	UNION
	SELECT name, rating, review_count::numeric, price::money, UPPER(primary_genre) AS category, content_rating, 
		   CASE WHEN size_bytes::numeric >= 1000000 THEN ROUND(size_bytes::numeric / 1000000,0)::text ||'M'
			 	WHEN size_bytes::numeric >- 1000	THEN ROUND(size_bytes::numeric / 1000   ,0)::text ||'k'
				ELSE size_bytes END AS size, 
		   'Apple' AS store
	FROM app_store_apps
	ORDER BY name),

distinct_apps AS (
	SELECT name, ROUND(AVG(rating),2) AS avg_rating, AVG(review_count)::INT AS avg_reviews, AVG(price::numeric)::money AS price
	FROM all_apps_data
	GROUP BY name),

distinct_apps_data AS (
	SELECT name, MIN(avg_rating) AS avg_rating, MIN(avg_reviews) AS avg_reviews, MIN(price) AS price, 
		   MIN(category) AS category, MIN(content_rating) AS content_rating, MIN(size) AS size
	FROM distinct_apps LEFT JOIN all_apps_data USING(name, price)
	GROUP BY name)

SELECT category, ROUND(AVG(avg_rating),2) AS avg_rating, SUM(avg_reviews) AS review_count, COUNT(name) AS num_of_apps
FROM distinct_apps_data
WHERE category IS NOT NULL
GROUP BY category
HAVING COUNT(name) > 50
ORDER BY avg_rating DESC;

-- b. Develop a Top 10 List of the apps that App Trader should buy based on profitability/return on investment as the sole priority.
/*
WITH all_apps AS (
	SELECT name, rating, review_count, price::money, category, content_rating, size, 'Android' AS store
	FROM play_store_apps
	UNION
	SELECT name, rating, review_count::numeric, price::money, primary_genre AS category, 
		   content_rating, size_bytes AS size, 'Apple' AS store
	FROM app_store_apps
	ORDER BY name),
	
both_stores AS (
	SELECT name
	FROM play_store_apps INNER JOIN app_store_apps USING (name)
	GROUP BY name
	ORDER BY name)

SELECT name, ROUND(AVG(rating)/25,2)*25 AS rounded_rating, AVG(review_count)::INT AS avg_review_count, AVG(price::numeric)::money AS price
FROM all_apps INNER JOIN both_stores USING (name)
WHERE price <= '$2.50'
GROUP BY name
ORDER BY rounded_rating DESC NULLS LAST, avg_review_count DESC
LIMIT 10;

-- The reason I have ordered everything like this is because of the following:
-- 1) Rating is the clearest indicator of longevity. As such, higher reviews scores translate to more money in the long run.
-- 2) Review counts are next because it confirms that several people enjoy the app. If you have a million reviews rating an app
--		at 5 stars versus 1 review rating an app at 5 stars, it becomes more obvious why review count is important.
-- 3) The price of each app is no more than $2.50 because this means that each app will cost the minimum price for payment.
--		While there may be other great apps that cost more, this list contains the best for a lower down payment.
-- 4) All of the apps on this list appear in both stores, meaning that marketing costs are also reduced.

*/


-- c. Develop a Top 4 list of the apps that App Trader should buy that are profitable but that also are thematically appropriate 
-- for the upcoming Halloween themed campaign.

-- c. Submit a report based on your findings. The report should include both of your lists of apps along with your analysis of 
-- their cost and potential profits. All analysis work must be done using PostgreSQL, however you may export query results to 
-- create charts in Excel for your report.




