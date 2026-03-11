import pandas as pd
from pathlib import Path
from datetime import datetime



# 專案根目錄
BASE_DIR = Path(__file__).resolve().parents[1]
input_file = BASE_DIR / "data" / "superstore_clean_20251229.csv"

# 讀取原始資料
df = pd.read_csv(input_file, encoding="utf-8")

def data_audit(df, base_dir=Path.cwd()):

    # 基本 info
    print("\n基本資訊 (df.info):")
    df.info()

    # 前十筆資料
    print("\n前十筆資料 (df.head):")
    print(df.head(10))

    # 建立 timestamp
    timestamp = datetime.now().strftime("%Y%m%d")

    # 動態檔名
    output_file = base_dir / "data" / f"clean_superstore_report_{timestamp}.xlsx"

    # 輸出到 Excel
    with pd.ExcelWriter(output_file, engine="xlsxwriter") as writer:
        df.describe(include='all').to_excel(writer, sheet_name="Describe")
        df.isnull().sum().to_frame("Missing").to_excel(writer, sheet_name="Missing")
        df.nunique().to_frame("Unique").to_excel(writer, sheet_name="Unique")
        df.dtypes.to_frame("Dtypes").to_excel(writer, sheet_name="Dtypes")
        df.head(100).to_excel(writer, sheet_name="Preview_100", index=False)
        df.sample(100, random_state=42).to_excel(writer, sheet_name="Sample_100", index=False)

    print(f"✅ 已輸出完整審核報告至 {output_file}")

    
    # 額外輸出 CSV
    preview_csv = base_dir / "data" / f"clean_superstore_preview_100_{timestamp}.csv"
    sample_csv = base_dir / "data" / f"clean_superstore_sample_100_{timestamp}.csv"

    df.head(100).to_csv(preview_csv, index=False, encoding="utf-8")
    df.sample(100, random_state=42).to_csv(sample_csv, index=False, encoding="utf-8")

    print(f"✅ 已輸出前100列至 {preview_csv}")
    print(f"✅ 已輸出隨機100列至 {sample_csv}")


data_audit(df, BASE_DIR)