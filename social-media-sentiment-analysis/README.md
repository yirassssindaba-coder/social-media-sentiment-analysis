# social-media-sentiment-analysis

Analisis sentimen sederhana dari data media sosial (demo). Termasuk skrip, notebook, dan instruksi menjalankan environment Jupyter secara permanen (PowerShell-safe).

Ringkasan
- Tujuan: menyediakan pipeline minimal untuk eksperimen sentiment analysis dan satu notebook final yang berisi 1 code cell dan telah dieksekusi (outputs tersimpan) supaya preview GitHub menampilkan hasil.
- Lokasi proyek (contoh): `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`
- Rekomendasi venv: `.venv` (atau `venv` sesuai preferensi). Sesuaikan perintah bila memakai nama lain.

Prasyarat
- Python 3.8–3.12 (3.14 bisa berfungsi tapi beberapa paket seperti pyarrow mungkin belum tersedia)
- Git
- Koneksi internet (untuk mengunduh paket / NLTK resources)

Isi folder (rekomendasi)
- social-media-sentiment-analysis/
  - create_notebook.py
  - data_collection.py
  - preprocess.py
  - train_model.py
  - evaluate.py
  - visualize.py
  - requirements.txt
  - README.md (folder-local)
  - social-media-sentiment-analysis.ipynb (final notebook — commit setelah dieksekusi)
  - data/ (ignored)
  - models/ (ignored kecuali model kecil ingin di-commit)
  - figures/ (opsional artefak)

Jangan commit
- `social-media-sentiment-analysis/data/` (raw/processed data besar)
- `social-media-sentiment-analysis/models/` (model besar)
- `.venv/` atau `venv/`
Tambahkan entri di `.gitignore`.

Quick start (PowerShell — singkat)
1. Pindah ke folder proyek:
   ```powershell
   Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
   Get-Location
   ```
2. Buat virtual environment dan aktifkan (direkomendasikan `.venv`):
   ```powershell
   py -3 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   ```
3. Upgrade pip & install dependencies:
   ```powershell
   python -m pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
   ```
4. Jalankan demo (jika ada `src\main.py` atau skrip utama):
   ```powershell
   python .\src\main.py
   ```
5. Jalankan JupyterLab (opsional):
   ```powershell
   python -m jupyter lab
   ```

Langkah instalasi Jupyter & pengaturan permanen (jalankan blok per blok)
Catatan: jalankan tiap blok satu per satu. Jangan paste semuanya sekaligus.

0) Pastikan lokasi kerja
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
Get-Location
Get-ChildItem -Name
```

1) Periksa struktur cepat
```powershell
Test-Path .\venv
Test-Path .\src\main.py
Test-Path .\README.md
Get-ChildItem -Directory | Select-Object Name
```

2) Perbaikan PATH sementara (jika `python` atau `where.exe` tidak ditemukan)
```powershell
Get-Command where.exe -ErrorAction SilentlyContinue
Get-Command python -ErrorAction SilentlyContinue

# Jika tidak ditemukan, gabungkan Path Machine + User (session only)
$machine = [Environment]::GetEnvironmentVariable('Path','Machine')
$user = [Environment]::GetEnvironmentVariable('Path','User')
$env:PATH = if ($user) { $machine + ';' + $user } else { $machine }
if (-not ($env:PATH -match 'Windows\\System32')) { $env:PATH += ';C:\Windows\System32' }

Get-Command python -ErrorAction SilentlyContinue
```

3) Temukan interpreter Python sistem (set variabel $PY)
```powershell
Remove-Variable PY -ErrorAction SilentlyContinue
$cmd = Get-Command python -ErrorAction SilentlyContinue
if ($cmd) { $PY = $cmd.Source } else {
  $candidates = @(
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "C:\Python314\python.exe",
    "C:\Python312\python.exe"
  )
  foreach ($p in $candidates) { if (-not $PY -and (Test-Path $p)) { $PY = $p } }
}
if (-not $PY) { Write-Error "Python tidak ditemukan. Install Python atau beri path penuh ke python.exe"; throw }
Write-Host "Using Python: $PY"
& $PY --version
```

4) Buat / perbaiki venv (jalankan di root proyek)
```powershell
if (-not (Test-Path .\.venv\Scripts\python.exe)) {
  if (Test-Path .\.venv) { Remove-Item -Recurse -Force .\.venv }
  & $PY -m venv .\.venv
}
Test-Path .\.venv\Scripts\python.exe
```

5) Pastikan ExecutionPolicy untuk menjalankan Activate.ps1 (CurrentUser)
```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

6) Aktifkan venv dan verifikasi interpreter venv
```powershell
. .\.venv\Scripts\Activate.ps1
python --version
python -c "import sys; print('sys.executable=', sys.executable)"
python -m pip --version
```

7) Install paket utama (jalankan hanya setelah venv aktif)
```powershell
python -m pip install --upgrade pip setuptools wheel

python -m pip install --upgrade certifi `
  pandas numpy scipy scikit-learn matplotlib seaborn `
  nltk ipywidgets notebook qtconsole widgetsnbextension `
  jupyter jupyterlab ipykernel `
  openpyxl xlsxwriter xlrd `
  plotly requests beautifulsoup4 lxml `
  joblib tqdm

# Enable widgets for classic notebook
jupyter nbextension enable --py widgetsnbextension --sys-prefix

# Download NLTK resource untuk VADER
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"

# Optional: record exact packages
python -m pip freeze > requirements.txt
```

Catatan: bila menggunakan Python 3.14, hindari memasang pyarrow (tidak tersedia wheel stabil saat ini).

8) Set SSL cert (rekomendasi permanen untuk User)
```powershell
$cert = & python -c "import certifi; print(certifi.where())"
$env:SSL_CERT_FILE = $cert
[Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$cert,'User')
Write-Host "SSL_CERT_FILE set permanently for User to: $cert"
```

9) Perbaiki / reinstall Jupyter launcher jika perlu
```powershell
Get-ChildItem .\.venv\Scripts\*jupyter* -Force | Select-Object Name,FullName
Remove-Item .\.venv\Scripts\jupyter.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\.venv\Scripts\jupyter-lab.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\.venv\Scripts\jupyter-notebook.exe -Force -ErrorAction SilentlyContinue
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
```

10) Daftarkan kernel ipykernel untuk venv (user-level)
```powershell
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

11) Jalankan JupyterLab dan periksa
```powershell
python -m jupyter lab
# atau debug:
# python -m jupyter lab --debug
```

Git — urutan PowerShell-safe untuk memastikan hanya 1 notebook final
- Jalankan perintah ini dari root repo (contoh `C:\Users\ASUS\Desktop\python-project`).

1) Masuk ke root repo dan verifikasi:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
git status
git branch --show-current
git remote -v
```

2) Pastikan remote benar (opsional):
```powershell
git remote set-url origin https://github.com/yirassssindaba-coder/python-project.git
git remote -v
```

3) Sinkronkan branch main:
```powershell
git fetch origin
git checkout main
if ($LASTEXITCODE -ne 0) {
  if (git ls-remote --heads origin main) {
    git checkout -B main origin/main
  } else {
    git checkout -B main
  }
}
git pull origin main
```

4) Stage/commit tracked changes (jika ada):
```powershell
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "feat: add/update social-media-sentiment-analysis project"
} else {
  Write-Host "No tracked changes to commit."
}
```

5) Pastikan hanya 1 notebook final (rename jika perlu):
```powershell
if (Test-Path "social-media-sentiment-analysis\Untitled1.ipynb") {
  git mv "social-media-sentiment-analysis\Untitled1.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb"
  git commit -m "chore: rename Untitled1.ipynb -> social-media-sentiment-analysis.ipynb"
  git push origin main
} else {
  Write-Host "No Untitled1.ipynb found. Use step 6 to create/overwrite the notebook."
}
```

6) Buat / overwrite notebook final (helper dengan nbformat)
- Buat script `create_notebook.py` (sudah tersedia di folder proyek yang saya sediakan) yang menulis 1 code cell berikut:

```python
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

print("pandas", pd.__version__)
nltk.download("vader_lexicon", quiet=True)
sid = SentimentIntensityAnalyzer()
print(sid.polarity_scores("I love this product"))
```

PowerShell untuk membuat/menjalankan helper:
```powershell
# jika Anda tidak memiliki file create_notebook.py di root, buat dan jalankan:
Set-Content -Path ".\create_notebook.py" -Value (Get-Content -Raw .\social-media-sentiment-analysis\create_notebook.py) -Encoding UTF8
python .\create_notebook.py

git add "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
git commit -m "chore: create social-media-sentiment-analysis.ipynb with requested content"
git push origin main
```

7) Hapus file ganda / duplikat di folder `social-media-sentiment-analysis`:
```powershell
Get-ChildItem -Path .\social-media-sentiment-analysis\ -File | Select-Object Name

$dupes = @(
  "social-media-sentiment-analysis\social-media-sentiment-analysis.py",
  "social-media-sentiment-analysis\social_media_sentiment_analysis.py",
  "social-media-sentiment-analysis\Untitled.ipynb",
  "social-media-sentiment-analysis\Untitled1.ipynb"
)

foreach ($f in $dupes) {
  git rm --ignore-unmatch $f
  if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue; Write-Host "Removed local file: $f" }
}
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: remove duplicate files in social-media-sentiment-analysis"
  git push origin main
}
```

8) Eksekusi notebook agar outputs tersimpan (nbconvert)
```powershell
python -m pip install --user nbformat nbconvert jupyter nltk
jupyter nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120

git add "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: execute notebook and record outputs"
  git push origin main
}
```

9) Perbaiki `.gitignore` dan hentikan tracking venv
```powershell
$venvPath = "social-media-sentiment-analysis/venv"
git rm -r --cached --ignore-unmatch $venvPath
if (Test-Path ".\gitignore" -PathType Leaf -ErrorAction SilentlyContinue) {
  if (-not (Test-Path ".\.gitignore")) { Move-Item ".\gitignore" ".\.gitignore" -Force }
}
if (-not (Test-Path ".\.gitignore")) { New-Item -Path ".\.gitignore" -ItemType File -Force | Out-Null }
$found = Select-String -Path .\.gitignore -Pattern $venvPath -SimpleMatch -Quiet
if (-not $found) { Add-Content -Path .\.gitignore -Value $venvPath; git add .\.gitignore; git commit -m "chore: add venv to .gitignore and stop tracking venv"; git push origin main }
```

10) Hapus/ignore helper `rename_notebooks.py` jika ada
```powershell
git rm --ignore-unmatch "social-media-sentiment-analysis/rename_notebooks.py"
Add-Content .\.gitignore "social-media-sentiment-analysis/rename_notebooks.py"
git add .\.gitignore
git commit -m "chore: ignore local rename_notebooks helper"
git push origin main
```

Verifikasi akhir
```powershell
git status
git branch --show-current
git remote -v
Get-ChildItem -Path .\social-media-sentiment-analysis\ -File | Select-Object Name
```

Contoh output yang diharapkan setelah notebook dijalankan
```
pandas 2.3.3
{'neg': 0.0, 'neu': 0.323, 'pos': 0.677, 'compound': 0.6369}
```

Troubleshooting singkat
- Jika `jupyter nbconvert --execute` gagal: jalankan `python -m pip install --user nbformat nbconvert jupyter nltk` lalu ulangi.
- NLTK `vader_lexicon` diunduh saat notebook dieksekusi; butuh koneksi internet.
- Pesan `git: 'credential-manager-core' is not a git command` biasanya peringatan helper credential; push masih bisa berhasil.
- Jika ada error permissions saat Set-ExecutionPolicy, jalankan dengan scope `CurrentUser` atau hubungi admin.

Catatan keamanan & praktik terbaik
- Jangan commit kredensial, file .env, atau data pribadi.
- Simpan dataset sensitif di luar repo atau gunakan storage/artefak.
- Untuk model besar, gunakan release/artifacts atau storage terpisah, bukan commit langsung.

Butuh bantuan lanjut?
- Saya dapat:
  - Buatkan file PowerShell `.ps1` otomatis untuk menjalankan seluruh alur (interaktif atau non-interactive), atau
  - Siapkan sample CSV berlabel kecil agar Anda langsung bisa train & lihat contoh output notebook, atau
  - Commit file-file Python & notebook (Anda memberi repo/branch dan izinkan akses).

---
