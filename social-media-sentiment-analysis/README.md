# Social Media Sentiment Analysis — README

Tujuan singkat  
Dokumen ini berisi instruksi aman (PowerShell / Python) untuk:
- Menjalankan notebook dan menghindari error papermill "No kernel name found",
- Menghindari error PowerShell umum (mis. penggunaan `||` atau `<...>`),
- Menangani .venv agar tidak tercatat di Git,
- Stage / commit / push perubahan secara aman (tanpa operator shell non-PowerShell),
- Menjalankan pemeriksaan file besar di folder results.

Baca seluruh dokumen lalu jalankan perintah baris‑per‑baris di PowerShell pada mesin Anda. Jangan jalankan perintah yang Anda tidak pahami. Ganti path contoh dengan path nyata bila perlu.

Lokasi contoh repo:
- Root repo: `C:\Users\ASUS\Desktop\python-project`
- Project folder: `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

---

## 1) Penyebab dan solusi error Papermill: "No kernel name found in notebook and no override provided."

Pesan error penuh:
ValueError: No kernel name found in notebook and no override provided.

Arti: notebook (.ipynb) tidak memiliki metadata kernelspec.name, sehingga papermill tidak tahu kernel mana yang dipakai. Solusi:
- Beri kernel pada notebook (metadata kernelspec), atau
- Panggil papermill dengan opsi `--kernel <kernel_name>`.

Langkah-langkah perbaikan (pilih salah satu):

A. Perbaiki kernel via Jupyter UI (paling mudah)
1. Buka notebook di Jupyter Notebook / JupyterLab:
   - Jalankan: `jupyter notebook` atau `jupyter lab` dari root repo virtualenv aktif.
2. Buka notebook yang dimaksud, menu Kernel → Change kernel → pilih kernel (mis. Python 3).
3. Simpan notebook. Notebook sekarang memiliki metadata kernelspec.

B. Tentukan kernel saat memanggil papermill
Jalankan (PowerShell):
```powershell
# contoh: gunakan kernel bernama 'python3' (periksa daftar kernel di bawah)
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb" --kernel "python3"
```

C. Periksa daftar kernel yang tersedia
```powershell
jupyter kernelspec list
```
Gunakan salah satu nama kernel dari daftar (kolom "kernel name") pada argumen `--kernel`.

D. Memperbarui metadata notebook lewat skrip Python (otomatis)
Jika Anda ingin menulis kernelspec langsung ke notebook tanpa membuka UI, jalankan skrip Python ini (PowerShell):
```powershell
# sesuaikan nama kernel 'python3' bila perlu
python - <<'PY'
import nbformat, sys
from pathlib import Path
nb_path = Path("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb")
nb = nbformat.read(str(nb_path), as_version=4)
# set kernelspec if missing
nb.metadata.setdefault("kernelspec", {})["name"] = nb.metadata.get("kernelspec", {}).get("name","python3")
nb.metadata["kernelspec"]["display_name"] = nb.metadata["kernelspec"].get("display_name","Python 3")
nbformat.write(nb, str(nb_path))
print("Updated kernelspec in", nb_path)
PY
```
Setelah menjalankan, coba ulangi papermill tanpa `--kernel`, atau tetap gunakan `--kernel` untuk kepastian.

---

## 2) Hindari error PowerShell: jangan pakai `||` atau placeholder `<file>` langsung

PowerShell tidak menerima `||` (bash operator) dan menganggap `<...>` sebagai token khusus. Gunakan alur kontrol PowerShell (if/else) dan path nyata.

Contoh yang MENYEBABKAN error (jangan pakai):
```powershell
git commit -m "msg" || Write-Host "Nothing to commit"
git add <file-yang-diperbaiki>
```

Contoh yang BENAR (PowerShell-safe):
```powershell
# commit only if there is staged content
$staged = git diff --cached --name-only
if ($staged) {
  git commit -m "docs: add/update README"
} else {
  Write-Host "Nothing to commit (no staged changes)." -ForegroundColor Yellow
}

# stage a concrete file (no angle brackets)
$path = "social-media-sentiment-analysis\data.csv"
if (Test-Path $path) {
  git add $path
} else {
  Write-Host "File not found: $path" -ForegroundColor Yellow
}
```

---

## 3) Skrip PowerShell aman untuk stage → commit → push (tanpa `||`)

Salin & jalankan baris‑per‑baris dari root repo:

```powershell
# Sesuaikan root dan project folder bila perlu
$RepoRoot = 'C:\Users\ASUS\Desktop\python-project'
$Project = Join-Path $RepoRoot 'social-media-sentiment-analysis'
Set-Location $RepoRoot

# Paths yang ingin Anda commit (cek keberadaan dulu)
$readme = Join-Path $Project 'README.md'
$runme  = Join-Path $Project 'RUNME.md'
$notebookOut = Join-Path $Project 'social-media-sentiment-analysis-output.ipynb'
$resultsDir = Join-Path $Project 'results'

# Stage only if files exist
if (Test-Path $readme) { git add $readme } else { Write-Host "README.md not found; skipping." -ForegroundColor Yellow }
if (Test-Path $runme)  { git add $runme  } else { Write-Host "RUNME.md not found; skipping." -ForegroundColor Yellow }
if (Test-Path $notebookOut) { git add $notebookOut }

if (Test-Path $resultsDir) {
  # stage all files inside results (ensure results content is safe)
  git add (Join-Path $resultsDir '*')
} else {
  Write-Host "No results folder to stage." -ForegroundColor Yellow
}

# Commit only if staged changes exist
$staged = git diff --cached --name-only
if ($staged) {
  git commit -m "docs: add/update README and results for social-media-sentiment-analysis"
} else {
  Write-Host "Nothing to commit (no staged changes)." -ForegroundColor Yellow
}

# Pull + rebase and push safely
git fetch origin
git pull --rebase --autostash origin main
# if conflicts occur, resolve them then run:
# git rebase --continue
git push origin main
```

Catatan: jika Anda menggunakan branch selain `main`, ganti `main` sesuai branch Anda.

---

## 4) Pastikan .venv tidak ter-track dan tidak muncul di diff/rebase

Langkah aman: hapus .venv dari index (tracking) dan pastikan `.gitignore` men‑ignore .venv. Jalankan perintah ini dari root repo:

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# Remove .venv from index if tracked (keamanan: keep files on disk)
git ls-files --error-unmatch "social-media-sentiment-analysis/.venv" 2>$null
if ($LASTEXITCODE -eq 0) {
  git rm -r --cached --ignore-unmatch "social-media-sentiment-analysis/.venv"
  Write-Host "Removed tracked .venv files from index."
} else {
  Write-Host "No tracked .venv found in index."
}

# Add .venv to .gitignore if missing
$gitignore = Join-Path $RepoRoot '.gitignore'
if (-not (Test-Path $gitignore)) { New-Item -Path $gitignore -ItemType File -Force | Out-Null }
$hasVenv = Select-String -Path $gitignore -Pattern '\.venv' -SimpleMatch -Quiet
if (-not $hasVenv) {
  Add-Content -Path $gitignore -Value "`n# ignore virtual environment`n.venv/"
  git add $gitignore
  $staged = git diff --cached --name-only
  if ($staged) { git commit -m "chore: ignore .venv" } else { Write-Host "No .gitignore changes to commit." -ForegroundColor Yellow }
} else {
  Write-Host ".venv already present in .gitignore"
}
```

Jika beberapa file .venv sudah ter-commit ke history remote dan perlu dihapus dari history, itu memerlukan BFG atau git filter-repo — itu berisiko dan tidak disarankan tanpa koordinasi tim.

---

## 5) Menjalankan papermill setelah perbaikan kernel (contoh PowerShell)

Jika Anda telah menambahkan metadata kernelspec ke notebook atau ingin meng-override kernel:

```powershell
# Option A: run with explicit kernel name
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb" --kernel "python3"

# Option B: if you updated notebook metadata via Jupyter UI or script, run without --kernel
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"
```

Jika papermill tetap error, first inspect notebook metadata:
```powershell
python - <<'PY'
import nbformat, sys
nb = nbformat.read("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb", as_version=4)
print(nb.metadata.get("kernelspec"))
PY
```
Output harus menampilkan dict dengan "name", contoh: `{'name': 'python3', 'display_name': 'Python 3'}`.

---

## 6) Jika rebase sedang berjalan — alur aman (tanpa `||`, tanpa angle brackets)
Periksa status dan konflik:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git status --porcelain=1 --branch
git diff --name-only --diff-filter=U
```
- Jika rebase aktif dan Anda ingin abort:
  ```powershell
  git rebase --abort
  ```
- Jika rebase aktif dan Anda telah menyelesaikan konflik dan men‑stage file, lanjutkan:
  ```powershell
  git rebase --continue
  ```

Jangan gunakan `git add <file-yang-diperbaiki>` literal — gunakan nama file nyata, mis:
```powershell
git add "social-media-sentiment-analysis\data.csv"
git rebase --continue
```

---

## 7) Ringkasan troubleshooting cepat untuk error yang Anda laporkan

- Papermill ValueError: tambahkan kernelspec ke notebook (via Jupyter UI) atau pakai `--kernel` saat memanggil papermill; atau jalankan skrip Python yang menulis metadata kernelspec.
- PowerShell ParserError karena `||`: ganti pola `cmd || echo` dengan if/else di PowerShell seperti contoh di bagian 2 dan 3.
- PowerShell ParserError karena `<...>`: jangan gunakan tanda sudut; masukkan nama file nyata dalam tanda kutip.
- .venv muncul sebagai deleted/modified: pastikan .venv ada di .gitignore, dan hapus dari index dengan `git rm -r --cached`.

---

## 8) Jika Anda ingin saya buatkan skrip otomatis (.ps1)

Saya dapat membuat:
- `fix-venv-rebase.ps1` — interaktif: mendeteksi rebase, menampilkan konflik, menghapus .venv dari index, menambahkan .gitignore, dan (opsional) auto-stage non-.venv conflicts and continue rebase.
- `run-notebook-and-push.ps1` — menjalankan papermill (dengan opsi --kernel), memeriksa results, melakukan dry-run staging (menampilkan file besar dan file yang akan distage), lalu (opsional) commit/push.

Ketik pilihan Anda: "Buat skrip fix-venv-rebase.ps1" atau "Buat skrip run-notebook-and-push.ps1" atau berikan output `git status --porcelain=1 --branch` sekarang supaya saya susun perintah konkret untuk keadaan Anda.

Terima kasih — README ini sudah diperbarui untuk menghilangkan sumber error yang Anda alami dan menampilkan alur perbaikan yang aman dan PowerShell‑friendly.
