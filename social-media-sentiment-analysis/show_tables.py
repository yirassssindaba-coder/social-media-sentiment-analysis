#!/usr/bin/env python3
"""
social-media-sentiment-analysis/show_tables.py

Load CSVs (raw + processed), save CSV/HTML snapshots to results/,
and optionally print to console.

Usage (from repo root):
  python social-media-sentiment-analysis/show_tables.py --head 200 --print
"""
import argparse
from pathlib import Path
from datetime import datetime
import pandas as pd
import sys

ROOT = Path.cwd()
SM_DIR = ROOT / "social-media-sentiment-analysis"
RAW_PATH = SM_DIR / "data" / "raw" / "tweets_scraped.csv"
PROC_PATH = SM_DIR / "data" / "processed" / "tweets_clean.csv"
OUT_DIR = SM_DIR / "results"

def load_or_message(path: Path, msg: str) -> pd.DataFrame:
    if path.exists():
        try:
            return pd.read_csv(path)
        except Exception as e:
            return pd.DataFrame({"error": [f"Failed to read {path.name}: {e}"]})
    else:
        return pd.DataFrame({"info": [msg]})

def save_snapshots(df: pd.DataFrame, name_prefix: str, head: int, out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    csv_path = out_dir / f"{name_prefix}_head{head}_{ts}.csv"
    html_path = out_dir / f"{name_prefix}_head{head}_{ts}.html"
    df.head(head).to_csv(csv_path, index=False)
    df.head(head).to_html(html_path, index=False)
    return csv_path, html_path

def main():
    p = argparse.ArgumentParser(description="Load and save tables for social-media-sentiment-analysis CSVs")
    p.add_argument("--head", type=int, default=200, help="number of rows to include in snapshots / display")
    p.add_argument("--print", action="store_true", help="print tables to console (text)")
    args = p.parse_args()

    pd.set_option("display.max_columns", 50)
    pd.set_option("display.max_colwidth", 200)

    df_raw = load_or_message(RAW_PATH, "tweets_scraped.csv not found. Run create_sample_data.py")
    df_proc = load_or_message(PROC_PATH, "tweets_clean.csv not found. Run preprocess.py / train_quick.py")

    # Save snapshots
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    raw_csv, raw_html = save_snapshots(df_raw, "tweets_scraped", args.head, OUT_DIR)
    proc_csv, proc_html = save_snapshots(df_proc, "tweets_clean", args.head, OUT_DIR)

    # Print short summary
    print(f"Raw file:  {RAW_PATH} -> rows: {len(df_raw)}")
    print(f"Proc file: {PROC_PATH} -> rows: {len(df_proc)}")
    print()
    print("Saved snapshots:")
    print(f" - {raw_csv}")
    print(f" - {raw_html}")
    print(f" - {proc_csv}")
    print(f" - {proc_html}")
    print()

    if args.print:
        # Print tables to console in readable text form
        print("=== Raw scraped tweets (head) ===")
        try:
            print(df_raw.head(args.head).to_string(index=False))
        except Exception:
            print(df_raw.head(args.head).to_string())
        print()
        print("=== Processed / cleaned tweets (head) ===")
        try:
            print(df_proc.head(args.head).to_string(index=False))
        except Exception:
            print(df_proc.head(args.head).to_string())
        print()

    return 0

if __name__ == "__main__":
    sys.exit(main())