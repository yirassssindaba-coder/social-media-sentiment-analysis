import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

print("pandas", pd.__version__)
nltk.download("vader_lexicon", quiet=True)
sid = SentimentIntensityAnalyzer()
print(sid.polarity_scores("I love this product"))