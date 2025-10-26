"""
preprocess.py
- Input CSV must have column 'text'. If 'label' exists, it is preserved.
- Outputs cleaned CSV to social-media-sentiment-analysis/data/processed/tweets_clean.csv (default).
"""
import argparse
import os
import re
import pandas as pd

def clean_text(s: str) -> str:
    if not isinstance(s, str):
        return ""
    s = s.lower()
    s = re.sub(r"http\S+", "", s)
    s = re.sub(r"@\w+", "", s)
    s = re.sub(r"#", "", s)
    s = re.sub(r"[^a-z0-9\s']", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="raw csv path with 'text' column")
    parser.add_argument("--output", default="social-media-sentiment-analysis/data/processed/tweets_clean.csv")
    args = parser.parse_args()

    df = pd.read_csv(args.input, encoding="utf-8")
    if "text" not in df.columns:
        raise SystemExit("Input CSV must have a 'text' column")
    df["text_clean"] = df["text"].astype(str).apply(clean_text)
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    df.to_csv(args.output, index=False, encoding="utf-8")
    print("Wrote cleaned data to", args.output)

if __name__ == "__main__":
    main()