# Social Media Sentiment Analysis — README

Ringkasan  
Dokumen ini adalah README lengkap untuk folder `social-media-sentiment-analysis`. Berisi instruksi aman (PowerShell) untuk:
- Menyimpan README dan RUNME ke folder project,
- Memeriksa dan memperbarui .gitignore,
- Menangani file besar (cek >100MB) dan opsi Git LFS,
- Menjalankan notebook untuk menghasilkan keluaran ke folder `results`,
- Stage, commit, rebase, dan push ke remote dengan cara yang aman,
- Menghentikan pelacakan virtual environment (.venv) agar tidak tercatat di Git.

Semua perintah harus dijalankan sendiri di mesin lokal Anda, baris per baris. Contoh path root repo pada instruksi ini:
`C:\Users\ASUS\Desktop\python-project`  
Lokasi project:  
`C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

Penting sebelum mulai
- Jangan jalankan perintah yang Anda tidak pahami.
- Jalankan perintah baris-per-baris di PowerShell (jangan gunakan shell-operator non-PowerShell seperti `||` atau tanda `<...>`).
- Jika branch utama bukan `main`, ganti semua contoh `main` sesuai branch Anda.
- README ini tidak menulis ulang riwayat Git — langkah itu berisiko dan dijelaskan terpisah jika diperlukan.

---

## 1. Simpan README.md di folder project
Metode (pilih salah satu):

Cara A — manual (direkomendasikan)
1. Buka editor (VS Code, Notepad).
2. Simpan file ini sebagai:
   `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis\README.md`

Cara B — salin dari file sumber (aman)
Buka PowerShell dan jalankan baris-per-baris (sesuaikan $sourcePath):
```powershell
$targetDir = 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path $targetDir)) {
  New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
  Write-Host "Created: $targetDir"
} else {
  Write-Host "Target exists: $targetDir"
}

$sourcePath = 'C:\Users\ASUS\Downloads\README_source.md'  # GANTI dengan path nyata
if (Test-Path $sourcePath) {
  Copy-Item -Path $sourcePath -Destination (Join-Path $targetDir 'README.md') -Force
  Write-Host "Copied: $sourcePath -> $targetDir\README.md"
} else {
  Write-Host "Source not found: $sourcePath" -ForegroundColor Yellow
}
```

Cara C — buat file kosong lalu edit:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path '.\README.md')) { New-Item -Path '.\README.md' -ItemType File -Force }
notepad .\README.md   # atau: code .\README.md
```

---

## 2. Periksa dan perbarui .gitignore agar .venv tidak ter-track
Pastikan virtual environment tidak dilacak dan folder `results` tidak di-ignore.

Periksa .gitignore untuk `.venv` dan `results`:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Select-String -Path .gitignore -Pattern ".venv","results" -SimpleMatch -ErrorAction SilentlyContinue
```

Tambahkan aturan `.venv/` jika belum ada:
```powershell
$gitignorePath = '.\ .gitignore'.Trim()
# buat .gitignore jika tidak ada
if (-not (Test-Path $gitignorePath)) { New-Item -Path $gitignorePath -ItemType File -Force | Out-Null }
$hasVenv = Select-String -Path $gitignorePath -Pattern '(^|/)\.venv(/|$)' -SimpleMatch -Quiet
if (-not $hasVenv) {
  Add-Content -Path $gitignorePath -Value "`n# ignore virtual environment`n.venv/"
  Write-Host ".venv/ added to .gitignore"
} else {
  Write-Host ".venv/ already present in .gitignore"
}
```

Jika `.gitignore` diubah, stage & commit (lihat bagian Git yang aman di bawah).

Catatan: jangan men-commit isi .venv ke repo. Jika file .venv sudah pernah di-commit, lihat bagian "Membersihkan history" di bagian akhir.

---

## 3. Cek file besar di folder `results` (aman)
Gunakan skrip aman yang memeriksa keberadaan folder sebelum memanggil Get-ChildItem — mencegah error "path not found".

```powershell
$repoRoot = 'C:\Users\ASUS\Desktop\python-project'
$project = Join-Path $repoRoot 'social-media-sentiment-analysis'
$results = Join-Path $project 'results'

if (-not (Test-Path $project)) { Write-Host "Project folder tidak ditemukan: $project" -ForegroundColor Yellow; return }
if (-not (Test-Path $results)) { Write-Host "Folder results tidak ada: $results" -ForegroundColor Yellow; return }

Get-ChildItem -Path $results -Recurse -File -ErrorAction SilentlyContinue |
  Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} |
  Format-Table -AutoSize
```

Cari file >100MB:
```powershell
Get-ChildItem -Path $results -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -gt 100MB } |
  Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}
```

Jika ada file >100MB: pindahkan ke luar repo atau gunakan Git LFS (langkah 4).

---

## 4. (Opsional) Setup Git LFS untuk file besar
Hanya jika perlu menyimpan file >100MB. Pastikan remote (GitHub) mendukung LFS.

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git lfs install
git lfs track "social-media-sentiment-analysis/results/**"
git add .gitattributes
# Commit jika ada perubahan staged
$staged = git diff --cached --name-only
if ($staged) { git commit -m "chore: track results via git-lfs" } else { Write-Host "No .gitattributes changes to commit" }
```

Periksa kuota LFS akun/organisasi sebelum mendorong file besar.

---

## 5. Menjalankan notebook untuk menghasilkan outputs (folder `results`)
Aktifkan virtualenv, instal dependensi, lalu jalankan notebook. Contoh PowerShell:

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
# buat dan aktifkan venv (jika belum)
if (-not (Test-Path '.\.venv')) { python -m venv .venv }
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # jika perlu
.\.venv\Scripts\Activate.ps1

# instal requirements jika ada
if (Test-Path '.\requirements.txt') { python -m pip install -r .\requirements.txt }
if (Test-Path '.\social-media-sentiment-analysis\requirements.txt') { python -m pip install -r .\social-media-sentiment-analysis\requirements.txt }

# jalankan notebook (nbconvert inplace)
python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --inplace

# atau gunakan papermill untuk output terpisah
python -m pip install papermill
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"

# verifikasi outputs
Get-ChildItem -Path "social-media-sentiment-analysis\results" -Recurse | Select-Object FullName,Length
```

---

## 6. Stage, commit, dan push dengan aman (langkah Git)
Ikuti urutan ini, jalankan baris-per-baris dari root repo.

- Pindah ke root repo:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
```

- Stage file dokumentasi dan output yang diinginkan (cek keberadaan sebelum add):
```powershell
$readme = '.\social-media-sentiment-analysis\README.md'
$runme = '.\social-media-sentiment-analysis\RUNME.md'
$notebookOut = '.\social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb'
$resultsDir = '.\social-media-sentiment-analysis\results'

if (Test-Path $readme) { git add $readme } else { Write-Host "README.md not found; skipping." -ForegroundColor Yellow }
if (Test-Path $runme)  { git add $runme  } else { Write-Host "RUNME.md not found; skipping." -ForegroundColor Yellow }
if (Test-Path $notebookOut) { git add $notebookOut }

if (Test-Path $resultsDir) {
  # only stage results files if present and safe (no >100MB check here)
  git add "$resultsDir\*"
} else {
  Write-Host "No results folder to stage."
}

git status --porcelain=1 --branch
git commit -m "docs: add/update README and results for social-media-sentiment-analysis" || Write-Host "Nothing to commit (or commit failed)."
```

- Sinkronisasi & push (aman):
```powershell
git fetch origin
git pull --rebase --autostash origin main
# resolve conflicts if prompted: fix files, git add "path\to\file", git rebase --continue
git push origin main
```

Jika branch bukan `main`, ganti `main` sesuai branch Anda.

---

## 7. Menyelesaikan rebase dan konflik (tips tanpa error PowerShell)
PowerShell memperlakukan karakter `<` dan operator seperti `||` berbeda dari bash. Jangan gunakan format placeholder `<file>` — gunakan nama file nyata.

Periksa konflik:
```powershell
git status
git diff --name-only --diff-filter=U
```

Setelah Anda memperbaiki file konflik dengan editor, stage file tersebut dengan path nyata:
```powershell
git add "social-media-sentiment-analysis\path\to\fixed-file.ext"
git rebase --continue
```

Jika Anda ingin membatalkan rebase:
```powershell
git rebase --abort
```

Jika Anda ingin mengembalikan semua perubahan lokal dan kembali ke HEAD (HATI‑HATI: ini membuang perubahan lokal):
```powershell
git reset --hard HEAD
```

---

## 8. Menghentikan pelacakan .venv (aman)
Jika .venv sempat ter-track, lakukan langkah-langkah ini (tidak menggunakan operator shell yang tidak valid):

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# Hapus tracked .venv dari index (tidak menghapus file di disk)
git ls-files --error-unmatch "social-media-sentiment-analysis/.venv" 2>$null
if ($LASTEXITCODE -eq 0) {
  git rm -r --cached --ignore-unmatch "social-media-sentiment-analysis/.venv"
  Write-Host "Removed .venv from index (cached)."
} else {
  Write-Host "No tracked .venv found in index."
}

# Pastikan .gitignore berisi .venv/
$existsVenv = Select-String -Path .gitignore -Pattern '.venv' -SimpleMatch -Quiet
if (-not $existsVenv) {
  Add-Content -Path .gitignore -Value "`n# ignore virtual environment`n.venv/"
  git add .gitignore
  git commit -m "chore: ignore .venv" || Write-Host "Nothing to commit for .gitignore"
} else {
  Write-Host ".venv already ignored."
}
```

Jika file .venv telah masuk ke history remote dan perlu dihapus dari history, itu memerlukan alat seperti BFG atau git filter-repo. Ini akan menulis ulang history dan memerlukan koordinasi tim — jangan lakukan tanpa persetujuan.

---

## 9. Membersihkan file besar yang sudah ter-commit (opsional, berisiko)
Jika Anda perlu menghapus file besar dari history, gunakan BFG atau git filter-repo. Contoh ringkas (koordinasikan dengan tim):

- Gunakan BFG: https://rtyley.github.io/bfg-repo-cleaner/  
- Setelah menjalankan BFG, jalankan:
```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force-with-lease origin main
```
JANGAN lakukan ini tanpa memahami konsekuensi.

---

## 10. Opsi tambahan / skrip otomatis
Jika Anda mau, saya bisa menambahkan skrip PowerShell siap-pakai:
- `fix-venv-rebase.ps1` — mendeteksi rebase, daftar konflik, hati-hati menghapus .venv dari index, menambahkan .gitignore, dan (opsional) auto-stage non-.venv conflicts.
- `create_runme_and_push.ps1` — menyalin RUNME/README dari sumber lokal, menjalankan dry-run (file yang akan distage dan file >100MB), dan (opsional) menjalankan git add/commit/push.

Katakan pilihan Anda: "Buat fix-venv-rebase.ps1" atau "Buat create_runme_and_push.ps1" atau "Saya jalankan manual".

---

Terima kasih — README ini disusun ulang untuk menghilangkan error PowerShell yang sering muncul (operator shell yang tidak valid, placeholder `<...>`, path yang tidak ada), dan menyediakan langkah-langkah aman agar Anda dapat menyimpan dokumentasi, menjalankan notebook, serta memasukkan hasil ke Git tanpa error. Ikuti tiap perintah baris‑per‑baris dan jangan jalankan perintah yang tidak Anda pahami.
