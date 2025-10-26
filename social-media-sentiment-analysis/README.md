# Perbaikan & Jalankan Model agar Notebook Menampilkan Prediksi (PowerShell-safe)

README singkat ini menjelaskan langkah-langkah praktis (PowerShell-safe) untuk:
- menyiapkan environment,
- membuat sample data (jika belum ada),
- melatih model cepat yang disimpan di path yang dicari notebook,
- mengeksekusi notebook agar preview GitHub menampilkan hasil prediksi (bukan pesan "No trained model..."),
- dan commit/push ke remote Git dengan aman.

Jalankan perintah dari root repo (contoh):
`C:\Users\ASUS\Desktop\python-project`

CATATAN PENTING
- Jalankan blok per blok (jangan paste semuanya sekaligus).
- Pastikan virtualenv aktif saat meng-install paket (jangan pakai `--user`).
- Jangan paste kode Python multi-line langsung ke PowerShell prompt — simpan ke file `.py` lalu jalankan, atau gunakan skrip kecil via PowerShell (contoh di bawah).

---

## 1. Pastikan lokasi kerja
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
```

## 2. Buat & aktifkan venv (jika belum)
```powershell
py -3 -m venv .venv
. .\.venv\Scripts\Activate.ps1

# verifikasi
python --version
python -m pip --version
```

## 3. Install dependensi utama (di venv)
```powershell
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r social-media-sentiment-analysis\requirements.txt

# Jika tidak ada requirements.txt, minimal:
python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
```

## 4. Buat sample data (jika belum ada)
- Jika Anda belum punya data raw, jalankan generator sample (lebih aman daripada paste CSV panjang):
```powershell
python .\social-media-sentiment-analysis\create_sample_data.py
# -> membuat social-media-sentiment-analysis\data\raw\tweets_scraped.csv
```

## 5. Latih model cepat (agar notebook dapat memuat model)
- Simpan file berikut sebagai `social-media-sentiment-analysis\train_quick.py` (atau gunakan `train_model.py` jika sudah siap).
- Jalankan dari root (venv harus aktif):
```powershell
python .\social-media-sentiment-analysis\train_quick.py
```
- Output yang diharapkan: training progress, classification report, dan
  `Saved model pipeline to: social-media-sentiment-analysis\models\model_pipeline.joblib`

Jika `train_quick.py` belum ada, Anda bisa menggunakan `train_model.py` yang ada di repo — pastikan input path sama dengan yang Anda buat pada langkah 4.

## 6. Verifikasi file model ada (PowerShell)
```powershell
Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib
# Jika True, file model ada di lokasi yang dicari notebook
```

## 7. (Re)buat notebook final & eksekusi agar outputs tersimpan
- Pastikan `create_notebook.py` berada di `social-media-sentiment-analysis\create_notebook.py`. Jika belum, tambahkan file helper tersebut.
- Jalankan helper untuk menulis notebook (1 code cell):
```powershell
python .\social-media-sentiment-analysis\create_notebook.py
```
- Eksekusi notebook (jalankan dari repo root sehingga path relatif sesuai):
```powershell
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```
- Jika Anda berada di dalam folder `social-media-sentiment-analysis`, jalankan:
```powershell
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```

## 8. Quick verify (menjalankan skrip kecil via PowerShell untuk melihat prediksi)
- Cara aman membuat skrip sementara dan menjalankannya:
```powershell
# tulis skrip verifikasi kecil
@'
import joblib
from pathlib import Path
p = Path("social-media-sentiment-analysis/models/model_pipeline.joblib")
if p.exists():
    pipe = joblib.load(p)
    samples = [
        "I absolutely love this! Highly recommend.",
        "This is ok, nothing special.",
        "Terrible experience, will never buy again."
    ]
    preds = pipe.predict(samples)
    for s, pr in zip(samples, preds):
        print(f"[{pr}] {s}")
else:
    print("Model not found at", p)
'@ | Out-File .\verify_model.py -Encoding UTF8

# jalankan dan hapus skrip verifikasi
python .\verify_model.py
Remove-Item .\verify_model.py -Force
```
- Contoh output yang diharapkan (label bisa bervariasi tergantung data/model):
```
[positive] I absolutely love this! Highly recommend.
[neutral] This is ok, nothing special.
[negative] Terrible experience, will never buy again.
```

## 9. Git: stage, commit, sinkronisasi dan push (hindari error 'rejected' / non-fast-forward)
1) Pastikan sinkron dengan remote:
```powershell
git fetch origin
git checkout main
git pull --rebase origin main
```
2) Tambah file dan commit:
```powershell
git add social-media-sentiment-analysis\create_notebook.py
git add social-media-sentiment-analysis\create_sample_data.py
git add social-media-sentiment-analysis\train_quick.py
git add social-media-sentiment-analysis\preprocess.py
git add social-media-sentiment-analysis\train_model.py
git add social-media-sentiment-analysis\evaluate.py
git add social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
# Opsional: tambahkan model hanya jika Anda sengaja ingin commit model biner
# git add social-media-sentiment-analysis\models\model_pipeline.joblib

git commit -m "chore: add training helper, sample data, and executed notebook"
git push origin main
```
- Jika push ditolak, ulangi `git pull --rebase origin main`, selesaikan konflik, lalu `git push origin main`.
- Jangan gunakan `git push --force` kecuali Anda paham risikonya.

## 10. Troubleshooting singkat (masalah yang sering muncul)
- Pesan notebook masih menampilkan "No trained model..."?
  - Pastikan `social-media-sentiment-analysis\models\model_pipeline.joblib` benar-benar ada (lihat langkah 6).
  - Pastikan Anda menjalankan nbconvert dari repo root agar path relatif yang dicek notebook sesuai.
- Error saat `python -m pip install` (WinError 32: file used by another process):
  - Tutup VS Code / terminal / Jupyter; jalankan:
    ```powershell
    Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName
    ```
    lalu hentikan proses yang relevan:
    ```powershell
    Stop-Process -Id 1234 -Force
    ```
  - Jika masih error, restart Windows lalu ulangi instal.
- Jangan gunakan `--user` saat venv aktif.
- Jika `snscrape` bermasalah di Python 3.14, gunakan sample CSV atau buat venv dengan Python 3.11/3.12.

---

## 11. Contoh urutan penuh (copy/paste baris per baris di PowerShell)
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
. .\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r social-media-sentiment-analysis\requirements.txt

python .\social-media-sentiment-analysis\create_sample_data.py
python .\social-media-sentiment-analysis\train_quick.py
python .\social-media-sentiment-analysis\create_notebook.py
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120

git fetch origin
git pull --rebase origin main
git add social-media-sentiment-analysis\*.py social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
git commit -m "chore: add training helper, sample data, and executed notebook"
git push origin main
```

---

Jika Anda jalankan langkah-langkah di atas dan notebook masih menampilkan pesan "No trained model ...", tempelkan output lengkap dari:
- `python .\social-media-sentiment-analysis\train_quick.py` dan
- `Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib` (hasil True/False),  
— saya akan bantu koreksi langkah spesifiknya.
