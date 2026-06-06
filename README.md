# Manufacturing-Defect-Intelligence-System
# Manufacturing Defect Intelligence System

## Project Overview
End-to-end data analytics project on 1,000 manufacturing
defect records across 100 products (Jan–Jun 2024).

## Tools Used
| Tool | Purpose |
|------|---------|
| MySQL 8.0 | Database + 15 analytical queries + 3 views |
| Excel 365 | 7 Pivot Tables + Interactive Dashboard |
| Power BI | 4-page BI report + DAX measures |
| Python (Jupyter) | EDA + 4 ML models + predictions |

## Dataset Stats
- Total Records : 1,000
- Products      : 100 unique
- Date Range    : Jan 2024 – Jun 2024
- Columns       : 8
- Total Cost    : $507,627.15
- Critical Rate : 33.3%

## Key Findings
- Structural defects most frequent: 352 (35.2%)
- Minor severity most common: 358 (35.8%)
- Avg repair cost: $507.63
- Visual Inspection + Manual Testing most used methods

## SQL Files
- 01_create_table.sql    → Database + table + CSV import
- 02_data_cleaning.sql   → 7 data quality validation checks
- 03_analysis_queries.sql → 15 queries (basic + intermediate + window)
- 04_views_creation.sql  → 3 reusable views

## How to Run SQL
1. Open MySQL Workbench
2. Run 01_create_table.sql
3. Run 02_data_cleaning.sql — verify all zeros
4. Run 03_analysis_queries.sql — 15 analysis queries
5. Run 04_views_creation.sql — creates 3 views
