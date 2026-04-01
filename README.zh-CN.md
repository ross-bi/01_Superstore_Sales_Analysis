[![English](https://img.shields.io/badge/English-Click_Here-blue?style=for-the-badge)](README.md)
&nbsp;&nbsp;
[![繁體中文](https://img.shields.io/badge/繁體中文-点击查看-blue?style=for-the-badge)](README.zh-TW.md)

# 超市销售与利润分析

**MySQL · Python · Power BI · Data Warehouse**

---

## 专案概述

本项目分析 [Kaggle Superstore 销售数据集](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)，深入探讨 2011–2014 年间全球 7 个市场的产品表现、获利驱动因素及折扣策略影响。

目标是透过结构化数据建模与可视化分析，支持**采购决策、库存规划与促销优化**。

### 项目涵盖范围

- 使用 **Python (pandas)** 进行数据清洗与验证
- 在 **MySQL** 中建立 Snowflake 式维度模型（staging → 维度/事实表 → 视图）：  
  `vw_sales_full` 供行级 SQL/Python 分析；`vw_sales_summary` 供预先汇总的 KPI 查询
- 双向数据检验以验证数据管道完整性
- 在 **Power BI** 中建立 3 页交互式仪表板
- 业务洞察与可行建议

---

## 数据集

| 项目 | 详细信息 |
|---|---|
| 来源 | [Kaggle — Superstore Sales Dataset](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)，作者：Laiba Anwer |
| 笔数 | ~51,000+ |
| 时间范围 | 2011–2014 |
| 涵盖范围 | 全球 7 个市场（APAC、EU、US、LATAM、EMEA、Africa、Canada） |
| 主要字段 | 订单日期、出货日期、客户、客户类别、地区、产品类别、子类别、销售额、数量、折扣、利润、运费、订单优先级 |

---

## 工具与技术

| 工具 | 用途 |
|---|---|
| Python (pandas) | 资料清洗、验证、稽核报告 |
| MySQL | 维度建模、数据加载、分析 SQL |
| Power BI | 交互式仪表板与 KPI 可视化 |
| GitHub | 版本控制与文件管理 |

---

## 1. 资料清洗（Python）

### `01_raw_data_preview_cnt.py` — 原始资料稽核
- 生成完整稽核报告（Excel）：描述性统计、缺失值、唯一值计数、资料型别
- 汇出行预览（100 笔）与随机样本（100 笔）为 CSV

### `02_clean_data_cnt.py` — 数据清洗与验证
- **日期格式化**：将不一致格式（DD/MM/YYYY、DD-MM-YYYY）统一转换为标准 datetime
- **数值验证**：去除货币符号与逗号，强制转换为值类型，并将错误记录至 CSV
- **文字标准化**：移除重音符号（São Paulo → Sao Paulo）、去除空白、统一首字母大写
- **数据质量检查**：小数精度分析；侦测 product ID ↔ product name 冲突
- **缺失值处理**：删除 `order_date` 为空的列；以 0 填补缺失的 `discount` 与 `shipping_cost`

### `03_clean_check_cnt.py` — 清洗后验证
- 对清洗后的数据重新执行完整稽核，确认所有问题已解决

---

## 2. 数据库设计（MySQL — Snowflake Schema）

本项目不采用平面表格，而是实作完整的 **Snowflake Schema**，包含正规化的维度层级与中央事实表。

### Schema 图

```mermaid
erDiagram
    fact_sales {
        string sales_id PK
        string order_id
        float sales
        int quantity
        float discount
        float profit
        float shipping_cost
        string order_priority
    }
    dim_date { date date_id PK }
    dim_customer { string customer_id PK }
    dim_product { string product_id PK }
    dim_sub_category { string sub_category_id PK }
    dim_category { string category_id PK }
    dim_state { string state_id PK }
    dim_country { string country_id PK }
    dim_region { string region_id PK }
    dim_market { string market_id PK }

    dim_date ||--o{ fact_sales : "order_date_id"
    dim_date ||--o{ fact_sales : "ship_date_id"
    dim_state ||--o{ fact_sales : "ships to"
    dim_product ||--o{ fact_sales : "contains"
    dim_customer ||--o{ fact_sales : "purchases"
    dim_market ||--o{ dim_region : "has"
    dim_region ||--o{ dim_country : "has"
    dim_country ||--o{ dim_state : "has"
    dim_category ||--o{ dim_sub_category : "has"
    dim_sub_category ||--o{ dim_product : "has"
```

### 维度表

| 表格 | 说明 | 主要设计决策 |
|---|---|---|
| `dim_date` | 10 年日历（2011–2020） | 预先生成，含 year、quarter、month、day_of_week、is_weekend |
| `dim_customer` | 唯一客户 + 客户类别 | 复合唯一键（customer_name, segment） |
| `dim_market` → `dim_region` → `dim_country` → `dim_state` | 地理层级 | 正规化 4 层层级，使用外键关联 |
| `dim_category` → `dim_sub_category` → `dim_product` | 产品层级 | 透过组合键处理 product_id ↔ product_name 的 1:N 冲突 |
| `fact_sales` | 交易级事实数据 | 代理键（sales_id）；保留重复的业务记录 |

---

## 3. SQL 管道与数据质量

### 加载与转换

| 步骤 | 脚本 | 用途 |
|---|---|---|
| 1 | `01.create_import_staging_cnt.sql` | 建立 staging 表并加载已清洗的 CSV |
| 2 | `02.check_staging_data_cnt.sql` | 验证列数/栏数、唯一键、重复值 |
| 3 | `03.create_import_dim_fact_cnt.sql` | 透过多表 INSERT 建立所有维度表与事实表 |

### 双向核对

| 步骤 | 脚本 | 用途 |
|---|---|---|
| 4 | `04.check_staging_exists_fact_not.sql` | staging 有但 fact 缺少的记录（加载遗漏） |
| 5 | `05.check_fact_exists_staging_not.sql` | fact 有但 staging 缺少的记录（幽灵记录） |
| 6 | `08.staging_vs_fact_view.sql` | 比较所有层级的总计（列数、销售额、数量、利润） |

### 视图与索引

| 步骤 | 脚本 | 用途 |
|---|---|---|
| 7 | `06.create_view.sql` | `vw_sales_full` — 行级 flattened 视图，供 SQL ad-hoc 分析与 Python EDA 使用 |
| 8 | `09.index.sql` | `vw_sales_summary` — 按时间/客户类别/地区/产品类别预先汇总的 KPI 查询视图；建立 `fact_sales` 索引 |
| 9 | `07.check_fact_vw_distinct.sql` | 验证事实表与视图的唯一值计数 |

---

## 4. SQL 分析

### 主要业务问题

**哪些产品类别的销售额与利润最高？**
```sql
SELECT category_name,
       ROUND(SUM(total_sales), 0)  AS sales,
       ROUND(SUM(total_profit), 0) AS profit,
       ROUND(AVG(profit_margin_pct), 1) AS avg_margin_pct
FROM vw_sales_summary
GROUP BY category_name
ORDER BY sales DESC;
```

**折扣对获利能力有何影响？**
```sql
SELECT
    CASE
        WHEN discount = 0        THEN '无折扣'
        WHEN discount <= 0.10    THEN '低折扣（0–10%）'
        WHEN discount <= 0.30    THEN '中折扣（11–30%）'
        ELSE                          '高折扣（>30%）'
    END AS discount_band,
    SUM(sales)   AS total_sales,
    SUM(profit)  AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM vw_sales_full
GROUP BY discount_band
ORDER BY profit_margin_pct DESC;
```

---

## 5. Power BI 仪表板（3 页）

### 第 1 页：高层摘要
<img src="screenshot/bi01.png" alt="Executive Summary Dashboard" width="100%">

- **KPI 卡片**：销售额（$4.30M）、利润（$504K）、ROI（13.28%）、销售额 YoY（+26.25%）、平均利润率（5.00%）
- **销售趋势**：月度对比（2013 vs 2014），突显季节性规律
- **前 10 子类别**：销售额、利润、利润率表格，含条件格式（负利润率标红）
- **市场分布**：圆饼图 — APAC（28%）、EU（24%）、US（17%）、LATAM（16%）、EMEA（7%）
- **ABC 分析**：按销售额与利润贡献度分类子类别
- **筛选器**：客户类别、产品类别

### 第 2 页：产品表现
<img src="screenshot/bi02.png" alt="Product Performance" width="100%">

- 产品类别获利比较（Technology 14%、Office Supplies 14%、Furniture 7%）
- 子类别年度销售额与利润直方图（2011–2014）
- ABC 树形图，可视化子类别分类
- 客户类别与产品类别销售分布圆饼图

### 第 3 页：促销影响
<img src="screenshot/bi03.png" alt="Promotion Impact" width="100%">

- **散点图**：各子类别平均折扣率 vs 平均利润率（气泡大小 = 数量）
- **折扣影响图表**：各年度不同折扣级别的销售额与利润分布
- **子类别 ROI 排名**：从 Paper（最高）到 Tables（负 ROI）
- 利润年度趋势

---

## 主要洞察

### 类别表现

| 类别 | 销售额 | 利润率 | 评估 |
|---|---|---|---|
| Technology | $4.74M | 14% | 核心成长引擎 — 销售额与利润率最高 |
| Office Supplies | $3.79M | 14% | 稳定获利来源 |
| Furniture | $4.11M | 7% | 高销量低利润 — 需检讨定价策略 |

### 折扣影响

| 折扣级别 | 利润率 | 评估 |
|---|---|---|
| 无折扣 | 25.32% | 最健康 — 无需优惠即有强劲需求 |
| 低折扣（0–10%） | 16.56% | 销量与利润的最佳平衡点 |
| 中折扣（11–30%） | 7.11% | 利润薄 — 谨慎使用 |
| 高折扣（>30%） | **-40.65%** | 净亏损 — 应避免 |

---

## 业务建议

1. **折扣上限设为 10%** — 超过 30% 的折扣持续产生净亏损
2. **检讨 Furniture 成本结构** — 销售额第 2 高，但利润率仅 7%
3. **停售或重新定价 Tables** — 4 年来持续负利润率（-13%）
4. **加大 Technology 投入** — 销售额与利润率的最强组合
5. **以产品类别差异化定价策略取代全面折扣**

---

## 项目结构
```
01_Superstore_Sales_Analysis/
│
├── data/ # 原始数据集（CSV）
├── scripts/
│ ├── 01_raw_data_preview_cnt.py # 原始资料稽核
│ ├── 02_clean_data_cnt.py # 数据清洗与验证
│ └── 03_clean_audit_cnt.py # 清洗后验证
├── output/ # 脚本生成的输出档案
│ ├── 01–04 管道脚本 # 原始稽核预览 → 清洗预览 → 清洗后汇入 → 清洗后稽核
├── sql/
│ ├── 01–08 管道脚本 # Staging → 维度表 → 事实表 → 视图
│ ├── 09.index.sql # 索引与汇总视图
│ └── analyst/ # 分析查询
├── powerBI/
│ ├── superstore.pbix # Power BI 仪表板
│ └── superstore.pdf # 仪表板汇出（3 页）
├── screenshot/ # 仪表板截图
└── README.md
```

---

## 重现步骤

**前置条件**：Python 3.8+、MySQL 8.0+、Power BI Desktop

1. 从 [Kaggle](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset) 下载 `superstore.csv`
2. 执行 `python scripts/02_clean_data_cnt.py`
3. 依序在 MySQL 执行 SQL 脚本（`01` → `08`）
4. 在 Power BI Desktop 开启 `superstore.pbix` 并连接至你的 MySQL 数据库。  
   直接汇入以下数据表（Star Schema）：  
   - **事实表**：`fact_sales`  
   - **维度表**：`dim_date` *（设定为 Date Table）*、`dim_customer`、`dim_product`、`dim_sub_category`、`dim_category`、`dim_state`、`dim_country`、`dim_region`、`dim_market`   
   - **注意**：`vw_sales_full` 供 SQL/Python ad-hoc 分析使用；`vw_sales_summary` 供 MySQL KPI 查询使用。两者均不作为 Power BI 数据源。

---

## 作者

Ross Tang | [GitHub](https://github.com/ross-bi)

## 授权

本项目采用 MIT 授权条款。详情请参阅 [LICENSE](./LICENSE) 文件。

