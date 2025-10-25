```text
# social-media-sentiment-analysis

Analisis sentimen sederhana dari data media sosial (demo). Termasuk skrip, notebook, dan instruksi menjalankan environment.

Quick start (PowerShell):
1. Buat/aktifkan virtual env:
   py -3 -m venv venv
   .\venv\Scripts\Activate.ps1
2. Install dependencies:
   python -m pip install --upgrade pip setuptools wheel
   python -m pip install -r requirements.txt
3. Jalankan demo script:
   python .\src\main.py
4. Jalankan JupyterLab (opsional):
   python -m jupyter lab

Catatan:
- Jangan commit folder venv/ atau data/raw/ ke GitHub. Gunakan .gitignore.
- Jika ingin push ke GitHub, gunakan SSH key atau Personal Access Token (PAT).
```

# Perbaikan & Instalasi Permanen Jupyter untuk proyek

Jalankan semua blok PowerShell ini dari folder proyek:  
`C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

Saya telah menggabungkan pengecekan, perbaikan, pemasangan paket yang hilang, dan langkah untuk membuat beberapa pengaturan menjadi permanen (User-level).  
Jalankan blok per blok (satu kali paste per blok). Jika sebuah blok mengeluarkan error, salin seluruh output error dan tempel di chat — saya bantu koreksi langkah spesifiknya.

---

## Catatan umum
- Buka PowerShell biasa (Run as Administrator hanya bila saya tandai).
- Jangan paste semuanya sekaligus — jalankan blok 1 → 2 → 3 … dst.
- Banyak perintah mengasumsikan venv berada di root proyek (`.\venv`). Jika struktur berbeda, sesuaikan path.
- Instalasi paket via pip di venv bersifat "permanen" untuk venv (tetap terpasang sampai venv dihapus). Mengatur SSL_CERT_FILE dengan `[Environment]::SetEnvironmentVariable(...,'User')` membuatnya permanen untuk user.

> Penting: beberapa contoh Git yang sering ditulis untuk Bash menggunakan operator seperti `||` atau tanda `<` untuk placeholder — operator tersebut tidak berlaku di PowerShell. README ini menggunakan sintaks PowerShell yang kompatibel. Saya juga mempertahankan alur perintah Git yang Anda gunakan, namun dituliskan dalam bentuk PowerShell‑safe agar bisa dieksekusi langsung.

---

## 0) Lokasi aman (mulai di sini)
`C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

Petunjuk: buka PowerShell (bukan Administrator kecuali dicatat), pindah ke path di atas, lalu jalankan tiap blok perintah di bawah secara berurutan. Jalankan satu blok, pastikan tidak error, lalu lanjut ke blok berikutnya.

---

## 1) Pastikan berada di root proyek
```powershell
Get-Location
Get-ChildItem -Name

# verifikasi file/folder penting
Test-Path .\venv
Test-Path .\src\main.py
Test-Path .\README.md
```

---

## 2) Periksa nested folder (hindari path ganda)
```powershell
Get-ChildItem -Directory | Select-Object Name

# jika ada nested dengan nama project, pindah ke parent yang benar:
# Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
```

---

## 3) Perbaiki session PATH sementara (jika where.exe/python tidak ditemukan)
```powershell
Write-Host "Session PATH exists?"; if ($env:PATH) { "Yes" } else { "No or empty" }
Get-Command where.exe -ErrorAction SilentlyContinue
Get-Command python -ErrorAction SilentlyContinue

# jika where.exe/python tidak ditemukan, jalankan (session-only):
$machine = [Environment]::GetEnvironmentVariable('Path','Machine')
$user = [Environment]::GetEnvironmentVariable('Path','User')
$env:PATH = if ($user) { $machine + ';' + $user } else { $machine }
if (-not ($env:PATH -match 'Windows\\System32')) { $env:PATH += ';C:\Windows\System32' }

# verifikasi lagi
Get-Command where.exe -ErrorAction SilentlyContinue
Get-Command python -ErrorAction SilentlyContinue
```

---

## 4) Temukan interpreter Python sistem dan set $PY
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

---

## 5) Cek / buat ulang venv jika perlu (jalankan di root proyek)
```powershell
Test-Path .\venv\Scripts\python.exe
Get-ChildItem .\venv\Scripts\* -ErrorAction SilentlyContinue | Select-Object Name

# Jika venv tidak ada / rusak:
if (-not (Test-Path .\venv\Scripts\python.exe)) {
  if (Test-Path .\venv) { Remove-Item -Recurse -Force .\venv }
  & $PY -m venv .\venv
}

Test-Path .\venv\Scripts\python.exe
```

---

## 6) Pastikan ExecutionPolicy agar Activate.ps1 bisa dijalankan (CurrentUser)
```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```
(You may be prompted; answer `Y`.)

---

## 7) Aktifkan venv (dot‑sourcing) dan verifikasi interpreter venv
```powershell
. .\venv\Scripts\Activate.ps1

# verifikasi
python --version
python -c "import sys; print('sys.executable=', sys.executable)"
python -m pip --version

# jika Activate.ps1 tidak ditemukan, gunakan:
# .\venv\Scripts\python.exe --version
```

---

## 8) Install semua module utama untuk data science, Jupyter, analisis sentimen, dan web scraping

Pastikan venv aktif sebelum menjalankan blok ini.

```powershell
python -m pip install --upgrade pip setuptools wheel

python -m pip install --upgrade certifi `
  pandas numpy scipy scikit-learn matplotlib seaborn `
  nltk `
  ipywidgets notebook qtconsole widgetsnbextension `
  jupyter jupyterlab ipykernel `
  openpyxl xlrd xlsxwriter `
  plotly `
  requests beautifulsoup4 lxml `
  joblib tqdm

# catatan: jangan install pyarrow di Python 3.14 (belum tersedia wheel)
# jika butuh pyarrow, gunakan Python 3.11/3.12 dan jalankan:
# python -m pip install --upgrade pyarrow

# Enable widgets extension for classic notebook
jupyter nbextension enable --py widgetsnbextension --sys-prefix

# Download resource NLTK 'vader_lexicon' agar SentimentIntensityAnalyzer siap pakai
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"

# Freeze requirements agar environment tercatat
python -m pip freeze > requirements.txt
```

Catatan:
- Jika kamu memakai Python 3.14, jangan install pyarrow (akan gagal build).
- Jika perlu pyarrow, buat venv dengan Python 3.11/3.12.

---

## 9) Perbaiki env var sertifikat (SSL_CERT_FILE) — permanen untuk User (direkomendasikan)
```powershell
# dapatkan path CA bundle certifi dan set untuk session
$cert = & python -c "import certifi; print(certifi.where())"
$env:SSL_CERT_FILE = $cert
Write-Host "Using SSL_CERT_FILE (session) = $env:SSL_CERT_FILE"

# set permanen untuk User agar berlaku di shell baru / Jupyter server baru
[Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$cert,'User')
Write-Host "SSL_CERT_FILE set permanently for User to: $cert"

# cek env var terkait
Get-ChildItem Env: | Where-Object Name -match 'CERT|SSL|REQUESTS|CURL|COMPOSER|PHP' | Format-Table Name,Value -AutoSize
```
Jika kamu tidak ingin membuatnya permanen, hapus baris SetEnvironmentVariable dan cukup gunakan session setting.

---

## 10) Reinstall / perbaiki Jupyter & pasang ulang launcher jika error (permanen di venv)
```powershell
# verify launcher executables in venv
Get-ChildItem .\venv\Scripts\*jupyter* -Force | Select-Object Name,FullName

# Jika ada wrapper yang korup, hapus dan reinstall untuk menulis ulang executable launcher
Remove-Item .\venv\Scripts\jupyter.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-lab.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-notebook.exe -Force -ErrorAction SilentlyContinue

python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
```

---

## 11) Daftarkan kernel ipykernel untuk venv (persisted for user)
```powershell
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

Kernel ini akan muncul di Jupyter UI untuk user kamu sampai kamu uninstall kernelspec.

---

## 12) Jalankan JupyterLab dan periksa log startup
```powershell
# hentikan server lama jika ada (Ctrl+C), lalu jalankan:
python -m jupyter lab

# jika perlu debug verbose:
# python -m jupyter lab --debug
```

Yang diharapkan: JupyterLab berjalan tanpa FileNotFoundError terkait SSL_CERT_FILE dan tanpa stacktrace untuk pypi extension manager. Buka URL yang diprint di terminal (`http://localhost:8888/lab?...`).

---

## Pemeriksaan cepat bila masih ada error
```powershell
Get-ChildItem Env: | Where-Object Name -match 'CERT|SSL|REQUESTS|CURL|COMPOSER|PHP' | Format-Table Name,Value -AutoSize
jupyter --version
python -m jupyter lab --version
(Get-Command jupyter -ErrorAction SilentlyContinue).Source
python -m jupyter lab --debug
```

---

## Verifikasi akhir setelah setup selesai

Jika JupyterLab sudah terbuka dan UI Launcher muncul, lakukan pemeriksaan berikut untuk memastikan setup sudah benar dan kernel venv aktif.

### Cek versi & kernel terdaftar:
```powershell
python --version
jupyter --version
jupyter kernelspec list
```

### Cek paket Jupyter core yang sebelumnya tidak terpasang:
```powershell
python -c "import ipywidgets, notebook, qtconsole; print('ipywidgets', getattr(ipywidgets,'__version__','n/a')); print('notebook', getattr(notebook,'__version__','n/a')); print('qtconsole', getattr(qtconsole,'__version__','n/a'))"
```

### Tes runtime sederhana di notebook/JupyterLab (jalankan di cell notebook):
```python
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

print('pandas', pd.__version__)
nltk.download('vader_lexicon', quiet=True)
sid = SentimentIntensityAnalyzer()
print(sid.polarity_scores("I love this product"))
```

Jika cell di atas mengembalikan skor tanpa error, kernel sudah berjalan end‑to‑end.

## Git — urutan perintah yang Anda gunakan (PowerShell-safe)

Tujuan akhir: di folder `social-media-sentiment-analysis` hanya ada 1 notebook:
`social-media-sentiment-analysis.ipynb`. Hapus duplikat (.py / .ipynb lainnya),
buat/overwrite notebook final dengan satu code cell (kode Anda), dan jalankan notebook
agar outputs tersimpan di file (supaya preview GitHub menampilkan output).

Catatan umum:
- Jalankan perintah dari root repository, mis. `C:\Users\ASUS\Desktop\python-project`.
- Semua perintah di bawah ditulis agar kompatibel dengan PowerShell (tanpa `||`).
- Skrip pembuatan notebook memakai nbformat; eksekusi notebook memakai nbconvert.

1) Masuk ke root repo dan verifikasi status
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
git status
git branch --show-current
git remote -v
```

2) Pastikan remote benar (jika perlu)
```powershell
git remote set-url origin https://github.com/yirassssindaba-coder/python-project.git
git remote -v
```

3) Sinkronkan branch main
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

4) Stage/commit tracked changes (jika ada)
```powershell
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "feat: add/update social-media-sentiment-analysis project"
} else {
  Write-Host "No tracked changes to commit."
}
```

5) SINGLE OPTION — Pastikan hanya 1 notebook: rename atau buat `social-media-sentiment-analysis.ipynb`
- Jika Anda hanya ingin mengganti nama satu file Untitled (jika ada), gunakan `git mv`:
```powershell
if (Test-Path "social-media-sentiment-analysis\Untitled1.ipynb") {
  git mv "social-media-sentiment-analysis\Untitled1.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb"
  git commit -m "chore: rename Untitled1.ipynb -> social-media-sentiment-analysis.ipynb"
  git push origin main
} else {
  Write-Host "No Untitled1.ipynb found. Use step 6 to create/overwrite the notebook."
}
```

6) Buat / overwrite notebook final (isi satu code cell sesuai permintaan)
- Gunakan helper Python untuk menulis notebook valid (nbformat). Ini membuat
  `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb` dengan isi:

  import pandas as pd
  import nltk
  from nltk.sentiment.vader import SentimentIntensityAnalyzer

  print("pandas", pd.__version__)
  nltk.download("vader_lexicon", quiet=True)
  sid = SentimentIntensityAnalyzer()
  print(sid.polarity_scores("I love this product"))

```powershell
# create_notebook.py: tulis notebook satu cell (PowerShell: membuat & menjalankan file Python helper)
$py = @'
import nbformat as nbf
nb = nbf.v4.new_notebook()
code = """import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

print(\"pandas\", pd.__version__)
nltk.download(\"vader_lexicon\", quiet=True)
sid = SentimentIntensityAnalyzer()
print(sid.polarity_scores(\"I love this product\"))"""
nb['cells'] = [nbf.v4.new_code_cell(code)]
out_path = "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
import os
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, "w", encoding="utf-8") as f:
    nbf.write(nb, f)
print("Notebook written:", out_path)
'@

Set-Content -Path ".\create_notebook.py" -Value $py -Encoding UTF8
python .\create_notebook.py

# Stage, commit, push the notebook
git add "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
git commit -m "chore: create social-media-sentiment-analysis.ipynb with requested content"
git push origin main

# Optional: remove helper script if not needed
Remove-Item .\create_notebook.py -Force -ErrorAction SilentlyContinue
```

7) Hapus file ganda / duplikat di folder `social-media-sentiment-analysis`
- Periksa isi folder dulu, lalu hapus file yang tidak diinginkan. Contoh umum (sesuaikan bila berbeda):

```powershell
# lihat daftar file di folder target
Get-ChildItem -Path .\social-media-sentiment-analysis\ -File | Select-Object Name

# contoh nama duplikat yang sering muncul (sesuaikan list bila perlu)
$dupes = @(
  "social-media-sentiment-analysis\social-media-sentiment-analysis.py",
  "social-media-sentiment-analysis\social_media_sentiment_analysis.py",
  "social-media-sentiment-analysis\Untitled.ipynb",
  "social-media-sentiment-analysis\Untitled1.ipynb"
)

foreach ($f in $dupes) {
  git rm --ignore-unmatch $f    # remove from index if tracked; no error if not
  if (Test-Path $f) {
    Remove-Item $f -Force -ErrorAction SilentlyContinue
    Write-Host "Removed local file: $f"
  } else {
    Write-Host "No local file: $f"
  }
}

# Commit deletions if any
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: remove duplicate files in social-media-sentiment-analysis"
  git push origin main
} else {
  Write-Host "No duplicate files to remove/commit."
}
```

8) Eksekusi notebook agar outputs tersimpan di file (supaya GitHub preview menampilkan hasil)
- Install jika perlu:
```powershell
python -m pip install --user nbformat nbconvert jupyter nltk
```
- Jalankan eksekusi (simpan outputs ke notebook file):
```powershell
jupyter nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```
- Commit outputs yang berubah (jika ada):
```powershell
git add "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: execute notebook and record outputs"
  git push origin main
} else {
  Write-Host "No notebook output changes to commit."
}
```

9) Perbaiki .gitignore dan hentikan tracking venv (PowerShell-safe)
```powershell
$venvPath = "social-media-sentiment-analysis/venv"
$gitignorePath = ".\.gitignore"

# Stop tracking venv safely
git rm -r --cached --ignore-unmatch $venvPath
Write-Host "Attempted to stop tracking $venvPath."

# Fix stray 'gitignore' (without dot) if present
if (Test-Path ".\gitignore" -PathType Leaf -ErrorAction SilentlyContinue) {
  if (-not (Test-Path $gitignorePath)) {
    Move-Item ".\gitignore" $gitignorePath -Force
    Write-Host "Renamed 'gitignore' -> '.gitignore'"
  } else {
    Remove-Item ".\gitignore" -Force
    Write-Host "Removed stray 'gitignore' (since .gitignore exists)."
  }
}

# Ensure .gitignore exists and contains venv entry
if (-not (Test-Path $gitignorePath)) {
  New-Item -Path $gitignorePath -ItemType File -Force | Out-Null
}

$found = Select-String -Path $gitignorePath -Pattern $venvPath -SimpleMatch -Quiet
if (-not $found) {
  Add-Content -Path $gitignorePath -Value $venvPath
  git add $gitignorePath
  if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
    git commit -m "chore: add venv to .gitignore and stop tracking venv"
    git push origin main
  } else {
    Write-Host "No .gitignore changes to commit."
  }
} else {
  Write-Host ".gitignore already contains $venvPath"
}
```

10) Hapus atau ignore skrip lokal `rename_notebooks.py` jika tidak ingin disimpan
```powershell
# Hapus dari repo jika ter-track
git rm --ignore-unmatch "social-media-sentiment-analysis/rename_notebooks.py"
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: remove local rename_notebooks helper"
  git push origin main
} else {
  Write-Host "rename_notebooks.py was not tracked or already removed."
}

# Atau: tambahkan ke .gitignore agar tidak muncul lagi
$entry = "social-media-sentiment-analysis/rename_notebooks.py"
if (-not (Select-String -Path .\.gitignore -Pattern $entry -SimpleMatch -Quiet)) {
  Add-Content .\.gitignore $entry
  git add .gitignore
  git commit -m "chore: ignore local rename_notebooks helper"
  git push origin main
}
```

11) Verifikasi akhir
```powershell
git status
git branch --show-current
git remote -v
Get-ChildItem -Path .\social-media-sentiment-analysis\ -File | Select-Object Name
```

12) Contoh output yang akan terlihat setelah notebook dijalankan
- Versi pandas (contoh):
```
pandas 2.3.3
```
- Hasil skor VADER (contoh):
```
{'neg': 0.0, 'neu': 0.323, 'pos': 0.677, 'compound': 0.6369}
```

Troubleshooting singkat
- Jika `jupyter nbconvert --execute` gagal karena paket belum terpasang, jalankan:
  `python -m pip install --user nbformat nbconvert jupyter nltk`
- NLTK resource `vader_lexicon` akan diunduh saat notebook dieksekusi karena kode memanggil `nltk.download("vader_lexicon", quiet=True)`. Pastikan koneksi internet tersedia.
- Pesan `git: 'credential-manager-core' is not a git command` hanya peringatan credential helper; push tetap dapat berhasil. Untuk menghapusnya, instal Git Credential Manager.

Jika Anda mau, saya bisa:
- Buat file PowerShell `.ps1` interaktif yang menjalankan langkah-langkah ini (menanyakan konfirmasi sebelum menghapus), atau
- Commit dan buat PR yang memperbarui README/penjelasan ini di repo — beri saya konfirmasi.
