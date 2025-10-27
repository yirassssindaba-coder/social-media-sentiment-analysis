# Social Media Sentiment Analysis — README

Ringkasan singkat  
Dokumen ini menjelaskan penyebab error PowerShell / Papermill yang Anda alami (mis. penggunaan heredoc/bash-style `<<'PY'` di PowerShell dan Papermill error "No kernel name found in notebook"), lalu memberi langkah-langkah praktis dan PowerShell‑friendly untuk memperbaiki notebook metadata, menjalankan Papermill, dan melakukan operasi Git dengan aman (tanpa operator bash seperti `||` dan tanpa placeholder `<...>`). Semua contoh disajikan agar bisa disalin langsung dan dijalankan baris‑per‑baris di PowerShell.

Penting
- Jangan jalankan baris yang Anda tidak pahami.
- Jalankan perintah baris‑per‑baris di PowerShell (tidak menempelkan semuanya sekali jalan bila Anda ragu).
- Ganti path contoh jika repo Anda berada di lokasi berbeda.
- Jika branch utama Anda bukan `main`, ganti `main` pada semua command git.

Masalah yang Anda lihat (penyebab)
- Anda mencoba menjalankan sintaks heredoc/bash-style:
  python - <<'PY' ... PY
  PowerShell tidak mendukung sintaks itu — `<'` diperlakukan sebagai operator dan menghasilkan ParserError.
- Papermill error:
  ValueError: No kernel name found in notebook and no override provided.
  Artinya notebook tidak memiliki metadata kernelspec.name sehingga Papermill tidak tahu kernel apa yang dipakai.

Solusi ringkas
1. Hindari heredoc di PowerShell. Untuk menjalankan skrip Python dari PowerShell, simpan skrip ke file sementara (.py) lalu jalankan `python script.py`.
2. Tambahkan kernelspec ke metadata notebook (via Jupyter UI atau script Python) atau jalankan Papermill dengan opsi `--kernel <kernel_name>`.
3. Pastikan paket yang dibutuhkan (nbformat, papermill, ipykernel) terinstal di venv yang Anda pakai.
4. Jangan gunakan operator `||` atau placeholder `<file>` di PowerShell — gunakan if/else dan nama file nyata.

Panduan langkah‑per‑langkah (PowerShell-friendly)
Ikuti langkah berikut dari root repo Anda (contoh path root dipakai di semua contoh):
`C:\Users\ASUS\Desktop\python-project`

A. Aktifkan virtual environment
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# jika Anda menggunakan .venv di root repo:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # bila perlu
.\.venv\Scripts\Activate.ps1

# pastikan python bekerja
python --version
```

B. Pastikan dependensi Python terpasang
```powershell
python -m pip install --upgrade pip
python -m pip install nbformat papermill ipykernel
```

C. Backup notebook sebelum mengubah metadata
```powershell
$nbPath = 'social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb'
if (-not (Test-Path $nbPath)) {
  Write-Host "Notebook not found: $nbPath" -ForegroundColor Red
  return
}
Copy-Item -Path $nbPath -Destination ($nbPath + '.bak') -Force
Write-Host "Backup created: $nbPath.bak"
```

D. Tambahkan kernelspec ke notebook (PowerShell‑safe)
- Cara yang paling sederhana: buka notebook di JupyterLab/Notebook, pilih Kernel → Change kernel → pilih (mis. Python 3), lalu Save.
- Jika Anda ingin otomatis (tanpa membuka UI), simpan dan jalankan skrip Python sementara dari PowerShell — contoh berikut membuat file Python sementara yang memperbarui metadata kernelspec menjadi "python3". Ganti `"python3"` jika kernel Anda berbeda.

```powershell
# buat file Python sementara (PowerShell here-string aman)
$pyScript = @'
import nbformat
from pathlib import Path

nb_path = Path("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb")
nb = nbformat.read(str(nb_path), as_version=4)

# Jika metadata kernelspec tidak ada atau kosong, set default "python3" (ubah jika perlu)
ks = nb.metadata.get("kernelspec", {})
ks.setdefault("name", "python3")
ks.setdefault("display_name", "Python 3")
nb.metadata["kernelspec"] = ks

nbformat.write(nb, str(nb_path))
print("Updated kernelspec in", nb_path)
'@

$tempPy = Join-Path $env:TEMP 'update_kernelspec.py'
Set-Content -Path $tempPy -Value $pyScript -Encoding UTF8
Write-Host "Temporary Python script written to $tempPy"

# jalankan skrip Python untuk memperbarui notebook
python $tempPy
# (opsional) hapus file sementara setelah sukses:
# Remove-Item -Path $tempPy -Force
```

E. Verifikasi metadata kernelspec (PowerShell‑safe)
Jika Anda ingin memeriksa metadata, gunakan file Python sementara juga (atau jalankan satu‑baris Python melalui PowerShell dengan argumen file):

```powershell
$checkScript = @'
import nbformat
nb = nbformat.read("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb", as_version=4)
print("kernelspec:", nb.metadata.get("kernelspec"))
'@
$checkPy = Join-Path $env:TEMP 'check_kernelspec.py'
Set-Content -Path $checkPy -Value $checkScript -Encoding UTF8
python $checkPy
# Remove-Item $checkPy -Force  # hapus jika ingin
```

F. Jalankan Papermill (gunakan --kernel jika ingin override)
Setelah kernelspec terpasang atau jika Anda mau override, jalankan papermill:

```powershell
# Option A: jalankan dan biarkan Papermill membaca kernelspec dari notebook
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"

# Option B: jalankan dengan opsi --kernel (jika notebook masih tidak berisi kernelspec atau Anda ingin override)
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb" --kernel "python3"
```

Jika Anda tidak yakin nama kernel, periksa:
```powershell
jupyter kernelspec list
```
Gunakan salah satu "kernel name" yang terdaftar (mis. python3, py310, dll) pada argumen `--kernel`.

G. Menangani error papermill lain
- Jika Papermill mengeluarkan error terkait kernel tidak ditemukan, pastikan kernel tersedia di environment yang sedang aktif. Jika perlu, register kernel dari venv:
```powershell
# jalankan saat venv aktif
python -m ipykernel install --user --name python3 --display-name "Python 3"
```

H. Git & .venv — hindari commit venv dan jangan gunakan `||`
PowerShell tidak menerima `||`. Gunakan kontrol alur PowerShell untuk commit conditional.

Langkah aman: hapus .venv dari index (tracking) jika pernah ter-track, tambahkan ke .gitignore, dan commit hanya bila ada perubahan staged.

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# Hapus .venv dari index jika ter-track (tidak menghapus file di disk)
$venvRel = 'social-media-sentiment-analysis/.venv'
# gunakan git ls-files untuk mengetahui apakah ada file yang ter-track
& git ls-files --error-unmatch -- $venvRel 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Removing tracked .venv from index..."
  & git rm -r --cached --ignore-unmatch -- $venvRel
} else {
  Write-Host "No tracked .venv files found in index."
}

# Pastikan .venv/ ada di .gitignore
$gitignore = Join-Path (Get-Location) '.gitignore'
if (-not (Test-Path $gitignore)) { New-Item -Path $gitignore -ItemType File -Force | Out-Null }
$hasVenv = Select-String -Path $gitignore -Pattern '(^|/)\.venv(/|$)' -SimpleMatch -Quiet
if (-not $hasVenv) {
  Add-Content -Path $gitignore -Value "`n# ignore virtual environment`n.venv/"
  & git add .gitignore
  # Commit only if there are staged changes
  $staged = & git diff --cached --name-only
  if ($staged -and $staged.Trim().Length -gt 0) {
    & git commit -m "chore: stop tracking .venv and update .gitignore"
  } else {
    Write-Host "No changes staged to commit for .gitignore."
  }
} else {
  Write-Host ".venv/ already present in .gitignore"
}
```

I. Men‑stage, commit, dan push perubahan dokumentasi & results (PowerShell-safe)
Contoh alur yang aman—cek keberadaan file dulu, stage hanya jika ada, commit jika ada staged changes:

```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

$readme = '.\social-media-sentiment-analysis\README.md'
$runme  = '.\social-media-sentiment-analysis\RUNME.md'
$results = '.\social-media-sentiment-analysis\results'
$notebookOut = '.\social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb'

if (Test-Path $readme) { & git add $readme } else { Write-Host "README not found; skipping." }
if (Test-Path $runme)  { & git add $runme  } else { Write-Host "RUNME not found; skipping." }
if (Test-Path $notebookOut) { & git add $notebookOut }
if (Test-Path $results) { & git add "$results\*" } else { Write-Host "No results to stage." }

$staged = & git diff --cached --name-only
if ($staged -and $staged.Trim().Length -gt 0) {
  & git commit -m "docs: add/update README and run outputs"
  & git fetch origin
  & git pull --rebase --autostash origin main
  # Resolve conflicts manually if prompted, then:
  # & git rebase --continue
  & git push origin main
} else {
  Write-Host "Nothing to commit (no staged changes)." -ForegroundColor Yellow
}
```

J. Kenapa error parser muncul sebelumnya (penutup)
- `python - <<'PY'` adalah sintaks shell heredoc yang *bukan* PowerShell; PowerShell mem-parsing `<` sebagai operator → ParserError.
- Menulis kode Python ke file sementara dan menjalankannya dengan `python script.py` adalah metode cross-platform dan PowerShell‑safe.
- Jangan gunakan `||` di PowerShell — gunakan if/else dan periksa `$LASTEXITCODE` atau `git diff --cached --name-only`.

K. Troubleshooting singkat
- Papermill masih error "No kernel name": jalankan langkah D (update kernelspec) atau gunakan `--kernel`.
- Papermill error "kernel not found": daftar kernel dengan `jupyter kernelspec list` dan daftarkan kernel yang sesuai dari venv (`python -m ipykernel install --user --name <name> --display-name "<display>"`).
- Git rebase sedang berjalan: `git status` → jika ingin abort: `git rebase --abort`; jika sudah menyelesaikan konflik dan staging, `git rebase --continue`.
- Jika Anda melihat ParserError di PowerShell: periksa apakah Anda menempelkan sintaks bash (heredoc `<<`, `||`, `&&`, atau `<file>` placeholders). Gunakan bentuk PowerShell yang saya tunjukkan di atas.

---

Jika Anda ingin, saya dapat:
- Menghasilkan file PowerShell siap‑pakai (contoh: `update_kernelspec_and_run.ps1`) yang melakukan seluruh alur: backup notebook → update kernelspec → run papermill (dengan opsi --kernel) → dry‑run stage → commit/push (opsional). Saya akan membuat versi interaktif yang meminta konfirmasi sebelum commit/push.
- Atau, jika Anda mau, kirimkan output `git status --porcelain=1 --branch` dan hasil percobaan papermill terbaru — saya akan susun perintah tepat untuk kondisi repo Anda.

Terima kasih — README ini sudah diperbarui agar bebas dari sintaks yang menyebabkan error di PowerShell dan menyertakan solusi praktis untuk error Papermill "No kernel name found". Ikuti langkah‑langkah di atas baris‑per‑baris. ````
