```markdown
# social-media-sentiment-analysis — README (ringkas, PowerShell-safe)

Deskripsi singkat
- Project demo: Analisis Sentimen Media Sosial (pipeline minimal + 1 notebook final).
- Tujuan README ini: memberi langkah jelas dari setup environment, membuat sample data, menjalankan pipeline, membuat/menjalankan notebook final, sampai commit ke Git — semua PowerShell-safe.

Catatan penting sebelum mulai
- Jalankan perintah dari root repository (contoh): `C:\Users\ASUS\Desktop\python-project`
- Gunakan virtual environment (rekomendasi: `.venv` di root).
- Jangan paste blok Python multi-line langsung ke PowerShell prompt — simpan ke file `.py` lalu jalankan `python script.py`, atau masuk REPL `python` lalu paste.
- Saat venv aktif, jangan gunakan `pip install --user` (akan error). Gunakan `python -m pip install ...`.

Prasyarat
- Python 3.8 - 3.12 direkomendasikan (Python 3.14 mungkin kompatibel namun beberapa paket belum stabil).
- Git, koneksi internet (paket & NLTK resource).

Struktur file rekomendasi (folder `social-media-sentiment-analysis`)
- create_notebook.py
- create_sample_data.py
- data_collection.py (opsional)
- preprocess.py
- train_model.py
- evaluate.py
- visualize.py (opsional)
- requirements.txt
- social-media-sentiment-analysis.ipynb (final notebook — commit setelah dieksekusi)
- data/ (ignored)
- models/ (ignored kecuali model kecil ingin di-commit)
- figures/ (opsional)
- README.md (lokal folder)

Tambahkan ke `.gitignore` (jika belum):
```
.venv/
venv/
social-media-sentiment-analysis/data/
social-media-sentiment-analysis/models/
.ipynb_checkpoints/
```

1) Setup environment (PowerShell)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# buat venv di root (jika belum)
py -3 -m venv .venv

# aktifkan venv (PowerShell)
. .\.venv\Scripts\Activate.ps1

# upgrade pip & install dependencies (di dalam venv — tanpa --user)
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r social-media-sentiment-analysis\requirements.txt

# jika tidak ada requirements.txt, minimal:
python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
```

2) Buat sample data (direkomendasikan, untuk pengujian cepat)
- Gunakan generator Python (lebih mudah daripada paste CSV panjang):
```powershell
python .\social-media-sentiment-analysis\create_sample_data.py
# file hasil: social-media-sentiment-analysis\data\raw\tweets_scraped.csv
```
- Atau copy `sample_tweets.csv` (ringkas) ke `data/raw/tweets_scraped.csv`.

3) Jalankan pipeline (preprocess → train → evaluate)
```powershell
python .\social-media-sentiment-analysis\preprocess.py --input .\social-media-sentiment-analysis\data\raw\tweets_scraped.csv --output .\social-media-sentiment-analysis\data\processed\tweets_clean.csv

python .\social-media-sentiment-analysis\train_model.py --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv --output .\social-media-sentiment-analysis\models\model_pipeline.joblib

python .\social-media-sentiment-analysis\evaluate.py --model .\social-media-sentiment-analysis\models\model_pipeline.joblib --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
```

4) Buat / overwrite notebook final (1 code cell) — helper nbformat
- File `social-media-sentiment-analysis/create_notebook.py` menulis notebook final (satu code cell).
- Jalankan:
```powershell
python .\social-media-sentiment-analysis\create_notebook.py
# menulis: social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
```

5) Eksekusi notebook agar outputs tersimpan (nbconvert)
- Jalankan dari repo root (direkomendasikan):
```powershell
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```
- Jika Anda berada di dalam folder `social-media-sentiment-analysis`, ganti path menjadi `"social-media-sentiment-analysis.ipynb"`.

6) Tambah, commit, push ke Git (PowerShell)
- Sebelum push: selalu sinkronkan dengan remote agar tidak terjadi penolakan (rejected) karena remote lebih maju.
```powershell
# Pastikan berada di root repo
git fetch origin
git checkout main

# Tarik remote lalu rebase (direkomendasikan)
git pull --rebase origin main

# Jika pull/rebase sukses, tambahkan file dan push
git add social-media-sentiment-analysis\create_notebook.py
git add social-media-sentiment-analysis\create_sample_data.py
git add social-media-sentiment-analysis\preprocess.py
git add social-media-sentiment-analysis\train_model.py
git add social-media-sentiment-analysis\evaluate.py
git add social-media-sentiment-analysis\visualize.py
git add social-media-sentiment-analysis\requirements.txt
git add social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb

git commit -m "chore: add social-media-sentiment-analysis pipeline and final executed notebook"
git push origin main
```
- Jika `git push` menolak (rejected): jalankan `git pull --rebase origin main`, selesaikan konflik jika ada, lalu `git push origin main`.
- Jangan gunakan `git push --force` kecuali Anda paham risikonya.

Troubleshooting umum
- WinError 32 (file in use) saat pip install: tutup terminal/editor/Jupyter; `Get-Process *jupyter*` untuk cek; hentikan proses dengan `Stop-Process -Id <PID>` (tanpa tanda `<`/`>`). Jika masih bermasalah restart Windows lalu ulangi instal.
- Kesalahan `--user` saat venv aktif: jangan pakai `--user`.
- nbconvert "pattern matched no files": pastikan path notebook sesuai terhadap current working directory (CWD).
- snscrape error (FileFinder.find_module): coba `python -m pip install --upgrade snscrape` atau install dari GitHub; jika tetap bermasalah gunakan sample CSV atau buat venv dengan Python 3.11/3.12.

Notebook — isi code cell (satu-satunya code cell di final notebook)
- Simpan file create_notebook.py agar ia menulis notebook berisi kode di bawah.
- Kode ini sudah diperbaiki agar:
  - mencari model di beberapa lokasi relatif (mencegah path mismatch saat nbconvert),
  - menampilkan instruksi bila model belum ada,
  - menggunakan ASCII characters untuk menghindari encoding artifacts.
```python
import sys
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import joblib
from pathlib import Path
import os

print('python', sys.version.split()[0], 'pandas', pd.__version__)

# Ensure NLTK VADER resource available
nltk.download('vader_lexicon', quiet=True)
sid = SentimentIntensityAnalyzer()
print('VADER example:', sid.polarity_scores('I love this product'))

# Try several plausible model locations (relative paths)
candidates = [
    Path('models/model_pipeline.joblib'),                                      # if cwd is notebook folder
    Path('social-media-sentiment-analysis/models/model_pipeline.joblib'),     # if cwd is repo root
    Path('..') / 'models' / 'model_pipeline.joblib',
    Path('..') / 'social-media-sentiment-analysis' / 'models' / 'model_pipeline.joblib'
]

model_path = None
for p in candidates:
    if p.exists():
        model_path = p
        break

if model_path:
    try:
        print('\\nLoaded model pipeline from', model_path)
        pipe = joblib.load(model_path)
        samples = [
            'I absolutely love this! Highly recommend.',
            'This is ok, nothing special.',
            'Terrible experience, will never buy again.'
        ]
        preds = pipe.predict(samples)
        for s, p in zip(samples, preds):
            print(f'[{p}]', s)
    except Exception as e:
        print('Error loading/using model pipeline:', e)
        print('To retrain: python social-media-sentiment-analysis\\train_model.py --input social-media-sentiment-analysis\\data\\processed\\tweets_clean.csv')
else:
    print('\\nNo trained model found. Checked these locations:')
    for p in candidates:
        print(' -', p)
    print('\\nTo train and produce a model file, run (from repo root):')
    print('  python social-media-sentiment-analysis\\preprocess.py --input social-media-sentiment-analysis\\data\\raw\\tweets_scraped.csv --output social-media-sentiment-analysis\\data\\processed\\tweets_clean.csv')
    print('  python social-media-sentiment-analysis\\train_model.py --input social-media-sentiment-analysis\\data\\processed\\tweets_clean.csv --output social-media-sentiment-analysis\\models\\model_pipeline.joblib')
```

Contoh output notebook (hasil eksekusi yang diharapkan)
```
pandas 2.3.3
VADER example: {'neg': 0.0, 'neu': 0.323, 'pos': 0.677, 'compound': 0.6369}

No trained model at social-media-sentiment-analysis/models/model_pipeline.joblib - run training pipeline to add predictions.
```
> Catatan: jika Anda melihat `â€”` atau karakter aneh di tempat tanda hubung panjang, pastikan file .py/.ipynb disimpan dengan encoding UTF-8 (biasanya default editor modern). Untuk menghindari masalah, README dan kode menggunakan ASCII hyphen (-) atau double hyphen (--).

Tambahan / Safety tips
- Buat branch backup jika ragu sebelum rebase/merge:
```powershell
git branch backup-before-sync
```
- Gunakan `git pull --rebase origin main` untuk menjaga riwayat linear dan memudahkan push.
- Jika Anda ingin saya membuat skrip PowerShell `manage_social_notebook.ps1` yang mengotomatiskan alur ini non-interactive, beri tahu dan saya buatkan.

---
```
