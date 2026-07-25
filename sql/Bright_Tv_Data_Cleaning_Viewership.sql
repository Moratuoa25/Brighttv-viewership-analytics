-- ============================================================
-- BRIGHT TV DATA ANALYTICS PROJECT
-- Data Cleaning and Feature Engineering
-- ============================================================
--
-- Purpose:
-- This query combines user profile data with viewership data
-- and creates a clean analytical dataset for dashboarding
-- and business analysis.
--
-- Main transformations:
-- 1. Clean Province values
-- 2. Create Age Groups
-- 3. Create Email and Social Media flags
-- 4. Clean Race and Gender
-- 5. Combine User IDs from viewership data
-- 6. Create date and time features
-- 7. Calculate viewing duration in minutes
-- 8. Create viewing duration buckets
-- 9. Classify weekdays vs weekends
-- 10. Standardise TV channel names
-- 11. Join user profile and viewership data
--
-- Output Table:
-- workspace.default.bright_tv_dataset_clean
--
-- ============================================================


CREATE OR REPLACE TABLE `workspace`.`default`.`bright_tv_dataset_clean` AS

WITH User_profile AS (

    -- =========================================
    -- 1. CLEAN USER PROFILE DATA
    -- =========================================

    SELECT
        UserID,

        -- Clean Province
        CASE
            WHEN Province IS NULL THEN 'Uncategorized'
            WHEN Province = ' ' THEN 'Uncategorized'
            WHEN Province = 'None' THEN 'Uncategorized'
            ELSE Province
        END AS Province,

        -- Create Age Groups
        CASE 
            WHEN TRY_CAST(Age AS BIGINT) = 0 THEN 'Infants'
            WHEN TRY_CAST(Age AS BIGINT) BETWEEN 1 AND 12 THEN 'Kids'
            WHEN TRY_CAST(Age AS BIGINT) BETWEEN 13 AND 19 THEN 'Teens'
            WHEN TRY_CAST(Age AS BIGINT) BETWEEN 20 AND 35 THEN 'Young'
            WHEN TRY_CAST(Age AS BIGINT) BETWEEN 36 AND 50 THEN 'Adults'
            WHEN TRY_CAST(Age AS BIGINT) BETWEEN 51 AND 65 THEN 'Elder'
            WHEN TRY_CAST(Age AS BIGINT) > 65 THEN 'Senior'
            ELSE 'Unknown'
        END AS Age_group,

        -- Create Email Availability Flag
        CASE
            WHEN Email IS NOT NULL
                 AND TRIM(Email) != ''
                 AND Email != 'None'
            THEN 1
            ELSE 0
        END AS email_flag,

        -- Create Social Media Availability Flag
        CASE 
            WHEN `Social Media Handle` IS NOT NULL
                 AND TRIM(`Social Media Handle`) != ''
                 AND `Social Media Handle` != 'None'
            THEN 1
            ELSE 0
        END AS sm_flag,

        -- Clean Race
        CASE
            WHEN Race IS NULL THEN 'None'
            WHEN Race = 'other' THEN 'None'
            WHEN Race = ' ' THEN 'None'
            ELSE Race
        END AS Race,

        -- Clean Gender
        CASE
            WHEN Gender IS NULL THEN 'None'
            WHEN Gender = ' ' THEN 'None'
            ELSE Gender
        END AS Gender

    FROM `workspace`.`default`.`bright_tv_user_profile`
),


clean_viewership AS (

    -- =========================================
    -- 2. CLEAN VIEWERSHIP DATA
    -- =========================================

    SELECT
        COALESCE(UserID0, UserID4) AS userid,
        Channel2,
        RecordDate2,
        `Duration 2`

    FROM `workspace`.`default`.`Bright_tv_dataset_viewership`
),


date_feature AS (

    -- =========================================
    -- 3. CREATE DATE AND TIME FEATURES
    -- =========================================

    SELECT
        *,

        YEAR(RecordDate2) AS year,
        MONTH(RecordDate2) AS month,
        DAY(RecordDate2) AS day,

        DAYNAME(RecordDate2) AS day_name,

        DATE_FORMAT(RecordDate2, 'HH:mm:ss') AS watch_time,

        DATE_FORMAT(`Duration 2`, 'HH:mm:ss') AS duration,


        -- Extract Hour of Day
        CASE
            WHEN RecordDate2 IS NULL
                 OR HOUR(RecordDate2) IS NULL
            THEN 'Unknown'
            ELSE CAST(HOUR(RecordDate2) AS STRING)
        END AS hour_of_day,


        -- Create Month Name
        CASE
            WHEN RecordDate2 IS NULL THEN 'Unknown'
            ELSE DATE_FORMAT(RecordDate2, 'MMM')
        END AS month_name,


        -- Convert Viewing Duration to Minutes
        CAST(SPLIT(DATE_FORMAT(`Duration 2`, 'HH:mm:ss'), ':')[0] AS INT) * 60 
        + CAST(SPLIT(DATE_FORMAT(`Duration 2`, 'HH:mm:ss'), ':')[1] AS INT) 
        + CAST(SPLIT(DATE_FORMAT(`Duration 2`, 'HH:mm:ss'), ':')[2] AS INT) / 60.0 
        AS duration_minutes,


        -- Create Duration Buckets
        CASE
            WHEN DATE_FORMAT(`Duration 2`, 'HH:mm:ss')
                 BETWEEN '00:00:00' AND '00:30:00'
                THEN '0-30 min'

            WHEN DATE_FORMAT(`Duration 2`, 'HH:mm:ss')
                 BETWEEN '00:30:01' AND '01:00:00'
                THEN '31-60 min'

            WHEN DATE_FORMAT(`Duration 2`, 'HH:mm:ss')
                 BETWEEN '01:00:01' AND '02:00:00'
                THEN '61-120 min'

            ELSE '120+ min'
        END AS duration_bucket

    FROM clean_viewership
),


channel_feature AS (

    -- =========================================
    -- 4. STANDARDISE CHANNEL NAMES
    -- =========================================

    SELECT
        *,

        -- Classify Weekdays and Weekends
        CASE
            WHEN LOWER(day_name) IN ('sat', 'sun')
                THEN 'weekend'
            ELSE 'weekday'
        END AS day_classification,


        -- Standardise TV Channel Names
        CASE
            WHEN Channel2 IN ('SawSee', 'Sawsee')
                THEN 'SawSee'

            WHEN Channel2 IN (
                'SuperSport Live Events',
                'Live on SuperSport',
                'Supersport Live Events',
                'DStv Events 1'
            )
                THEN 'Live Events'

            ELSE Channel2
        END AS Tv_channel

    FROM date_feature
)


-- =========================================
-- 5. JOIN USER PROFILE AND VIEWERSHIP DATA
-- =========================================

SELECT
    A.*,

    COALESCE(B.channel2, 'Unknown') AS channel2,
    B.watch_time,
    B.duration,
    B.duration_minutes,

    COALESCE(B.duration_bucket, 'Unknown') AS duration_bucket,

    B.year,

    COALESCE(B.month, 'Unknown') AS month,

    B.day,

    COALESCE(B.hour_of_day, 'Unknown') AS hour_of_day,

    COALESCE(B.day_name, 'Unknown') AS day_name,

    COALESCE(B.month_name, 'Unknown') AS month_name,

    COALESCE(B.Tv_channel, 'Unknown') AS Tv_channel,

    COALESCE(B.day_classification, 'Unknown') AS day_classification


FROM User_profile AS A

LEFT JOIN channel_feature AS B

    ON A.UserID = B.userid;
	
	
	-- ============================================================
-- BRIGHT TV DATA ANALYTICS PROJECT
-- SQL DATA EXPLORATION, QUALITY CHECKS & CLEANING
-- ============================================================


-- ============================================================
-- SECTION 1: INITIAL DATA EXPLORATION
-- ============================================================

-- View the first 10 rows of the dataset
-- Purpose: Understand the structure and columns before analysis

SELECT *
FROM `workspace`.`default`.`bright_tv_dataset`
LIMIT 10;


-- ============================================================
-- SECTION 2: CHECKING FOR DUPLICATES
-- ============================================================

-- Check whether a UserID appears more than once
-- Purpose: Identify potential duplicate users

SELECT
    UserID,
    COUNT(*) AS duplicate_count
FROM `workspace`.`default`.`bright_tv_dataset`
GROUP BY UserID
HAVING COUNT(*) > 1;


-- ============================================================
-- SECTION 3: CHECKING DATASET SIZE
-- ============================================================

-- Check total number of rows and unique users

SELECT
    COUNT(*) AS number_of_rows,
    COUNT(DISTINCT UserID) AS number_of_subs
FROM `workspace`.`default`.`bright_tv_dataset`;


-- ============================================================
-- SECTION 4: CHECKING NULL USER IDs
-- ============================================================

-- Check whether any rows have a missing UserID

SELECT COUNT(*) AS row_count
FROM `workspace`.`default`.`bright_tv_dataset`
WHERE UserID IS NULL;


-- ============================================================
-- SECTION 5: GENDER DATA QUALITY CHECKS
-- ============================================================

-- View unique Gender values

SELECT DISTINCT Gender
FROM `workspace`.`default`.`bright_tv_dataset`;


-- Check for blank Gender values

SELECT COUNT(*) AS blank_gender_count
FROM `workspace`.`default`.`bright_tv_dataset`
WHERE Gender = ' ';


-- Check for NULL Gender values

SELECT COUNT(*) AS null_gender_count
FROM `workspace`.`default`.`bright_tv_dataset`
WHERE Gender IS NULL;


-- Count unique users by Gender
-- Standardise blank Gender values as 'None'

SELECT
    COUNT(DISTINCT UserID) AS subs,
    CASE
        WHEN Gender = ' ' THEN 'None'
        ELSE Gender
    END AS Gender
FROM `workspace`.`default`.`bright_tv_dataset`
GROUP BY Gender;


-- ============================================================
-- SECTION 6: RACE DATA QUALITY CHECKS
-- ============================================================

-- View unique Race values

SELECT DISTINCT Race
FROM `workspace`.`default`.`bright_tv_dataset`;


-- Check for NULL Race values

SELECT COUNT(*) AS null_race_count
FROM `workspace`.`default`.`bright_tv_dataset`
WHERE Race IS NULL;


-- Standardise Race values

SELECT DISTINCT
    CASE
        WHEN Race = 'other' THEN 'None'
        WHEN Race = ' ' THEN 'None'
        ELSE Race
    END AS Race
FROM `workspace`.`default`.`bright_tv_dataset`;


-- ============================================================
-- SECTION 7: PROVINCE DATA QUALITY CHECKS
-- ============================================================

-- View unique Province values

SELECT DISTINCT Province
FROM `workspace`.`default`.`bright_tv_dataset`;


-- Check for NULL Province values

SELECT COUNT(*) AS null_province_count
FROM `workspace`.`default`.`bright_tv_dataset`
WHERE Province IS NULL;


-- Standardise Province values

SELECT DISTINCT
    CASE
        WHEN Province = ' ' THEN 'Uncategorized'
        WHEN Province = 'None' THEN 'Uncategorized'
        ELSE Province
    END AS Province
FROM `workspace`.`default`.`bright_tv_dataset`;


-- ============================================================
-- SECTION 8: AGE DATA QUALITY CHECKS
-- ============================================================

-- Check minimum and maximum age

SELECT
    MIN(Age) AS min_age,
    MAX(Age) AS max_age
FROM `workspace`.`default`.`bright_tv_dataset`;


-- Check for NULL Age values

SELECT COUNT(*) AS age_null
FROM `workspace`.`default`.`bright_tv_dataset`
WHERE Age IS NULL;


-- ============================================================
-- SECTION 9: USER PROFILE CLEANING AND FEATURE ENGINEERING
-- ============================================================

WITH User_profile AS (

    SELECT
        UserID,

        -- Clean Province
        CASE
            WHEN Province = ' ' THEN 'Uncategorized'
            WHEN Province = 'None' THEN 'Uncategorized'
            ELSE Province
        END AS Province,

        Age,

        -- Create Age Groups
        CASE
            WHEN Age = 0 THEN 'Infants'
            WHEN Age BETWEEN 1 AND 12 THEN 'Kids'
            WHEN Age BETWEEN 13 AND 19 THEN 'Teens'
            WHEN Age BETWEEN 20 AND 35 THEN 'Young'
            WHEN Age BETWEEN 36 AND 50 THEN 'Adults'
            WHEN Age BETWEEN 51 AND 65 THEN 'Elder'
            WHEN Age > 65 THEN 'Senior'
            ELSE 'Unknown'
        END AS Age_group,

        -- Create Email Flag
        CASE
            WHEN Email IS NOT NULL
                 AND TRIM(Email) != ''
                 AND Email != 'None'
            THEN 1
            ELSE 0
        END AS email_flag,

        -- Create Social Media Flag
        CASE
            WHEN `Social Media Handle` IS NOT NULL
                 AND TRIM(`Social Media Handle`) != ''
                 AND `Social Media Handle` != 'None'
            THEN 1
            ELSE 0
        END AS sm_flag,

        -- Clean Race
        CASE
            WHEN Race IS NULL THEN 'None'
            WHEN Race = 'other' THEN 'None'
            WHEN Race = ' ' THEN 'None'
            ELSE Race
        END AS Race,

        -- Clean Gender
        CASE
            WHEN Gender IS NULL THEN 'None'
            WHEN Gender = ' ' THEN 'None'
            ELSE Gender
        END AS Gender

    FROM `workspace`.`default`.`bright_tv_dataset`
)

SELECT *
FROM User_profile;s

-- ============================================================
-- BRIGHT TV VIEWERSHIP ANALYSIS
-- ============================================================


-- 1. TOTAL VIEWERS

SELECT COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`;


-- 2. UNIQUE VIEWERS

SELECT COUNT(DISTINCT UserID) AS unique_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`;


-- 3. AVERAGE VIEWING DURATION

SELECT
    ROUND(AVG(duration_minutes), 1) AS average_duration_minutes
FROM `workspace`.`default`.`bright_tv_dataset_clean`
WHERE duration_minutes IS NOT NULL;


-- 4. TOTAL WATCH TIME

SELECT
    ROUND(SUM(duration_minutes), 0) AS total_watch_time_minutes
FROM `workspace`.`default`.`bright_tv_dataset_clean`
WHERE duration_minutes IS NOT NULL;


-- 5. TOP TV CHANNELS

SELECT
    Tv_channel,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY Tv_channel
ORDER BY total_viewers DESC;


-- 6. VIEWERS BY PROVINCE

SELECT
    Province,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY Province
ORDER BY total_viewers DESC;


-- 7. VIEWERS BY GENDER

SELECT
    Gender,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY Gender
ORDER BY total_viewers DESC;


-- 8. VIEWING BY HOUR OF DAY

SELECT
    hour_of_day,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
WHERE hour_of_day != 'Unknown'
GROUP BY hour_of_day
ORDER BY CAST(hour_of_day AS INT);


-- 9. VIEWERS BY AGE GROUP

SELECT
    Age_group,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY Age_group
ORDER BY total_viewers DESC;


-- 10. WEEKDAY VS WEEKEND VIEWING

SELECT
    day_classification,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY day_classification
ORDER BY total_viewers DESC;


-- 11. VIEWERS BY RACE

SELECT
    Race,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY Race
ORDER BY total_viewers DESC;


-- 12. VIEWING BY MONTH

SELECT
    month,
    month_name,
    COUNT(*) AS total_viewers
FROM `workspace`.`default`.`bright_tv_dataset_clean`
GROUP BY month, month_name
ORDER BY month;