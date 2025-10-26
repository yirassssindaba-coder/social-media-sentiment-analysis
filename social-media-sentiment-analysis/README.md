```markdown
# social-media-sentiment-analysis — Sample Data (clean & copyable)

Deskripsi singkat
- Project: Analisis Sentimen Media Sosial — demo pipeline minimal.
- Tujuan README ini: jelaskan langkah dari "set lokasi" hingga "commit ke Git" secara PowerShell‑safe.
- Hasil akhir yang diharapkan: folder `social-media-sentiment-analysis` berisi 1 notebook final
  `social-media-sentiment-analysis.ipynb` (1 code cell) yang sudah dieksekusi sehingga GitHub preview menampilkan outputs.

Prasyarat
- Jalankan perintah dari root repository (contoh): `C:\Users\ASUS\Desktop\python-project`
- Python 3.8–3.12 direkomendasikan. Python 3.14 dapat digunakan tetapi beberapa paket mungkin tak kompatibel.
- Git terpasang dan remote sudah dikonfigurasi.
- Koneksi internet untuk pip install dan unduh resource NLTK.

Ringkasan file yang sebaiknya ada
- social-media-sentiment-analysis/
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
  - README.md (lokal folder, optional)

.gitignore (rekomendasi)
Tambahkan entri berikut ke `.gitignore`:
```
.venv/
venv/
social-media-sentiment-analysis/data/
social-media-sentiment-analysis/models/
.ipynb_checkpoints/
```

Langkah-langkah lengkap (PowerShell-safe)
Ikuti langkah ini satu per satu — jalankan dari root repo.

1) Masuk ke root repo
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
```

2) Buat virtual environment dan aktifkan (rekomendasi: .venv)
```powershell
py -3 -m venv .venv
. .\.venv\Scripts\Activate.ps1
```

3) Upgrade pip dan install dependencies (di dalam venv — jangan gunakan `--user`)
```powershell
python -m pip install --upgrade pip setuptools wheel
# Jika Anda punya requirements.txt di folder social-media-sentiment-analysis:
python -m pip install -r social-media-sentiment-analysis\requirements.txt

# Jika tidak ada requirements.txt, minimal install:
python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
```

4) (Rekomendasi) Buat sample data cepat untuk menguji pipeline
- Gunakan generator Python (lebih aman daripada menempel CSV panjang):
```powershell
# dari repo root, setelah venv aktif:
python .\social-media-sentiment-analysis\create_sample_data.py
# Hasil: social-media-sentiment-analysis\data\raw\tweets_scraped.csv
```
- Alternatif manual: copy isi `social-media-sentiment-analysis/data/raw/sample_tweets.csv` → `social-media-sentiment-analysis/data/raw/tweets_scraped.csv`

5) Preprocess data → train → evaluate
```powershell
# Preprocess (ubah path jika berbedak)
python .\social-media-sentiment-analysis\preprocess.py --input .\social-media-sentiment-analysis\data\raw\tweets_scraped.csv --output .\social-media-sentiment-analysis\data\processed\tweets_clean.csv

# Train baseline (TF-IDF + LogisticRegression)
python .\social-media-sentiment-analysis\train_model.py --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv --output .\social-media-sentiment-analysis\models\model_pipeline.joblib

# Evaluate (simpan confusion matrix di folder figures/)
python .\social-media-sentiment-analysis\evaluate.py --model .\social-media-sentiment-analysis\models\model_pipeline.joblib --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
```

6) Buat / overwrite notebook final (1 code cell) menggunakan helper nbformat
```powershell
# helper create_notebook.py harus ada di social-media-sentiment-analysis/create_notebook.py
python .\social-media-sentiment-analysis\create_notebook.py
# Ini menulis: social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
```

7) Eksekusi notebook agar outputs tersimpan (gunakan python -m nbconvert)
- Jalankan dari repo root (recommended):
```powershell
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```
- Jika Anda menjalankan dari dalam folder `social-media-sentiment-analysis`:
```powershell
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```

8) Stage, commit, dan push ke Git
- Tambahkan file yang relevan (pastikan .gitignore sudah benar sehingga data/models tidak ikut ter-track kecuali Anda sengaja commit model kecil):
```powershell
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

Troubleshooting singkat (paling umum)

A) WinError 32 (file used by another process) saat `pip install`  
- Tutup semua terminal / editor / Jupyter server / browser yang mungkin memakai file di `.venv\Scripts`.  
- Cek proses:
```powershell
Get-Process *jupyter* -ErrorAction SilentlyContinue
```
- Hentikan proses yang relevan:
```powershell
Stop-Process -Id <PID> -Force
```
- Jika tidak bisa, restart Windows lalu ulangi:
```powershell
. .\.venv\Scripts\Activate.ps1
python -m pip install --upgrade --force-reinstall jupyter jupyterlab nbconvert ipykernel
```
- Jika pip uninstall meninggalkan direktori temporary `~...` di site-packages, hapus hanya direktori yang spesifik disebut di warning (contoh path di pesan pip).

B) Error: "Can not perform a '--user' install. User site-packages are not visible in this virtualenv."  
- Jangan gunakan `--user` ketika venv aktif. Gunakan `python -m pip install <pkg>`.

C) nbconvert: "pattern matched no files"  
- Pastikan path target notebook benar dan Anda menjalankan nbconvert dari folder yang sesuai. Gunakan path relatif sesuai CWD.

D) snscrape error `'FileFinder' object has no attribute 'find_module'`  
- Coba:
```powershell
python -m pip install --upgrade snscrape
# atau bila perlu:
python -m pip install --upgrade --force-reinstall "git+https://github.com/JustAnotherArchivist/snscrape.git"
```
- Jika tetap bermasalah pada Python 3.14, gunakan venv dengan Python 3.11/3.12 atau gunakan sample CSV (create_sample_data.py).

E) Jangan paste blok Python multi-line langsung ke PowerShell  
- Simpan kode ke `.py` dan jalankan `python script.py`, atau masuk REPL `python` dan jalankan di dalamnya.

Minimal checklist verifikasi akhir
- Ada file `social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb` di folder tersebut.
- Notebook sudah dieksekusi (outputs tersimpan).
- `git status` bersih setelah commit/push.
- Data mentah & model besar tidak terkomit (periksa `.gitignore`).

Contoh ringkas run sequence (copy/paste ke PowerShell, jalankan baris per baris)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
py -3 -m venv .venv
. .\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r social-media-sentiment-analysis\requirements.txt

python .\social-media-sentiment-analysis\create_sample_data.py
python .\social-media-sentiment-analysis\preprocess.py --input .\social-media-sentiment-analysis\data\raw\tweets_scraped.csv --output .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
python .\social-media-sentiment-analysis\train_model.py --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv --output .\social-media-sentiment-analysis\models\model_pipeline.joblib
python .\social-media-sentiment-analysis\evaluate.py --model .\social-media-sentiment-analysis\models\model_pipeline.joblib --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
python .\social-media-sentiment-analysis\create_notebook.py
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120

git add social-media-sentiment-analysis\*.py social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
git commit -m "chore: add social-media-sentiment-analysis pipeline and executed notebook"
git push origin main
```

Penutup singkat
- README ini mengumpulkan semua langkah dari set lokasi hingga commit ke Git secara PowerShell‑safe.  
- Jika Anda ingin, saya bisa: membuat `manage_social_notebook.ps1` yang mengotomatiskan semua langkah di atas (non-interactive), atau langsung commit file-file yang saya sarankan ke repository Anda — sebutkan repo/branch dan saya bantu susun commit message. 
```
```
