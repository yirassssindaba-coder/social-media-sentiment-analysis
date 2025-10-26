# create_sample_data.py
# Generates a small labeled CSV dataset for quick testing:
# Result: social-media-sentiment-analysis/data/raw/tweets_scraped.csv
#
# Usage (from repo root):
#   . .venv\Scripts\Activate.ps1   # activate venv (PowerShell)
#   python .\social-media-sentiment-analysis\create_sample_data.py

import csv
from pathlib import Path

OUT = Path("social-media-sentiment-analysis/data/raw/tweets_scraped.csv")
OUT.parent.mkdir(parents=True, exist_ok=True)

# Clean, human-readable sample sentences by label
positive = [
    "I love this product",
    "Absolutely fantastic, highly recommend",
    "Works great and arrived quickly",
    "Exceeded my expectations",
    "Very satisfied with the purchase",
    "Excellent quality",
    "Five stars",
    "Would buy again",
    "Great value for money",
    "Superb craftsmanship",
]

neutral = [
    "It's okay, not great",
    "Average product",
    "Neither good nor bad",
    "Works as expected",
    "Not much to say",
    "Decent for the price",
    "Neutral feelings about this",
    "Fairly ordinary item",
    "Meh, it's fine",
    "Nothing special",
]

negative = [
    "Terrible experience, do not buy",
    "Broke after first use",
    "Very disappointed",
    "Poor quality and bad service",
    "Not worth the money",
    "Would not recommend",
    "Awful product",
    "Stopped working quickly",
    "Bad customer support",
    "Regret this purchase",
]

# Build rows by repeating lists to reach ~200 rows (or adjust as needed)
rows = []
for i in range(20):  # 10 * 20 = 200 rows
    for s in positive:
        rows.append((s, "positive"))
    for s in neutral:
        rows.append((s, "neutral"))
    for s in negative:
        rows.append((s, "negative"))

# Optional: shuffle to mix labels (can uncomment if you want randomness)
# import random
# random.shuffle(rows)

with OUT.open("w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["text", "label"])
    writer.writerows(rows)

print(f"Wrote sample CSV to: {OUT} ({len(rows)} rows)")