import pandas as pd
from pathlib import Path
from datetime import datetime


def data_audit(df, base_dir=Path.cwd()):

    # 基本 info
    print("\n基本資訊 (df.info):")
    df.info()

    # 前十筆資料
    print("\n前十筆資料 (df.head):")
    print(df.head(10))

    # 建立 timestamp
    timestamp = datetime.now().strftime("%Y%m%d")

    # 確保輸出目錄存在
    output_dir = base_dir / "output" / "01_raw_preview"
    output_dir.mkdir(parents=True, exist_ok=True)

    # 動態檔名
    output_file = base_dir / "output" / "01_raw_preview" / f"raw_superstore_report_{timestamp}.xlsx"

    # sample 加保護
    sample_size = min(100, len(df))

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
    preview_csv = base_dir / "output" / "01_raw_preview" / f"raw_superstore_preview_100_{timestamp}.csv"
    sample_csv = base_dir / "output" / "01_raw_preview" / f"raw_superstore_sample_100_{timestamp}.csv"

    df.head(100).to_csv(preview_csv, index=False, encoding="utf-8")
    df.sample(100, random_state=42).to_csv(sample_csv, index=False, encoding="utf-8")

    print(f"✅ 已輸出前100列至 {preview_csv}")
    print(f"✅ 已輸出隨機100列至 {sample_csv}")

# 加上 __main__ 保護
if __name__ == "__main__":
    # 專案根目錄
    BASE_DIR = Path(__file__).resolve().parents[1]
    input_file = BASE_DIR / "data" / "superstore.csv"
    # 讀取原始資料
    df = pd.read_csv(input_file, encoding="utf-8")
    print(f"✅ 成功讀取，共 {len(df)} 筆資料")

    data_audit(df, BASE_DIR)