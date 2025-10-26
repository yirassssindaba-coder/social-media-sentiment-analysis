"""
visualize.py — lightweight helpers for plotting
"""
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import os

def plot_label_distribution(df, label_col="label", out="social-media-sentiment-analysis/figures/label_dist.png"):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    plt.figure(figsize=(6,4))
    sns.countplot(y=df[label_col], order=df[label_col].value_counts().index)
    plt.title("Label distribution")
    plt.tight_layout()
    plt.savefig(out)
    print("Saved label distribution to", out)

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python visualize.py social-media-sentiment-analysis/data/processed/tweets_clean.csv")
    else:
        df = pd.read_csv(sys.argv[1], encoding="utf-8")
        plot_label_distribution(df)