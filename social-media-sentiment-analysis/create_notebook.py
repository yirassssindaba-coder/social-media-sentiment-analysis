import nbformat as nbf
nb = nbf.v4.new_notebook()
code = """import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import joblib
import os

print('pandas', pd.__version__)
nltk.download('vader_lexicon', quiet=True)
sid = SentimentIntensityAnalyzer()
print('VADER example:', sid.polarity_scores('I love this product'))

# If a trained pipeline exists, load and run a few examples
model_path = 'social-media-sentiment-analysis/models/model_pipeline.joblib'
if os.path.exists(model_path):
    print('\\nLoaded model pipeline from', model_path)
    pipe = joblib.load(model_path)
    samples = [
        'I absolutely love this! Highly recommend.',
        'This is ok, nothing special.',
        'Terrible experience, will never buy again.'
    ]
    preds = pipe.predict(samples)
    for s,p in zip(samples, preds):
        print(f'[{p}]', s)
else:
    print('\\nNo trained model at', model_path, '— run training pipeline to add predictions.')
"""
nb['cells'] = [nbf.v4.new_code_cell(code)]
out_path = "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
import os
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w", encoding="utf-8") as f:
    nbf.write(nb, f)
print("Notebook written:", out_path)