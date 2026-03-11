# Superstore Sales & Profit Analysis

**MySQL · Python · Power BI · Data Warehouse Project**

---

## Project Overview

This project analyzes the [Kaggle Superstore Sales Dataset](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset) to uncover insights about product performance, profitability, and the impact of discount strategies across global markets (2011–2014).

The goal is to support **procurement, inventory planning, and promotion optimization** through data-driven decision-making.

### What This Project Covers

- Data cleaning & validation using **Python (pandas)**
- Snowflake-style dimensional modeling in **MySQL** (staging → dimension/fact tables → views)
- Data integrity verification with bidirectional reconciliation
- Interactive dashboards built in **Power BI** (3 pages)
- Business insights & actionable recommendations

---

## Dataset

| Item | Detail |
|------|--------|
| Source | [Kaggle — Superstore Sales Dataset](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset) by Laiba Anwer |
| Rows | ~51,000+ |
| Time Range | 2011–2014 |
| Coverage | 7 global markets (APAC, EU, US, LATAM, EMEA, Africa, Canada) |
| Key Fields | Order Date, Ship Date, Customer, Segment, Region, Product Category/Sub-Category, Sales, Quantity, Discount, Profit, Shipping Cost, Order Priority |

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| Python (pandas) | Data cleaning, validation & audit reporting |
| MySQL | Dimensional modeling, data loading & analytical SQL |
| Power BI | Interactive dashboard & KPI visualization |
| GitHub | Version control & documentation |

---

## 1. Data Cleaning (Python)

Three Python scripts handle the complete data quality pipeline:

### `01_raw_data_preview_cnt.py` — Raw Data Audit
- Generates a full audit report (Excel): descriptive statistics, missing values, unique counts, data types
- Exports preview (first 100 rows) and random sample (100 rows) as CSV for quick inspection

### `02_clean_data_cnt.py` — Data Cleaning & Validation
- **Date formatting**: Converts inconsistent date formats (DD/MM/YYYY, DD-MM-YYYY) to standard datetime
- **Numeric validation**: Strips currency symbols/commas, coerces to numeric, logs errors to CSV
- **Text standardization**: Removes accents (e.g., São Paulo → Sao Paulo), trims whitespace, applies Proper Case
- **Data quality checks**:
  - Decimal precision analysis for all numeric fields → `numeric_decimal_summary.csv`
  - Product ID ↔ Product Name conflict detection → `product_id_name_conflicts.csv`
- **Missing value handling**: Drops rows with null `order_date`; fills missing `discount` and `shipping_cost` with 0

### `03_clean_check_cnt.py` — Post-Clean Verification
- Re-runs the full audit on cleaned data to confirm all issues are resolved
- Outputs cleaned report (Excel) + preview/sample CSVs for comparison

---

## 2. Database Design (MySQL — Snowflake Schema)

Instead of a single flat table, this project implements a **snowflake schema** with normalized dimension tables and a central fact table, demonstrating production-level data warehouse design.

### Schema Diagram

```
                        dim_date
                       (date_id PK)
                      ┌─────┴─────┐
                order_date_id   ship_date_id
                      │             │
dim_region ──► dim_market ──► dim_country ──► dim_state
                                                  │
dim_category ──► dim_sub_category ──► dim_product  │
                                          │        │
                                     ┌────┴────────┘
                                     │
                                fact_sales
                              (sales_id PK)
                              order_id
                              sales, quantity
                              discount, profit
                              shipping_cost
                              order_priority
                                     │
                                dim_customer
                              (customer_id PK)
```

### Dimension Tables

| Table | Description | Key Design Decisions |
|-------|-------------|---------------------|
| `dim_date` | 10-year calendar (2011–2020) | Pre-generated with year, quarter, month, day_of_week, is_weekend |
| `dim_customer` | Unique customer + segment | Composite unique key (customer_name, segment) |
| `dim_region` → `dim_market` → `dim_country` → `dim_state` | Geographic hierarchy | Normalized 4-level hierarchy with foreign keys |
| `dim_category` → `dim_sub_category` → `dim_product` | Product hierarchy | Handles 1:N product_id ↔ product_name conflicts via composite unique key |
| `fact_sales` | Transaction-level facts | Surrogate key (sales_id); preserves duplicate business records from staging |

---

## 3. Data Pipeline & Quality Assurance

The SQL pipeline follows a strict staging → transform → validate workflow:

### Loading & Transformation

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `01.create_import_staging_cnt.sql` | Create staging table & load cleaned CSV via `LOAD DATA` |
| 2 | `02.check_staging_data_cnt.sql` | Verify row/column counts, check unique keys, detect full duplicates |
| 3 | `03.create_import_dim_fact_cnt.sql` | Create all dimension & fact tables; populate via INSERT with multi-table JOINs |

### Bidirectional Reconciliation

| Step | Script | Purpose |
|------|--------|---------|
| 4 | `04.check_staging_exists_fact_not.sql` | Find records in staging but missing from fact (loading gaps) |
| 5 | `05.check_fact_exists_staging_not.sql` | Find records in fact but missing from staging (phantom records) |
| 6 | `08.staging_vs_fact_view.sql` | Compare totals (row count, sales, quantity, profit) across staging → fact → view |

### Views & Indexes

| Step | Script | Purpose |
|------|--------|---------|
| 7 | `06.create_view.sql` | `vw_sales_full` — full denormalized view joining all dimensions (for Power BI) |
| 8 | `index.sql` | `vw_sales_summary` — pre-aggregated view by time, segment, region, category |
| 9 | `07.check_fact_vw_distinct.sql` | Verify distinct value counts across fact table and view |

---

## 4. SQL Analysis

### Analyst Queries (`sql/analyst/`)

| Query | Business Question |
|-------|-------------------|
| `market_country_x_category.sql` | Sales & profit breakdown by market → country → state → category → sub-category |
| `raw_produt_id_x_profit.sql` | Per-product sales, profit & shipping cost ranking |
| `raw_produt_id_x_month.sql` | Monthly product-level sales trends (seasonality detection) |
| `raw_produt_id_x_year.sql` | Year-over-year product performance comparison |

### Key Business Questions (from views)

**Which product categories generate the highest sales?**
```sql
SELECT category_name,
       ROUND(SUM(total_sales), 0) AS sales,
       ROUND(SUM(total_profit), 0) AS profit,
       ROUND(AVG(profit_margin_pct), 1) AS avg_margin_pct
FROM vw_sales_summary
GROUP BY category_name
ORDER BY sales DESC;
```

**How do discounts affect profitability?**
```sql
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.10 THEN 'Low (0–10%)'
        WHEN discount <= 0.30 THEN 'Medium (11–30%)'
        ELSE 'High (>30%)'
    END AS discount_band,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM vw_sales_full
GROUP BY discount_band
ORDER BY profit_margin_pct DESC;
```

---

## 5. Power BI Dashboard (3 Pages)

### Page 1: Executive Summary
<img src="powerBI.jpg" alt="Executive Summary Dashboard" width="100%">

- **KPI Cards**: Sales ($4.30M), Profit ($504K), ROI (13.28%), Sales YoY (+26.25%), AVG Margin (5.00%)
- **Sales Trend**: Monthly sales comparison (2013 vs 2014) showing seasonal patterns
- **Top 10 Sub-Categories**: Sales, Profit, Margin table with conditional formatting (negative margins highlighted)
- **Market Distribution**: Pie chart — APAC (28%), EU (24%), US (17%), LATAM (16%), EMEA (7%)
- **ABC Analysis**: Sub-category classification by sales and profit contribution
- **Slicers**: Segment (Consumer/Corporate/Home Office), Category

### Page 2: Product Performance
- **Category Profitability Table**: Technology (14% margin), Office Supplies (14%), Furniture (7%)
- **Sub-Category Deep Dive**: Sales & profit bar charts with year-over-year comparison (2011–2014)
- **ABC Treemap**: Visual classification of sub-categories by sales volume
- **Segment & Category Breakdown**: Pie charts for sales distribution

### Page 3: Promotion Impact
- **Discount vs Margin Scatter Plot**: AVG Discount % vs AVG Margin % by sub-category (with quantity as bubble size)
- **Discount Impact Charts**: Sales and profit distribution by discount level across years
- **ROI by Sub-Category**: Bar chart ranking — Paper (highest ROI) to Tables (negative ROI)
- **Profit Trend**: Year-over-year profit growth visualization

**Interactive Features**: Year slicer (2011–2014), Segment slicer, Category slicer, Sub-Category dropdown

---

## Key Insights

### Category Performance
| Category | Sales | Profit Margin | Assessment |
|----------|-------|---------------|------------|
| Technology | $4.74M | 14% | Core growth engine — highest sales AND profit margin |
| Office Supplies | $3.79M | 14% | Stable profit source — similar margin with lower volume |
| Furniture | $4.11M | 7% | High volume, low margin — needs pricing/cost review |

### Discount Impact
| Discount Band | Sales | Profit Margin | Assessment |
|---------------|-------|---------------|------------|
| No Discount | $6.99M | 25.32% | Healthiest — strong demand without discounting |
| Low (0–10%) | $1.70M | 16.56% | Best balance of volume and profit |
| Medium (11–30%) | $2.13M | 7.11% | Thin margin — use cautiously |
| High (>30%) | $1.80M | **-40.65%** | Unprofitable — causes net losses |

### Sub-Category Highlights
- **Top Performers**: Copiers ($104K profit, 19% margin), Phones ($71K, 13%), Accessories (16% margin)
- **Underperformers**: Tables (-$30K profit, -13% margin), Machines (-3% avg margin)
- **High Potential**: Bookcases (12% margin, $513K sales) — strong demand with room for margin improvement

---

## Business Recommendations

1. **Cap discounts at 10%** — Discounts above 30% generate net losses; low discounts (0–10%) achieve the best balance of volume and profit
2. **Investigate Furniture costs** — Second-highest sales but only 7% margin; review supply chain and pricing structure
3. **Discontinue or reprice Tables** — Consistent negative margin (-13%) across all years suggests structural unprofitability
4. **Double down on Technology** — Highest sales and strong margin; allocate marketing and inventory resources here
5. **Implement category-specific pricing** — Replace blanket discount policies with targeted strategies per sub-category

---

## Project Structure

```
01_Superstore_Sales_Analysis/
│
├── data/
│   ├── superstore.csv                              # Original raw dataset
│   ├── SuperStoreOrders.csv.zip                     # Compressed backup
│   ├── superstore_clean_20251229.csv                # Cleaned dataset (MySQL import source)
│   ├── raw_superstore_report_20251229.xlsx          # Raw data audit report
│   ├── clean_superstore_report_20251229.xlsx        # Clean data audit report
│   ├── numeric_decimal_summary_20251229.csv         # Decimal precision analysis
│   ├── product_id_name_conflicts_20251229.csv       # Product ID conflict report
│   ├── superstore_unique_text_20251229.csv          # Unique text values reference
│   ├── raw_superstore_preview_100_20251229.csv      # Raw data preview (100 rows)
│   ├── raw_superstore_sample_100_20251229.csv       # Raw data random sample
│   ├── clean_superstore_preview_100_20251229.csv    # Clean data preview (100 rows)
│   └── clean_superstore_sample_100_20251229.csv     # Clean data random sample
│
├── scripts/
│   ├── 01_raw_data_preview_cnt.py                   # Raw data audit
│   ├── 02_clean_data_cnt.py                         # Data cleaning & validation
│   └── 03_clean_check_cnt.py                        # Post-clean verification
│
├── sql/
│   ├── 01.create_import_staging_cnt.sql             # Create staging table & import
│   ├── 02.check_staging_data_cnt.sql                # Staging data validation
│   ├── 03.create_import_dim_fact_cnt.sql            # Dimension & fact table creation
│   ├── 04.check_staging_exists_fact_not.sql         # Staging → Fact reconciliation
│   ├── 05.check_fact_exists_staging_not.sql         # Fact → Staging reconciliation
│   ├── 06.create_view.sql                           # Full denormalized view
│   ├── 07.check_fact_vw_distinct.sql                # View integrity check
│   ├── 08.staging_vs_fact_view.sql                  # Cross-layer total comparison
│   ├── index.sql                                    # Indexes & summary view
│   ├── test_powerbi.sql                             # KPI verification queries
│   ├── drop_table.sql                               # Schema teardown (dependency-safe)
│   ├── README.txt                                   # SQL design notes & business insights
│   ├── README_PROGRESS.txt                          # Development progress log
│   └── analyst/
│       ├── market_country_x_category.sql            # Geographic × Category breakdown
│       ├── raw_produt_id_x_profit.sql               # Product-level profitability
│       ├── raw_produt_id_x_month.sql                # Monthly product trends
│       └── raw_produt_id_x_year.sql                 # Yearly product comparison
│
├── powerBI/
│   ├── superstore.pbix                              # Power BI dashboard file
│   └── superstore.pdf                               # Dashboard export (3 pages)
│
├── Ref/                                             # Reference dashboards & notebooks
│
└── README.md
```

---

## How to Reproduce

### Prerequisites
- Python 3.8+ with `pandas`, `xlsxwriter`
- MySQL 8.0+
- Power BI Desktop

### Steps
1. **Download dataset**: Get `superstore.csv` from [Kaggle](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)
2. **Run data cleaning**: `python scripts/02_clean_data_cnt.py`
3. **Set up MySQL**: Execute SQL scripts in order (`01` → `08`)
4. **Open Power BI**: Connect `superstore.pbix` to your MySQL instance via `vw_sales_full`
