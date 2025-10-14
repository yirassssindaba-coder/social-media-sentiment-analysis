# Lokasi aman untuk menjalankan perintah
C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis

> Petunjuk: buka PowerShell (bukan Administrator kecuali dicatat), pindah ke path di atas, lalu jalankan tiap blok perintah di bawah secara berurutan. Jalankan satu blok, pastikan tidak error, lalu lanjut ke blok berikutnya. Jika sebuah blok mengembalikan error, salin seluruh output error dan tempel di issue/chat agar dapat dibantu.

---

## 1) Pastikan kamu berada di root proyek yang benar
```powershell
# 1) cek lokasi kerja & file/folder root
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
# 2) cari folder bernama project di dalam folder saat ini (cek duplikat)
Get-ChildItem -Directory | Select-Object Name

# jika ada nested folder bernama "social-media-sentiment-analysis" di dalam,
# pindah ke parent yang berisi venv (sesuaikan path bila perlu):
# Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
```

---

## 3) Perbaiki session PATH sementara (jika where.exe/python tidak ditemukan)
```powershell
# 3) pastikan PATH session ada dan System32 tersedia
Write-Host "Session PATH exists?"; if ($env:PATH) { "Yes" } else { "No or empty" }
Get-Command where.exe -ErrorAction SilentlyContinue
Get-Command python -ErrorAction SilentlyContinue

# jika where.exe atau python tidak ditemukan, jalankan ini (session-only):
$machine = [Environment]::GetEnvironmentVariable('Path','Machine')
$user = [Environment]::GetEnvironmentVariable('Path','User')
$env:PATH = if ($user) { $machine + ';' + $user } else { $machine }
if (-not ($env:PATH -match 'Windows\\System32')) { $env:PATH += ';C:\Windows\System32' }

# verifikasi
Get-Command where.exe -ErrorAction SilentlyContinue
Get-Command python -ErrorAction SilentlyContinue
```

---

## 4) Temukan interpreter Python sistem dan set $PY
```powershell
# 4) cari python.exe sistem sehingga venv dibuat/pakai interpreter yang benar
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
# 5) pastikan venv ada & berisi python.exe
Test-Path .\venv\Scripts\python.exe
Get-ChildItem .\venv\Scripts\* -ErrorAction SilentlyContinue | Select-Object Name

# Jika venv tidak ada atau rusak: (akan menghapus venv lama jika ada)
if (-not (Test-Path .\venv\Scripts\python.exe)) {
  if (Test-Path .\venv) { Remove-Item -Recurse -Force .\venv }
  & $PY -m venv .\venv
}

# verifikasi akhir
Test-Path .\venv\Scripts\python.exe
```

---

## 6) Pastikan ExecutionPolicy untuk menjalankan Activate.ps1 (CurrentUser)
```powershell
# 6) cek kebijakan eksekusi & set aman untuk CurrentUser bila perlu
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

---

## 7) Aktifkan venv dengan dot‑sourcing dan verifikasi interpreter venv
```powershell
# 7) dot-source Activation (perhatikan titik + spasi)
. .\venv\Scripts\Activate.ps1

# verifikasi bahwa python sekarang menunjuk ke venv
python --version
python -c "import sys; print('sys.executable=', sys.executable)"
python -m pip --version

# jika Activate.ps1 masih tidak ditemukan, gunakan python langsung:
# .\venv\Scripts\python.exe --version
```

---

## 8) Perbaiki env var sertifikat yang menyebabkan Jupyter extension error
```powershell
# 8A) Direkomendasikan: arahkan SSL_CERT_FILE ke certifi (session & optional user)
python -m pip install --upgrade certifi
$cert = & python -c "import certifi; print(certifi.where())"
$env:SSL_CERT_FILE = $cert
# (opsional, permanen):
# [Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$cert,'User')
Write-Host "Using SSL_CERT_FILE = $env:SSL_CERT_FILE"

# 8B) Atau: jika kamu yakin var menunjuk file hilang, hapus untuk session & user
# Remove-Item Env:\SSL_CERT_FILE -ErrorAction SilentlyContinue
# [Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$null,'User')

# cek env var terkait
Get-ChildItem Env: | Where-Object Name -match 'CERT|SSL|REQUESTS|CURL|COMPOSER|PHP' | Format-Table Name,Value -AutoSize
```

---

## 9) Reinstall / perbaiki Jupyter & launcher di dalam venv
```powershell
# 9) pastikan venv aktif, lalu perbarui & reinstall jupyter agar wrapper exe menunjuk ke python venv
python -m pip install --upgrade pip setuptools wheel
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel

# verifikasi launcher jupyter di venv
Get-ChildItem .\venv\Scripts\*jupyter* -Force | Select-Object Name,FullName

# bila masih ada launcher yang rusak, hapus lalu reinstall:
Remove-Item .\venv\Scripts\jupyter.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-lab.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-notebook.exe -Force -ErrorAction SilentlyContinue
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
```

---

## 10) Daftarkan kernel ipykernel untuk venv
```powershell
# 10) register kernel (aman dijalankan ulang)
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

---

## 11) (Opsional) Freeze requirements dari venv
```powershell
# 11) buat requirements.txt dari venv agar bisa recreate environment nanti
python -m pip freeze > .\requirements.txt
Get-Content .\requirements.txt -TotalCount 20
```

---

## 12) Jalankan JupyterLab dan periksa log startup
```powershell
# 12) hentikan server lama jika ada (Ctrl+C), lalu jalankan:
python -m jupyter lab

# Jika perlu debug verbose:
# python -m jupyter lab --debug
```

---

## Pemeriksaan cepat bila masih ada error
```powershell
# cek env cert vars
Get-ChildItem Env: | Where-Object Name -match 'CERT|SSL|REQUESTS|CURL|COMPOSER|PHP' | Format-Table Name,Value -AutoSize

# cek jupyter versions
jupyter --version
python -m jupyter lab --version

# cek exe wrapper jupyter yang aktif
(Get-Command jupyter -ErrorAction SilentlyContinue).Source

# jika jupyter gagal start, jalankan debug dan paste log:
python -m jupyter lab --debug
```

---

Jika kamu jalankan tiap blok berurutan dan tetap mendapat error pada salah satu langkah, salin seluruh output error dari langkah tersebut dan tempel di sini. Saya akan bantu koreksi langkah spesifiknya.
