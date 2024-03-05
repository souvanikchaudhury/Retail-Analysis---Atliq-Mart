ALTER TABLE fact_events
CHANGE `quantity_sold(before_promo)` quantity_sold_before_promo INT;
ALTER TABLE fact_events
CHANGE `quantity_sold(after_promo)` quantity_sold_after_promo INT;
SELECT * FROM retail_events_db.fact_events;

#1.  Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free).
#This information will help us identify high-value products that are currently being heavily discounted, which can be useful for evaluating 
#our pricing and promotion strategies.

SELECT 
    p.product_code,
	p.product_name,
    f.base_price,
    f.promo_type
FROM 
    dim_products as p
Join fact_events as f on f.product_code = p.product_code
WHERE 
    base_price > 500
    AND promo_type = 'BOGOF';
    
#2.  Generate a report that provides an overview of the number of stores in each city. 
#The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence.
#The report includes two essential fields: city and store count, which will assist in optimizing our retail operations.    
    
SELECT city, COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

#3.  Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
#The report includes three key fields: campaign_name, totaI_revenue(before_promotion), totaI_revenue(after_promotion). 
#This report should help in evaluating the financial impact of our promotional campaigns. (Display the values in millions)

WITH CampaignRevenueCTE AS (
    SELECT 
        c.campaign_name,
        fe.base_price * fe.quantity_sold_before_promo AS revenue_before_promo,
        fe.base_price * fe.quantity_sold_after_promo AS revenue_after_promo
    FROM dim_campaigns c
    JOIN fact_events fe 
    ON c.campaign_id = fe.campaign_id
)

SELECT 
    campaign_name,
    SUM(revenue_before_promo) / 1000000 AS total_revenue_before_promotion,
    SUM(revenue_after_promo) / 1000000 AS total_revenue_after_promotion
FROM CampaignRevenueCTE
GROUP BY campaign_name;

#.4.Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
#Additionally, provide rankings for the categories based on their ISU%. 
#The report will include three key fields: category, isu%, and rank order. 
#This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales

WITH DiwaliCategoryMetrics AS (
    SELECT 
        dp.category,
        SUM(fe.quantity_sold_after_promo - fe.quantity_sold_before_promo) AS incremental_sold_quantity,
        SUM(fe.quantity_sold_before_promo) AS baseline_sold_quantity
    FROM dim_campaigns dc
    JOIN fact_events fe ON dc.campaign_id = fe.campaign_id
    JOIN dim_products dp ON fe.product_code = dp.product_code
    WHERE dc.campaign_name = 'Diwali'
    GROUP BY dp.category
)

SELECT 
    category,
    COALESCE(
        (CAST(incremental_sold_quantity AS DECIMAL(10, 2)) / NULLIF(baseline_sold_quantity, 0)) * 100, 
        0
    ) AS isu_percentage,
    RANK() OVER (ORDER BY (CAST(incremental_sold_quantity AS DECIMAL(10, 2)) / NULLIF(baseline_sold_quantity, 0)) DESC) AS rank_order
FROM DiwaliCategoryMetrics
ORDER BY rank_order;



#5.  Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
#The report will provide essential information including product name, category, and ir%.
#This analysis helps identify the most successful products in terms of incremental revenue across our campaigns, assisting in product optimization.

SELECT 
    dp.product_name,
    dp.category,
    COALESCE(
        (SUM(fe.base_price * fe.quantity_sold_after_promo) - SUM(fe.base_price * fe.quantity_sold_before_promo)) /
        NULLIF(SUM(fe.base_price * fe.quantity_sold_before_promo), 0) * 100,
        0
    ) AS ir_percentage
FROM dim_products dp
JOIN fact_events fe ON dp.product_code = fe.product_code
GROUP BY dp.product_name, dp.category
ORDER BY ir_percentage DESC
LIMIT 5;










