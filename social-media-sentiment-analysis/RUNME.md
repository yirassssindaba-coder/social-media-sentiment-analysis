# RUNME — Social Media Sentiment Analysis

Tujuan  
Dokumen ini berisi instruksi langkah‑demi‑langkah (PowerShell‑safe) untuk:
- Menyimpan RUNME.md ke folder project,
- Menyiapkan virtualenv dan dependensi,
- Memperbaiki error Papermill "No kernel name found" secara aman,
- Menjalankan notebook untuk menghasilkan keluaran ke folder `results`,
- Memeriksa folder `results` tanpa error "path not found",
- Menghindari masalah PowerShell umum (mis. penggunaan `||`, heredoc `<<` atau placeholder `<...>`),
- Menghentikan pelacakan virtualenv (.venv) agar tidak tercatat di Git,
- Men‑stage, commit, dan push perubahan dengan aman.

Catatan umum — baca sebelum menjalankan
- Jalankan setiap perintah baris‑per‑baris di PowerShell. Jangan gabungkan perintah bash (`&&`, `||`, heredoc `<<`) — gunakan pemisah PowerShell (`;`) atau if/else.
- Jangan jalankan perintah yang Anda tidak pahami.
- Jika branch utama Anda bukan `main`, ganti `main` pada perintah git.
- Contoh path dalam dokumen ini:  
  Root repo: `C:\Users\ASUS\Desktop\python-project`  
  Project: `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

---

## 1) Simpan RUNME.md ke folder project
Cara A — manual (direkomendasikan)
1. Buka editor (VS Code, Notepad).
2. Salin seluruh isi file ini dan Save As ke:
   `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis\RUNME.md`

Cara B — salin dari file sumber (PowerShell-safe)
```powershell
$targetDir = 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
$sourcePath = 'C:\path\to\your\RUNME_source.md'  # GANTI dengan path nyata sebelum menjalankan
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
notepad .\RUNME.md   # atau: code .\RUNME.md
```

---

## 2) Persyaratan dasar
- Git terpasang dan terkonfigurasi (user.name, user.email).
- Python 3.8+.
- Virtual environment direkomendasikan: `.venv` di root repo.
- (Opsional) Git LFS untuk file besar.

---

## 3) Buat & aktifkan virtual environment (PowerShell)
Jalankan dari root repo:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# buat virtualenv jika belum ada
if (-not (Test-Path '.\.venv')) { python -m venv .venv }

# aktifkan (PowerShell)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force   # jika perlu
.\.venv\Scripts\Activate.ps1

# verifikasi
python --version
pip --version
```

---

## 4) Instal dependensi Python
Jalankan dari root repo:
```powershell
python -m pip install --upgrade pip
# instal langsung paket yang dipakai untuk notebook/run: nbformat, papermill, ipykernel
python -m pip install nbformat papermill ipykernel
# jika ada requirements:
if (Test-Path '.\requirements.txt') { python -m pip install -r .\requirements.txt }
if (Test-Path '.\social-media-sentiment-analysis\requirements.txt') { python -m pip install -r .\social-media-sentiment-analysis\requirements.txt }
```

---

## 5) Periksa `.gitignore` & folder `results` tanpa error
Gunakan pemeriksaan yang aman (cek keberadaan folder dahulu):

```powershell
$repoRoot   = 'C:\Users\ASUS\Desktop\python-project'
$projectDir = Join-Path $repoRoot 'social-media-sentiment-analysis'
$resultsDir = Join-Path $projectDir 'results'

if (-not (Test-Path $repoRoot)) { Write-Host "Repo root tidak ditemukan: $repoRoot" -ForegroundColor Red; return }
if (-not (Test-Path $projectDir)) { Write-Host "Project folder tidak ditemukan: $projectDir" -ForegroundColor Yellow; return }

# Cek .gitignore untuk 'results' (PowerShell-safe)
Select-String -Path (Join-Path $repoRoot '.gitignore') -Pattern "results","social-media-sentiment-analysis/results" -SimpleMatch -ErrorAction SilentlyContinue
if ($?) { Write-Host ".gitignore mungkin mengecualikan results — periksa isinya" -ForegroundColor Yellow } else { Write-Host ".gitignore tidak mengecualikan results (sementara)." -ForegroundColor Green }

# Aman: daftar file di results (hanya jika folder ada)
if (Test-Path $resultsDir) {
  Get-ChildItem -Path $resultsDir -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} |
    Format-Table -AutoSize
} else {
  Write-Host "Folder results tidak ditemukan (tidak ada file untuk diperiksa)." -ForegroundColor Yellow
}
```

Cek file >100MB (jika folder ada):
```powershell
if (Test-Path $resultsDir) {
  Get-ChildItem -Path $resultsDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } |
    Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}
}
```

Jika ada file >100MB: pindahkan keluar repo atau gunakan Git LFS (langkah berikut).

---

## 6) (Opsional) Setup Git LFS untuk file besar
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git lfs install
git lfs track "social-media-sentiment-analysis/results/**"
git add .gitattributes
# PowerShell-safe commit: periksa staged changes dulu
$staged = git diff --cached --name-only
if ($staged) { git commit -m "chore: track results via git-lfs" } else { Write-Host "No .gitattributes changes to commit." -ForegroundColor Yellow }
```
Periksa kuota LFS di remote sebelum push.

---

## 7) Menjalankan notebook — menghindari error Papermill "No kernel name found"
Penyebab umum: notebook tidak memiliki metadata `kernelspec.name`. Jangan gunakan heredoc (bash `<<`) di PowerShell — gunakan file Python sementara atau ubah metadata via Jupyter UI.

Langkah A — Perbaiki via Jupyter UI (paling mudah)
1. Aktifkan venv (lihat bagian 3).
2. Jalankan `jupyter notebook` atau `jupyter lab`.
3. Buka notebook `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb`.
4. Kernel → Change Kernel → pilih kernel Python (mis. "Python 3"), lalu Save.

Langkah B — Perbaiki otomatis lewat file Python sementara (PowerShell-safe)
Salin dan jalankan baris-per-baris:
```powershell
# Pastikan venv aktif (lihat bagian 3)
# 1) Backup notebook
$nbPath = 'social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb'
if (-not (Test-Path $nbPath)) { Write-Host "Notebook tidak ditemukan: $nbPath" -ForegroundColor Red; return }
Copy-Item -Path $nbPath -Destination ($nbPath + '.bak') -Force
Write-Host "Backup dibuat: $nbPath.bak"

# 2) Tulis skrip Python sementara untuk menambahkan kernelspec jika hilang
$pyScript = @'
import nbformat
from pathlib import Path

nb_path = Path("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb")
nb = nbformat.read(str(nb_path), as_version=4)

ks = nb.metadata.get("kernelspec", {})
ks.setdefault("name", "python3")           # ubah "python3" jika kernel Anda berbeda
ks.setdefault("display_name", "Python 3")
nb.metadata["kernelspec"] = ks

nbformat.write(nb, str(nb_path))
print("Updated kernelspec in", nb_path)
'@

$tempPy = Join-Path $env:TEMP 'update_kernelspec.py'
Set-Content -Path $tempPy -Value $pyScript -Encoding UTF8
Write-Host "Temporary script written to $tempPy"

# 3) Jalankan skrip Python untuk memperbarui metadata
python $tempPy

# 4) (Opsional) hapus file sementara
# Remove-Item -Path $tempPy -Force
```

Langkah C — Jalankan Papermill (PowerShell-safe)
Setelah metadata kernelspec ada, jalankan papermill:
```powershell
# Option 1: biarkan papermill baca kernelspec dari notebook
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"

# Option 2: jika ingin override kernel secara eksplisit
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb" --kernel "python3"
```

Jika Anda tidak yakin nama kernel:
```powershell
jupyter kernelspec list
```
Gunakan nama kernel yang tertera (contoh: `python3`, `py310`, dsb.) pada opsi `--kernel`.

Jika kernel belum terdaftar dalam sistem, daftar kernel dari venv:
```powershell
# jalankan ketika venv aktif
python -m ipykernel install --user --name python3 --display-name "Python 3"
```

---

## 8) Menjalankan notebook tanpa Papermill (alternatif)
Jika Anda tidak ingin menggunakan papermill, pakai nbconvert:
```powershell
python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --inplace
```

---

## 9) Menghentikan pelacakan .venv (aman, tanpa error PowerShell)
Jalankan dari root repo (PowerShell-safe — tanpa `||`):
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# Hapus .venv dari index jika pernah ter-track (file tetap ada di disk)
$venvRel = 'social-media-sentiment-analysis/.venv'
& git ls-files --error-unmatch -- $venvRel 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Removing tracked .venv from index..."
  & git rm -r --cached --ignore-unmatch -- $venvRel
} else {
  Write-Host "No tracked .venv found in index."
}

# Pastikan .venv/ ada di .gitignore
$gitignore = Join-Path (Get-Location) '.gitignore'
if (-not (Test-Path $gitignore)) { New-Item -Path $gitignore -ItemType File -Force | Out-Null }
$hasVenv = Select-String -Path $gitignore -Pattern '\.venv' -SimpleMatch -Quiet
if (-not $hasVenv) {
  Add-Content -Path $gitignore -Value "`n# ignore virtual environment`n.venv/"
  & git add $gitignore
  $staged = & git diff --cached --name-only
  if ($staged -and $staged.Trim().Length -gt 0) {
    & git commit -m "chore: stop tracking .venv and update .gitignore"
  } else {
    Write-Host "No .gitignore changes to commit."
  }
} else {
  Write-Host ".venv already present in .gitignore"
}
```

Jika beberapa file .venv sudah dipush dan Anda perlu menghapusnya dari history, itu memerlukan BFG atau git filter-repo (berisiko) — koordinasikan dengan tim sebelum melakukannya.

---

## 10) Stage, commit, push perubahan (PowerShell-safe)
Selalu cek dulu apa yang akan Anda commit; gunakan kontrol alur PowerShell, bukan `||`.

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

$readme = '.\social-media-sentiment-analysis\README.md'
$runme  = '.\social-media-sentiment-analysis\RUNME.md'
$notebookOut = '.\social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb'
$resultsDir = '.\social-media-sentiment-analysis\results'

if (Test-Path $readme) { & git add $readme } else { Write-Host "README not found; skipping." -ForegroundColor Yellow }
if (Test-Path $runme)  { & git add $runme  } else { Write-Host "RUNME not found; skipping." -ForegroundColor Yellow }
if (Test-Path $notebookOut) { & git add $notebookOut }
if (Test-Path $resultsDir) { & git add "$resultsDir\*" } else { Write-Host "No results to stage." -ForegroundColor Yellow }

# Commit only if staged
$staged = & git diff --cached --name-only
if ($staged -and $staged.Trim().Length -gt 0) {
  & git commit -m "docs: add/update RUNME and results"
  & git fetch origin
  & git pull --rebase --autostash origin main
  # if conflicts occur: fix files, git add "path\to\file", then run: git rebase --continue
  & git push origin main
} else {
  Write-Host "Nothing to commit (no staged changes)." -ForegroundColor Yellow
}
```

---

## 11) Troubleshooting cepat & prinsip pencegahan
- Error Parser di PowerShell muncul karena Anda menempelkan sintaks bash (contoh: `||`, `<<'PY'`, `git add <file>`). Hindari itu.
- Untuk menjalankan kode Python dari PowerShell, tulis ke file `.py` lalu jalankan `python script.py`.
- Periksa kernel notebook dengan membuka di Jupyter Lab/Notebook atau dengan script Python (lihat bagian 7).
- Jangan commit `.venv`. Tambahkan `.venv/` ke `.gitignore` dan hapus dari index jika perlu.
- Jika rebase sedang berlangsung: `git status` → jika ingin abort: `git rebase --abort` → atau setelah menyelesaikan konflik dan staging: `git rebase --continue`.

---

## 12) Opsi: saya buatkan skrip (.ps1) otomatis
Jika Anda mau, saya dapat membuatkan salah satu skrip berikut:
- `update_kernelspec_and_run.ps1` — backup notebook, update kernelspec (via temporary .py), run papermill (dengan opsi --kernel), dan tampilkan hasil.
- `create_runme_and_push.ps1` — salin RUNME, dry‑run (tampilkan file besar & file yang akan distage), lalu (opsional) commit/push setelah konfirmasi.
- `fix-venv-and-git.ps1` — hapus .venv dari index, perbarui .gitignore, commit jika perlu.

Ketik pilihan Anda: "Buat update_kernelspec_and_run.ps1", "Buat create_runme_and_push.ps1", atau "Buat fix-venv-and-git.ps1" — saya akan sediakan skrip lengkap yang bisa Anda simpan dan jalankan.

---

Terima kasih — dokumen RUNME.md ini telah diperbarui agar bebas dari sintaks yang menyebabkan error di PowerShell dan memuat solusi praktis untuk error Papermill "No kernel name found". Ikuti langkah baris‑per‑baris dan gunakan skrip sementara yang disediakan untuk operasi otomatis yang aman. ````
