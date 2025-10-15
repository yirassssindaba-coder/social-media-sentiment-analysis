# src/utils.py
import re

def clean_text(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r"http\S+", "", text)            # remove urls
    text = re.sub(r"@\w+", "", text)               # remove mentions
    text = re.sub(r"[^A-Za-z0-9\s']", " ", text)   # keep basic chars
    return " ".join(text.split()).lower()