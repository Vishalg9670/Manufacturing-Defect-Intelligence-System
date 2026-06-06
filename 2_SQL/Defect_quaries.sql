-- Creating a Database
CREATE DATABASE manufacturing_db;
USE manufacturing_db;
select * from defects;
rename table defscts to defects;
select *from defects;
describe defects;


-- Total rows check 
SELECT COUNT(*) AS total_rows FROM defects;

-- CHECK 1: NULL values — Every columns must be zero value 

SELECT
    SUM(CASE WHEN defect_id        IS NULL THEN 1 ELSE 0 END) AS null_defect_id,
    SUM(CASE WHEN product_id       IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN defect_type      IS NULL THEN 1 ELSE 0 END) AS null_defect_type,
    SUM(CASE WHEN defect_date      IS NULL THEN 1 ELSE 0 END) AS null_defect_date,
    SUM(CASE WHEN defect_location  IS NULL THEN 1 ELSE 0 END) AS null_location,
    SUM(CASE WHEN severity         IS NULL THEN 1 ELSE 0 END) AS null_severity,
    SUM(CASE WHEN inspection_method IS NULL THEN 1 ELSE 0 END) AS null_method,
    SUM(CASE WHEN repair_cost      IS NULL THEN 1 ELSE 0 END) AS null_cost
FROM defects;

-- checking duplicate in defect_id
select defect_id , count(*) as occurance from defects 
group by defect_id 
having count(*)>1;

-- CHECK 3: Date range verify 
SELECT
    MIN(defect_date)              AS earliest_date,
    MAX(defect_date)              AS latest_date,
    COUNT(DISTINCT defect_date)   AS unique_dates,
    COUNT(DISTINCT MONTH(defect_date)) AS months_covered
FROM defects;

alter table defects modify defect_date date ;
UPDATE defects
SET defect_date = STR_TO_DATE(defect_date, '%m/%d/%Y');

-- ─────────────────────────────────────────
-- CHECK 4: Repair cost outlier check
-- ─────────────────────────────────────────
SELECT
    MIN(repair_cost)   AS min_cost,
    MAX(repair_cost)   AS max_cost,
    ROUND(AVG(repair_cost), 2) AS avg_cost,
    COUNT(CASE WHEN repair_cost < 0      THEN 1 END) AS negative_costs,
    COUNT(CASE WHEN repair_cost > 100000 THEN 1 END) AS extreme_outliers,
    COUNT(CASE WHEN repair_cost = 0      THEN 1 END) AS zero_costs
FROM defects;
-- Expected: min=10.22, max=999.64, avg=507.63
--           negatives=0, outliers=0, zeros=0

-- ─────────────────────────────────────────
-- CHECK 5: Categorical values spelling check
-- Koi typo toh nahi? e.g. "Criticall" ya "minor"
-- ─────────────────────────────────────────
SELECT 'severity'         AS col_name, severity          AS value, COUNT(*) AS cnt FROM defects GROUP BY severity
UNION ALL
SELECT 'defect_type',       defect_type, COUNT(*) FROM defects GROUP BY defect_type
UNION ALL
SELECT 'defect_location',   defect_location,  COUNT(*) FROM defects GROUP BY defect_location
UNION ALL
SELECT 'inspection_method', inspection_method, COUNT(*) FROM defects GROUP BY inspection_method
ORDER BY col_name, value;



-- Expected output:
-- severity        → Critical(333), Minor(358), Moderate(309)
-- defect_type     → Cosmetic(309), Functional(339), Structural(352)
-- defect_location → Component(326), Internal(321), Surface(353)
-- inspection_method → Automated Testing(297), Manual Testing(352), Visual Inspection(351)
-- ─────────────────────────────────────────
-- CHECK 6: Product ID range check
-- Expected: product_id 1 to 100 only
-- ─────────────────────────────────────────
SELECT
    MIN(product_id)            AS min_product,
    MAX(product_id)            AS max_product,
    COUNT(DISTINCT product_id) AS unique_products
FROM defects;
-- Expected: min=1, max=100, unique=100

-- ─────────────────────────────────────────
-- CHECK 7: Final Summary — Data Quality Report
-- ─────────────────────────────────────────
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id)  AS unique_products,
    COUNT(DISTINCT defect_type)  AS defect_types,
    COUNT(DISTINCT severity) AS severity_levels,
    COUNT(DISTINCT inspection_method) AS inspection_methods,
    MIN(defect_date)  AS data_start,
    MAX(defect_date) AS data_end,
    ROUND(SUM(repair_cost), 2) AS total_repair_cost,
    ROUND(AVG(repair_cost), 2) AS avg_repair_cost
FROM defects;

-- =============================================
-- DATA QUALITY RESULT:
-- All checks passed. Dataset is clean.
-- No NULLs | No duplicates | No outliers
-- Consistent categorical values
-- Ready for analysis!
-- =============================================

-- ─────────────────────────────────────────
-- QUERY 1: Defect Type Distribution
-- Business Question: Konsa defect type sabse common
--                   aur sabse mehenga hai?
-- ─────────────────────────────────────────
SELECT
    defect_type,
    COUNT(*)                                                     AS total_defects,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM defects), 2) AS pct_of_total,
    ROUND(SUM(repair_cost), 2)                                   AS total_repair_cost,
    ROUND(AVG(repair_cost), 2)                                   AS avg_repair_cost,
    ROUND(MAX(repair_cost), 2)                                   AS max_repair_cost,
    ROUND(MIN(repair_cost), 2)                                   AS min_repair_cost
FROM defects
GROUP BY defect_type
ORDER BY total_defects DESC;

-- Expected output:
-- Structural  | 352 | 35.20% | ~$178,xxx | ~$507
-- Functional  | 339 | 33.90% | ~$172,xxx | ~$507
-- Cosmetic    | 309 | 30.90% | ~$157,xxx | ~$508

-- ─────────────────────────────────────────
-- QUERY 2: Severity Breakdown
-- Business Question: Har severity level ka
--                   financial impact kya hai?
-- ─────────────────────────────────────────
SELECT
    severity,
    COUNT(*)                                                     AS defect_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM defects), 2) AS pct_of_total,
    ROUND(AVG(repair_cost), 2)                                   AS avg_repair_cost,
    ROUND(SUM(repair_cost), 2)                                   AS total_repair_cost,
    ROUND(MAX(repair_cost), 2)                                   AS max_repair_cost,
    ROUND(MIN(repair_cost), 2)                                   AS min_repair_cost
FROM defects
GROUP BY severity
ORDER BY FIELD(severity, 'Critical', 'Moderate', 'Minor');

-- FIELD() function se custom order milti hai
-- Critical pehle, phir Moderate, phir Minor
-- Expected:
-- Critical | 333 | 33.30%
-- Moderate | 309 | 30.90%
-- Minor    | 358 | 35.80%

-- ─────────────────────────────────────────
-- QUERY 2: Severity Breakdown
-- Business Question: Har severity level ka
--                   financial impact kya hai?
-- ─────────────────────────────────────────
SELECT
    severity,
    COUNT(*)                                                     AS defect_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM defects), 2) AS pct_of_total,
    ROUND(AVG(repair_cost), 2)                                   AS avg_repair_cost,
    ROUND(SUM(repair_cost), 2)                                   AS total_repair_cost,
    ROUND(MAX(repair_cost), 2)                                   AS max_repair_cost,
    ROUND(MIN(repair_cost), 2)                                   AS min_repair_cost
FROM defects
GROUP BY severity
ORDER BY FIELD(severity, 'Critical', 'Moderate', 'Minor');

-- FIELD() function se custom order milti hai
-- Critical pehle, phir Moderate, phir Minor
-- Expected:
-- Critical | 333 | 33.30%
-- Moderate | 309 | 30.90%
-- Minor    | 358 | 35.80%\

-- ─────────────────────────────────────────
-- QUERY 3: Monthly Trend Analysis
-- Business Question: Jan se Jun 2024 tak
--                   defects aur cost ka trend?
-- ─────────────────────────────────────────
SELECT
    MONTH(defect_date)                                          AS month_num,
    MONTHNAME(defect_date)                                      AS month_name,
    COUNT(*)                                                    AS total_defects,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)     AS critical_count,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END)     AS moderate_count,
    SUM(CASE WHEN severity = 'Minor'    THEN 1 ELSE 0 END)     AS minor_count,
    ROUND(SUM(repair_cost), 2)                                  AS monthly_total_cost,
    ROUND(AVG(repair_cost), 2)                                  AS monthly_avg_cost
FROM defects
GROUP BY month_num, month_name
ORDER BY month_num;

-- month_num se ORDER BY karo — 
-- MONTHNAME se karo toh alphabetical hoga (April, Feb...)
-- which is wrong for trend analysis

-- ─────────────────────────────────────────
-- QUERY 4: Top 10 Most Defective Products
-- Business Question: Konse products mein
--                   sabse zyada defects hain?
-- ─────────────────────────────────────────
SELECT
    product_id,
    COUNT(*)                                                    AS total_defects,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)     AS critical_count,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END)     AS moderate_count,
    SUM(CASE WHEN severity = 'Minor'    THEN 1 ELSE 0 END)     AS minor_count,
    ROUND(SUM(repair_cost), 2)                                  AS total_cost,
    ROUND(AVG(repair_cost), 2)                                  AS avg_cost_per_defect
FROM defects
GROUP BY product_id
ORDER BY total_defects DESC
LIMIT 10;

-- ─────────────────────────────────────────
-- QUERY 5: Inspection Method Effectiveness
-- Business Question: Konsa method sabse zyada
--                   critical defects pakad raha hai?
-- ─────────────────────────────────────────
SELECT
    inspection_method,
    COUNT(*)                                                            AS total_inspections,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)             AS critical_caught,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END)             AS moderate_caught,
    SUM(CASE WHEN severity = 'Minor'    THEN 1 ELSE 0 END)             AS minor_caught,
    ROUND(
        SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                                   AS critical_catch_rate_pct,
    ROUND(AVG(repair_cost), 2)                                          AS avg_cost,
    ROUND(SUM(repair_cost), 2)                                          AS total_cost
FROM defects
GROUP BY inspection_method
ORDER BY critical_caught DESC;

-- Expected:
-- Visual Inspection | 351 total
-- Manual Testing    | 352 total
-- Automated Testing | 297 total

-- ─────────────────────────────────────────
-- QUERY 6: Defect Type vs Severity Matrix
-- Business Question: Konsa defect type
--                   sabse zyada critical incidents produce karta hai?
-- ─────────────────────────────────────────
SELECT
    defect_type,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)  AS Critical,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END)  AS Moderate,
    SUM(CASE WHEN severity = 'Minor'    THEN 1 ELSE 0 END)  AS Minor,
    COUNT(*)                                                 AS Total,
    ROUND(
        SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    )                                                        AS critical_pct
FROM defects
GROUP BY defect_type
ORDER BY Critical DESC;

-- Ye query Excel mein cross-tab pivot ka SQL version hai
-- Interview mein bol sako: "Ye conditional aggregation hai —
-- CASE WHEN se multiple columns ek hi query mein"

-- ─────────────────────────────────────────
-- QUERY 7: Location vs Defect Type
-- Business Question: Kaunsi location mein
--                   kaunsa defect type zyada aata hai?
-- ─────────────────────────────────────────
SELECT
    defect_location,
    defect_type,
    COUNT(*)                    AS defect_count,
    ROUND(AVG(repair_cost), 2)  AS avg_cost,
    ROUND(SUM(repair_cost), 2)  AS total_cost
FROM defects
GROUP BY defect_location, defect_type
ORDER BY defect_location, defect_count DESC;

-- Output: 9 rows (3 locations × 3 types)
-- Power BI mein iska Matrix visual banta hai — heatmap jaisa dikhta hai

-- ─────────────────────────────────────────
-- QUERY 8: Cost Category Distribution
-- Business Question: Kitne defects Low/Medium/High
--                   cost range mein hain?
-- ─────────────────────────────────────────
SELECT
    CASE
        WHEN repair_cost < 200              THEN 'Low (< $200)'
        WHEN repair_cost BETWEEN 200 AND 600 THEN 'Medium ($200–$600)'
        ELSE                                     'High (> $600)'
    END                                                          AS cost_category,
    COUNT(*)                                                     AS defect_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM defects), 2) AS pct_of_total,
    ROUND(SUM(repair_cost), 2)                                   AS total_cost,
    ROUND(AVG(repair_cost), 2)                                   AS avg_cost
FROM defects
GROUP BY cost_category
ORDER BY avg_cost DESC;

-- ─────────────────────────────────────────
-- QUERY 9: Week-wise Defect Trend
-- Business Question: Kaunse specific weeks mein
--                   defect spikes hain?
-- ─────────────────────────────────────────
SELECT
    WEEK(defect_date, 1)                                        AS week_number,
    MIN(defect_date)                                            AS week_start_date,
    COUNT(*)                                                    AS defects_per_week,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END)     AS critical_this_week,
    ROUND(SUM(repair_cost), 2)                                  AS weekly_cost
FROM defects
GROUP BY week_number
ORDER BY week_number;

-- WEEK(date, 1) → Monday ko week start maanta hai
-- Isse production cycle patterns dikh sakte hain

-- ─────────────────────────────────────────
-- QUERY 10: Products with ONLY Critical Defects
-- Business Question: Konse products ke 100%
--                   defects Critical hain?
-- ─────────────────────────────────────────
SELECT
    d.product_id,
    COUNT(*)                    AS total_defects,
    ROUND(SUM(repair_cost), 2)  AS total_cost,
    ROUND(AVG(repair_cost), 2)  AS avg_cost
FROM defects d
WHERE severity = 'Critical'
GROUP BY d.product_id
HAVING COUNT(*) = (
    SELECT COUNT(*) 
    FROM defects d2 
    WHERE d2.product_id = d.product_id
)
ORDER BY total_defects DESC;

-- Ye HAVING + Subquery combination interview mein
-- advanced SQL skill dikhata hai
-- Matlab: sirf wo products jahan SARE defects Critical hain

-- ─────────────────────────────────────────
-- QUERY 11: Running Total of Repair Cost
-- Window Function: SUM() OVER (ORDER BY)
-- Business Use: Cumulative budget kitna consume
--              ho chuka hai month by month?
-- ─────────────────────────────────────────
SELECT
    MONTH(defect_date)                  AS month_num,
    MONTHNAME(defect_date)              AS month_name,
    COUNT(*)                            AS monthly_defects,
    ROUND(SUM(repair_cost), 2)          AS monthly_cost,
    ROUND(
        SUM(SUM(repair_cost)) OVER (
            ORDER BY MONTH(defect_date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2
    )                                   AS running_total_cost
FROM defects
GROUP BY month_num, month_name
ORDER BY month_num;

-- SUM(SUM()) — outer SUM is window function
--              inner SUM is GROUP BY aggregation
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- matlab: pehle row se current row tak sab add karo

-- ─────────────────────────────────────────
-- QUERY 12: Rank Products by Repair Cost
-- Window Function: RANK() OVER (ORDER BY)
-- Business Use: Sabse bada financial liability
--              kaunsa product hai?
-- ─────────────────────────────────────────
SELECT
    product_id,
    COUNT(*)                                            AS defect_count,
    ROUND(SUM(repair_cost), 2)                          AS total_cost,
    RANK()       OVER (ORDER BY SUM(repair_cost) DESC)  AS cost_rank,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC)          AS frequency_rank
FROM defects
GROUP BY product_id
ORDER BY cost_rank
LIMIT 15;

-- RANK()       → tie hone pe next rank skip hoti hai (1,1,3,4)
-- DENSE_RANK() → tie hone pe skip nahi hoti (1,1,2,3)
-- Dono ek saath dikhaoge → interview mein difference pata hai ye prove hoga
-- ─────────────────────────────────────────
-- QUERY 13: Month over Month Change
-- Window Function: LAG() OVER (ORDER BY)
-- Business Use: Defect rate improve ho rahi hai
--              ya deteriorate?
-- ─────────────────────────────────────────
WITH monthly_data AS (
    SELECT
        MONTH(defect_date)          AS mo,
        MONTHNAME(defect_date)      AS month_name,
        COUNT(*)                    AS defect_count,
        ROUND(SUM(repair_cost), 2)  AS total_cost
    FROM defects
    GROUP BY mo, month_name
)
SELECT
    mo,
    month_name,
    defect_count                                           AS current_month,
    LAG(defect_count) OVER (ORDER BY mo)                  AS previous_month,
    defect_count - LAG(defect_count) OVER (ORDER BY mo)   AS mom_change,
    ROUND(
        (defect_count - LAG(defect_count) OVER (ORDER BY mo))
        * 100.0 / NULLIF(LAG(defect_count) OVER (ORDER BY mo), 0)
    , 1)                                                   AS mom_change_pct
FROM monthly_data
ORDER BY mo;

-- LAG() → previous row ki value laata hai
-- NULLIF(x, 0) → divide by zero error se bachata hai
-- CTE (WITH clause) → complex query ko readable banata hai
-- January ka previous_month = NULL (koi pehli month nahi)
-- ─────────────────────────────────────────
-- QUERY 14: Repair Cost Percentile Ranking
-- Window Function: PERCENT_RANK() OVER
-- Business Use: Konse defects top 10% cost
--              range mein hain?
-- ─────────────────────────────────────────
SELECT
    defect_id,
    product_id,
    severity,
    defect_type,
    repair_cost,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY repair_cost) * 100, 2
    )                   AS cost_percentile,
    CASE
        WHEN PERCENT_RANK() OVER (ORDER BY repair_cost) >= 0.90
            THEN 'Top 10% — Highest Cost'
        WHEN PERCENT_RANK() OVER (ORDER BY repair_cost) >= 0.75
            THEN 'Top 25%'
        WHEN PERCENT_RANK() OVER (ORDER BY repair_cost) >= 0.50
            THEN 'Above Average'
        ELSE
            'Below Average'
    END                 AS cost_tier
FROM defects
ORDER BY repair_cost DESC
LIMIT 20;

-- PERCENT_RANK() returns 0 to 1
-- 0.90 matlab 90th percentile — top 10% mein hai
-- * 100 karo toh 0-100 range mein aa jaata hai

-- ─────────────────────────────────────────
-- QUERY 15: Product Composite Risk Score
-- Combines: Frequency(40%) + Severity(35%) + Cost(25%)
-- Business Use: Ek single risk number per product
--              taaki priority decide ho sake
-- ─────────────────────────────────────────
SELECT
    product_id,
    COUNT(*)                                                    AS defect_frequency,
    ROUND(
        AVG(CASE severity
            WHEN 'Critical' THEN 3
            WHEN 'Moderate' THEN 2
            ELSE 1 END)
    , 2)                                                        AS avg_severity_score,
    ROUND(SUM(repair_cost), 2)                                  AS total_cost,
    -- Composite Score Formula
    ROUND(
        (COUNT(*) * 0.40) +
        (AVG(CASE severity
            WHEN 'Critical' THEN 3
            WHEN 'Moderate' THEN 2
            ELSE 1 END) * 0.35) +
        (SUM(repair_cost) / 1000 * 0.25)
    , 2)                                                        AS composite_risk_score,
    -- Risk Label
    CASE
        WHEN COUNT(*) >= 15
          OR SUM(CASE WHEN severity='Critical' THEN 1 ELSE 0 END) >= 8
        THEN 'HIGH RISK'
        WHEN COUNT(*) >= 10
          OR SUM(CASE WHEN severity='Critical' THEN 1 ELSE 0 END) >= 5
        THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END                                                         AS risk_level
FROM defects
GROUP BY product_id
ORDER BY composite_risk_score DESC
LIMIT 15;

-- Interview mein explain karo:
-- "Maine teenon factors ko alag alag weightage diya —
-- frequency sabse important (40%) kyunki repeat defects
-- process problem indicate karte hain. Severity (35%) kyunki
-- critical defects safety risk hain. Cost (25%) financial impact ke liye."


-- =============================================
-- File    : 04_views_creation.sql
-- Purpose : Reusable views for Power BI + ML
-- =============================================

USE manufacturing_db;

-- ─────────────────────────────────────────
-- VIEW 1: v_monthly_summary
-- Used by: Power BI Page 1 (Executive Summary)
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW v_monthly_summary AS
SELECT
    MONTH(defect_date) AS month_num,
    MONTHNAME(defect_date) AS month_name,
    COUNT(*) AS total_defects,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END) AS critical_count,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END) AS moderate_count,
    SUM(CASE WHEN severity = 'Minor' THEN 1 ELSE 0 END) AS minor_count,
    ROUND(SUM(repair_cost),2) AS total_cost,
    ROUND(AVG(repair_cost),2) AS avg_cost
FROM defects
GROUP BY MONTH(defect_date), MONTHNAME(defect_date);

-- ─────────────────────────────────────────
-- VIEW 2: v_product_risk
-- Used by: Power BI Page 2 (Product Analysis)
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW v_product_risk AS
SELECT
    product_id,
    COUNT(*) AS total_defects,
    SUM(CASE WHEN severity = 'Critical' THEN 1 ELSE 0 END) AS critical_count,
    SUM(CASE WHEN severity = 'Moderate' THEN 1 ELSE 0 END) AS moderate_count,
    SUM(CASE WHEN severity = 'Minor' THEN 1 ELSE 0 END) AS minor_count,
    ROUND(SUM(repair_cost), 2) AS total_cost,
    ROUND(AVG(repair_cost), 2) AS avg_cost,
    ROUND(
        (COUNT(*) * 0.40) +
        (AVG(CASE severity
            WHEN 'Critical' THEN 3
            WHEN 'Moderate' THEN 2
            ELSE 1 END) * 0.35) +
        (SUM(repair_cost) / 1000 * 0.25)
    , 2) AS risk_score,
    CASE
        WHEN COUNT(*) >= 15
          OR SUM(CASE WHEN severity='Critical' THEN 1 ELSE 0 END) >= 8
        THEN 'HIGH RISK'
        WHEN COUNT(*) >= 10
          OR SUM(CASE WHEN severity='Critical' THEN 1 ELSE 0 END) >= 5
        THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM defects
GROUP BY product_id;

-- ─────────────────────────────────────────
-- VIEW 3: v_ml_dataset
-- Used by: Jupyter Notebook (Week 3 ML)
-- Extra derived features add kiye hain
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW v_ml_dataset AS
SELECT
    defect_id,
    product_id,
    defect_type,
    defect_date,
    YEAR(defect_date) AS year,
    MONTH(defect_date) AS month,
    DAYOFWEEK(defect_date) AS day_of_week,
    QUARTER(defect_date) AS quarter,
    WEEK(defect_date,1) AS week_number,
    defect_location,
    severity,
    inspection_method,
    repair_cost,
    CASE severity
        WHEN 'Critical' THEN 3
        WHEN 'Moderate' THEN 2
        ELSE 1
    END AS severity_score,
    CASE
        WHEN repair_cost < 200 THEN 'Low'
        WHEN repair_cost <= 600 THEN 'Medium'
        ELSE 'High'
    END AS cost_category
FROM defects;

SELECT *
FROM v_ml_dataset;