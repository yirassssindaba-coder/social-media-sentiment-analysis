"""
evaluate.py
- Load pipeline and dataset, produce classification report & confusion matrix figure.
"""
import argparse
import os
import pandas as pd
import joblib
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--input", required=True, help="processed csv with text_clean and label")
    parser.add_argument("--out-dir", default="social-media-sentiment-analysis/figures")
    args = parser.parse_args()

    model = joblib.load(args.model)
    df = pd.read_csv(args.input, encoding="utf-8")
    X = df["text_clean"].astype(str)
    y = df["label"].astype(str)

    preds = model.predict(X)
    print("Classification Report:")
    print(classification_report(y, preds))

    labels = sorted(list(set(y)))
    cm = confusion_matrix(y, preds, labels=labels)
    os.makedirs(args.out_dir, exist_ok=True)
    plt.figure(figsize=(6,5))
    sns.heatmap(cm, annot=True, fmt="d", xticklabels=labels, yticklabels=labels, cmap="Blues")
    plt.xlabel("Predicted")
    plt.ylabel("True")
    p = os.path.join(args.out_dir, "confusion_matrix.png")
    plt.tight_layout()
    plt.savefig(p)
    print("Saved confusion matrix to", p)

if __name__ == "__main__":
    main()