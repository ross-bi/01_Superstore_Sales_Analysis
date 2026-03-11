# Project
Superstore Sales & Profit Analysis
MySQL • Python • Tableau • Data Visualization Project

##  Project Overview
This project analyzes the Superstore Sales dataset to uncover insights about product performance, profitability, and the impact of discount strategies.
The goal is to support procurement, inventory planning, and promotion optimization through data-driven decision-making.
The project includes:
- Data cleaning using Python
- Database design & SQL analysis in MySQL
- Interactive dashboards built in Tableau
- Business insights & recommendations

##  Dataset
Source: Kaggle – Superstore Sales Dataset
Rows: ~10,000+
Key fields:
- Order Date, Ship Date
- Customer Name, Segment, Region
- Product Category, Sub-Category
- Sales, Quantity, Discount, Profit
- Shipping Cost, Order Priority
##  Tools & Technologies

| Tool              | Purpose                        |
|-------------------|--------------------------------|
| Python (pandas)   | Data cleaning & preprocessing  |
| MySQL             | Data modeling & analytical SQL |
| Tableau           | Dashboard creation             |
| GitHub            | Version control & documentation|





##  1. Data Cleaning (Python)
Tasks performed:
- Converted date fields to YYYY-MM-DD
- Ensured numeric fields (Sales, Profit, Discount) are correctly typed
- Removed inconsistent formatting and whitespace
- Exported a clean CSV for MySQL import
Example script (simplified):
```python
import pandas as pd

df = pd.read_csv("superstore.csv")
df['order_date'] = pd.to_datetime(df['order_date'])
df['ship_date'] = pd.to_datetime(df['ship_date'])
df.to_csv("superstore_clean.csv", index=False)

```


##  2. Database Schema (MySQL)
A single fact table was created for analysis:
```
superstore_orders
├── order_id
├── order_date
├── ship_date
├── ship_mode
├── customer_name
├── segment
├── state
├── country
├── market
├── region
├── product_id
├── category
├── sub_category
├── product_name
├── sales
├── quantity
├── discount
├── profit
├── shipping_cost
├── order_priority
└── year

```

## 3. SQL Analysis
Key business questions answered:
 Which product categories generate the highest sales?
```sql
SELECT category, SUM(sales) AS total_sales
FROM superstore_orders
GROUP BY category
ORDER BY total_sales DESC;
```

 Which categories have the highest profit margin?
```sql
SELECT category,
       SUM(profit) / SUM(sales) AS profit_margin
FROM superstore_orders
GROUP BY category
ORDER BY profit_margin DESC;
```

 How do discounts affect profit?
```sql
SELECT discount,
       SUM(sales) AS total_sales,
       SUM(profit) AS total_profit
FROM superstore_orders
GROUP BY discount
ORDER BY discount;
```


## 4. Tableau Dashboard
The dashboard includes:
Sales & Profit Overview
- Total Sales, Total Profit, Profit Margin KPIs
- Sales by Category & Sub-Category
- Profitability heatmap
Discount Impact Analysis
- Discount band vs Profit Margin
- Sales vs Profit scatter plot
- Category-level discount sensitivity
Procurement & Inventory Insights
- High-volume / low-margin products
- Monthly sales trends
- Category performance ranking

 Key Insights
- Some high-sales categories have very low profit margins, indicating over-discounting.
- Discounts above certain thresholds significantly reduce profitability.
- Several sub-categories show strong demand with minimal discounting, suggesting potential for margin improvement.
- Seasonal patterns indicate predictable spikes useful for inventory planning.

 Business Recommendations
- Reduce deep discounts on low-margin categories.
- Increase visibility and stock levels for high-margin, high-demand products.
- Reallocate promotional budget to categories with strong profit elasticity.
- Implement category-specific pricing strategies instead of blanket discounts.

 Project Structure
```
Superstore_Project/
│
├── data/
│   └── superstore_clean.csv
│
├── scripts/
│   └── clean_data.py
│
├── sql/
│   └── analysis_queries.sql
│
├── tableau/
│   └── dashboard.twbx
│
└── README.md
```
