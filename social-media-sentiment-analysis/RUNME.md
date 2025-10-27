# RUNME — Social Media Sentiment Analysis

Tujuan  
Dokumen ini menjelaskan langkah-langkah singkat dan dapat langsung dijalankan (PowerShell) untuk men-setup environment, menjalankan notebook/script di folder `social-media-sentiment-analysis`, menghasilkan keluaran ke folder `results`, serta menyimpan file RUNME.md ke repo dan memasukkannya ke Git. Dokumen dibuat agar mudah disalin, disimpan, dan dicetak.

Lokasi target (contoh)
- Root repo contoh: `C:\Users\ASUS\Desktop\python-project`
- Folder project: `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`
- Lokasi RUNME.md yang disarankan:  
  `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis\RUNME.md`

Penting sebelum menjalankan
- Jalankan setiap baris per baris di PowerShell (jangan gabungkan dengan `&&`/`||`; gunakan `;` jika perlu).
- Jangan jalankan perintah yang Anda tidak pahami.
- Jika branch utama Anda bukan `main`, ganti `main` pada perintah git.
- Pastikan Anda berada di mesin lokal yang memiliki akses ke repo dan internet (untuk pip/git lfs).

1) Simpan RUNME.md ke folder repo
Simpan dokumen ini langsung sebagai file RUNME.md pada lokasi project. Pilih salah satu metode:

Cara A — manual (direkomendasikan)
1. Buka editor (VS Code, Notepad).
2. Salin seluruh isi file ini dan Save As ke:
   `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis\RUNME.md`

Cara B — salin dari file sumber
1. Buka PowerShell dan jalankan (sesuaikan path sumber):
```powershell
$targetDir = 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
$sourcePath = 'C:\path\to\your\RUNME_source.md'  # GANTI dengan path nyata
if (Test-Path $sourcePath) {
  Copy-Item -Path $sourcePath -Destination (Join-Path $targetDir 'RUNME.md') -Force
  Write-Host "RUNME.md disalin ke $targetDir"
} else {
  Write-Host "Sumber tidak ditemukan: $sourcePath" -ForegroundColor Yellow
}
```

Cara C — buat file kosong lalu edit
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path '.\RUNME.md')) { New-Item -Path '.\RUNME.md' -ItemType File -Force }
notepad .\RUNME.md   # atau: code .\RUNME.md untuk VS Code
```

2) Persyaratan dasar (prerequisites)
- Git terpasang dan terkonfigurasi (user.name, user.email).
- Python 3.8+ (atau versi yang sesuai project).
- (Opsional) Git LFS jika Anda menyimpan file besar.
- Virtual environment (direkomendasikan .venv di root repo).

3) Buat dan aktifkan virtual environment
Jalankan dari root repo:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# buat virtualenv jika belum ada
python -m venv .venv

# aktifkan (PowerShell)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # bila perlu
.\.venv\Scripts\Activate.ps1

# verifikasi Python
python --version
pip --version
```

4) Instal dependensi
Jika ada file requirements.txt di root atau di folder project, instal:
```powershell
# contoh: requirements di root or di folder social-media-sentiment-analysis
python -m pip install --upgrade pip
if (Test-Path '.\requirements.txt') {
  python -m pip install -r .\requirements.txt
}
if (Test-Path '.\social-media-sentiment-analysis\requirements.txt') {
  python -m pip install -r .\social-media-sentiment-analysis\requirements.txt
}
```

5) Periksa .gitignore dan file besar  
Pastikan folder `results` tidak di-ignore dan tidak ada file >100MB.

- Periksa .gitignore untuk pola results:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Select-String -Path .gitignore -Pattern "results","social-media-sentiment-analysis/results" -SimpleMatch -Quiet
if ($?) { Write-Host ".gitignore mungkin mengecualikan results — periksa .gitignore" -ForegroundColor Yellow } else { Write-Host ".gitignore tidak mengecualikan results (sementara)." -ForegroundColor Green }
```

- Solusi aman untuk memeriksa folder results tanpa error "path not found":  
  skrip di bawah memeriksa keberadaan folder sebelum memanggil Get-ChildItem, menampilkan daftar file jika ada, dan menampilkan file >100MB jika ditemukan. Salin dan jalankan baris-per-baris.

```powershell
# Sesuaikan path repo/project jika perlu
$repoRoot   = 'C:\Users\ASUS\Desktop\python-project'
$projectDir = Join-Path $repoRoot 'social-media-sentiment-analysis'
$resultsDir = Join-Path $projectDir 'results'

# Jika Anda ingin skrip membuat folder yang hilang, ubah ke $true
$autoCreateMissingFolders = $true

# Pastikan root repo ada
if (-not (Test-Path -Path $repoRoot)) {
  Write-Host "Repo root tidak ditemukan: $repoRoot" -ForegroundColor Red
  return
}

# Pastikan folder project ada (buat jika perlu)
if (-not (Test-Path -Path $projectDir)) {
  Write-Host "Folder project tidak ditemukan: $projectDir" -ForegroundColor Yellow
  if ($autoCreateMissingFolders) {
    New-Item -Path $projectDir -ItemType Directory -Force | Out-Null
    Write-Host "Membuat folder project: $projectDir" -ForegroundColor Green
  } else {
    Write-Host "Batalkan operasi. Buat folder project atau perbaiki path terlebih dahulu." -ForegroundColor Red
    return
  }
} else {
  Write-Host "Folder project ada: $projectDir" -ForegroundColor Green
}

# Pastikan folder results ada (buat jika perlu)
if (-not (Test-Path -Path $resultsDir)) {
  Write-Host "Folder results tidak ditemukan: $resultsDir" -ForegroundColor Yellow
  if ($autoCreateMissingFolders) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
    Write-Host "Membuat folder results kosong: $resultsDir" -ForegroundColor Green
  } else {
    Write-Host "Tidak ada folder results. Jika Anda ingin melanjutkan tanpa folder results, abaikan peringatan ini." -ForegroundColor Yellow
  }
} else {
  Write-Host "Folder results ada: $resultsDir" -ForegroundColor Green
}

# Ambil daftar file secara aman (hanya jika folder ada)
$files = @()
if (Test-Path -Path $resultsDir) {
  try {
    $files = Get-ChildItem -Path $resultsDir -Recurse -File -ErrorAction Stop
  } catch {
    Write-Host "Gagal membaca folder results: $($_.Exception.Message)" -ForegroundColor Red
  }
} else {
  Write-Host "Lewati pemeriksaan file results karena folder tidak ada." -ForegroundColor Yellow
}

# Tampilkan ringkasan file jika ada
if ($files -and $files.Count -gt 0) {
  $files | Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize
} else {
  Write-Host "Tidak ada file di $resultsDir." -ForegroundColor Yellow
}

# Cari file > 100 MB
if ($files -and $files.Count -gt 0) {
  $bigFiles = $files | Where-Object { $_.Length -gt 100MB }
  if ($bigFiles -and $bigFiles.Count -gt 0) {
    Write-Host "File >100MB ditemukan (pindah atau gunakan Git LFS):" -ForegroundColor Yellow
    $bigFiles | Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize
  } else {
    Write-Host "Tidak ada file >100MB di $resultsDir." -ForegroundColor Green
  }
}
```

Jika ada file >100MB, pindahkan atau aktifkan Git LFS (langkah 6).

6) (Opsional) Setup Git LFS  
Jika Anda perlu melacak file besar:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git lfs install
git lfs track "social-media-sentiment-analysis/results/**"
git add .gitattributes
git commit -m "chore: track results via git-lfs" 2>$null
```
Periksa kuota LFS di remote sebelum mendorong banyak file besar.

7) Menjalankan notebook untuk menghasilkan outputs (folder `results`)  
Pilih salah satu metode untuk mengeksekusi notebook dan menghasilkan keluaran di folder `results`.

Metode A — nbconvert (sederhana, inplace)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --inplace
```

Metode B — papermill (lebih andal; bisa parameterisasi)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
python -m pip install papermill
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"
```

Metode C — jalankan script Python (jika repo memiliki script runner)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
python run_analysis.py   # contoh, ganti dengan nama script yang ada
```

Setelah selesai, periksa hasil (gunakan solusi aman pada langkah 5).

8) Commit & push RUNME.md dan hasil (aman)  
Langkah-langkah berikut menjalankan git secara aman. Jalankan baris-per-baris dari root repo.

- Stage RUNME.md dan file lain:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git add ".\social-media-sentiment-analysis\RUNME.md"
# optional add notebook
if (Test-Path ".\social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb") {
  git add ".\social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"
}
# stage results (hanya jika sudah yakin dan tidak ada file >100MB)
if (Test-Path ".\social-media-sentiment-analysis\results") {
  git add "social-media-sentiment-analysis/results/*"
}
```

- Verifikasi dan commit:
```powershell
git status --porcelain=1 --branch
git commit -m "docs: add RUNME for social-media-sentiment-analysis"
```

- Sinkronisasi remote & push (safe):
```powershell
git fetch origin
git pull --rebase --autostash origin main
# resolve conflicts if prompted: fix files, git add <file>, git rebase --continue
git push origin main
```

Jika Anda benar-benar perlu memaksa push (hati-hati):
```powershell
git push --force-with-lease origin main
```

9) Verifikasi di remote
- Buka web browser ke path project di GitHub untuk memeriksa RUNME.md dan results:
  `https://github.com/yirassssindaba-coder/python-project/tree/main/social-media-sentiment-analysis`

- Atau clone ke folder sementara:
```powershell
cd $env:TEMP
git clone https://github.com/yirassssindaba-coder/python-project.git tmp-check
cd tmp-check
git ls-files "social-media-sentiment-analysis" | Select-Object -First 200
```

10) Troubleshooting singkat
- Jika PowerShell menolak menjalankan skrip: jalankan `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` (hanya untuk sesi ini).
- Jika `git commit` menghasilkan "nothing to commit": periksa `git status` untuk memastikan file benar-benar telah `git add`.
- Jika notebook gagal dieksekusi: periksa error traceback di notebook, pastikan dependensi terinstal dan data input tersedia.
- Jika file >100MB tertambahkan: batalkan commit, hapus file dari staging, gunakan Git LFS atau pindahkan file.

Kontak & opsi lanjutan
- Saya bisa membuatkan skrip PowerShell (`create_runme_and_push.ps1`) yang:
  - Menyalin RUNME dari sumber lokal (jika ada),
  - Menjalankan dry‑run (menampilkan file yang akan distage dan file >100MB),
  - (Opsional) melakukan git add/commit/push otomatis.

Jika Anda ingin skrip tersebut, ketik:  
- "Buat skrip salin RUNME" — saya kirimkan kode `.ps1` yang menyalin + dry‑run.  
- "Buat skrip salin & commit RUNME" — saya kirimkan `.ps1` yang juga menjalankan git add/commit/push (opsional, berisiko).

Terima kasih — file RUNME.md ini dibuat agar mudah disalin dan langsung disimpan ke lokasi project Anda. Ikuti langkah baris‑per‑baris di atas untuk menjalankan notebook dan menyimpan hasil ke Git dengan aman.