# Social Media Sentiment Analysis — README

Ringkasan singkat  
Dokumen ini memberi instruksi PowerShell‑friendly dan langkah‑demi‑langkah untuk:
1. Menyimpan README / RUNME ke folder project,
2. Menyiapkan virtual environment dan dependensi,
3. Memperbaiki error Papermill "No kernel name found" tanpa heredoc,
4. Menjalankan notebook untuk menghasilkan keluaran ke folder `results`,
5. Memeriksa file besar dan mengatur Git LFS (opsional),
6. Menghindari commit `.venv` dan melakukan stage/commit/push yang aman.

Semua perintah ditujukan dijalankan baris‑per‑baris di PowerShell pada mesin lokal. Ganti path contoh jika perlu. Jika branch utama Anda bukan `main`, ganti `main` pada semua perintah git.

1) Persyaratan awal
1.1 Pastikan Git dan Python (3.8+) terpasang.  
1.2 Disarankan membuat virtual environment `.venv` di root repo: `C:\Users\ASUS\Desktop\python-project`.  
1.3 Jalankan perintah ini dari PowerShell (baris‑per‑baris):
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
```

2) Menyimpan README.md / RUNME.md ke folder project
Pilih salah satu metode di bawah.

2.1 Cara A — manual (direkomendasikan)  
- Buka editor (VS Code, Notepad).  
- Salin isi file README ini dan Save As ke:
  `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis\README.md`

2.2 Cara B — salin dari file sumber (PowerShell-safe)
```powershell
$targetDir = 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
$sourcePath = 'C:\path\to\your\README_source.md'  # GANTI dengan path nyata
if (Test-Path $sourcePath) {
  Copy-Item -Path $sourcePath -Destination (Join-Path $targetDir 'README.md') -Force
  Write-Host "README.md disalin ke $targetDir"
} else {
  Write-Host "Sumber tidak ditemukan: $sourcePath" -ForegroundColor Yellow
}
```

2.3 Cara C — buat file kosong lalu edit (ditambahkan sesuai permintaan)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'
if (-not (Test-Path '.\README.md')) { New-Item -Path '.\README.md' -ItemType File -Force }
notepad .\README.md   # atau: code .\README.md untuk VS Code
```
> Catatan: gunakan Cara C juga untuk membuat `RUNME.md` bila perlu (ganti nama file).

3) Buat & aktifkan virtual environment
3.1 Jalankan dari root repo:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# buat venv jika belum ada
if (-not (Test-Path '.\.venv')) { python -m venv .venv }

# aktifkan (PowerShell)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # bila perlu
.\.venv\Scripts\Activate.ps1

# verifikasi
python --version
pip --version
```

4) Instal dependensi penting
```powershell
python -m pip install --upgrade pip
python -m pip install nbformat papermill ipykernel jupyter
# jika ada requirements:
if (Test-Path '.\requirements.txt') { python -m pip install -r .\requirements.txt }
if (Test-Path '.\social-media-sentiment-analysis\requirements.txt') { python -m pip install -r .\social-media-sentiment-analysis\requirements.txt }
```

5) Periksa `.gitignore` dan folder `results` dengan aman
5.1 Pastikan folder `results` tidak di‑ignore (atau sengaja di‑ignore sesuai kebutuhan):
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Select-String -Path .gitignore -Pattern "results","social-media-sentiment-analysis/results" -SimpleMatch -ErrorAction SilentlyContinue
if ($?) { Write-Host ".gitignore mungkin mengecualikan results — periksa isinya" -ForegroundColor Yellow } else { Write-Host ".gitignore tidak mengecualikan results (sementara)." -ForegroundColor Green }
```

5.2 Solusi aman untuk memeriksa folder `results` tanpa error "path not found":
```powershell
$repoRoot   = 'C:\Users\ASUS\Desktop\python-project'
$projectDir = Join-Path $repoRoot 'social-media-sentiment-analysis'
$resultsDir = Join-Path $projectDir 'results'
$autoCreateMissingFolders = $false   # ubah ke $true jika ingin auto-create

if (-not (Test-Path $repoRoot)) { Write-Host "Repo root tidak ditemukan: $repoRoot" -ForegroundColor Red; return }
if (-not (Test-Path $projectDir)) { Write-Host "Project folder tidak ditemukan: $projectDir" -ForegroundColor Yellow; return }

if (-not (Test-Path $resultsDir)) {
  Write-Host "Folder results tidak ditemukan: $resultsDir" -ForegroundColor Yellow
  if ($autoCreateMissingFolders) {
    New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
    Write-Host "Membuat folder results kosong: $resultsDir" -ForegroundColor Green
  } else {
    Write-Host "Lewati pemeriksaan file results (folder tidak ada)." -ForegroundColor Yellow
  }
} else {
  Get-ChildItem -Path $resultsDir -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} |
    Format-Table -AutoSize
}
```

5.3 Cari file >100MB (jika folder ada):
```powershell
if (Test-Path $resultsDir) {
  Get-ChildItem -Path $resultsDir -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } |
    Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}
}
```

6) (Opsional) Setup Git LFS untuk file besar
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git lfs install
git lfs track "social-media-sentiment-analysis/results/**"
git add .gitattributes
$staged = git diff --cached --name-only
if ($staged) { git commit -m "chore: track results via git-lfs" } else { Write-Host "No .gitattributes changes to commit." -ForegroundColor Yellow }
```

7) Menjalankan notebook — menghindari error Papermill "No kernel name found"
7.1 Penyebab: notebook tidak memiliki metadata `kernelspec.name`. Hindari menggunakan heredoc `<<'PY'` di PowerShell.

7.2 Solusi A — perbaiki via Jupyter UI (direkomendasikan)
- Aktifkan venv, jalankan `jupyter notebook` atau `jupyter lab`, buka notebook, pilih Kernel → Change kernel → pilih Python kernel (mis. Python 3), lalu Save.

7.3 Solusi B — otomatis via file Python sementara (PowerShell-safe)
Salin baris‑per‑baris berikut (tidak menggunakan heredoc):
```powershell
# backup notebook
$nbPath = 'social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb'
if (-not (Test-Path $nbPath)) { Write-Host "Notebook tidak ditemukan: $nbPath" -ForegroundColor Red; return }
Copy-Item -Path $nbPath -Destination ($nbPath + '.bak') -Force
Write-Host "Backup dibuat: $nbPath.bak"

# buat skrip Python sementara untuk menambahkan kernelspec (ubah "python3" jika perlu)
$pyScript = @'
import nbformat
from pathlib import Path
nb_path = Path("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb")
nb = nbformat.read(str(nb_path), as_version=4)
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

# jalankan skrip
python $tempPy

# (opsional) hapus skrip sementara
# Remove-Item -Path $tempPy -Force
```

7.4 Verifikasi kernelspec (opsional)
```powershell
$checkScript = @'
import nbformat
nb = nbformat.read("social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb", as_version=4)
print("kernelspec:", nb.metadata.get("kernelspec"))
'@
$checkPy = Join-Path $env:TEMP 'check_kernelspec.py'
Set-Content -Path $checkPy -Value $checkScript -Encoding UTF8
python $checkPy
# Remove-Item $checkPy -Force  # opsional
```

7.5 Jalankan Papermill (PowerShell-safe)
```powershell
# Option A: biarkan papermill baca kernelspec dari notebook
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"

# Option B: override kernel jika mau
papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb" --kernel "python3"
```
Jika kernel belum terdaftar, daftarkan dari venv:
```powershell
python -m ipykernel install --user --name python3 --display-name "Python 3"
```

8) Alternatif: jalankan notebook tanpa Papermill
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --inplace
```

9) Hentikan pelacakan `.venv` dan perbarui `.gitignore` (aman)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
$venvRel = 'social-media-sentiment-analysis/.venv'
& git ls-files --error-unmatch -- $venvRel 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Removing tracked .venv from index..."
  & git rm -r --cached --ignore-unmatch -- $venvRel
} else {
  Write-Host "No tracked .venv found in index."
}

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

10) Stage, commit, push secara aman (PowerShell-safe)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'

$readme = '.\social-media-sentiment-analysis\README.md'
$runme  = '.\social-media-sentiment-analysis\RUNME.md'
$results = '.\social-media-sentiment-analysis\results'
$notebookOut = '.\social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb'

if (Test-Path $readme) { & git add $readme } else { Write-Host "README not found; skipping." -ForegroundColor Yellow }
if (Test-Path $runme)  { & git add $runme  } else { Write-Host "RUNME not found; skipping." -ForegroundColor Yellow }
if (Test-Path $notebookOut) { & git add $notebookOut }
if (Test-Path $results) { & git add "$results\*" } else { Write-Host "No results to stage." -ForegroundColor Yellow }

$staged = & git diff --cached --name-only
if ($staged -and $staged.Trim().Length -gt 0) {
  & git commit -m "docs: add/update README and run outputs"
  & git fetch origin
  & git pull --rebase --autostash origin main
  # jika konflik: perbaiki file, git add "path\to\file", lalu: git rebase --continue
  & git push origin main
} else {
  Write-Host "Nothing to commit (no staged changes)." -ForegroundColor Yellow
}
```

11) Troubleshooting singkat
- ParserError di PowerShell: jangan tempel sintaks bash (`||`, `&&`, heredoc `<<`, placeholder `<...>`). Gunakan bentuk PowerShell yang disediakan.  
- Papermill "No kernel name found": perbaiki metadata kernelspec (bagian 7) atau gunakan `--kernel`.  
- Papermill "kernel not found": jalankan `jupyter kernelspec list` dan register kernel dari venv (`python -m ipykernel install --user --name <name> --display-name "<display>"`).  
- Jika rebase aktif: `git status` → `git rebase --abort` (jika ingin membatalkan) atau setelah menyelesaikan konflik dan `git add` → `git rebase --continue`.

12) Opsi skrip otomatis (opsional)
Saya dapat menyediakan skrip PowerShell siap pakai:
- `update_kernelspec_and_run.ps1` — backup notebook, update kernelspec (temporary .py), run papermill (dengan `--kernel` option), dan tampilkan hasil.  
- `create_runme_and_push.ps1` — salin RUNME, dry‑run (tampilkan file besar & file yang akan distage), lalu (opsional) commit/push.  
- `fix-venv-and-git.ps1` — menghapus .venv dari index, memperbarui .gitignore, commit jika perlu.

Ketik pilihan Anda: "Buat update_kernelspec_and_run.ps1", "Buat create_runme_and_push.ps1", atau "Buat fix-venv-and-git.ps1" — saya akan buatkan skrip lengkap interaktif yang aman.

---

Terima kasih — README ini dirancang untuk mudah disalin, dicetak, dan dijalankan di PowerShell tanpa menimbulkan error parser atau Papermill terkait kernel. Ikuti langkah‑langkah berangka di atas baris‑per‑baris.````