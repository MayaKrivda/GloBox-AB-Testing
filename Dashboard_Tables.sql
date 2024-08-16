
/* Code for Tableau tables (Main + Geo)*/

-- Main
WITH purchase_rank AS (
    SELECT
        uid,
        dt,
        ROW_NUMBER() OVER (PARTITION BY uid ORDER BY dt) AS num_purchase,
        device,
        spent
    FROM activity
),

no_dups AS (
	SELECT
		uid,
		MAX(CASE WHEN num_purchase = 1 THEN dt END) AS first_purch,
		MAX(CASE WHEN num_purchase = 2 THEN dt ELSE 0 END) AS second_purch,
		MAX(CASE WHEN num_purchase = 1 THEN spent END) AS first_spent,
		MAX(CASE WHEN num_purchase = 2 THEN spent ELSE 0 END) AS second_spent,
		MAX(device) AS device -- Assuming device is the same for both purchases or you want to show one of them
	FROM
		purchase_rank
	GROUP BY
		uid)
        
SELECT
	u.id,
    u.country,
    u.gender,
    ab.`group`,
    ab.join_dt,
    ab.device,
	COALESCE(n.first_purch, 0) AS first_purch,
    COALESCE(n.second_purch, 0) AS second_purch,
	COALESCE(n.first_spent, 0) AS first_spent,
	COALESCE(n.second_spent, 0) AS second_spent,
    CASE WHEN n.first_purch != 0 AND n.second_purch != 0 THEN 2
		WHEN  n.first_purch != 0 AND n.second_purch = 0 THEN 1
        ELSE 0 END
	AS purch_item
FROM users AS u
	LEFT JOIN ab_group AS ab
		ON u.id = ab.uid
	LEFT JOIN no_dups AS n
		ON u.id = n.uid;

        
-- Geographics
CREATE TABLE purchase_count_distribution AS (
	SELECT 
		purchase_count,
		`group`,
        gender,
        country,
		COUNT(DISTINCT id) AS total_users,
		ROUND(SUM(total_spent), 2) AS total_purchases
	FROM (
		SELECT 
			DISTINCT id,
			`group`,
            gender,
            country,
			SUM(CASE WHEN spent IS NOT NULL THEN spent ELSE 0 END) AS total_spent,
			COUNT(purchase_time) AS purchase_count
		FROM MAIN
		GROUP BY id, `group`, gender, country
	) AS purchase_summary
	GROUP BY purchase_count, `group`, gender, country
	ORDER BY purchase_count);
    
WITH country_group_con_rate_and_avg_purch AS (
SELECT
	 ROW_NUMBER() OVER (ORDER BY country) AS row_num,
	 country,
	`group`,
	 SUM(total_users) AS total_users,
     ROUND(SUM(CASE WHEN purchase_count > 0 THEN total_users ELSE 0 END) / SUM(total_users) * 100.00, 2) AS total_conv_rate,
     ROUND(SUM(total_purchases)/SUM(total_users), 2) AS avg_purchase_per_user
FROM purchase_count_distribution
WHERE gender = 'F' OR gender = 'M' OR gender = 'O'
GROUP BY country, `group`
ORDER BY country, `group`),

change_cal AS (
SELECT
	row_num,
	country,
	total_conv_rate - LAG(total_conv_rate, 1) OVER (PARTITION BY country ORDER BY country) AS change_conv_rate,
	ROUND(avg_purchase_per_user - LAG(avg_purchase_per_user, 1) OVER (PARTITION BY country ORDER BY country), 2) AS change_purchase
FROM country_group_con_rate_and_avg_purch
WHERE country != ''
)

SELECT
	country,
    change_conv_rate,
    change_purchase
FROM change_cal
WHERE row_num % 2 = 0;
    