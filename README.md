# Perbaikan & Instalasi Permanen Jupyter untuk proyek
Jalankan semua blok PowerShell ini dari folder proyek:
C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis

Saya telah menggabungkan pengecekan, perbaikan, pemasangan paket yang hilang, dan langkah untuk membuat beberapa pengaturan menjadi permanen (User‑level). Jalankan blok per blok (satu kali paste per blok). Jika sebuah blok mengeluarkan error, salin seluruh output error dan tempel di chat — saya bantu koreksi langkah spesifiknya.

---

## Catatan umum
- Buka PowerShell biasa (Run as Administrator hanya bila saya tandai).
- Jangan paste semuanya sekaligus — jalankan blok 1 → 2 → 3 … dst.
- Banyak perintah mengasumsikan venv berada di root proyek (.\venv). Jika struktur berbeda, sesuaikan path.
- Instalasi paket via pip di venv bersifat "permanen" untuk venv (tetap terpasang sampai venv dihapus). Mengatur SSL_CERT_FILE dengan [Environment]::SetEnvironmentVariable(...,'User') membuatnya permanen untuk user.

---

## 0) Lokasi aman (mulai di sini)
C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis

> Petunjuk: buka PowerShell (bukan Administrator kecuali dicatat), pindah ke path di atas, lalu jalankan tiap blok perintah di bawah secara berurutan. Jalankan satu blok, pastikan tidak error, lalu lanjut ke blok berikutnya.

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

## 8) Perbaiki env var sertifikat (SSL_CERT_FILE) — permanen untuk User (direkomendasikan)
```powershell
# install certifi ke venv
python -m pip install --upgrade certifi

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

## 9) Reinstall / perbaiki Jupyter & pasang semua paket core yang hilang (permanen di venv)
Semua perintah berikut menginstal ke venv aktif sehingga perubahan bersifat permanen untuk environment proyek ini (sampai venv dihapus).

```powershell
# upgrade pip/build tools
python -m pip install --upgrade pip setuptools wheel

# reinstall jupyter core & ipykernel (rewrite console_scripts)
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel

# install packages yang belum terpasang sebelumnya (ipywidgets, notebook, qtconsole) dan widget support
python -m pip install --upgrade ipywidgets notebook qtconsole widgetsnbextension

# enable widgets extension for classic notebook within this venv
jupyter nbextension enable --py widgetsnbextension --sys-prefix

# verify imports & versions (one line per check)
python -c "import ipywidgets; print('ipywidgets', getattr(ipywidgets,'__version__','n/a'))"
python -c "import notebook; print('notebook', getattr(notebook,'__version__','n/a'))"
python -c "import qtconsole; print('qtconsole', getattr(qtconsole,'__version__','n/a'))"
python -c "import jupyterlab; print('jupyterlab', getattr(jupyterlab,'__version__','n/a'))"

# show jupyter core summary
jupyter --version

# verify launcher executables in venv
Get-ChildItem .\venv\Scripts\*jupyter* -Force | Select-Object Name,FullName

# if any corrupted wrapper caused 'Unable to create process' earlier, remove and reinstall to rewrite them
Remove-Item .\venv\Scripts\jupyter.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-lab.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-notebook.exe -Force -ErrorAction SilentlyContinue
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
```

> Catatan: semua paket di atas dipasang ke dalam venv sehingga bersifat permanen untuk proyek ini (kecuali kamu menghapus venv).

---

## 10) Daftarkan kernel ipykernel untuk venv (persisted for user)
```powershell
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

Kernel ini akan muncul di Jupyter UI untuk user kamu sampai kamu uninstall kernelspec.

---

## 11) (Opsional) Freeze requirements (persistent file)
```powershell
python -m pip freeze > .\requirements.txt
Get-Content .\requirements.txt -TotalCount 30
```

---

## 12) Jalankan JupyterLab dan periksa log startup
```powershell
# hentikan server lama jika ada (Ctrl+C), lalu jalankan:
python -m jupyter lab

# jika perlu debug verbose:
# python -m jupyter lab --debug
```

Yang diharapkan: JupyterLab berjalan tanpa FileNotFoundError terkait SSL_CERT_FILE dan tanpa stacktrace untuk pypi extension manager. Buka URL yang diprint di terminal (http://localhost:8888/lab?...).

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

Jika salah satu langkah mengeluarkan error, salin seluruh output error langkah tersebut dan tempelkan di sini. Saya akan bantu perbaiki langkah spesifiknya agar JupyterLab berjalan bersih dan perubahan yang diperlukan bersifat permanen untuk proyekmu.
