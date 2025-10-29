# Menjalankan run_myproject.ps1 — Panduan Lengkap (PowerShell)

Dokumen ini menjelaskan cara menjalankan skrip PowerShell `run_myproject.ps1` untuk menyiapkan environment (virtualenv), menginstall dependency, dan mengeksekusi skrip analisis sentimen pada proyek Anda. Instruksi ditulis agar mudah disalin dan dicetak.

Lokasi proyek contoh yang dipakai di panduan:
C:\Users\ASUS\Desktop\python-project-remote

Lokasi contoh runner:
C:\temp\run_myproject.ps1

Catatan singkat:
- Gunakan PowerShell 7 (`pwsh`) bila tersedia, tetapi Windows PowerShell 5.1 juga didukung.
- Jalankan PowerShell sebagai user biasa kecuali Anda perlu `winget` melakukan instalasi otomatis (butuh admin).
- Jika ExecutionPolicy mencegah eksekusi, gunakan parameter `-ExecutionPolicy Bypass` saat memanggil file `.ps1`.

---

## Isi README ini
1. Persiapan singkat  
2. Menemukan entrypoint (file .py) di folder scripts  
3. Perintah Set-Location + eksekusi run_myproject.ps1 (copy → paste)  
4. Contoh panggilan dengan opsi umum  
5. Memeriksa log dan hasil  
6. Variabel lingkungan / API keys  
7. Troubleshooting umum  
8. Opsi: wrapper yang otomatis set-location lalu menjalankan runner

---

## 1) Persiapan singkat
- Pastikan Git terpasang: `git --version`  
- Pastikan Python 3.8+ terpasang: `python --version`  
- Simpan file `run_myproject.ps1` di lokasi yang mudah diakses (mis. `C:\temp\run_myproject.ps1`)  
- Pastikan folder proyek Anda ada (contoh: `C:\Users\ASUS\Desktop\python-project-remote`) dan di dalamnya ada folder `scripts\` berisi file .py yang menjadi entrypoint.

---

## 2) Menemukan entrypoint di folder scripts
Jalankan salah satu perintah ini untuk melihat semua file Python di folder scripts:
- PowerShell 7 / pwsh:
```powershell
pwsh -NoProfile -Command "Get-ChildItem -Path 'C:\Users\ASUS\Desktop\python-project-remote\scripts' -Filter *.py -Recurse | Select-Object FullName"
```
- Windows PowerShell:
```powershell
powershell -NoProfile -Command "Get-ChildItem -Path 'C:\Users\ASUS\Desktop\python-project-remote\scripts' -Filter *.py -Recurse | Select-Object FullName"
```
Catat nama file yang Anda anggap sebagai entrypoint (mis. `run_sentiment.py`, `run.py`, `main.py`, dsb).

---

## 3) Set-Location lalu jalankan run_myproject.ps1 (copy → paste)
Jika `run_myproject.ps1` disimpan di `C:\temp` dan repo lokal ada di `C:\Users\ASUS\Desktop\python-project-remote`, gunakan contoh berikut.

Contoh (PowerShell 7 / pwsh):
```powershell
pwsh -NoProfile -Command "Set-Location 'C:\Users\ASUS\Desktop\python-project-remote'; & 'C:\temp\run_myproject.ps1' -CloneDir (Get-Location) -Entrypoint 'scripts\run_sentiment.py' -ForceRecreateVenv"
```

Contoh (Windows PowerShell):
```powershell
powershell -NoProfile -Command "Set-Location 'C:\Users\ASUS\Desktop\python-project-remote'; & 'C:\temp\run_myproject.ps1' -CloneDir (Get-Location) -Entrypoint 'scripts\run_sentiment.py' -ForceRecreateVenv"
```

Penjelasan parameter:
- `-CloneDir (Get-Location)` → memberi path repo sekarang ke runner sehingga script tidak meng-clone ulang.
- `-Entrypoint 'scripts\run_sentiment.py'` → ganti sesuai nama file entrypoint Anda.
- `-ForceRecreateVenv` → opsional; hapus .venv lama lalu buat venv baru.

Jika Anda lebih suka memanggil runner dari folder lain tetapi ingin runner bekerja pada repo tertentu:
```powershell
pwsh -ExecutionPolicy Bypass -File "C:\temp\run_myproject.ps1" -CloneDir "C:\Users\ASUS\Desktop\python-project-remote" -Entrypoint "scripts\run_sentiment.py"
```

---

## 4) Contoh panggilan lain yang berguna
- Hanya jalankan tanpa recreate venv (pakai venv yang ada jika tersedia):
```powershell
pwsh -ExecutionPolicy Bypass -File "C:\temp\run_myproject.ps1" -CloneDir "C:\Users\ASUS\Desktop\python-project-remote" -Entrypoint "scripts\run_sentiment.py"
```
- Jika repo belum di-clone dan Anda ingin runner yang otomatis meng-clone dari URL:
```powershell
pwsh -ExecutionPolicy Bypass -File "C:\temp\run_myproject.ps1" -RepoUrl "https://github.com/yirassssindaba-coder/myproject.git" -Entrypoint "scripts\run_sentiment.py"
```

---

## 5) Memeriksa log dan hasil
- Log setup (tempat Anda menjalankan `run_myproject.ps1`):
  - `run_myproject.log` (file dibuat di working directory tempat Anda menjalankan perintah)
  - Tampilkan tail:
```powershell
Get-Content .\run_myproject.log -Tail 200
```
- Log eksekusi skrip (di root repo setelah runner masuk ke repo):
  - `C:\Users\ASUS\Desktop\python-project-remote\run_execution.log`
```powershell
Get-Content "C:\Users\ASUS\Desktop\python-project-remote\run_execution.log" -Tail 400
```
- Folder hasil (default):  
  `C:\Users\ASUS\Desktop\python-project-remote\results`  
  Tampilkan isinya:
```powershell
Get-ChildItem "C:\Users\ASUS\Desktop\python-project-remote\results" -Recurse
```

---

## 6) Menyediakan API keys / environment variables
Jika skrip membutuhkan kunci API (mis. Twitter), set environment variables di sesi PowerShell yang sama sebelum memanggil runner:
```powershell
$env:TWITTER_API_KEY = "xxxx"
$env:TWITTER_API_SECRET = "yyyy"
# lalu jalankan perintah pwsh/powershell seperti contoh di atas
```
Jangan masukkan secret sensitif ke dalam file README atau commit ke git.

---

## 7) Troubleshooting umum (rapid fixes)
- ExecutionPolicy mencegah eksekusi:
  - Gunakan parameter `-ExecutionPolicy Bypass` (lihat contoh panggilan).
  - Atau jalankan: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`
- `git` atau `python` tidak ditemukan:
  - Install manual: Git (https://git-scm.com), Python (https://python.org), lalu restart PowerShell.
  - `run_myproject.ps1` mencoba menggunakan `winget` otomatis jika tersedia (memerlukan admin).
- `pip install` gagal karena build tools:
  - Install Visual C++ Build Tools (https://visualstudio.microsoft.com/visual-cpp-build-tools/).
- Entrypoint auto-detection salah:
  - Tentukan entrypoint eksplisit dengan `-Entrypoint "scripts\your_script.py"`.
- Repo privat:
  - Clone manual menggunakan SSH or HTTPS+PAT sebelum menjalankan runner, atau jalankan runner dengan `-CloneDir` yang menunjuk ke folder yang sudah diclone.

---

## 8) Opsi wrapper: otomatis Set-Location lalu panggil runner
Simpan file ini sebagai `run_and_execute.ps1` (opsional):
```powershell
param(
  [string]$RepoDir = "C:\Users\ASUS\Desktop\python-project-remote",
  [string]$RunnerScript = "C:\temp\run_myproject.ps1",
  [string]$Entrypoint = "scripts\run_sentiment.py",
  [switch]$ForceRecreateVenv
)
Set-Location $RepoDir
$invokeArgs = @('-CloneDir', (Get-Location).Path, '-Entrypoint', $Entrypoint)
if ($ForceRecreateVenv) { $invokeArgs += '-ForceRecreateVenv' }
& $RunnerScript @invokeArgs
```
Contoh jalankan wrapper:
```powershell
pwsh -ExecutionPolicy Bypass -File "C:\temp\run_and_execute.ps1" -ForceRecreateVenv
```

---

## Tips pencetakan / copy-paste
- File ini ditulis agar mudah disalin seluruhnya (copy → paste) ke editor, lalu dicetak.
- Untuk mencetak dari PowerShell ISE / VS Code: buka file README.md lalu Print (Ctrl+P) atau gunakan fitur "Export to PDF" di editor.

---

Itu dia: README ini sudah saya susun untuk Anda; Anda tinggal menempelkan file ini sebagai `README.md` di root proyek Anda. Setelah Anda menjalankan perintah di atas dan bila muncul error, kirimkan 150–400 baris terakhir dari `run_myproject.log` dan `run_execution.log` — saya akan bantu analisis langkah per langkah. Saya juga bisa membuat file wrapper `run_and_execute.ps1` atau menaruh `deploy-clean.ps1` ke repo jika Anda ingin otomatisasi lebih lanjut.
