[![English](https://img.shields.io/badge/English-Click_Here-blue?style=for-the-badge)](README.md)
&nbsp;&nbsp;
[![简体中文](https://img.shields.io/badge/简体中文-点击查看-blue?style=for-the-badge)](README.zh-CN.md)

# 超市銷售與利潤分析

**MySQL · Python · Power BI · 資料倉儲**

---

## 專案概述

本專案分析 [Kaggle Superstore 銷售資料集](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)，深入探討 7 個全球市場（2011–2014 年）的產品表現、盈利驅動因素以及折扣策略的實際影響。

目標是透過結構化資料建模與視覺化分析，為**採購決策、庫存規劃及促銷優化**提供數據支援。

### 涵蓋範疇

- 使用 **Python（pandas）** 進行資料清理與驗證
- 在 **MySQL** 中建立雪花綱要資料倉儲（staging → 維度表/事實表 → 視圖）
- 雙向資料核對，確保整條 pipeline 的完整性
- 在 **Power BI** 中建立 3 頁互動式儀表板
- 業務洞察與可行建議

---

## 資料集

| 項目 | 說明 |
|---|---|
| 來源 | [Kaggle — Superstore Sales Dataset](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset)（作者：Laiba Anwer）|
| 資料筆數 | ~51,000+ |
| 時間範圍 | 2011–2014 年 |
| 涵蓋市場 | 7 個全球市場（APAC、EU、US、LATAM、EMEA、Africa、Canada）|
| 主要欄位 | 訂單日期、出貨日期、客戶、客群、地區、產品類別/子類別、銷售額、數量、折扣、利潤、運費、訂單優先級 |

---

## 工具與技術

| 工具 | 用途 |
|---|---|
| Python（pandas） | 資料清理、驗證、稽核報告 |
| MySQL | 維度建模、資料載入、分析 SQL |
| Power BI | 互動式儀表板與 KPI 視覺化 |
| GitHub | 版本控制與文件記錄 |

---

## 一、資料清理（Python）

### `01_raw_data_preview_cnt.py` — 原始資料稽核
- 生成完整稽核報告（Excel）：描述性統計、缺失值、唯一值計數、資料類型
- 輸出前 100 筆預覽及隨機 100 筆樣本（CSV）

### `02_clean_data_cnt.py` — 資料清理與驗證
- **日期格式**：統一不同格式（DD/MM/YYYY、DD-MM-YYYY）為標準 datetime
- **數值驗證**：移除貨幣符號/逗號，強制轉換為數值，錯誤記錄存 CSV
- **文字標準化**：移除口音符號（São Paulo → Sao Paulo）、修剪空白、統一首字大寫
- **資料品質檢查**：小數位數分析；產品 ID ↔ 產品名稱衝突偵測
- **缺失值處理**：刪除 `order_date` 為空的列；`discount` 及 `shipping_cost` 缺失補 0

### `03_clean_check_cnt.py` — 清理後驗證
- 對清理後資料重新執行完整稽核，確認所有問題已解決

---

## 二、資料庫設計（MySQL — 雪花綱要）

本專案採用完整**雪花綱要**，以正規化維度層級與中央事實表取代單一平面表格。

### 綱要圖

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

### 維度表說明

| 表格 | 說明 | 設計重點 |
|---|---|---|
| `dim_date` | 10 年日曆（2011–2020） | 預先生成，含年、季、月、星期幾、是否週末 |
| `dim_customer` | 唯一客戶 + 客群 | 複合唯一鍵（customer_name, segment） |
| `dim_region` → `dim_market` → `dim_country` → `dim_state` | 地理層級 | 正規化 4 層層級，含外鍵關聯 |
| `dim_category` → `dim_sub_category` → `dim_product` | 產品層級 | 用複合唯一鍵處理 1:N 的產品 ID ↔ 產品名稱衝突 |
| `fact_sales` | 交易層級事實 | 代理鍵（sales_id）；保留 staging 中的重複業務記錄 |

---

## 三、SQL Pipeline 與資料品質

### 載入與轉換

| 步驟 | 腳本 | 用途 |
|---|---|---|
| 1 | `01.create_import_staging_cnt.sql` | 建立 staging 表並載入清理後的 CSV |
| 2 | `02.check_staging_data_cnt.sql` | 驗證列/欄計數、唯一鍵、重複資料 |
| 3 | `03.create_import_dim_fact_cnt.sql` | 透過多表 INSERT 建立所有維度表與事實表 |

### 雙向資料核對

| 步驟 | 腳本 | 用途 |
|---|---|---|
| 4 | `04.check_staging_exists_fact_not.sql` | 找出 staging 有但 fact 沒有的記錄 |
| 5 | `05.check_fact_exists_staging_not.sql` | 找出 fact 有但 staging 沒有的記錄 |
| 6 | `08.staging_vs_fact_view.sql` | 跨層比對總計（列數、銷售額、數量、利潤） |

---
## 四、SQL 分析

### 主要商業問題

**哪些商品類別帶來最高的銷售額與利潤？**
```sql
SELECT category_name,
       ROUND(SUM(total_sales), 0)  AS sales,
       ROUND(SUM(total_profit), 0) AS profit,
       ROUND(AVG(profit_margin_pct), 1) AS avg_margin_pct
FROM vw_sales_summary
GROUP BY category_name
ORDER BY sales DESC;
```

**折扣如何影響獲利能力？**
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

## 五、Power BI 儀表板（3 頁）

### 第 1 頁：執行摘要
<img src="screenshot/bi01.png" alt="執行摘要儀表板" width="100%">

- **KPI 卡片**：銷售額（$4.30M）、利潤（$504K）、ROI（13.28%）、銷售額 YoY（+26.25%）、平均利潤率（5.00%）
- **銷售趨勢**：2013 vs 2014 月度比較，呈現季節性模式
- **前 10 大子類別**：銷售、利潤、利潤率表格（負利潤率以條件格式標記）
- **市場分布**：圓餅圖 — APAC（28%）、EU（24%）、US（17%）、LATAM（16%）
- **ABC 分析**：按銷售及利潤貢獻分類子類別

### 第 2 頁：產品表現
<img src="screenshot/bi02.png" alt="產品表現" width="100%">

- 類別盈利比較（科技 14%、辦公用品 14%、家具 7%）
- 子類別 YoY 銷售與利潤橫條圖（2011–2014）
- ABC Treemap 視覺化分類

### 第 3 頁：促銷影響
<img src="screenshot/bi03.png" alt="促銷影響" width="100%">

- **散點圖**：平均折扣率 vs 平均利潤率（以數量為氣泡大小）
- **折扣影響圖**：各折扣層級的銷售與利潤分布
- **子類別 ROI 排名**：從紙張（最高）到桌子（負 ROI）

---

## 主要洞察

### 類別表現

| 類別 | 銷售額 | 利潤率 | 評估 |
|---|---|---|---|
| 科技 | $4.74M | 14% | 核心增長引擎 — 最高銷售額與利潤率 |
| 辦公用品 | $3.79M | 14% | 穩定利潤來源 |
| 家具 | $4.11M | 7% | 高銷售量、低利潤率 — 需要定價審查 |

### 折扣影響

| 折扣區間 | 利潤率 | 評估 |
|---|---|---|
| 無折扣 | 25.32% | 最健康 |
| 低（0–10%） | 16.56% | 銷量與利潤的最佳平衡 |
| 中（11–30%） | 7.11% | 利潤微薄，謹慎使用 |
| 高（>30%） | **-40.65%** | 淨虧損，避免使用 |

---

## 業務建議

1. **折扣上限設為 10%** — 超過 30% 的折扣持續造成虧損
2. **審查家具成本結構** — 銷售額排第 2，但利潤率只有 7%
3. **停售或重新定價桌子** — 4 年持續負利潤率（-13%）
4. **加大科技產品投入** — 最強的收入與利潤率組合
5. **以類別專屬定價策略取代全面折扣政策**

---

## 專案結構

```
01_Superstore_Sales_Analysis/
│
├── data/                                          # 原始資料、清理後資料與稽核資料集
├── scripts/
│   ├── 01_raw_data_preview_cnt.py                 # 原始資料稽核
│   ├── 02_clean_data_cnt.py                       # 資料清理與驗證
│   └── 03_clean_check_cnt.py                      # 清理後驗證檢查
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

## 如何重現本專案

**前置需求**：Python 3.8+、MySQL 8.0+、Power BI Desktop

1. 從 [Kaggle](https://www.kaggle.com/datasets/laibaanwer/superstore-sales-dataset) 下載 `superstore.csv`
2. 執行 `python scripts/02_clean_data_cnt.py`
3. 依序（01 → 08）在 MySQL 執行 SQL 腳本
4. 在 Power BI Desktop 開啟 `superstore.pbix`，透過 `vw_sales_full` 連接 MySQL

---

## 授權條款

本專案採用 [MIT LICENSE](./LICENSE)  授權。
