import pandas as pd
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import nltk

try:
    nltk.data.find('sentiment/vader_lexicon')
except:
    nltk.download('vader_lexicon')

def demo():
    df = pd.DataFrame({'id':[1,2,3], 'text':["I love it","Not good","It's okay"]})
    sid = SentimentIntensityAnalyzer()
    df[['neg','neu','pos','compound']] = df['text'].apply(lambda t: pd.Series(sid.polarity_scores(str(t))))
    print(df)

if __name__ == '__main__':
    demo()