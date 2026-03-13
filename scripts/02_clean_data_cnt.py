import logging
from datetime import datetime
from pathlib import Path
import pandas as pd
import unicodedata

def remove_accents(text: str) -> str:
    """移除字串中的重音符號"""
    if text is None:
        return None
    return ''.join(
        c for c in unicodedata.normalize('NFKD', str(text))
        if not unicodedata.combining(c)
    )


# 工具函式
# 設定 logging 格式
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def is_ascii(s: str) -> bool:
    """判斷字串是否為 ASCII（主要英文）"""
    try:
        s.encode("ascii")
        return True
    except UnicodeEncodeError:
        return False

# 輸出 DataFrame 中所有文字欄位的唯一值
def export_unique_text_values(df: pd.DataFrame, base_dir: Path):
    """輸出文字欄位唯一值（寬格式：每個欄位一欄）"""
    timestamp = datetime.now().strftime("%Y%m%d")
    output_file = base_dir / "output" / "02_clean_preview" / f"superstore_unique_text_{timestamp}.csv"

    text_cols = df.select_dtypes(include="object").columns
    unique_values = {}
    for col in text_cols:
        values = (
            df[col]
            .dropna()
            .astype(str)
            .str.strip()
            .str.replace(r"\s+", " ", regex=True)  # 合併多餘空格
            .unique()
        )
        unique_values[col] = sorted(values)
        logging.info(f"🔍 {col}: 共 {len(unique_values[col])} 個唯一值")

    # 寬格式組裝（不同長度自動補空）
    unique_df = pd.DataFrame({k: pd.Series(v) for k, v in unique_values.items()})

    try:
        unique_df.to_csv(output_file, index=False, encoding="utf-8")
        logging.info(f"✅ 已輸出唯一文字欄位（寬格式）至 {output_file}")
    except Exception as e:
        logging.error(f"❌ 輸出唯一值 CSV 失敗: {e}")

# 主清理函式
def clean_superstore(base_dir: Path):
    input_file = base_dir / "data" / "superstore.csv"
    timestamp = datetime.now().strftime("%Y%m%d")
    output_file = base_dir / "output" / "03_clean_data" / f"superstore_clean_{timestamp}.csv"

    # 讀取原始資料
    try:
        df = pd.read_csv(input_file, encoding="utf-8")
        logging.info(f"✅ 成功讀取 {input_file}, 共 {len(df)} 筆資料")
    except Exception as e:
        logging.error(f"❌ 讀取檔案失敗: {e}")
        logging.error("請確認檔案路徑或編碼 utf-8 ")
        return None
    logging.info(f"欄位: {list(df.columns)}")

    # 日期欄位轉換
    date_cols = ["order_date", "ship_date"]
    for col in date_cols:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip().str.replace(r"[-.]", "/", regex=True)
            try:
                df[col] = pd.to_datetime(df[col], dayfirst=True, errors="coerce")
            except Exception:
                df[col] = pd.to_datetime(df[col], format="%d/%m/%Y", errors="coerce")
            logging.info(f"📅 已轉換日期欄位: {col}, NaT 數量 {df[col].isna().sum()}")

    # 數值欄位型態檢查
    num_cols = ["sales", "profit", "discount", "quantity", "shipping_cost"]
    for col in num_cols:
        if col in df.columns:
            before_na = df[col].isna().sum()

            # 先清理字串中的逗號、貨幣符號等
            df[col] = (
                df[col]
                .astype(str)
                .str.strip()
                .str.replace(",", "", regex=False)
                .str.replace(r"[^\d.\-]", "", regex=True)
            )

            df[col] = pd.to_numeric(df[col], errors="coerce")
            after_na = df[col].isna().sum()
            new_errors = after_na - before_na
            logging.info(f"🔢 {col}: 新增錯誤值 {new_errors} 筆, 總 NaN {after_na} 筆")

            # 輸出錯誤報告 CSV
            bad_mask = df[col].isna()
            if bad_mask.any():
                report_path = base_dir / "output" / "02_clean_preview" / f"{col}_invalid_{timestamp}.csv"
                df.loc[bad_mask, [col]].to_csv(report_path, index=False, encoding="utf-8")
                logging.info(f"📝 已輸出 {col} 錯誤報告: {report_path}")

# ========= 1) 數值欄位小數位數統計 =========
    # 只對實際存在的數值欄位做統計
    numeric_existing = [c for c in num_cols if c in df.columns]
    decimal_summary = []

    for col in numeric_existing:
        # 捨棄 NaN，只看有值的資料
        s = df[col].dropna()

        if s.empty:
            continue

        # 轉成字串處理小數位數，避免 float 表示問題
        str_vals = s.map(lambda x: format(x, "f"))

        # 小數前後位數
        int_digits = str_vals.map(
            lambda x: len(x.split(".")[0].replace("-", ""))
        )
        dec_digits = str_vals.map(
            lambda x: len(x.split(".")[1].rstrip("0")) if "." in x else 0
        )

        decimal_summary.append({
            "column": col,
            "max_int_digits": int_digits.max(),
            "max_decimal_digits": dec_digits.max(),
            "min_int_digits": int_digits.min(),
            "min_decimal_digits": dec_digits.min(),
        })

    if decimal_summary:
        dec_df = pd.DataFrame(decimal_summary)
        dec_path = base_dir / "output" / "02_clean_preview" / f"numeric_decimal_summary_{timestamp}.csv"
        dec_df.to_csv(dec_path, index=False, encoding="utf-8")
        logging.info(f"📏 已輸出數值欄位小數位數統計: {dec_path}")

    # ========= 2) 檢查 product_id 是否對應多個 product_name =========
    if "product_id" in df.columns and "product_name" in df.columns:
        # 只看有值的 product_id
        tmp = (
            df[["product_id", "product_name"]]
            .dropna(subset=["product_id"])
            .drop_duplicates()
        )

        # 每個 product_id 有多少個不同的 product_name
        counts = (
            tmp.groupby("product_id")["product_name"]
            .nunique()
            .reset_index(name="name_count")
        )

        # 篩出 name_count > 1 的 product_id
        conflict_ids = counts[counts["name_count"] > 1]["product_id"]

        if not conflict_ids.empty:
            conflict_df = tmp[tmp["product_id"].isin(conflict_ids)].sort_values(
                ["product_id", "product_name"]
            )
            conflict_path = base_dir / "output" / "02_clean_preview" / f"product_id_name_conflicts_{timestamp}.csv"
            conflict_df.to_csv(conflict_path, index=False, encoding="utf-8")
            logging.warning(
                f"⚠️ 發現 {len(conflict_ids)} 個 product_id 對應多個 product_name，已輸出報表: {conflict_path}"
            )
        else:
            logging.info("✅ 所有 product_id 僅對應一個 product_name")

            
    # 字串清理+去重音符號
    str_cols = df.select_dtypes(include="object").columns
    for col in str_cols:
        before = df[col].copy()
        df[col] = (
            df[col]
            .astype(str)
            .str.strip()
            .str.replace(r"[\r\n]+", " ", regex=True) # 去掉換行符號
            .str.replace(r"\s+", " ", regex=True) # 合併多餘空格
            .apply(remove_accents) # 去重音符號
        )
        changed = (before != df[col]).sum()
        if changed:
            logging.info(f"✂️ 去除空白: {col}, 修正 {changed} 筆 / 共 {len(df)} 筆")

    # 特定欄位大寫化
    for col in ["order_id", "product_id", "market", "region"]:
        if col in df.columns:
            before = df[col].copy()
            df[col] = df[col].astype(str).str.upper()
            changed = (before != df[col]).sum()
            logging.info(f"🔠 大寫化 {col}: 修正 {changed} 筆")

    # Proper Case（僅 ASCII）
    for col in str_cols:
        if col not in ["order_id", "product_id", "market", "region"]:
            before = df[col].copy()
            df[col] = df[col].apply(lambda x: x.title() if is_ascii(x) else x)
            changed = (before != df[col]).sum()
            if changed:
                logging.info(f"🅿️ Proper Case（ASCII）{col}: 修正 {changed} 筆")

    # 缺失值處理
    before_drop = len(df)
    df = df.dropna(subset=["order_date"])
    dropped = before_drop - len(df)
    logging.info(f"🗑️ 因缺失 order_date 刪除列: {dropped} 筆 ({dropped/before_drop:.2%})")

    if "discount" in df.columns:
        missing_discount = df["discount"].isna().sum()
        df["discount"] = df["discount"].fillna(0)
        logging.info(f"🩹 填補 discount: {missing_discount} 筆 → 0")

    if "shipping_cost" in df.columns:
        missing_shipcost = df["shipping_cost"].isna().sum()
        df["shipping_cost"] = df["shipping_cost"].fillna(0)
        logging.info(f"🩹 填補 shipping_cost: {missing_shipcost} 筆 → 0")

    # 輸出清理後的 CSV
    try:
        df.to_csv(output_file, index=False, encoding="utf-8")
        logging.info(f"✅ 清理完成，已輸出至 {output_file}")
    except Exception as e:
        logging.error(f"❌ 輸出檔案失敗: {e}")

    # 額外輸出唯一文字欄位
    export_unique_text_values(df, base_dir)

    return df

if __name__ == "__main__":
    BASE_DIR = Path(__file__).resolve().parents[1]
    df = clean_superstore(BASE_DIR)


