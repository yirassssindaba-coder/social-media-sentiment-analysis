```markdown
# social-media-sentiment-analysis — Full Setup, Training, Execute Notebook & Commit Semua Folder (Opsi B)

PERINGATAN SANGAT PENTING
- Anda memilih Opsi B: semua folder (termasuk `.venv` / `venv`, `data/`, `models/`, `src/`, dsb.) akan dimasukkan ke repositori.
- Ini BERISIKO: repos akan membesar dan GitHub menolak file >100MB. Pastikan tidak ada file sensitif (API keys, password) yang ikut ter-commit.
- Saya sertakan langkah pengecekan file besar dan opsi Git LFS bila diperlukan. Bacalah seluruh README sebelum mengeksekusi perintah.

Prasyarat
- Jalankan dari root repo: `C:\Users\ASUS\Desktop\python-project`
- PowerShell (jalankan biasa, gunakan Run as Administrator bila diperlukan)
- Python 3.8–3.12 direkomendasikan (3.14 mungkin bermasalah pada beberapa paket)
- Git terpasang dan akses push ke remote

Ringkasan alur yang akan dilakukan (urut)
- Buat & aktifkan venv
- Install dependensi (di venv)
- Buat sample data (opsional)
- Train quick model agar notebook dapat memuat model
- Buat & eksekusi notebook final (simpan outputs)
- Hentikan proses Jupyter bila diperlukan
- Periksa file besar (>100MB)
- (Opsi B) Hapus entry .gitignore yang mencegah commit, add semua file, commit & push
- Jika ada masalah ukuran, gunakan Git LFS atau hapus file besar

Ikuti langkah di bawah baris demi baris. Jangan paste seluruh file sekaligus — jalankan blok per blok.

---

## A. Lokasi kerja
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
```

---

## B. Virtual environment
```powershell
# Buat venv di root jika belum
py -3 -m venv .venv

# Aktifkan (PowerShell)
. .\.venv\Scripts\Activate.ps1

# Verifikasi
python --version
python -m pip --version
```

---

## C. Install dependency (di venv)
Gunakan requirements jika ada; jika tidak, install minimal set:
```powershell
python -m pip install --upgrade pip setuptools wheel
# Jika ada requirements.txt:
python -m pip install -r social-media-sentiment-analysis\requirements.txt

# Jika tidak ada:
python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
# snscrape optional (waspadai Python 3.14 compatibility)
python -m pip install snscrape
```

Enable widgets & unduh resource NLTK:
```powershell
jupyter nbextension enable --py widgetsnbextension --sys-prefix
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"
```

Jika pip install error WinError 32 (file used by another process):
- Tutup VS Code / terminal / browser / Jupyter.
- Lihat proses jupyter dan hentikan (lihat bagian "Stop Jupyter safely").
- Jika perlu, restart Windows lalu ulangi install.

---

## D. Buat sample data (opsional, direkomendasikan untuk test cepat)
```powershell
python .\social-media-sentiment-analysis\create_sample_data.py
# Hasil: social-media-sentiment-analysis\data\raw\tweets_scraped.csv
```

---

## E. Train quick model sehingga notebook bisa menampilkan prediksi
Simpan `train_quick.py` di folder `social-media-sentiment-analysis` (skrip disediakan sebelumnya). Jalankan:
```powershell
python .\social-media-sentiment-analysis\train_quick.py
```
Verifikasi file model:
```powershell
Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib
```
Jika True, model ada di lokasi yang dicek notebook.

---

## F. Verifikasi prediksi singkat (tanpa membuka notebook)
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

## G. Buat & eksekusi notebook final (satu code cell) dan simpan outputs
```powershell
# create_notebook.py menulis social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
python .\social-media-sentiment-analysis\create_notebook.py

# Eksekusi notebook (jalankan dari repo root)
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```
Buka notebook di JupyterLab/VS Code untuk memastikan outputs (VADER + prediksi) muncul.

---

## H. Stop Jupyter dengan aman (jika perlu)
Jangan gunakan placeholder; jalankan skrip aman ini untuk mendeteksi & menghentikan proses Jupyter:
```powershell
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

Atau hentikan berdasarkan nama:
```powershell
Get-Process -Name jupyter-lab,jupyter-notebook -ErrorAction SilentlyContinue | Select-Object Id,ProcessName
Stop-Process -Name jupyter-lab -Force -ErrorAction SilentlyContinue
Stop-Process -Name jupyter-notebook -Force -ErrorAction SilentlyContinue
```

---

## I. PENTING — Periksa file besar (>100MB) sebelum commit (GitHub menolak file >100MB)
Jalankan:
```powershell
Get-ChildItem -Recurse -File | Where-Object { $_.Length -gt 100MB } | Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}
```
- Jika ada file >100MB: Pindahkan atau gunakan Git LFS. Jangan push file >100MB langsung.

---

## J. (Opsi B) Siapkan repo untuk commit semua folder — Hapus entry .gitignore yang mencegah commit
> Anda memilih commit semua folder. Hapus baris ignore untuk data/models/venv jika ada.
```powershell
# Hapus baris ignore untuk venv/data/models (HATI-HATI)
(Get-Content .\.gitignore) | Where-Object { $_ -notmatch '^(social-media-sentiment-analysis\/models\/|social-media-sentiment-analysis\/data\/|^\.venv/|^venv/)' } | Set-Content .\.gitignore
Get-Content .\.gitignore
```

---

## K. (Opsional) Siapkan Git LFS bila ada file besar yang ingin Anda tetap track
Instal Git LFS dan track pola yang diinginkan:
```powershell
# install Git LFS manually before this step if not installed
git lfs install
git lfs track "social-media-sentiment-analysis/models/*"
git lfs track "social-media-sentiment-analysis/data/**/*"
git add .gitattributes
```
Jika file besar sudah tercommit tanpa LFS, lakukan migrasi (lihat bagian migrasi di bawah).

---

## L. Tambah semua file ke Git (Opsi B: semua file termasuk venv/data/models)
```powershell
git add -A
git commit -m "chore: add full project including data, src, venv, models, figures (Opsi B)"
```

Jika commit gagal karena tidak ada perubahan, jalankan `git status` untuk verifikasi.

---

## M. Sinkronisasi dengan remote & push (hindari non-fast-forward)
```powershell
git fetch origin
git checkout main
git pull --rebase origin main
# selesaikan konflik jika muncul:
# - edit file, lalu:
git add .\path\to\resolved-file.py
git rebase --continue

# setelah rebase sukses:
git push origin main
```

Jika push ditolak karena non-fast-forward dan Anda benar-benar ingin overwrite remote history (risiko):
```powershell
git push --force-with-lease origin main
```
Gunakan hanya jika Anda memahami konsekuensinya.

---

## N. Jika perlu migrasi file yang sudah tercommit ke Git LFS (advanced / destruktif)
Backup branch dulu:
```powershell
git checkout -b backup-before-lfs-migrate
git push origin backup-before-lfs-migrate
```
Migrasi:
```powershell
git lfs migrate import --include="social-media-sentiment-analysis/models/**,social-media-sentiment-analysis/data/**" --include-ref=refs/heads/main
git push origin main --force-with-lease
```
Setelah migrasi, re-clone repo di mesin lain.

---

## O. Cek dan verifikasi akhir
- Verifikasi model file:
```powershell
Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib
```
- Verifikasi notebook outputs: buka `social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb` di Jupyter/VS Code atau lihat preview GitHub setelah push.
- Verifikasi status Git:
```powershell
git status --porcelain=1 --branch
git log --oneline -n 20
```

---

## P. Mengatasi credential helper warning
Jika Anda lihat:
```
git: 'credential-manager-core' is not a git command
```
Install Git Credential Manager (GCM) for Windows: https://aka.ms/gcm/windows  
Atau set helper yang tersedia:
```powershell
git config --global credential.helper manager-core
```

---

## Q. Jika masih terblokir — kirim output berikut ke saya
Tempel isi output dari perintah-perintah ini agar saya bantu langkah selanjutnya:
1. `git status --porcelain=1 --branch`
2. `git log --oneline HEAD..origin/main`
3. `Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path`
4. `Get-ChildItem -Recurse -File | Where-Object { $_.Length -gt 100MB } | Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}`
5. `Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib` (True/False)

Kirim output lengkap — saya akan analisa dan berikan perintah tepat berikutnya (resolusi konflik / migration / push).

---

## Penutup singkat
- Anda memilih Opsi B dan saya telah merangkum langkah lengkap untuk commit seluruh folder.  
- Jalankan tiap blok per blok, verifikasi hasil, dan laporkan output bila ada yang error.  
- Bila Anda mau, saya bisa buatkan skrip PowerShell `commit_all_opB.ps1` yang akan melakukan pengecekan file besar, menambah semua file, membuat commit, dan push (non-interactive). Sebutkan jika Anda ingin skrip otomatis itu, dan saya akan buatkan file `.ps1` yang bisa langsung Anda jalankan.
```
