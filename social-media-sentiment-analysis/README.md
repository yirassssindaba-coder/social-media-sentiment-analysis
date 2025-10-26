```markdown
# social-media-sentiment-analysis — Full Setup & Troubleshooting (PowerShell-safe)

This README collects and consolidates all previous instructions into one clear, copy‑pasteable, PowerShell‑safe guide. It covers:

- environment setup (venv),
- installing Jupyter + data science packages (permanent in venv),
- creating sample data,
- quick training to produce a model the notebook will load,
- creating & executing the single-cell notebook so GitHub preview shows outputs,
- safe Git workflow (fetch/rebase, resolving non-fast-forward pushes),
- handling untracked `models/` and `figures/` directories,
- safely stopping Jupyter processes (no literal `<PID>`),
- best practices (.gitignore, not committing venv or large data),
- common troubleshooting.

Run each block one at a time from the project root. Example project root:
`C:\Users\ASUS\Desktop\python-project`

Important notes
- Always run commands from repo root unless stated otherwise.
- Activate the virtual environment before running Python installs or scripts.
- Do not paste multi-line Python directly to PowerShell prompt — save to .py and run `python script.py` or use a heredoc pattern.
- When a command example shows a path, use that exact path or your adjusted path; do NOT type placeholders like `<PID>`.

---

## Quick reference — what will be in your repo
Recommended files / folders inside `social-media-sentiment-analysis/`:
- create_notebook.py           (writes final notebook with one code cell)
- create_sample_data.py       (creates sample CSV for testing)
- train_quick.py              (quick trainer that produces models/model_pipeline.joblib)
- preprocess.py               (optional / production training)
- train_model.py              (optional / production training)
- evaluate.py                 (produces evaluation figures)
- visualize.py                (optional plotting helpers)
- requirements.txt
- social-media-sentiment-analysis.ipynb  (final executed notebook)
- data/                       (ignored by default)
- models/                     (ignored by default)
- figures/                    (optional, often ignored)
- README.md

Recommended root `.gitignore` includes:
```
.venv/
venv/
social-media-sentiment-analysis/data/
social-media-sentiment-analysis/models/
.ipynb_checkpoints/
__pycache__/
*.pyc
```

---

## 0) Start here — set location
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
```

---

## 1) Create & activate virtualenv (recommended `.venv`)
```powershell
py -3 -m venv .venv
. .\.venv\Scripts\Activate.ps1

# verify
python --version
python -m pip --version
```

---

## 2) Install required packages (inside venv; do NOT use `--user`)
If you have `social-media-sentiment-analysis\requirements.txt`:
```powershell
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r social-media-sentiment-analysis\requirements.txt
```

If not, install a minimal set:
```powershell
python -m pip install --upgrade pip setuptools wheel
python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
# optional: snscrape (may be problematic on Python 3.14)
python -m pip install snscrape
```

Enable widgets (classic notebook):
```powershell
jupyter nbextension enable --py widgetsnbextension --sys-prefix
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"
```

If you encounter WinError 32 (file lock) while installing:
- Close VS Code, terminals, browsers, Jupyter servers.
- Check running Jupyter processes and stop them (see section "Stop Jupyter safely" below).
- Restart Windows if necessary, then run install again.

---

## 3) Create sample data (recommended for testing)
Use the generator script to avoid pasting long CSV:
```powershell
python .\social-media-sentiment-analysis\create_sample_data.py
# -> creates social-media-sentiment-analysis\data\raw\tweets_scraped.csv
```

If you prefer a small manual file, copy `data/raw/sample_tweets.csv` to `data/raw/tweets_scraped.csv`.

---

## 4) Quick train to produce model that notebook expects
Save and run the quick training script `train_quick.py` (provided separately). From repo root:
```powershell
python .\social-media-sentiment-analysis\train_quick.py
```
Expected outcome:
- A model file created at:
  `social-media-sentiment-analysis\models\model_pipeline.joblib`
- Terminal output showing training progress and a classification report.

If file exists, verify:
```powershell
Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib
```
True means model exists.

---

## 5) Verify model can predict (quick check)
Run a small verification script (safe heredoc approach):
```powershell
python - <<'PY'
import joblib
from pathlib import Path
p = Path("social-media-sentiment-analysis/models/model_pipeline.joblib")
if not p.exists():
    print("Model not found at", p)
    raise SystemExit(1)
pipe = joblib.load(p)
samples = [
    "I absolutely love this! Highly recommend.",
    "This is ok, nothing special.",
    "Terrible experience, will never buy again."
]
print("Predictions:", list(pipe.predict(samples)))
PY
```

---

## 6) Create & execute final notebook (one code cell)
Write the notebook (helper `create_notebook.py` should create `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb` with a single code cell that loads NLTK VADER and attempts to load the pipeline from common paths). Then execute it so outputs are embedded:

From repo root:
```powershell
python .\social-media-sentiment-analysis\create_notebook.py

# Execute notebook and save outputs into file (run from repo root)
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```

Open the notebook in JupyterLab or VS Code to confirm the output shows VADER output and model predictions (not the "No trained model..." message).

---

## 7) Stop Jupyter safely (no literal placeholders)
If you need to stop running Jupyter processes before reinstalling or updating packages, run these safe commands — copy/paste exactly:

```powershell
# Detect jupyter processes
$pj = Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path

if ($null -eq $pj -or $pj.Count -eq 0) {
  Write-Host "No Jupyter processes found."
} else {
  Write-Host "Jupyter processes found:"
  $pj | Format-Table -AutoSize
  foreach ($p in $pj) {
    try {
      Write-Host "Stopping PID" $p.Id "ProcessName" $p.ProcessName
      Stop-Process -Id $p.Id -Force -ErrorAction Stop
      Write-Host "Stopped PID" $p.Id
    } catch {
      Write-Host "Failed to stop PID" $p.Id "- " $_.Exception.Message
    }
  }
}
```

Alternative by name:
```powershell
Get-Process -Name jupyter-lab,jupyter-notebook -ErrorAction SilentlyContinue | Select-Object Id,ProcessName
Stop-Process -Name jupyter-lab -Force -ErrorAction SilentlyContinue
Stop-Process -Name jupyter-notebook -Force -ErrorAction SilentlyContinue
```

Do NOT run `Stop-Process -Id <PID>` with angle brackets. Use numeric IDs returned by `Get-Process`.

---

## 8) Git: handle untracked models/figures & .gitignore
Decide whether to track models/figures or ignore them. Recommended: ignore.

Add ignore entries and stop tracking if previously tracked:
```powershell
# Add to .gitignore if missing
$entry1 = "social-media-sentiment-analysis/models/"
$entry2 = "social-media-sentiment-analysis/figures/"
if (-not (Select-String -Path .\.gitignore -Pattern $entry1 -SimpleMatch -Quiet)) { Add-Content .\.gitignore $entry1 }
if (-not (Select-String -Path .\.gitignore -Pattern $entry2 -SimpleMatch -Quiet)) { Add-Content .\.gitignore $entry2 }

# Stop tracking if they were tracked earlier (does not delete local files)
git rm -r --cached --ignore-unmatch social-media-sentiment-analysis/models
git rm -r --cached --ignore-unmatch social-media-sentiment-analysis/figures

git add .gitignore
git commit -m "chore: ignore models and figures directories"
git push origin main
```

If you intentionally want to commit small models/figures, add them explicitly:
```powershell
git add social-media-sentiment-analysis/models/
git add social-media-sentiment-analysis/figures/
git commit -m "chore: add small model and figures"
git push origin main
```

---

## 9) Git: resolve non-fast-forward push (rejected push)
If `git push` is rejected with `non-fast-forward`, follow this safe flow:

```powershell
# from repo root
git fetch origin
git checkout main

# Recommended: rebase your local commits onto origin/main
git pull --rebase origin main

# resolve any conflicts if Git stops for conflicts:
# - edit files to remove conflict markers
# - then:
git add .\path\to\resolved-file.py
git rebase --continue

# After rebase finishes:
git push origin main
```

If you prefer merge:
```powershell
git pull origin main
# fix conflicts if any, then:
git add .\path\to\resolved-file.py
git commit -m "Resolve merge conflicts"
git push origin main
```

If you earlier stashed work, reapply it:
```powershell
git stash list
git stash pop    # check conflicts and resolve if necessary
```

If you see credential helper warnings (`git: 'credential-manager-core' is not a git command`), install Git Credential Manager for Windows or set a helper you have:
```powershell
git config --global credential.helper manager-core
# or install GCM from https://aka.ms/gcm/windows
```

---

## 10) Final commit checklist & commands
Only commit code, notebook (executed), README, requirements — avoid committing venv/data/models unless intended.

Example final steps:
```powershell
# ensure up-to-date
git fetch origin
git pull --rebase origin main

# add files (example set)
git add social-media-sentiment-analysis\*.py
git add social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
git add README.md
git add requirements.txt

git commit -m "chore: add sentiment analysis pipeline, sample data generator, quick training, and executed notebook"
git push origin main
```

---

## 11) Common troubleshooting quick list
- `No trained model...` in notebook: run `train_quick.py` to create `models/model_pipeline.joblib` and re-execute the notebook (nbconvert).
- `pip install` WinError 32: close processes using .venv\Scripts\*, stop Jupyter processes (see step 7), or restart Windows.
- `snscrape` errors on Python 3.14: either install snscrape from GitHub or use Python 3.11/3.12 venv. Or use sample CSV to avoid scraping.
- Encoding artifacts (â€”): save .py and .ipynb as UTF‑8 (most editors default to UTF-8).

---

## If you are still blocked
Run and paste the outputs of the following commands here (I will inspect and provide exact next commands):
1. `git status --porcelain=1 --branch`
2. `git log --oneline HEAD..origin/main`
3. `Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path`
4. `Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib` (True/False)

I will analyze those outputs and tell you the precise steps to finish the workflow and get the notebook showing model predictions.

---

Thank you — this README consolidates the full, safe, PowerShell‑compatible workflow so you can create sample data, train a quick model, embed the outputs into a one‑cell notebook, and commit/push your project without the common pitfalls you encountered earlier.
```


# social-media-sentiment-analysis — Commit Semua Folder (Opsi B — termasuk data, src, venv, models)

PERINGATAN PENTING
- Opsi B menambahkan semua folder ke repo (termasuk .venv / venv, data, models). Ini bukan best practice — repo bisa menjadi sangat besar, berisi file biner, file OS‑specific, atau data sensitif.
- Pastikan tidak ada file sensitif (kunci, password, API keys) di folder yang akan di‑commit. Jika ada, hapus dulu atau pindahkan ke tempat aman.
- GitHub menolak file >100MB. Periksa file besar sebelum commit. Jika ada file besar, gunakan Git LFS atau simpan di tempat lain (S3/GDrive/Releases).
- Jika Anda tetap ingin melanjutkan, ikuti langkah di bawah. Langkah ini menuntun Anda melakukan commit/push lengkap dan menangani masalah umum.

LANGKAH-LANGKAH (PowerShell-safe)

1) Set lokasi kerja (root repo)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
```

2) Aktifkan virtualenv (opsional, untuk menjalankan skrip)
```powershell
. .\.venv\Scripts\Activate.ps1
```

3) Periksa status git saat ini
```powershell
git status
git branch --show-current
```

4) (KRITIS) Cari file besar (> 100 MB) — GitHub tidak akan menerima file ini
```powershell
# Cari file lebih besar dari 100MB di working tree
Get-ChildItem -Recurse -File | Where-Object { $_.Length -gt 100MB } | Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}
```
- Jika output ada file >100MB: jangan lanjut push tanpa tindakan. Anda harus:
  - Hapus file tersebut dari working tree, atau
  - Pindahkan file ke storage eksternal, atau
  - Gunakan Git LFS (lihat langkah 7).

5) Periksa isi .gitignore (opsional) — kita akan override/ubah sesuai keputusan Opsi B
```powershell
Get-Content .\.gitignore -ErrorAction SilentlyContinue
```
- Jika Anda ingin commit semuanya, hapus / comment entry yang meng-ignore venv/data/models/ (atau update `.gitignore` sesuai kebutuhan).

6) Jika .gitignore masih berisi entri untuk folder yang ingin Anda commit, hapus entri tersebut.
Contoh: menghapus baris yang meng-ignore models/ dan data/ (edit manual atau via PowerShell):
```powershell
# HATI-HATI: ini akan menghapus baris peng-ignore untuk models/ dan data/
(Get-Content .\.gitignore) | Where-Object {$_ -notmatch '^(social-media-sentiment-analysis\/models\/|social-media-sentiment-analysis\/data\/|^\.venv/|^venv/)'} | Set-Content .\.gitignore
```
- Verifikasi ulang:
```powershell
Get-Content .\.gitignore
```

7) (Opsional tapi dianjurkan) Siapkan Git LFS bila ada file besar yang ingin Anda track
- Install Git LFS (jika belum): download & install Git LFS for Windows atau gunakan winget/choco.
- Setelah terinstall:
```powershell
git lfs install
# contoh: track model binary dan data zip/npz
git lfs track "social-media-sentiment-analysis/models/*"
git lfs track "social-media-sentiment-analysis/data/**/*"
git add .gitattributes
```
- Catatan: jika Anda sudah commit file besar sebelumnya, gunakan `git lfs migrate` (lihat bagian "Mengalihkan file yang sudah di-commit ke LFS" di bawah).

8) Tambah semua file ke index (Opsi B = commit semua termasuk venv/data/models)
```powershell
git add -A
```

9) Commit perubahan (jika belum ada commit lokal)
```powershell
git commit -m "chore: add full project including data, src, venv, models, figures (Opsi B)"
```
- Jika git menolak commit karena tidak ada perubahan, periksa `git status --porcelain=1`.

10) Sinkronisasi dengan remote sebelum push (penting)
```powershell
git fetch origin
git checkout main
# disarankan rebase untuk linear history
git pull --rebase origin main
```
- Jika rebase / pull memicu konflik → perbaiki file konflik di editor → `git add <file>` → `git rebase --continue` (atau `git merge --continue` jika merge).

11) Push ke remote
```powershell
git push origin main
```
- Jika push gagal karena ukuran, GitHub akan menolak. Periksa pesan error dan ikuti opsi LFS atau hapus file besar.

12) Jika push ditolak karena non-fast-forward setelah Anda mengedit history, gunakan:
```powershell
# Hanya jika Anda yakin tidak menimpa pekerjaan orang lain
git push --force-with-lease origin main
```
- Jangan gunakan `--force` tanpa memahami risikonya.

Tambahan: Mengalihkan file yang sudah di‑commit ke Git LFS (jika Anda sudah commit file besar)
- Hati‑hati: ini akan mengubah riwayat. Backup branch terlebih dahulu.
```powershell
# buat backup branch
git checkout -b backup-before-lfs-migrate
git push origin backup-before-lfs-migrate

# migrasi (contoh file model)
git lfs migrate import --include="social-media-sentiment-analysis/models/**,social-media-sentiment-analysis/data/**" --include-ref=refs/heads/main
# lalu push (mungkin perlu --force-with-lease karena riwayat berubah)
git push origin main --force-with-lease
```
- Setelah itu re-clone repo di mesin lain agar checkout benar.

Membersihkan file sensitif atau besar yang tidak seharusnya masuk (jika terlanjur commit)
- Gunakan BFG Repo-Cleaner atau `git filter-repo` untuk menghapus file dari history. Ini proses yang destruktif dan perlu koordinasi jika repo berskala tim.

Cek hasil di remote / GitHub
- Setelah berhasil push, buka GitHub repo → periksa tab Code untuk melihat folder yang Anda push.
- Jika ada file yang gagal push karena ukuran, GitHub akan menampilkan error, dan Anda harus mengikuti langkah LFS atau menghapus file tersebut.

Rekomendasi terakhir & best-practice
- Meskipun Anda memilih Opsi B, saya tetap sarankan:
  - Hanya commit model kecil (mis. yang < 10MB) bila benar‑benar diperlukan.
  - Untuk model besar / data sensitif, gunakan release artifacts, cloud storage, atau Git LFS.
  - Jangan commit virtualenv (.venv / venv) — lebih baik commit requirements.txt / environment.yml.
  - Jika ada file sensitif yang sudah tercommit, segera gunakan BFG / filter-repo untuk menghapusnya dari history dan ubah kredensial yang terpapar.

Need-to-know: credential helper warning
- Jika Anda ingin hilangkan pesan `git: 'credential-manager-core' is not a git command`:
  - Install Git Credential Manager: https://aka.ms/gcm/windows
  - Atau set helper ke salah satu yang terinstal:
    ```powershell
    git config --global credential.helper manager-core
    ```

---

Kalau Anda ingin, saya bisa:
- Buatkan rangkaian perintah PowerShell yang langsung mengeksekusi Opsi B untuk Anda (satu file .ps1 non-interactive) — tetapi saya sarankan Anda mengecek hasil `Get-ChildItem -Recurse | Where-Object Length -gt 100MB` dulu.
- Atau saya bisa bantu menulis skrip `git lfs migrate` aman (dengan backup branch) jika ternyata ada file >100MB yang sudah tercommit.

Mau saya siapkan skrip PowerShell otomatis untuk menjalankan seluruh alur Opsi B sekarang (termasuk pengecekan file besar, men-commit, dan push)? Jika ya, konfirmasi dan saya akan sertakan skrip lengkapnya.
