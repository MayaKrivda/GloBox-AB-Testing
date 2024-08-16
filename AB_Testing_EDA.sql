
/* GloBox - A/B Testing */
  
-- Handling Missing Values
-- 1. EDA missing values - precentage of missing gender and country
SELECT
    COUNT(*) AS total_records,
	COUNT(CASE WHEN gender != '' THEN 1 END)  AS total_gender,
    COUNT(CASE WHEN country != '' THEN 1 END)  AS total_country,
    COUNT(CASE WHEN gender = '' THEN 1 END) AS missing_gender,
    COUNT(CASE WHEN country = '' THEN 1 END) AS missing_country,
    100 - (COUNT(CASE WHEN gender != '' THEN 1 END) * 100.0 / COUNT(*)) AS missing_gender_perc,
    100 - (COUNT(CASE WHEN country != '' THEN 1 END) * 100.0 / COUNT(*)) AS missing_country_perc
FROM
    main;
    
-- Exploring the behaviour of the gender data distribution across group and country
WITH distribution_gender_data AS (
SELECT 
    gender, 
    `group`,
    country,
	COUNT(*) AS count, 
	ROUND(COUNT(*) / (SELECT COUNT(*) FROM users WHERE gender IS NOT NULL) * 100.0, 2)  AS percentage
FROM 
    main
GROUP BY 
    gender,
    `group`,
    country)
    
SELECT
	*
FROM distribution_gender_data
WHERE gender = ''
ORDER BY country;

SELECT
	DISTINCT join_dt,
    COUNT(CASE WHEN gender ='' THEN 1 ELSE NULL END) AS null_count,
    COUNT(CASE WHEN gender != '' THEN 1 ELSE NULL END) AS non_null_count,
    ROUND(COUNT(CASE WHEN gender ='' THEN 1 ELSE NULL END) / COUNT(CASE WHEN gender != '' THEN 1 ELSE NULL END) * 100, 2) AS prec
FROM MAIN
GROUP BY join_dt
ORDER BY join_dt;
 
-- 2. Chi-Square test for missing gender values
-- Step 1: Count of existing and missing gender values
WITH count_table AS (
    SELECT
        `group`,
        SUM(CASE WHEN gender = '' THEN 1 ELSE 0 END) AS missing_gender,
        SUM(CASE WHEN gender != '' THEN 1 ELSE 0 END) AS non_missing_gender
    FROM
        main
    GROUP BY
        `group`),

-- Step 2: Calculate expected frequencies
expected_frequencies AS (
    SELECT
        `group`,
        missing_gender,
        non_missing_gender,
        (missing_gender + non_missing_gender) * 
        (SELECT SUM(missing_gender) / SUM(missing_gender + non_missing_gender) FROM count_table) AS expected_missing_gender,
        (missing_gender + non_missing_gender) * 
        (SELECT SUM(non_missing_gender) / SUM(missing_gender + non_missing_gender) FROM count_table) AS expected_non_missing_gender
    FROM
        count_table),

-- Step 3: Calculate the chi-square statistic
chi_square_test AS (
    SELECT
        SUM(
            POWER(missing_gender - expected_missing_gender, 2) / expected_missing_gender +
            POWER(non_missing_gender - expected_non_missing_gender, 2) / expected_non_missing_gender
        ) AS chi_square_statistic
    FROM
        expected_frequencies)

-- Step 4: Output the chi-square statistic and the critical value
SELECT
    ROUND(chi_square_statistic, 4) AS chi_sqquare_stat,
    -- Critical value for df = (number of groups - 1) * 1 (2 categories: missing and non-missing)
    CASE
        WHEN chi_square_statistic > 3.841 THEN 'Significant'
        ELSE 'Not Significant'
    END AS significance
FROM
    chi_square_test;
    
/* General info and created supporting tables:
	1. Experiment durtion
    2. MAIN table
    3. Purchase_count table (The number of items purchased break down by assigned group and gender) */

-- 1. Experiment duration
SELECT
    MIN(join_dt) AS first_day,
    MAX(join_dt) AS last_date,
    DATEDIFF(MAX(join_dt), MIN(join_dt)) AS duration_in_days
FROM ab_group;

-- 2. Creating MAIN table with all relevant info
CREATE TABLE MAIN AS(
	SELECT
		users.id,
		users.country,
		users.gender,
		ab_group.group,
		ab_group.join_dt,
		ab_group.device,
        CASE WHEN activity.dt IS NOT NULL THEN 1 ELSE 0 END AS conversion,
		activity.dt AS purchase_time,
		activity.device AS purchased_device,
		activity.spent
	FROM users
		LEFT JOIN ab_group
		ON users.id = ab_group.uid
		LEFT JOIN activity
		ON users.id = activity. uid);
        
-- 3. Distribution of purchase_count by assigned group and gender with count of
-- 	  cooresponding users and purchase sum 
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

/* KPIs:
	1. User Conversion Rate
    2. Average Purchase Amount
    3. User Engagement
*/

-- 1 + 2. User Conversion Rate By Groups + Average Purchase Amount
-- Total Conversion Rate
SELECT
	ROUND(SUM(CASE WHEN purchase_count > 0 THEN total_users ELSE 0 END) / SUM(total_users) * 100, 2) AS total_conv_rate
FROM purchase_count_distribution;  -- 4.28 %

-- A/B group convension rate and the avg purchase per user
SELECT
	`group`,
	 SUM(total_users) AS total_users,
     ROUND(SUM(CASE WHEN purchase_count > 0 THEN total_users ELSE 0 END) / SUM(total_users) * 100.00, 2) AS total_conv_rate,
     ROUND(SUM(total_purchases)/SUM(total_users), 2) AS avg_purchase_per_user
FROM purchase_count_distribution
GROUP BY `group`; -- A: conv_rate 3.92%, avg_purchase 3.37$
				  -- B: conv_rate 4.63%, avg_purchase 3.39$
                  
-- A/B group convension rate and the avg purchase per user - BY GENDER
SELECT
	 gender,
	`group`,
	 SUM(total_users) AS total_users,
     ROUND(SUM(CASE WHEN purchase_count > 0 THEN total_users ELSE 0 END) / SUM(total_users) * 100.00, 2) AS total_conv_rate,
     ROUND(SUM(total_purchases)/SUM(total_users), 2) AS avg_purchase_per_user
FROM purchase_count_distribution
GROUP BY  gender, `group`; /* Group A: F: conv_rate 5.14%, avg_purchase 4.46$
								       M: conv_rate 2.63%, avg_purchase 2.25$
                                       O: conv_rate 3.22%, avg_purchase 2.77$
								
							  Group B: F: conv_rate 5.44%, avg_purchase 4.13$
								       M: conv_rate 3.79%, avg_purchase 2.6$
                                       O: conv_rate 3.02%, avg_purchase 2.77$ */
                  
-- A/B group convension rate and the avg purchase per user - BY COUNTRY
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
-- DROP TABLE country_group_con_rate_and_avg_purch;

/*SELECT
	row_num,
    country,
    `group`,
    total_users,
    total_conv_rate,
    avg_purchase_per_user,
    
FROM country_group_con_rate_and_avg_purch AS c
	JOIN country_group_con_rate_and_avg_purch AS c2
		ON c.row_num = c2.row_num;	*/

change_cal AS (
SELECT
	row_num,
	country,
    total_users - LAG(total_users, 1) OVER (PARTITION BY country ORDER BY country) AS change_users,
	total_conv_rate - LAG(total_conv_rate, 1) OVER (PARTITION BY country ORDER BY country) AS change_conv_rate,
	ROUND(avg_purchase_per_user - LAG(avg_purchase_per_user, 1) OVER (PARTITION BY country ORDER BY country), 2) AS change_purchase
FROM country_group_con_rate_and_avg_purch
WHERE country != ''
)

SELECT
	*
FROM change_cal
WHERE row_num % 2 = 0; /* The subtraction of Group A from Group B yields a value
						  where a positive result indicates a favorable difference
                          for Group B, whereas a negative result signifies a preference
                          for Group A.
                          The results indicate that Turkey experienced the most significant
                          negative impact from the banner, with a decrease in conversion rate
                          of -0.44 and a reduction in average purchase amount by $1.20.
                          Overall, five countries exhibited an increase in average purchases,
                          while five other countries also demonstrated a positive change */

-- 3. User engagement (number of purchased products) - BY GROUP AND GENDER
WITH number_items AS (SELECT
	DISTINCT id,
    `group`,
    gender,
    country,
    device,
    SUM(conversion) AS number_of_items
FROM main
GROUP BY id,
		`group`,
        gender,
        country,
        device)

SELECT
    `group`,
    gender,
    SUM(CASE WHEN number_of_items = 0 THEN 1 ELSE 0 END) AS zero_product,
	SUM(CASE WHEN number_of_items = 1 THEN 1 ELSE 0 END) AS one_product,
	SUM(CASE WHEN number_of_items = 2 THEN 1 ELSE 0 END) AS two_product
FROM number_items
WHERE gender != ''
GROUP BY
	`group`,
	 gender
ORDER BY `group`,
		  gender;
--  Remove ,gender; in the group by for total user engagement
                    /* Group A: 0: 20123  1: 757  2: 51
					   Group B: 0: 20196, 1: 900, 2: 61 */
	    /*BY GENDER    Group A: F: 0: 9551  1: 483  2: 35
					  		    M: 0: 9790  1: 249  2: 15
							    O: 0: 782   1: 25   2: 1
                       Group B: F: 0: 9514  1: 512  2: 35
							    M: 0: 9847  1: 365  2: 23
							    O: 0: 835   1: 23   2: 3 */

/* Tests:
	1. T-test for avgerage spent
    2. Z-Test for conversion rate */

-- 1. T-test
-- Gathering nessecery info
WITH MAIN_short AS(
SELECT
	DISTINCT id,
    gender,
    `group`,
    SUM(spent) AS spent
FROM MAIN
GROUP BY id,
         gender,
         `group`),
         
-- Calculate means and standard deviations         
stats AS (
    SELECT `group`,
           AVG(COALESCE(spent, 0)) AS mean_purchase,
           STDDEV(COALESCE(spent, 0)) AS stddev_purchase,
           COUNT(DISTINCT id) AS n
    FROM MAIN_short
    GROUP BY `group`),

stat_ab AS (
	SELECT
		ROUND(a.mean_purchase, 2) AS mean_a,
		ROUND(b.mean_purchase, 2) AS mean_b,
		ROUND(a.stddev_purchase, 2) AS stddev_a,
		ROUND(b.stddev_purchase, 2) AS stddev_b,
		a.n AS n_a,
		b.n AS n_b,
		a.n + b.n - 2 AS degree_of_freedom,
		ROUND((a.mean_purchase - b.mean_purchase) / 
			SQRT((POW(a.stddev_purchase, 2) / a.n) + (POW(b.stddev_purchase, 2) / b.n)), 3) AS t_stat
	FROM stats a
		JOIN stats b
			ON a.`group` = 'A' AND b.`group` = 'B')
	
SELECT
    t_stat,
CASE
	WHEN ABS(t_stat) > 1.96 THEN 'Reject H0'
	ELSE 'Fail to Reject H0'
END AS decision
FROM
	stat_ab;   /* t_stat = -0.070
				  degree_of_freedom (df) = 48941
				  critical value for wwo-tailed test: ± 1.96
                  |-0.070| < 1.96 --> can't reject the null hypothesis H0 */
                  
				
-- 2. Z-Test 
WITH MAIN_short AS(
SELECT
	DISTINCT id,
    `group`,
    SUM(conversion) AS conversion
FROM MAIN
GROUP BY id,
         `group`),
         
conversion_rates AS (
    SELECT
        `group`,
        COUNT(id) AS total_users,
        SUM(conversion) AS conversions,
        AVG(conversion) AS conversion_rate
    FROM
        MAIN_short
    GROUP BY
        `group`),
        
z_test AS (
    SELECT
        (cr1.conversion_rate - cr2.conversion_rate) /
        SQRT((cr1.conversion_rate * (1 - cr1.conversion_rate) / cr1.total_users) +
             (cr2.conversion_rate * (1 - cr2.conversion_rate) / cr2.total_users)) AS z_stat
    FROM
        conversion_rates cr1
    CROSS JOIN
        conversion_rates cr2
    WHERE
        cr1.`group` = 'A' AND cr2.`group` = 'B')

SELECT
    ROUND(z_stat, 2) AS z_stat,
    CASE
        WHEN ABS(z_stat) > 1.96 THEN 'Reject H0'
        ELSE 'Fail to Reject H0'
    END AS decision
FROM
    z_test;  /* z_stat = -4.19
				The null hypothesis H0 is rejected, indicating a significant
                difference in conversion rates */

