```markdown
# social-media-sentiment-analysis

Analisis sentimen sederhana dari data media sosial (demo). Repo ini berisi skrip untuk:
- pengumpulan data (opsional),
- preprocess,
- training baseline (TF-IDF + LogisticRegression),
- evaluasi & visualisasi,
- dan satu notebook final yang hanya berisi 1 code cell dan sudah dieksekusi (outputs tersimpan) untuk preview GitHub.

Ringkasan tujuan
- Hanya ada 1 notebook final: `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb`
- Semua perintah disajikan PowerShell-safe (jalankan dari root repo, mis. `C:\Users\ASUS\Desktop\python-project`)
- Jika Anda mengalami error saat install/nbconvert, bagian Troubleshooting di bawah menjelaskan perbaikan umum.

Prasyarat
- Python 3.8–3.12 (rekomendasi). Python 3.14 *bisa* dipakai, tetapi beberapa paket mungkin belum kompatibel.
- Git
- Koneksi internet saat install paket / mengunduh NLTK resources

Struktur yang direkomendasikan
- social-media-sentiment-analysis/
  - create_notebook.py
  - create_sample_data.py        # (opsional) generator CSV sample
  - data_collection.py
  - preprocess.py
  - train_model.py
  - evaluate.py
  - visualize.py
  - requirements.txt
  - social-media-sentiment-analysis.ipynb  (final notebook — commit setelah dieksekusi)
  - data/ (ignored)
  - models/ (ignored kecuali model kecil ingin di-commit)
  - figures/ (opsional)
  - README.md (lokal folder)

.gitignore (pastikan)
- social-media-sentiment-analysis/data/
- social-media-sentiment-analysis/models/
- .venv/ atau venv/

Quick start (PowerShell — singkat)
1. Dari repo root:
   ```powershell
   Set-Location 'C:\Users\ASUS\Desktop\python-project'
   ```

2. Buat dan aktifkan venv (direkomendasikan `.venv` di root):
   ```powershell
   py -3 -m venv .venv
   . .\.venv\Scripts\Activate.ps1
   ```

3. Upgrade pip dan install dependencies (di dalam venv — jangan gunakan `--user`):
   ```powershell
   python -m pip install --upgrade pip setuptools wheel
   python -m pip install -r social-media-sentiment-analysis\requirements.txt
   # atau minimal:
   python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
   ```

4. Siapkan data sample cepat (opsional, rekomendasi untuk testing)
   - Cara cepat: jalankan generator Python (lebih aman daripada menempel CSV panjang ke terminal):
     ```powershell
     python .\social-media-sentiment-analysis\create_sample_data.py
     ```
     Ini membuat `social-media-sentiment-analysis\data\raw\tweets_scraped.csv` dengan contoh berlabel.

5. Preprocess, train, evaluate:
   ```powershell
   python .\social-media-sentiment-analysis\preprocess.py --input .\social-media-sentiment-analysis\data\raw\tweets_scraped.csv --output .\social-media-sentiment-analysis\data\processed\tweets_clean.csv

   python .\social-media-sentiment-analysis\train_model.py --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv --output .\social-media-sentiment-analysis\models\model_pipeline.joblib

   python .\social-media-sentiment-analysis\evaluate.py --model .\social-media-sentiment-analysis\models\model_pipeline.joblib --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
   ```

6. Buat / overwrite notebook final (helper nbformat sudah disediakan)
   ```powershell
   python .\social-media-sentiment-analysis\create_notebook.py
   ```

7. Eksekusi notebook untuk menyimpan outputs (jalankan dari repo root)
   ```powershell
   python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
   ```

8. Commit & push (dari repo root)
   ```powershell
   git add social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
   git add social-media-sentiment-analysis\*.py
   git commit -m "chore: add social-media-sentiment-analysis project and executed notebook"
   git push origin main
   ```

Troubleshooting singkat (paling sering muncul)

A) WinError 32: file sedang digunakan saat pip install (contoh `jupyter-lab.exe`)
- Tutup semua terminal, editor (VS Code), Jupyter server/browser.
- Cek proses:
  ```powershell
  Get-Process *jupyter* -ErrorAction SilentlyContinue
  ```
- Hentikan proses yang berjalan:
  ```powershell
  Stop-Process -Id <PID> -Force
  ```
- Jika masih gagal, restart Windows lalu reinstall:
  ```powershell
  . .\.venv\Scripts\Activate.ps1
  python -m pip install --upgrade --force-reinstall jupyter jupyterlab nbconvert ipykernel
  ```
- Hati-hati: jika pip uninstall meninggalkan folder temp seperti `~pds`, hapus hanya folder yang disebut di warning:
  ```powershell
  Remove-Item -Recurse -Force ".\.venv\Lib\site-packages\~pds" -ErrorAction SilentlyContinue
  ```

B) "Can not perform a '--user' install" di venv
- Jangan gunakan `--user` ketika venv aktif. Gunakan:
  ```powershell
  python -m pip install <package>
  ```

C) nbconvert: "pattern matched no files"
- Pastikan Anda menjalankan perintah dari folder yang sesuai atau gunakan path relatif ke cwd.
  - Dari repo root:
    ```powershell
    python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
    ```
  - Jika Anda berada di dalam folder `social-media-sentiment-analysis`:
    ```powershell
    python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
    ```

D) snscrape error: `'FileFinder' object has no attribute 'find_module'`
- Coba upgrade snscrape:
  ```powershell
  python -m pip install --upgrade snscrape
  ```
- Jika masih error (terutama di Python 3.14), install dari GitHub:
  ```powershell
  python -m pip install --upgrade --force-reinstall "git+https://github.com/JustAnotherArchivist/snscrape.git"
  ```
- Jika snscrape tidak bisa dipakai, gunakan sample CSV (langkah 4) atau gunakan Python 3.11/3.12 venv.

E) FileNotFoundError untuk CSV / model
- Pastikan file input ada (lihat langkah 4 sample) dan jalankan `preprocess.py` → `train_model.py` sebelum `evaluate.py`.
- Jika ingin cepat test tanpa scraping, gunakan `create_sample_data.py`.

Catatan penting saat memakai PowerShell
- Jangan paste multi-line Python langsung ke PowerShell prompt—PowerShell akan menginterpretasikan `import`/`from` sebagai perintahnya. Simpan kode ke `.py` lalu jalankan `python script.py`, atau gunakan REPL `python` terlebih dahulu.

Fallback: jika snscrape tidak bisa dipasang pada Python 3.14
- Buat venv dengan Python 3.11/3.12:
  ```powershell
  py -3.11 -m venv .venv-py311
  . .\.venv-py311\Scripts\Activate.ps1
  python -m pip install -r social-media-sentiment-analysis\requirements.txt
  ```

Verifikasi akhir
- Pastikan hanya satu notebook `.ipynb` di folder `social-media-sentiment-analysis`.
  ```powershell
  Get-ChildItem -Path .\social-media-sentiment-analysis\ -Filter *.ipynb -File | Select-Object Name
  ```
- Notebook sudah berisi outputs (buka di GitHub preview).
- `git status` bersih setelah commit.

Butuh saya tambahkan?
- Saya dapat buatkan `manage_social_notebook.ps1` non-interactive yang memanggil `python -m nbconvert` dan membersihkan leftover site-packages, atau
- Commit file `create_sample_data.py` + README.md langsung ke repo (sebutkan owner/repo dan branch).

```
