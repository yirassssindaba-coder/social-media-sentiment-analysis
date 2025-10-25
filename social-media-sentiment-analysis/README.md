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

Panduan ini sudah disederhanakan dan diperbaiki untuk kondisi Anda:
- Hanya 1 cara untuk mengganti/menjaga notebook: gunakan git mv / overwrite satu file notebook bernama social-media-sentiment-analysis.ipynb.
- Perintah PowerShell-safe (tanpa operator shell non-PowerShell seperti `||`).
- Memperbaiki penanganan .gitignore / venv dan menghapus file Untitled* yang tersisa.
- Menyertakan instruksi cara mengganti isi notebook menjadi satu code cell sesuai permintaan Anda.

Catatan singkat sebelum mulai:
- Jalankan semua perintah dari root repository, mis. `C:\Users\ASUS\Desktop\python-project`.
- Jika menjalankan dari Jupyter, jalankan skrip Python sebagai proses shell: `!python ...` atau jalankan dari PowerShell langsung.

1) Masuk ke root repo dan verifikasi status
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
git status
git branch --show-current
git remote -v
```

2) Set / verifikasi remote URL (jika perlu)
```powershell
git remote set-url origin https://github.com/yirassssindaba-coder/python-project.git
git remote -v
```

3) Ambil update dari remote
```powershell
git fetch origin
```

4) Pastikan branch `main` lokal ada dan up-to-date (PowerShell-safe)
```powershell
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

5) Stage tracked changes & commit (jika ada perubahan tracked yang ingin Anda commit)
```powershell
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "feat: add/update social-media-sentiment-analysis project"
} else {
  Write-Host "No tracked changes to commit."
}
```

6) (SINGLE OPTION) Pastikan hanya 1 notebook: rename / buat social-media-sentiment-analysis.ipynb
- Tujuan: hanya ada satu notebook di folder `social-media-sentiment-analysis` bernama `social-media-sentiment-analysis.ipynb` dan isinya satu code-cell sesuai kode Anda.
- Jika Anda hanya perlu mengganti nama satu file Untitled1.ipynb yang sudah ada ke nama final, jalankan:
```powershell
# dari root repo
if (Test-Path "social-media-sentiment-analysis\Untitled1.ipynb") {
  git mv "social-media-sentiment-analysis\Untitled1.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb"
  git status --porcelain
  git commit -m "chore: rename Untitled1.ipynb -> social-media-sentiment-analysis.ipynb"
  git push origin main
} else {
  Write-Host "File 'social-media-sentiment-analysis\\Untitled1.ipynb' tidak ditemukan. Jika Anda ingin membuat notebook baru, lihat langkah pembuatan di bawah."
}
```

7) Jika Anda ingin membuat/overwrite notebook agar isinya tepat seperti yang Anda minta
- Buat script kecil yang menulis notebook (menggunakan nbformat). Simpan sebagai create_notebook.py, jalankan, lalu commit.
```powershell
# Buat file create_notebook.py (jalankan di PowerShell)
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
with open("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb", "w", encoding="utf-8") as f:
    nbf.write(nb, f)
print("Notebook written: social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb")
'@

# Pastikan folder ada
if (-not (Test-Path ".\social-media-sentiment-analysis")) {
  New-Item -ItemType Directory -Path ".\social-media-sentiment-analysis" | Out-Null
}

# Tulis script
Set-Content -Path ".\create_notebook.py" -Value $py -Encoding UTF8

# Jalankan script untuk membuat/overwrite notebook
python .\create_notebook.py

# Stage, commit, push the notebook
git add "social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb"
git commit -m "chore: create social-media-sentiment-analysis.ipynb with requested contents"
git push origin main

# Hapus helper script jika tidak diperlukan
Remove-Item .\create_notebook.py -Force
```

8) Hapus semua file Untitled*.ipynb ekstra (preview dulu, lalu hapus)
- Preview file yang akan dihapus:
```powershell
Get-ChildItem -Path . -Recurse -Filter "Untitled*.ipynb" | Select-Object FullName
```
- Jika sudah OK, hapus tracked/untracked Untitled* (git-aware):
```powershell
Get-ChildItem -Path . -Recurse -Filter "Untitled*.ipynb" | ForEach-Object {
  $full = $_.FullName
  $rel = $full.Replace((Get-Location).Path + "\", "")
  git rm --ignore-unmatch "$rel"
  if (Test-Path $full) { Remove-Item $full -Force -ErrorAction SilentlyContinue }
  Write-Host "Removed: $rel"
}

git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: remove leftover Untitled notebooks"
  git push origin main
} else {
  Write-Host "No changes to commit after removing Untitled files."
}
```

9) Hentikan tracking `venv` (PowerShell-safe) dan perbaiki .gitignore (dengan perilaku robust)
- Potongan ini menghindari error jika venv tidak ter-track dan memperbaiki kasus file `gitignore` (tanpa titik) yang mungkin dibuat tidak sengaja.
```powershell
$venvPath = "social-media-sentiment-analysis/venv"
$gitignorePath = ".\.gitignore"

# Stop tracking venv safely (no fatal error if not tracked)
git rm -r --cached --ignore-unmatch "$venvPath"
Write-Host "Attempted to stop tracking '$venvPath' (no error if it wasn't tracked)."

# If a stray 'gitignore' (without dot) exists, move or remove it appropriately
if (Test-Path ".\gitignore" -PathType Leaf -ErrorAction SilentlyContinue) {
  if (-not (Test-Path $gitignorePath)) {
    Move-Item -Path ".\gitignore" -Destination $gitignorePath -Force
    Write-Host "Renamed 'gitignore' -> '.gitignore'"
  } else {
    Remove-Item ".\gitignore" -Force
    Write-Host "Removed stray 'gitignore' (since .gitignore already exists)."
  }
}

# Ensure .gitignore exists
if (-not (Test-Path $gitignorePath)) {
  New-Item -Path $gitignorePath -ItemType File -Force | Out-Null
  Write-Host "Created .gitignore"
}

# Add venv path to .gitignore if not present
$found = Select-String -Path $gitignorePath -Pattern $venvPath -SimpleMatch -Quiet
if (-not $found) {
  Add-Content -Path $gitignorePath -Value $venvPath
  Write-Host "Added '$venvPath' to .gitignore"
  git add $gitignorePath
  if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
    git commit -m "chore: add venv to .gitignore and stop tracking venv"
    git push origin main
    Write-Host "Committed and pushed .gitignore update."
  } else {
    Write-Host "No changes staged after updating .gitignore."
  }
} else {
  Write-Host ".gitignore already contains an entry for '$venvPath'"
}
```

10) Hapus atau ignore skrip lokal `rename_notebooks.py` (jika tidak ingin disimpan di repo)
```powershell
# Remove from repo if tracked
git rm --ignore-unmatch "social-media-sentiment-analysis/rename_notebooks.py"
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  git commit -m "chore: remove local rename_notebooks helper"
  git push origin main
} else {
  Write-Host "rename_notebooks.py was not tracked or already removed."
}

# If you prefer to keep it locally but not commit, add to .gitignore
$entry = "social-media-sentiment-analysis/rename_notebooks.py"
if (-not (Select-String -Path .\.gitignore -Pattern $entry -SimpleMatch -Quiet)) {
  Add-Content .\.gitignore $entry
  git add .gitignore
  git commit -m "chore: ignore local rename_notebooks helper"
  git push origin main
} else {
  Write-Host ".gitignore already ignores rename_notebooks.py"
}
```

11) Push akhir & verifikasi
```powershell
git push origin main
git status
git branch --show-current
git remote -v
```

12) Troubleshooting singkat
- Warning "git: 'credential-manager-core' is not a git command." hanya peringatan credential helper; push tetap berhasil. Untuk menghilangkan, instal Git Credential Manager: https://aka.ms/gcm/latest
- Jika Jupyter menambahkan argumen kernel menyebabkan skrip Python error, jalankan skrip sebagai proses shell: `!python create_notebook.py` atau jalankan dari PowerShell `python .\create_notebook.py`.
- Selalu preview sebelum menghapus dengan `Get-ChildItem ... | Select-Object FullName` dan lakukan dry-run.
- Skrip "rename_notebooks.py" bersifat helper lokal — jika Anda tidak ingin memasukkannya di repo, hapus atau tambahkan ke .gitignore seperti di langkah 10.

--- 

Tambahan: isi notebook yang diminta
- Anda meminta agar file notebook final `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb` hanya berisi satu code cell dengan kode ini:

```python
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

print("pandas", pd.__version__)
nltk.download("vader_lexicon", quiet=True)
sid = SentimentIntensityAnalyzer()
print(sid.polarity_scores("I love this product"))
```

- Gunakan langkah 7 di atas untuk membuat/overwrite notebook tersebut secara otomatis (create_notebook.py) atau buka Jupyter, buat satu code cell dengan isi di atas lalu Save As → social-media-sentiment-analysis.ipynb.

Jika Anda setuju, saya bisa:
- 1) Commit/perbarui README (file ini) di repo dan buat PR, atau
- 2) Buat file PowerShell (.ps1) otomatis yang menjalankan langkah-langkah ini (dengan konfirmasi sebelum menghapus), lalu kirimkan kontennya agar Anda jalankan.

Sebutkan mana yang diinginkan.  
```
