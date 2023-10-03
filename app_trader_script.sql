-- 1.
SELECT *
FROM app_store_apps;

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

-- ***The reason I have ordered most things in the order of rating and then review count is because of the following:
-- 1) Rating is the clearest indicator of longevity. As such, higher reviews scores translate to more money in the long run.
-- 2) Review counts are next because it confirms that several people enjoy the app. If you have a million reviews rating an app
--		at 5 stars versus 1 review rating an app at 5 stars, it becomes more obvious why review count is important. ***


-- a. Develop some general recommendations about the price range, genre, content rating, or any other app characteristics that 
-- the company should target.

WITH size_in_bytes AS (
	SELECT name,
		   CASE WHEN size LIKE '%M' THEN TRIM('M' FROM size)
				WHEN size LIKE '%k' THEN TRIM('k' FROM size)
				ELSE '-1' END AS size_bytes
	FROM play_store_apps),

all_apps_data AS (
	SELECT name, rating, review_count, price::money, 
		   CASE WHEN category = 'REFERENCE' THEN 'BOOKS AND REFERENCE'
				ELSE category END AS category,
		   CASE WHEN content_rating LIKE '%17%' THEN '17+'
		 		ELSE content_rating END AS content_rating,
		   size, 
		   CASE WHEN size LIKE '%G' THEN ROUND(size_bytes::numeric*1000000000,0)
				WHEN size LIKE '%M' THEN ROUND(size_bytes::numeric*1000000   ,0)
				WHEN size LIKE '%k' THEN ROUND(size_bytes::numeric*1000      ,0)
				ELSE size_bytes::numeric END AS size_bytes,
		   'Android' AS store
	FROM play_store_apps INNER JOIN size_in_bytes USING (name)
	UNION
	SELECT name, rating, review_count::numeric, price::money, 
		   CASE WHEN primary_genre = 'Book' OR primary_genre = 'Reference' THEN 'BOOKS_AND_REFERENCE'
				WHEN primary_genre = 'Food & Drink' THEN 'FOOD_AND_DRINK'
				WHEN primary_genre = 'Games' THEN 'GAME'
				WHEN primary_genre = 'Health & Fitness' THEN 'HEALTH_AND_FITNESS'
				WHEN primary_genre = 'Navigation' THEN 'MAPS_AND_NAVIGATION'
				WHEN primary_genre = 'News' THEN 'NEWS_AND_MAGAZINES'
				WHEN primary_genre = 'Photo & Video' THEN 'PHOTOGRAPHY'
				WHEN primary_genre = 'Social Networking' THEN 'SOCIAL'
				WHEN primary_genre = 'Travel' THEN 'TRAVEL_AND_LOCAL'
				ELSE UPPER(primary_genre) END AS category, 
		   content_rating, 
		   CASE WHEN size_bytes::numeric >= 1000000 THEN ROUND(size_bytes::numeric / 1000000,0)::text ||'M'
			 	WHEN size_bytes::numeric >- 1000	THEN ROUND(size_bytes::numeric / 1000   ,0)::text ||'k'
				ELSE size_bytes END AS size, 
		   size_bytes::numeric,
		   'Apple' AS store
	FROM app_store_apps
	ORDER BY name),

distinct_apps AS (
	SELECT name, ROUND(AVG(rating),2) AS avg_rating, AVG(review_count)::INT AS avg_reviews, AVG(price::numeric)::money AS price
	FROM all_apps_data
	GROUP BY name),

distinct_apps_data AS (
	SELECT name, 
		   MIN(avg_rating) AS avg_rating, 
		   MIN(avg_reviews) AS avg_reviews,
		   MIN(price) AS price, 
		   MAX(category) AS category, 
		   MIN(content_rating) AS content_rating, 
		   MIN(size) AS size, MAX(size_bytes) AS size_bytes,
		   CASE WHEN name IN (SELECT name FROM app_store_apps) AND name IN (SELECT name FROM play_store_apps) THEN 'Both'
				ELSE MIN(store) END AS store
	FROM distinct_apps LEFT JOIN all_apps_data USING(name, price)
	GROUP BY name)

/*
SELECT category, COUNT(name) AS num_of_apps, ROUND(AVG(avg_rating/25),2)*25 AS avg_rating, AVG(avg_reviews)::INT AS avg_reviews
FROM distinct_apps_data
WHERE category IS NOT NULL
GROUP BY category
ORDER BY avg_rating DESC, avg_reviews DESC;


SELECT size_range, COUNT(name), ROUND(AVG(avg_rating)/25,2)*25 AS avg_rating
FROM (SELECT name, size, avg_rating,
	   CASE WHEN size_bytes >= 1000000000 THEN 'Very Large'
	   		WHEN size_bytes >= 100000000  THEN 'Large'
			WHEN size_bytes >= 10000000   THEN 'Large-Medium'
			WHEN size_bytes >= 1000000    THEN 'Medium'
	  		WHEN size_bytes >= 100000     THEN 'Small-Medium'
	  		WHEN size_bytes >= 10000      THEN 'Small'
	  		WHEN size_bytes >= 1000       THEN 'Very Small'
			WHEN size_bytes >= 1          THEN 'How did you even make this app?'
			ELSE 'Varies/Unknown' END AS size_range
	  FROM distinct_apps_data
	 ) AS size_range
GROUP BY size_range
ORDER BY avg_rating DESC;


SELECT content_rating, ROUND(AVG(avg_rating)/25,2)*25 AS avg_rating, 
	   AVG(avg_reviews)::INT AS review_count, COUNT(name) AS tot_apps,
	   (AVG(avg_reviews)/ COUNT(name))::INT AS review_per_app
FROM distinct_apps_data
GROUP BY content_rating
HAVING COUNT(name) > 100
ORDER BY avg_rating DESC, review_per_app DESC;
*/

-- The CTEs in this are fairly convoluted, but a lot of is cleaning and organzing data so that everything is normalized
-- and condensed as much as possible (especially with the case statement for category haha).

-- From this, however, I was able to determine that the 'Events' category is the highest rated on average, followed by 
-- 'Personalization' and 'Family'. These are the categories that I would recommend to App Trader.

-- With the next query, I looked at app size to see if there was a correlation between the size and rating. I do NOT believe
-- there is one. All the sizes score either 3.75 or 4.00 if they're known while unknown only scores a 4.25... with the exception
-- of the 'Very Small' category. There is exactly one app small enough to be in this category, so I have decided to leave it out
-- of analysis.

-- The third query is rating based on content rating. Now, there are two different kinds of ratings being reported: 
-- There is the ESRB rating system of E, E10, T, M, and AO as well as the App Store's unique rating of
-- 4+, 9+, 12+, and 17+. I removed AO from the list because there are only 3 apps (not enought to make conclusive claims) and there
-- are no M ratings. However, there is still a trend: E10 and 9+ are the top of their respective systems, followed by T and 12+,
-- then by E and 4+. However, the ESRB ratings are all above the App store's rating, so I would encourage App Trader to invest
-- in apps rated by the ESRB (that is, ratings of E, E10, T, M, and AO), then followed by the priority of E10 and Teen since
-- they generally score better.
-- With this in mind, it can be interpreted that the Play Store may have better rated games than the App Store.
-- I've used the followed to investigate that:

SELECT AVG(rating)
FROM app_store_apps;

SELECT AVG(rating)
FROM play_store_apps;

-- Play Store typically score higher than the App Store by the average, so seeing that the ESRB rating score higher makes sense
-- because the Play Store uses ESRB ratings while the App Store doesn't.







-- b. Develop a Top 10 List of the apps that App Trader should buy based on profitability/return on investment as the sole priority.

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
	GROUP BY name)

SELECT name, ROUND(AVG(rating)/25,2)*25 AS rounded_rating, AVG(review_count)::INT AS avg_review_count, AVG(price::numeric)::money AS price
FROM all_apps INNER JOIN both_stores USING (name)
WHERE price <= '$2.50'
GROUP BY name
ORDER BY rounded_rating DESC NULLS LAST, avg_review_count DESC
LIMIT 10;

-- *** The price of each app is no more than $2.50 because this means that each app will cost the minimum price for payment.
--			While there may be other great apps that cost more, this list contains the best for a lower down payment.
--	   All of the apps on this list appear in both stores, meaning that marketing costs are optimized. ***




-- c. Develop a Top 4 list of the apps that App Trader should buy that are profitable but that also are thematically appropriate 
-- for the upcoming Halloween themed campaign.

WITH size_in_bytes AS (
	SELECT name,
		   CASE WHEN size LIKE '%M' THEN TRIM('M' FROM size)
				WHEN size LIKE '%k' THEN TRIM('k' FROM size)
				ELSE '-1' END AS size_bytes
	FROM play_store_apps),

all_apps_data AS (
	SELECT name, rating, review_count, price::money, 
		   CASE WHEN category = 'REFERENCE' THEN 'BOOKS AND REFERENCE'
				ELSE category END AS category,
		   CASE WHEN content_rating LIKE '%17%' THEN '17+'
		 		ELSE content_rating END AS content_rating,
		   size, 
		   CASE WHEN size LIKE '%G' THEN ROUND(size_bytes::numeric*1000000000,0)
				WHEN size LIKE '%M' THEN ROUND(size_bytes::numeric*1000000   ,0)
				WHEN size LIKE '%k' THEN ROUND(size_bytes::numeric*1000      ,0)
				ELSE size_bytes::numeric END AS size_bytes,
		   'Android' AS store
	FROM play_store_apps INNER JOIN size_in_bytes USING (name)
	UNION
	SELECT name, rating, review_count::numeric, price::money, 
		   CASE WHEN primary_genre = 'Book' OR primary_genre = 'Reference' THEN 'BOOKS_AND_REFERENCE'
				WHEN primary_genre = 'Food & Drink' THEN 'FOOD_AND_DRINK'
				WHEN primary_genre = 'Games' THEN 'GAME'
				WHEN primary_genre = 'Health & Fitness' THEN 'HEALTH_AND_FITNESS'
				WHEN primary_genre = 'Navigation' THEN 'MAPS_AND_NAVIGATION'
				WHEN primary_genre = 'News' THEN 'NEWS_AND_MAGAZINES'
				WHEN primary_genre = 'Photo & Video' THEN 'PHOTOGRAPHY'
				WHEN primary_genre = 'Social Networking' THEN 'SOCIAL'
				WHEN primary_genre = 'Travel' THEN 'TRAVEL_AND_LOCAL'
				ELSE UPPER(primary_genre) END AS category, 
		   content_rating, 
		   CASE WHEN size_bytes::numeric >= 1000000 THEN ROUND(size_bytes::numeric / 1000000,0)::text ||'M'
			 	WHEN size_bytes::numeric >- 1000	THEN ROUND(size_bytes::numeric / 1000   ,0)::text ||'k'
				ELSE size_bytes END AS size, 
		   size_bytes::numeric,
		   'Apple' AS store
	FROM app_store_apps
	ORDER BY name),

distinct_apps AS (
	SELECT name, ROUND(AVG(rating),2) AS avg_rating, AVG(review_count)::INT AS avg_reviews, AVG(price::numeric)::money AS price
	FROM all_apps_data
	GROUP BY name),

distinct_apps_data AS (
	SELECT name, 
		   MIN(avg_rating) AS avg_rating, 
		   MIN(avg_reviews) AS avg_reviews,
		   MIN(price) AS price, 
		   MAX(category) AS category, 
		   MIN(content_rating) AS content_rating, 
		   MIN(size) AS size, MAX(size_bytes) AS size_bytes,
		   CASE WHEN name IN (SELECT name FROM app_store_apps) AND name IN (SELECT name FROM play_store_apps) THEN 'Both'
				ELSE MIN(store) END AS store
	FROM distinct_apps LEFT JOIN all_apps_data USING(name, price)
	GROUP BY name)
	

SELECT *
FROM distinct_apps_data
WHERE (name ILIKE '%halloween%' OR name ILIKE '%ghost%' OR name ILIKE '%pumpkin%') AND avg_reviews > 100
ORDER BY avg_rating DESC, avg_reviews DESC
LIMIT 4;




-- c. Submit a report based on your findings. The report should include both of your lists of apps along with your analysis of 
-- their cost and potential profits. All analysis work must be done using PostgreSQL, however you may export query results to 
-- create charts in Excel for your report.

