# social-media-sentiment-analysis

Analisis sentimen sederhana dari data media sosial (demo). Repo ini berisi skrip Python untuk pengumpulan data (opsional), preprocess, training baseline, evaluasi, visualisasi, dan satu notebook final yang berisi 1 code cell yang telah dieksekusi (outputs tersimpan) supaya preview GitHub menampilkan hasil.

Ringkasan
- Tujuan: pipeline minimal end-to-end untuk eksperimen sentiment analysis dan artefak yang mudah ditinjau oleh recruiter / reviewer.
- Contoh lokasi kerja: `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`
- Rekomendasi venv: `.venv` (disarankan di root repo atau di dalam folder `social-media-sentiment-analysis` sesuai preferensi).

Prasyarat
- Python 3.8 - 3.12 (Python 3.14 dapat dipakai tetapi beberapa paket seperti `pyarrow` belum tersedia).
- Git
- Koneksi internet (untuk pip install & NLTK resource seperti `vader_lexicon`).

Struktur yang direkomendasikan
- social-media-sentiment-analysis/
  - create_notebook.py
  - data_collection.py
  - preprocess.py
  - train_model.py
  - evaluate.py
  - visualize.py
  - requirements.txt
  - README.md (lokal folder)
  - social-media-sentiment-analysis.ipynb (final notebook — commit setelah dieksekusi)
  - data/ (ignored)
  - models/ (ignored kecuali model kecil ingin di-commit)
  - figures/ (opsional artefak)
- manage_social_notebook.ps1 (opsional helper di root repo)
- .gitignore (pastikan memasukkan data/, models/, .venv/)

Jangan commit ke repo
- `social-media-sentiment-analysis/data/` (raw / processed dataset besar)
- `social-media-sentiment-analysis/models/` (model besar)
- virtual environment (`.venv/`, `venv/`, dll.)
Tambahkan entri tersebut ke `.gitignore`.

Quick start (PowerShell — singkat)
1. Masuk folder proyek:
   ```powershell
   Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
   ```
2. Buat virtualenv dan aktifkan:
   ```powershell
   py -3 -m venv .venv
   . .\.venv\Scripts\Activate.ps1
   ```
3. Upgrade pip & install dependencies (di dalam venv; jangan gunakan `--user`):
   ```powershell
   python -m pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
   ```
4. (Opsional) Jalankan skrip demo:
   ```powershell
   python .\src\main.py   # jika ada
   ```
5. (Opsional) Jalankan JupyterLab:
   ```powershell
   python -m jupyter lab
   ```

Panduan instalasi Jupyter & pengaturan (jalankan blok per blok)
- Jalankan setiap blok satu per satu. Jangan paste semuanya sekaligus.

0) Pastikan lokasi kerja (jalankan dari root folder `social-media-sentiment-analysis` atau repo root jika Anda menaruh files di subfolder)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
Get-ChildItem -Name
```

1) Verifikasi interpreter & PATH jika perlu
```powershell
Get-Command python -ErrorAction SilentlyContinue

# Jika python tidak ditemukan, perbaiki PATH session-only:
$machine = [Environment]::GetEnvironmentVariable('Path','Machine')
$user = [Environment]::GetEnvironmentVariable('Path','User')
$env:PATH = if ($user) { $machine + ';' + $user } else { $machine }
if (-not ($env:PATH -match 'Windows\\System32')) { $env:PATH += ';C:\Windows\System32' }
Get-Command python -ErrorAction SilentlyContinue
```

2) Buat / perbaiki virtual environment (jalankan di folder proyek)
```powershell
# gunakan .venv di dalam project
if (-not (Test-Path .\.venv\Scripts\python.exe)) {
  if (Test-Path .\.venv) { Remove-Item -Recurse -Force .\.venv }
  py -3 -m venv .\.venv
}
. .\.venv\Scripts\Activate.ps1
python --version
python -m pip --version
```

3) Pastikan ExecutionPolicy (agar Activate.ps1 bisa dijalankan)
```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

4) Install paket penting (di dalam venv — tanpa `--user`)
```powershell
python -m pip install --upgrade pip setuptools wheel

python -m pip install nbformat nbconvert jupyter jupyterlab ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm snscrape
# sesuaikan dengan content requirements.txt
```

Catatan penting:
- Jangan gunakan `python -m pip install --user ...` saat venv aktif — akan menghasilkan error "User site-packages are not visible in this virtualenv."
- Jika `pip install` gagal karena file sedang dipakai (WinError 32), tutup semua terminal/IDE/Jupyter yang mungkin menggunakan file tersebut, lalu ulangi atau restart Windows.

5) Enable widgets & unduh resource NLTK
```powershell
jupyter nbextension enable --py widgetsnbextension --sys-prefix
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"
```

6) (Opsional) Set SSL_CERT_FILE permanen untuk User jika ada masalah SSL
```powershell
$cert = & python -c "import certifi; print(certifi.where())"
[Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$cert,'User')
Write-Host "SSL_CERT_FILE set for User to: $cert"
```

7) (Jika diperlukan) Reinstall Jupyter launcher setelah mengatasi file-lock
```powershell
# Pastikan tidak ada proses jupyter/jupyter-lab aktif
Get-Process *jupyter* -ErrorAction SilentlyContinue

# Jika ada file launcher bermasalah, hapus executable dan reinstall
Remove-Item .\.venv\Scripts\jupyter.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\.venv\Scripts\jupyter-lab.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\.venv\Scripts\jupyter-notebook.exe -Force -ErrorAction SilentlyContinue

python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
```

8) Daftarkan kernel venv ke Jupyter (user-level)
```powershell
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

Menulis dan mengeksekusi notebook final (PowerShell-safe)
- Jangan paste blok Python langsung ke PowerShell — PowerShell akan mengira itu perintah. Jalankan file `.py` atau gunakan `python -c "..."` / REPL `python`.

1) Buat / overwrite notebook final (sudah disediakan `create_notebook.py`)
```powershell
# Jalankan helper yang menulis satu code-cell notebook:
python .\social-media-sentiment-analysis\create_notebook.py
```

2) Eksekusi notebook agar outputs tersimpan (gunakan python -m nbconvert untuk menghindari masalah launcher)
```powershell
# Pastikan venv aktif dan nbconvert terinstal di venv
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```

Tips menjalankan nbconvert bila mengalami error:
- Jika muncul error module not found untuk `jupyterlab`, periksa instalasi jupyter/jupyterlab di venv dan reinstall jika perlu.
- Jika muncul warning Proactor event loop (zmq), biasanya informatif — periksa apakah notebook tetap berhasil dieksekusi.
- Jika NLTK resource belum terunduh, jalankan `python -c "import nltk; nltk.download('vader_lexicon', quiet=False)"` di venv.

Git — PowerShell-safe workflow untuk memastikan hanya satu notebook final
Jalankan perintah di bawah dari repo root (contoh `C:\Users\ASUS\Desktop\python-project`).

1) Sinkronisasi branch utama & commit tracked changes
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git fetch origin
git checkout main
if ($LASTEXITCODE -ne 0) {
  if (git ls-remote --heads origin main) { git checkout -B main origin/main } else { git checkout -B main }
}
git pull origin main

git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "feat: add/update social-media-sentiment-analysis project"
  git push origin main
}
```

2) Rename untitled notebook jika ada (opsional)
```powershell
if (Test-Path "social-media-sentiment-analysis\Untitled1.ipynb") {
  git mv "social-media-sentiment-analysis\Untitled1.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb"
  git commit -m "chore: rename Untitled1.ipynb -> social-media-sentiment-analysis.ipynb"
  git push origin main
}
```

3) Tambah create_notebook.py, script lain, dan notebook yang sudah dieksekusi lalu push
```powershell
git add social-media-sentiment-analysis\create_notebook.py
git add social-media-sentiment-analysis\*.py
git add social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
git commit -m "chore: add social-media-sentiment-analysis helpers and notebook"
git push origin main
```

Membersihkan duplikat
- Periksa isi folder target, lalu hapus file duplikat yang tidak perlu (contoh `Untitled.ipynb`, `.py` duplikat).
- Gunakan `git rm --ignore-unmatch <file>` lalu commit.

Troubleshooting umum & rekomendasi
- WinError 32 (file sedang digunakan) saat `pip install`: tutup VS Code/terminal/Jupyter; jika perlu restart Windows; ulangi `pip install`.
- Jangan gunakan `--user` ketika venv aktif.
- Jangan paste code Python multi-line langsung ke PowerShell (PowerShell bukan Python REPL).
- Jika notebook tidak menampilkan prediksi model: pastikan Anda sudah menjalankan pipeline training (preprocess -> train_model) dan file model disimpan ke salah satu lokasi yang dicek (lihat `create_notebook.py` lines for candidate paths).
- Simpan semua file `.py` dan notebook sebagai UTF-8 untuk menghindari artefak encoding (mis. â€”).

Contoh perintah training (dari repo root)
```powershell
# Scrape (opsional)
python .\social-media-sentiment-analysis\data_collection.py --mode scrape --query "product review" --limit 500 --out social-media-sentiment-analysis\data\raw\tweets_scraped.csv

# Preprocess
python .\social-media-sentiment-analysis\preprocess.py --input social-media-sentiment-analysis\data\raw\tweets_scraped.csv

# Train baseline
python .\social-media-sentiment-analysis\train_model.py --input social-media-sentiment-analysis\data\processed\tweets_clean.csv

# Evaluate (opsional)
python .\social-media-sentiment-analysis\evaluate.py --model social-media-sentiment-analysis\models\model_pipeline.joblib --input social-media-sentiment-analysis\data\processed\tweets_clean.csv
```

Verifikasi akhir
```powershell
git status
git branch --show-current
git remote -v
Get-ChildItem -Path .\social-media-sentiment-analysis\ -Filter *.ipynb -File | Select-Object Name
```

Output contoh yang diharapkan setelah notebook dieksekusi
```
pandas 2.3.3
{'neg': 0.0, 'neu': 0.323, 'pos': 0.677, 'compound': 0.6369}
```

Praktik terbaik & keamanan
- Jangan commit data sensitif atau kredensial. Gunakan `.env` + `.gitignore` jika perlu.
- Simpan model besar di storage terpisah (release, S3, GDrive), bukan di repo.
- Simpan snapshot environment (`pip freeze > requirements.txt`) untuk reproduktibilitas.

Butuh bantuan lanjutan?
- Saya dapat menyiapkan:
  - `manage_social_notebook.ps1` (non-interactive) yang memanggil `python -m nbconvert` untuk mengeksekusi notebook dan commit hasilnya, atau
  - contoh CSV kecil (50 baris) berlabel agar Anda bisa langsung menjalankan training & melihat prediksi, atau
  - commit file `create_notebook.py` yang lebih robust (mencari model di beberapa path) — jika Anda mau saya commit, berikan repo/branch.
