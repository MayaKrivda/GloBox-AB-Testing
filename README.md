# GloBox A/B Testing Analysis

## Project Overview

This project focuses on analyzing the impact of a promotional banner on user conversion rates and overall engagement within the food and drink category for GloBox, an e-commerce platform. The primary objective of the A/B test was to determine whether the banner increased user awareness and revenue. The analysis was conducted using SQL and Tableau, with extensive Exploratory Data Analysis (EDA) to ensure data quality and accurate insights.

## Repository Contents

This repository contains the following files and resources:

1. **SQL Code for EDA and A/B Testing:**
   - `EDA_AB_Testing.sql`: SQL scripts used to perform Exploratory Data Analysis (EDA) and A/B testing on the dataset. This script includes data cleaning, transformations, and statistical tests (T-test and Z-test) used in the analysis.

2. **Tableau Dashboard:**
   - `dashboard.twbx`: Tableau workbook containing the dashboard used to visualize the results of the A/B test. The dashboard provides interactive insights into key metrics such as conversion rates, average purchase amounts, and user engagement across different user segments.

3. **SQL Code for Dashboard Tables:**
   - `dashboard_tables.sql`: SQL script used to generate the tables that were subsequently imported into Tableau for visualization. This script includes the creation of aggregated views used to drive the dashboard’s insights.

4. **Original Data Files:**
   - `users.csv`: Contains user demographics, including unique user IDs, country codes, and gender.
   - `groups.csv`: Details the A/B test group assignments, including user IDs, group designations (Control or Treatment), join dates, and device types.
   - `activity.csv`: Captures user purchasing activity, including purchase dates, devices used, and amounts spent.

## Key Insights

1. **Overall Impact of the Banner:**
   - The promotional banner led to an increase in conversion rates but did not significantly boost the average purchase amount. In some regions, particularly Turkey, the banner had a negative impact on women's spending, with the average purchase value for women dropping from **$4.46** to **$4.13**.

2. **Device-Specific Performance:**
   - iOS users showed higher responsiveness to the banner in terms of both conversion rates and average spending. However, Android users did not respond as positively, indicating a need for device-specific optimizations.

3. **Gender-Based Insights:**
   - Women were generally more likely to make purchases across all devices, but in the Treatment group, their average spend decreased after exposure to the banner compared to the Control group, highlighting potential issues with the banner's effectiveness.

4. **Geographical Variations:**
   - 50% of the top 10 countries showed a decrease in average purchase value, with no consistent pattern by region, suggesting that the banner’s impact varied significantly across different markets.

## How to Use

1. **Run the SQL Scripts:**
   - Execute `EDA_AB_Testing.sql` to perform the initial EDA and A/B test analysis.
   - Use `Dashboard_Tables.sql` to create the necessary tables for the Tableau dashboard.

2. **Explore the Tableau Dashboard:**
   - Open `dashboard.twbx` in Tableau to interact with the visualized results.

3. **Data Files:**
   - The `users.csv`, `groups.csv`, and `activity.csv` files contain the raw data used for this analysis. These can be used to replicate the analysis or to perform further investigations.

## Conclusion

The findings from this project provide actionable insights into the effectiveness of the promotional banner, with specific recommendations for device-specific optimizations, gender-based targeting, and localized marketing strategies. The provided SQL scripts and Tableau dashboard offer a comprehensive view of the analysis and can be adapted for similar projects.

## Author
**Maya Krivda**  

