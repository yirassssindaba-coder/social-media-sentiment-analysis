# Perbaikan & Instalasi Permanen Jupyter untuk proyek (Windows)

Dokumentasi ini berisi panduan lengkap untuk membuat environment Python/venv, menginstal paket yang diperlukan untuk proyek social-media-sentiment-analysis, mengatur SSL cert secara permanen, mendaftarkan kernel, dan memperbaiki masalah instalasi Jupyter/JupyterLab di Windows — termasuk solusi untuk error:

`ERROR: Could not install packages due to an OSError: [WinError 32] The process cannot access the file because it is being used by another process: '...jupyter-lab.exe' -> '...jupyter-lab.exe.deleteme'`

File ini dirancang agar Anda bisa menjalankan potongan-potongan PowerShell (blok) satu-per-satu dari root proyek:
`C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

> Petunjuk ringkas:
> - Jalankan setiap blok secara berurutan (1 → 2 → ... → 12).
> - Jika instalasi pip gagal dengan WinError 32, jalankan Block 10b (Release locks) yang tersedia di bawah.
> - Buka PowerShell normal; jalankan sebagai Administrator hanya bila diminta.
> - Jangan paste semua blok sekaligus — jalankan satu blok, periksa output, lanjut ke blok berikutnya.

---

## Isi singkat
- Blok 0–7: verifikasi lokasi, PATH, temukan Python, buat/aktifkan venv, set ExecutionPolicy.
- Blok 8: pasang paket utama (pandas, jupyterlab, dll.).
- Blok 9: set SSL_CERT_FILE permanen via certifi.
- Blok 10: reinstall Jupyter (normal).
- Blok 10b: Release locks & retry (otomatis hentikan proses terkait, hapus .deleteme/exe, reinstall dengan retry) — gunakan hanya bila muncul WinError 32.
- Blok 11–12: daftar kernel ipykernel dan jalankan JupyterLab; verifikasi.

---

## Cara menggunakan
1. Buka PowerShell.
2. Pindah ke folder proyek:
   ```
   cd C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis
   ```
3. Jalankan setiap blok sesuai urutan. Bila muncul error pada suatu blok, salin seluruh output error dan kirim di chat untuk dukungan lebih lanjut.

---

## Blok PowerShell (jalankan satu-blok-per-paste)
Berikut adalah semua blok yang Anda perlukan. Ikuti urutan.

### 0) Lokasi aman — verifikasi Anda berada di root proyek
```powershell
Get-Location
Get-ChildItem -Name

# verifikasi file/folder penting (sesuaikan nama file jika berbeda)
Test-Path .\venv
Test-Path .\src\main.py
Test-Path .\README.md
```

### 1) Periksa nested folder (hindari path ganda)
```powershell
Get-ChildItem -Directory | Select-Object Name

# jika ada nested dengan nama project, pindah ke parent yang benar:
# Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
```

### 2) Perbaiki session PATH sementara (jika where.exe/python tidak ditemukan)
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

### 3) Temukan interpreter Python sistem dan set $PY
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

### 4) Cek / buat ulang venv jika perlu (jalankan di root proyek)
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

### 5) Pastikan ExecutionPolicy agar Activate.ps1 bisa dijalankan (CurrentUser)
```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```
(Anda mungkin diminta konfirmasi; jawab `Y`.)

### 6) Aktifkan venv (dot‑sourcing) dan verifikasi interpreter venv
```powershell
. .\venv\Scripts\Activate.ps1

# verifikasi
python --version
python -c "import sys; print('sys.executable=', sys.executable)"
python -m pip --version

# jika Activate.ps1 tidak ditemukan, gunakan:
# .\venv\Scripts\python.exe --version
```

### 7) Install semua module utama untuk data science, Jupyter, analisis sentimen, dan web scraping
> Pastikan venv aktif sebelum menjalankan ini.
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

# Enable widgets extension for classic notebook
jupyter nbextension enable --py widgetsnbextension --sys-prefix

# Download resource NLTK 'vader_lexicon'
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"

# Freeze requirements
python -m pip freeze > requirements.txt
```

> Catatan: Jika Anda menggunakan Python 3.14, hindari `pyarrow` karena belum tersedia wheel. Gunakan Python 3.11/3.12 jika perlu `pyarrow`.

### 8) Perbaiki env var sertifikat (SSL_CERT_FILE) — permanen untuk User (direkomendasikan)
```powershell
$cert = & python -c "import certifi; print(certifi.where())"
$env:SSL_CERT_FILE = $cert
Write-Host "Using SSL_CERT_FILE (session) = $env:SSL_CERT_FILE"

# set permanen untuk User
[Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$cert,'User')
Write-Host "SSL_CERT_FILE set permanently for User to: $cert"

# cek env var terkait
Get-ChildItem Env: | Where-Object Name -match 'CERT|SSL|REQUESTS|CURL|COMPOSER|PHP' | Format-Table Name,Value -AutoSize
```

---

## 9) Reinstall / perbaiki Jupyter & pasang ulang launcher jika error (permanen di venv)

Jalankan blok normal berikut. Jika berhasil tanpa WinError 32, Anda dapat lanjut ke langkah 11–12. Jika `pip` mengembalikan WinError 32 berkaitan dengan `jupyter-lab.exe.deleteme`, lanjutkan ke Block 10b (Release locks).

```powershell
# BLOCK 10 - Reinstall Jupyter (normal)
Write-Host "=== Block 10: Reinstall Jupyter packages (normal) ===" -ForegroundColor Cyan

# Pastikan venv aktif (jalankan .\venv\Scripts\Activate.ps1 sebelumnya)
$venvScripts = Join-Path (Resolve-Path .\venv).ProviderPath "Scripts"
Write-Host "Inspecting venv Scripts folder: $venvScripts"
Get-ChildItem -Path $venvScripts -Filter "*jupyter*" -Force -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTime

# Remove known wrapper files if present (non-fatal)
$wrappers = @("jupyter.exe","jupyter-lab.exe","jupyter-notebook.exe","jupyter-server.exe")
foreach ($w in $wrappers) {
    $p = Join-Path $venvScripts $w
    if (Test-Path $p) {
        try { Remove-Item -LiteralPath $p -Force -ErrorAction Stop; Write-Host "Removed wrapper: $p" -ForegroundColor Green }
        catch { Write-Host "Warning: failed to delete $p : $($_.Exception.Message)" -ForegroundColor Yellow }
    }
    $d = $p + ".deleteme"
    if (Test-Path $d) {
        try { Remove-Item -LiteralPath $d -Force -ErrorAction Stop; Write-Host "Removed .deleteme: $d" -ForegroundColor Green }
        catch { Write-Host "Warning: failed to delete $d : $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

# Reinstall jupyter packages (single attempt)
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
Write-Host "Block 10 completed. If pip failed with WinError 32, run Block 10b."
```

---

### 10) BLOCK 10b — Release locks & reattempt reinstall (gunakan bila muncul WinError 32)
Blok ini:
- Mendeteksi proses yang mungkin mengunci file launcher (jupyter/jupyter-lab/python/node)
- Menampilkan proses dan meminta konfirmasi sebelum menghentikannya (aman)
- Menghapus file `.deleteme` dan executable yang bermasalah
- Melakukan retry pip install beberapa kali
- Jika masih gagal, berikan rekomendasi (antivirus, reboot, Process Explorer)

**Jalankan blok ini hanya jika Anda melihat WinError 32 saat instal.**
```powershell
### BLOCK 10b - Release locks & retry install (run only if you saw WinError 32)
Write-Host "=== Block 10b: Release locks and retry install ===" -ForegroundColor Cyan

# venv Scripts path
$venvScripts = Join-Path (Resolve-Path .\venv).ProviderPath "Scripts"
Write-Host "Inspecting venv Scripts folder: $venvScripts"

# Helper function to attempt pip installs with retries
function Retry-PipInstall([string[]]$pkgs, [int]$tries=3, [int]$delaySec=3) {
    for ($i=1; $i -le $tries; $i++) {
        Write-Host "pip install attempt $i of $tries for: $($pkgs -join ', ')" -ForegroundColor Cyan
        try {
            python -m pip install --upgrade --force-reinstall $pkgs 2>&1 | Tee-Object -Variable pipOut
            if ($LASTEXITCODE -eq 0) { Write-Host "pip install succeeded." -ForegroundColor Green; return $true }
            else { Write-Host "pip install returned exit code $LASTEXITCODE. Output below:" -ForegroundColor Yellow; $pipOut; Start-Sleep -Seconds $delaySec }
        } catch {
            Write-Host "Exception during pip install: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds $delaySec
        }
    }
    return $false
}

# Find candidate processes that may lock files
$likelyNames = @("jupyter","jupyter-lab","python","pythonw","node")
$found = Get-Process -ErrorAction SilentlyContinue | Where-Object { $likelyNames -contains $_.Name } | Select-Object Id,Name,Path
if ($found) {
    Write-Host "Found potentially relevant processes (will list and then stop them) :" -ForegroundColor Yellow
    $found | Format-Table -AutoSize
    # Prompt user to continue stopping processes
    $ans = Read-Host "Stop these processes now? (Y/N) [recommended Y]"
    if ($ans -match '^[Yy]') {
        foreach ($pr in $found) {
            try { Write-Host "Stopping process Id=$($pr.Id) Name=$($pr.Name)" -ForegroundColor Yellow; Stop-Process -Id $pr.Id -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 300 }
            catch { Write-Host "Could not stop process Id=$($pr.Id) : $($_.Exception.Message)" -ForegroundColor Red }
        }
    } else {
        Write-Host "User declined to stop processes. You can stop them manually (Task Manager) and re-run this block." -ForegroundColor Yellow
    }
} else {
    Write-Host "No matching processes found by name. Continuing..." -ForegroundColor Green
}

# Optional: use handle.exe (Sysinternals) if installed
$handleExe = (Get-Command handle.exe -ErrorAction SilentlyContinue).Source
if (-not $handleExe) {
    $possibleHandlePath = "$env:ProgramFiles\Sysinternals\handle.exe"
    if (Test-Path $possibleHandlePath) { $handleExe = $possibleHandlePath }
}
if ($handleExe) {
    Write-Host "Using handle.exe to find locks on jupyter-lab.exe (may require Admin)..." -ForegroundColor Cyan
    $targetExe = Join-Path $venvScripts "jupyter-lab.exe"
    try { & $handleExe $targetExe 2>&1 | Tee-Object -Variable handleOut; $handleOut | Write-Host } catch { Write-Host "handle.exe invocation failed or requires elevation." -ForegroundColor Yellow }
} else {
    Write-Host "handle.exe not found — skip advanced handle check. Use Process Explorer (Sysinternals) if needed." -ForegroundColor Yellow
}

# Attempt to remove .deleteme and exe (retry)
$exePath = Join-Path $venvScripts "jupyter-lab.exe"
$deleteme = $exePath + ".deleteme"
for ($i=1; $i -le 6; $i++) {
    try {
        if (Test-Path $deleteme) { Write-Host "Attempting to remove $deleteme (try $i)"; Remove-Item -LiteralPath $deleteme -Force -ErrorAction Stop }
        if (Test-Path $exePath)  { Write-Host "Attempting to remove $exePath (try $i)"; Remove-Item -LiteralPath $exePath -Force -ErrorAction Stop }
        break
    } catch {
        Write-Host "Remove attempt $i failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-Sleep -Seconds (1 * $i)
    }
}

# Retry pip install with multiple attempts
$pkgs = @("jupyter","jupyterlab","ipykernel")
$ok = Retry-PipInstall -pkgs $pkgs -tries 3 -delaySec 3
if (-not $ok) {
    Write-Host "Reinstall still failed. Common causes: antivirus locking files, other python processes, or permissions." -ForegroundColor Red
    Write-Host "- Close all IDEs and terminals (VSCode, PyCharm, PowerShell, CMD), stop Jupyter services." -ForegroundColor Yellow
    Write-Host "- Temporarily disable antivirus or add exception for the venv folder." -ForegroundColor Yellow
    Write-Host "- Reboot Windows and re-run this Block (10b)." -ForegroundColor Yellow
} else {
    Write-Host "Reinstall successful." -ForegroundColor Green
}

# List jupyter wrappers present after the attempt
Get-ChildItem -Path $venvScripts -Filter "*jupyter*" -Force -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTime
Write-Host "Block 10b finished."
```

---

## 11) Daftarkan kernel ipykernel untuk venv (persisted for user)
```powershell
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

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

Cek versi, kernel, dan paket penting:
```powershell
python --version
jupyter --version
jupyter kernelspec list

python -c "import ipywidgets, notebook, qtconsole; print('ipywidgets', getattr(ipywidgets,'__version__','n/a')); print('notebook', getattr(notebook,'__version__','n/a')); print('qtconsole', getattr(qtconsole,'__version__','n/a'))"
```

Tes runtime sederhana (jalankan di cell notebook):
```python
import pandas as pd
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

print('pandas', pd.__version__)
nltk.download('vader_lexicon', quiet=True)
sid = SentimentIntensityAnalyzer()
print(sid.polarity_scores("I love this product"))
```

---

## Tips lanjutan & troubleshooting
- Jika 10b tidak melepaskan kunci: pakai Process Explorer (Sysinternals) untuk menemukan handle yang menahan file; hentikan proses itu lalu hapus `.deleteme`.
- Jika antivirus menyebabkan masalah: tambahkan pengecualian untuk folder venv atau nonaktifkan sementara real-time protection saat melakukan reinstall.
- Jika masih gagal: reboot Windows lalu jalankan Block 10b segera setelah boot sebelum membuka editor.

---

Jika Anda ingin, saya bisa:
- Mengubah Block 10b menjadi varian interaktif (konfirmasi per-proses) — lebih aman di lingkungan produksi.
- Membuat skrip tunggal yang menjalankan semua pemeriksaan dan menyediakan checkpoint interaktif.
- Membuat versi dokumentasi dalam bahasa Inggris juga.

Jika Anda sudah siap, jalankan Block 10 terlebih dahulu (atau langsung Block 10b jika sudah melihat WinError 32). Jika ada error, tempel semua keluaran error di sini dan saya bantu analisis detail.
