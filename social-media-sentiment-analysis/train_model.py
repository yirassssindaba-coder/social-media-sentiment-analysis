"""
train_model.py
- Expects CSV with columns: text_clean and label
- Saves model pipeline to social-media-sentiment-analysis/models/model_pipeline.joblib
"""
import argparse
import os
import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import joblib

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="processed csv with text_clean and label")
    parser.add_argument("--output", default="social-media-sentiment-analysis/models/model_pipeline.joblib")
    parser.add_argument("--test-size", type=float, default=0.2)
    args = parser.parse_args()

    df = pd.read_csv(args.input, encoding="utf-8")
    if "text_clean" not in df.columns:
        raise SystemExit("Input must contain 'text_clean' column.")
    if "label" not in df.columns:
        raise SystemExit("Input must contain 'label' column for supervised training.")

    X = df["text_clean"].astype(str)
    y = df["label"].astype(str)

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=args.test_size, random_state=42, stratify=y)

    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1,2), max_features=20000)),
        ("clf", LogisticRegression(max_iter=1000, class_weight="balanced"))
    ])

    pipeline.fit(X_train, y_train)

    preds = pipeline.predict(X_test)
    print("Classification report on test set:")
    print(classification_report(y_test, preds))

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    joblib.dump(pipeline, args.output)
    print("Saved model pipeline to", args.output)

if __name__ == "__main__":
    main()