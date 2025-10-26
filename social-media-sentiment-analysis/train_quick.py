# Quick training script for local testing
# - Reads social-media-sentiment-analysis/data/raw/tweets_scraped.csv
# - If not present, instructs to run create_sample_data.py first
# - Trains TF-IDF + LogisticRegression and saves pipeline to:
#     social-media-sentiment-analysis/models/model_pipeline.joblib
# Usage (from repo root, with venv active):
#   python .\social-media-sentiment-analysis\train_quick.py

import os
import sys
from pathlib import Path

import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import joblib

ROOT = Path("social-media-sentiment-analysis")
RAW = ROOT / "data" / "raw" / "tweets_scraped.csv"
PROCESSED = ROOT / "data" / "processed" / "tweets_clean.csv"
MODEL_OUT = ROOT / "models" / "model_pipeline.joblib"

def simple_preprocess_text(s):
    if not isinstance(s, str):
        return ""
    import re
    s = s.lower()
    s = re.sub(r"http\S+", "", s)
    s = re.sub(r"@\w+", "", s)
    s = re.sub(r"#", "", s)
    s = re.sub(r"[^a-z0-9\s']", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def main():
    if not RAW.exists():
        print(f"Input CSV not found: {RAW}")
        print("Run create_sample_data.py first or place a CSV at the path above.")
        sys.exit(1)

    print("Loading raw data:", RAW)
    df = pd.read_csv(RAW, encoding="utf-8")
    if "text" not in df.columns or "label" not in df.columns:
        print("CSV must have columns: text,label")
        sys.exit(1)

    df["text_clean"] = df["text"].astype(str).apply(simple_preprocess_text)
    os.makedirs(MODEL_OUT.parent, exist_ok=True)

    X = df["text_clean"]
    y = df["label"].astype(str)

    # small train/test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1,2), max_features=10000)),
        ("clf", LogisticRegression(max_iter=1000, class_weight="balanced"))
    ])

    print("Training pipeline...")
    pipeline.fit(X_train, y_train)

    print("Evaluating on test set...")
    preds = pipeline.predict(X_test)
    print(classification_report(y_test, preds))

    joblib.dump(pipeline, MODEL_OUT)
    print("Saved model pipeline to:", MODEL_OUT)

if __name__ == "__main__":
    main()