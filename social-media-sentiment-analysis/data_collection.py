"""
data_collection.py

Usage:
- If you already have a CSV with columns 'text' and (optional) 'label', use that.
- Otherwise run: python data_collection.py --mode scrape --query "your keyword" --limit 500 --out data/raw/tweets_scraped.csv
"""
import argparse
import os
import pandas as pd
from tqdm import tqdm

def fetch_with_snscrape(query, limit=500, out_csv="social-media-sentiment-analysis/data/raw/tweets_scraped.csv"):
    try:
        import snscrape.modules.twitter as sntwitter
    except Exception:
        raise RuntimeError("snscrape is required for scraping. Install with: pip install snscrape")
    rows = []
    for i, tweet in enumerate(tqdm(sntwitter.TwitterSearchScraper(query).get_items())):
        if i >= limit:
            break
        rows.append({
            "date": tweet.date.isoformat(),
            "id": tweet.id,
            "user": tweet.user.username,
            "text": tweet.content,
            "likeCount": tweet.likeCount
        })
    os.makedirs(os.path.dirname(out_csv), exist_ok=True)
    df = pd.DataFrame(rows)
    df.to_csv(out_csv, index=False, encoding="utf-8")
    print("Saved:", out_csv)
    return out_csv

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["csv", "scrape"], default="csv")
    parser.add_argument("--csv", help="Path to CSV with columns text,label (if mode=csv)")
    parser.add_argument("--query", help="Search query for snscrape (if mode=scrape)", default="product review")
    parser.add_argument("--limit", type=int, default=500)
    parser.add_argument("--out", default="social-media-sentiment-analysis/data/raw/tweets_scraped.csv")
    args = parser.parse_args()

    if args.mode == "csv":
        if not args.csv:
            raise SystemExit("Provide --csv path when mode=csv")
        if not os.path.exists(args.csv):
            raise SystemExit(f"CSV not found: {args.csv}")
        print("Using existing CSV:", args.csv)
    else:
        fetch_with_snscrape(args.query, limit=args.limit, out_csv=args.out)

if __name__ == "__main__":
    main()