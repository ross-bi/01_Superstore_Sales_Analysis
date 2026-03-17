[![English](https://img.shields.io/badge/English-Click_Here-blue?style=for-the-badge)](README.md)
&nbsp;&nbsp;
[![繁體中文](https://img.shields.io/badge/繁體中文-点击查看-blue?style=for-the-badge)](README.zh-TW.md)

# 超市销售与利润分析

**MySQL · Python · Power BI · 资料仓储**

---

## 专案概述

本项目分析 [Kaggle Superstore 销售数据集](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)，深入探讨 7 个全球市场（2011–2014 年）的产品表现、盈利驱动因素以及折扣策略的实际影响。

目标是透过结构化数据建模与可视化分析，为**采购决策、库存规划及促销优化**提供数据支持。

### 涵盖范畴

- 使用 **Python（pandas）** 进行数据清理与验证
- 在 **MySQL** 中建立雪花纲要数据仓储（staging → 维度表/事实表 → 视图）
- 双向数据检验，确保整条 pipeline 的完整性
- 在 **Power BI** 中建立 3 页交互式仪表板
- 业务洞察与可行建议

---

## 数据集

| 项目 | 说明 |
|---|---|
| 来源 | [Kaggle — Superstore Sales Dataset](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)（作者：Laiba Anwer）|
| 资料笔数 | ~51,000+ |
| 时间范围 | 2011–2014 年 |
| 涵盖市场 | 7 个全球市场（APAC、EU、US、LATAM、EMEA、Africa、Canada）|
| 主要字段 | 订单日期、出货日期、客户、客群、地区、产品类别/子类别、销售额、数量、折扣、利润、运费、订单优先级 |

---

## 工具与技术

| 工具 | 用途 |
|---|---|
| Python（pandas） | 资料清理、验证、稽核报告 |
| MySQL | 维度建模、数据加载、分析 SQL |
| Power BI | 交互式仪表板与 KPI 可视化 |
| GitHub | 版本控制与文件记录 |

---

## 一、资料清理（Python）

### `01_raw_data_preview_cnt.py` — 原始资料稽核
- 生成完整稽核报告（Excel）：描述性统计、缺失值、唯一值计数、数据类型
- 输出前 100 笔预览及随机 100 笔样本（CSV）

### `02_clean_data_cnt.py` — 数据清理与验证
- **日期格式**：统一不同格式（DD/MM/YYYY、DD-MM-YYYY）为标准 datetime
- **数值验证**：移除货币符号/逗号，强制转换为数值，错误记录存 CSV
- **文字标准化**：移除口音符号（São Paulo → Sao Paulo）、修剪空白、统一首字大写
- **数据质量检查**：小数字数分析；产品 ID ↔ 产品名称冲突侦测
- **缺失值处理**：删除 `order_date` 为空的列；`discount` 及 `shipping_cost` 缺失补 0

### `03_clean_check_cnt.py` — 清理后验证
- 对清理后数据重新执行完整稽核，确认所有问题已解决

---

## 二、数据库设计（MySQL — 雪花纲要）

本项目采用完整**雪花纲要**，以正规化维度层级与中央事实表取代单一平面表格。

### 纲要图

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
    dim_market { string market_id PK }
    dim_region { string region_id PK }

    dim_date ||--o{ fact_sales : "order_date_id"
    dim_date ||--o{ fact_sales : "ship_date_id"
    dim_state ||--o{ fact_sales : "ships to"
    dim_product ||--o{ fact_sales : "contains"
    dim_customer ||--o{ fact_sales : "purchases"
    dim_region ||--o{ dim_market : "has"
    dim_market ||--o{ dim_country : "has"
    dim_country ||--o{ dim_state : "has"
    dim_category ||--o{ dim_sub_category : "has"
    dim_sub_category ||--o{ dim_product : "has"
```

### 维度表说明

| 表格 | 说明 | 设计重点 |
|---|---|---|
| `dim_date` | 10 年日历（2011–2020） | 预先生成，含年、季、月、星期几、是否周末 |
| `dim_customer` | 唯一客户 + 客群 | 复合唯一键（customer_name, segment） |
| `dim_region` → `dim_market` → `dim_country` → `dim_state` | 地理层级 | 正规化 4 层层级，含外键关联 |
| `dim_category` → `dim_sub_category` → `dim_product` | 产品层级 | 用复合唯一键处理 1:N 的产品 ID ↔ 产品名称冲突 |
| `fact_sales` | 交易层级事实 | 代理键（sales_id）；保留 staging 中的重复业务记录 |

---

## 三、SQL Pipeline 与数据质量

### 加载与转换

| 步骤 | 脚本 | 用途 |
|---|---|---|
| 1 | `01.create_import_staging_cnt.sql` | 建立 staging 表并加载清理后的 CSV |
| 2 | `02.check_staging_data_cnt.sql` | 验证列/栏计数、唯一键、重复数据 |
| 3 | `03.create_import_dim_fact_cnt.sql` | 透过多表 INSERT 建立所有维度表与事实表 |

### 双向数据检验

| 步骤 | 脚本 | 用途 |
|---|---|---|
| 4 | `04.check_staging_exists_fact_not.sql` | 找出 staging 有但 fact 没有的记录 |
| 5 | `05.check_fact_exists_staging_not.sql` | 找出 fact 有但 staging 没有的记录 |
| 6 | `08.staging_vs_fact_view.sql` | 跨层比对总计（列数、销售额、数量、利润） |

---
## 四、SQL 分析

### 主要商业问题

**哪些商品类别带来最高的销售额与利润？**
```sql
SELECT category_name,
       ROUND(SUM(total_sales), 0)  AS sales,
       ROUND(SUM(total_profit), 0) AS profit,
       ROUND(AVG(profit_margin_pct), 1) AS avg_margin_pct
FROM vw_sales_summary
GROUP BY category_name
ORDER BY sales DESC;
```

**折扣如何影响获利能力？**
```sql
SELECT
    CASE
        WHEN discount = 0        THEN 'No Discount'
        WHEN discount <= 0.10    THEN 'Low (0–10%)'
        WHEN discount <= 0.30    THEN 'Medium (11–30%)'
        ELSE                          'High (>30%)'
    END AS discount_band,
    SUM(sales)   AS total_sales,
    SUM(profit)  AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM vw_sales_full
GROUP BY discount_band
ORDER BY profit_margin_pct DESC;
```
---
## 五、Power BI 仪表板（3 页）

### 第 1 页：执行摘要
<img src="screenshot/bi01.png" alt="执行摘要仪表板" width="100%">

- **KPI 卡片**：销售额（$4.30M）、利润（$504K）、ROI（13.28%）、销售额 YoY（+26.25%）、平均利润率（5.00%）
- **销售趋势**：2013 vs 2014 月度比较，呈现季节性模式
- **前 10 大子类别**：销售、利润、利润率表格（负利润率以条件格式标记）
- **市场分布**：圆饼图 — APAC（28%）、EU（24%）、US（17%）、LATAM（16%）
- **ABC 分析**：按销售及利润贡献分类子类别

### 第 2 页：产品表现
<img src="screenshot/bi02.png" alt="产品表现" width="100%">

- 类别盈利比较（科技 14%、办公用品 14%、家具 7%）
- 子类别 YoY 销售与利润条形图（2011–2014）
- ABC Treemap 可视化分类

### 第 3 页：促销影响
<img src="screenshot/bi03.png" alt="促销影响" width="100%">

- **散点图**：平均折扣率 vs 平均利润率（以数量为气泡大小）
- **折扣影响图**：各折扣层级的销售与利润分布
- **子类别 ROI 排名**：从纸张（最高）到桌子（负 ROI）

---

## 主要洞察

### 类别表现

| 类别 | 销售额 | 利润率 | 评估 |
|---|---|---|---|
| 科技 | $4.74M | 14% | 核心增长引擎 — 最高销售额与利润率 |
| 办公用品 | $3.79M | 14% | 稳定利润来源 |
| 家具 | $4.11M | 7% | 高销售量、低利润率 — 需要定价审查 |

### 折扣影响

| 折扣区间 | 利润率 | 评估 |
|---|---|---|
| 无折扣 | 25.32% | 最健康 |
| 低（0–10%） | 16.56% | 销量与利润的最佳平衡 |
| 中（11–30%） | 7.11% | 利润微薄，谨慎使用 |
| 高（>30%） | **-40.65%** | 净亏损，避免使用 |

---

## 业务建议

1. **折扣上限设为 10%** — 超过 30% 的折扣持续造成亏损
2. **审查家具成本结构** — 销售额排第 2，但利润率只有 7%
3. **停售或重新定价桌子** — 4 年持续负利润率（-13%）
4. **加大科技产品投入** — 最强的收入与利润率组合
5. **以类别专属定价策略取代全面折扣政策**

---

## 项目结构

```
01_Superstore_Sales_Analysis/
│
├── data/                                          # 原始資料、清理後資料與稽核資料集
├── scripts/
│   ├── 01_raw_data_preview_cnt.py                 # 原始資料稽核
│   ├── 02_clean_data_cnt.py                       # 資料清理與驗證
│   └── 03_clean_audit_cnt.py                      # 清理後驗證檢查
├── output/                                        # 脚本产生的输出档案
│   ├── 01–04 pipeline scripts                     # 原始稽核预览 → 清理后预览 → 清理后资料（供汇入）→ 清理后稽核报告
├── sql/
│   ├── 01–08 pipeline scripts                     # 從暫存層 → 維度表 → 事實表 → 檢視表的流程腳本
│   ├── index.sql                                  # 索引與彙總檢視
│   └── analyst/                                   # 分析用 SQL 查詢
├── powerBI/
│   ├── superstore.pbix                            # Power BI 儀表板檔案
│   └── superstore.pdf                             # 儀表板導出檔（3 頁）
├── screenshot/                                    # 儀表板截圖
└── README.md

```
---

## 如何重现本项目

**前置需求**：Python 3.8+、MySQL 8.0+、Power BI Desktop

1. 从 [Kaggle](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset) 下载 `superstore.csv`
2. 执行 `python scripts/02_clean_data_cnt.py`
3. 依序（01 → 08）在 MySQL 执行 SQL 脚本
4. 在 Power BI Desktop 开启 `superstore.pbix`，透过 `vw_sales_full` 连接 MySQL

---

## 授权条款

本项目采用 [MIT LICENSE](./LICENSE)  授权。
