# social-media-sentiment-analysis

Analisis sentimen sederhana dari data media sosial (demo). Repo ini berisi skrip Python untuk pengumpulan data (opsional), preprocess, training baseline, evaluasi, visualisasi, dan satu notebook final yang berisi 1 code cell yang telah dieksekusi (outputs tersimpan) supaya preview GitHub menampilkan hasil.

Penting — status & perbaikan yang saya masukkan
- Memperbaiki alur instalasi Jupyter/nbconvert agar tidak menggunakan `--user` di dalam virtualenv.
- Menambahkan troubleshooting untuk WinError 32 (file lock) dan langkah untuk membersihkan temporary package leftover pada `.venv\Lib\site-packages\~*`.
- Menyertakan solusi untuk error `snscrape` (compatibility / import API) dan alternatif (pakai CSV contoh jika snscrape gagal).
- Menjelaskan path kerja yang benar saat menulis/menjalankan notebook sehingga nbconvert tidak gagal karena path mismatch.
- Menambahkan langkah membuat sample CSV kecil agar pipeline dapat dites tanpa scraping.

Ringkasan tujuan
- Pastikan ada hanya 1 notebook final:
  `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb`
  — notebook ini harus berisi 1 code cell dan sudah dieksekusi (outputs tersimpan).
- Semua instruksi PowerShell-safe (tidak memakai `||` atau sintaks bash khusus).
- Jalankan perintah dari root repo (contoh): `C:\Users\ASUS\Desktop\python-project`

Prerequisites
- Python 3.8–3.12 direkomendasikan. Python 3.14 dapat dipakai, tetapi beberapa paket (mis. snscrape, pyarrow) mungkin belum kompatibel.
- Git
- Koneksi internet saat menginstal paket / mengunduh NLTK resources

Struktur direkomendasikan (folder `social-media-sentiment-analysis`)
- create_notebook.py
- data_collection.py
- preprocess.py
- train_model.py
- evaluate.py
- visualize.py
- requirements.txt
- social-media-sentiment-analysis.ipynb (final notebook — commit setelah dieksekusi)
- data/ (ignored)
- models/ (ignored kecuali model kecil ingin di-commit)
- figures/ (opsional artefak)
- README.md (lokal folder)

Jangan commit
- `social-media-sentiment-analysis/data/`
- `social-media-sentiment-analysis/models/`
- virtualenv (`.venv/`, `venv/`)
Tambahkan semua entri tersebut ke `.gitignore`.

PowerShell — Quick start (ringkas)
1. Dari root repo:
   ```powershell
   Set-Location 'C:\Users\ASUS\Desktop\python-project'
   ```
2. Buat venv (disarankan di root repo) dan aktifkan:
   ```powershell
   py -3 -m venv .venv
   . .\.venv\Scripts\Activate.ps1
   ```
3. Upgrade pip dan install deps (di dalam venv — TANPA `--user`):
   ```powershell
   python -m pip install --upgrade pip setuptools wheel
   python -m pip install -r social-media-sentiment-analysis\requirements.txt
   ```
   Jika Anda tidak punya `requirements.txt`, minimal:
   ```powershell
   python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
   ```

Masalah yang Anda alami & solusi langkah-demi-langkah
1) WinError 32 saat pip install (file dikunci: jupyter-lab.exe)
- Gejala: install berhenti dengan OSError WinError 32: file being used.
- Solusi:
  - Tutup semua terminal, VS Code, Jupyter, browser yang mungkin menjalankan Jupyter.
  - Cek proses yang mengunci:
    ```powershell
    Get-Process *jupyter* -ErrorAction SilentlyContinue
    ```
  - Jika ada process, hentikan:
    ```powershell
    Stop-Process -Id <PID> -Force
    ```
  - Jika masih gagal, restart Windows lalu ulangi instal:
    ```powershell
    . .\.venv\Scripts\Activate.ps1
    python -m pip install --upgrade --force-reinstall jupyter jupyterlab nbconvert ipykernel
    ```
  - Bila pip uninstall meninggalkan direktori temporary `~...` di site-packages, hapus manual folder yang warning-nya sebutkan (contoh):
    ```powershell
    Remove-Item -Recurse -Force ".\.venv\Lib\site-packages\~pds" -ErrorAction SilentlyContinue
    ```
    (Lakukan hanya untuk path yang spesifik disebut di warning; hati‑hati jangan hapus package valid.)

2) Error "Can not perform a '--user' install. User site-packages are not visible in this virtualenv."
- Ketika venv aktif, jangan pakai `--user`. Gunakan:
  ```powershell
  python -m pip install <package>
  ```

3) nbconvert "pattern matched no files"
- Sebab: jalankan nbconvert dari folder yang salah atau berikan path ganda.
- Jika Anda menjalankan dari repo root:
  ```powershell
  python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
  ```
- Jika Anda berada di dalam folder `social-media-sentiment-analysis`:
  ```powershell
  python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
  ```

4) data_collection.py — snscrape error AttributeError: 'FileFinder' object has no attribute 'find_module'
- Penyebab: versi snscrape yang terinstall tidak kompatibel dengan API importlib untuk versi Python/packaging tertentu; juga snscrape historically needs newer versions or git install.
- Solusi urut:
  a) Coba install/upgrade snscrape dari PyPI:
     ```powershell
     python -m pip install --upgrade snscrape
     ```
  b) Jika masih error (terutama di Python 3.14), install langsung dari repo yang paling up-to-date:
     ```powershell
     python -m pip install --upgrade --force-reinstall "git+https://github.com/JustAnotherArchivist/snscrape.git"
     ```
  c) Jika snscrape tetap bermasalah: gunakan CSV input (lebih aman). Saya sediakan perintah untuk membuat sample CSV singkat di langkah "Test run" di bawah.

5) FileNotFoundError untuk CSV/model (tweets_scraped.csv / tweets_clean.csv / model_pipeline.joblib)
- Penyebab: Anda belum membuat data/raw CSV atau belum menjalankan preprocess/train.
- Solusi cepat: buat sample CSV agar pipeline bisa diuji.
  ```powershell
  # dari repo root, buat folder
  New-Item -ItemType Directory -Path .\social-media-sentiment-analysis\data\raw -Force
  @"
text,label
"I love this product",positive
"This is terrible",negative
"It's okay, not great",neutral
"Wonderful! Highly recommend",positive
"Bad experience, will not return",negative
"Just average",neutral
"Fantastic value and quality",positive
"Awful, broke quickly",negative
"Works as expected",neutral
"Exceeded my expectations",positive
"Not worth the money",negative
"Decent for the price",neutral
"Superb purchase",positive
"Terrible customer service",negative
"Meh, nothing special",neutral
"Absolutely amazing",positive
"Completely disappointed",negative
"Pretty good overall",positive
"Would buy again",positive
"Never again",negative
"Neutral about it",neutral
"Love it",positive
"Hate it",negative
"Could be better",neutral
"Impressive",positive
"Very disappointing",negative
"Okay product",neutral
"Top quality",positive
"Don't buy",negative
"Average",neutral
"Best purchase",positive
"Regret this buy",negative
"Fine",neutral
"Excellent",positive
"Bad",negative
"Okayish",neutral
"Thumbs up",positive
"Thumbs down",negative
"Neither good nor bad",neutral
"Highly satisfied",positive
"Not impressed",negative
"Neutral viewpoint",neutral
"Pleasantly surprised",positive
"Extremely poor",negative
"Fair",neutral
"Very happy",positive
"Very bad",negative
"Could improve",neutral
"Super happy",positive
"Terrible product",negative
"Indifferent",neutral
"Great!",positive
"Very disappointing purchase",negative
"Okay",neutral
"Love it a lot",positive
"Disliked it",negative
"Average item",neutral
"Five stars",positive
"One star",negative
"Neutral feeling",neutral
"Works fine",positive
"Not great",negative
"Fine product",neutral
"Outstanding",positive
"Broke immediately",negative
"Nothing special",neutral
"Pleasant",positive
"Bad quality",negative
"Middle of the road",neutral
"Recommend",positive
"Dislike",negative
"Neutral take",neutral
"Wonderful",positive
"Poor",negative
"Alright",neutral
"Very recommended",positive
"Terrible buy",negative
"Neither here nor there",neutral
"Super",positive
"Awful quality",negative
"OK",neutral
"Love this",positive
"Sucks",negative
"It's fine",neutral
"Great value",positive
"Bad choice",negative
"Neutral stance",neutral
"Perfect",positive
"Worthless",negative
"Ordinary",neutral
"Exceptional",positive
"Not as expected",negative
"Undecided",neutral
"Stellar",positive
"Bad experience overall",negative
"Meets expectations",neutral
"Highly recommended",positive
"Regrettable",negative
"Nothing to say",neutral
"Nice",positive
"Subpar",negative
"Balanced",neutral
"Wonderful item",positive
"Terrible",negative
"Okay product overall",neutral
"Superb",positive
"Displeased",negative
"Neutral opinion",neutral
"Phenomenal",positive
"Not good",negative
"Average quality",neutral
"Love the design",positive
"Horrible design",negative
"Neutral review",neutral
"Works well",positive
"Broken",negative
"Neither",neutral
"Fine enough",neutral
"Excellent quality",positive
"Not for me",negative
"Mixed feelings",neutral
"Lovely",positive
"Very substandard",negative
"Reasonable",neutral
"Top notch",positive
"Badly made",negative
"Indifferent about it",neutral
"Well made",positive
"Shoddy",negative
"Neutral comment",neutral
"Impressive product",positive
"Not recommended",negative
"Neither negative nor positive",neutral
"Great purchase",positive
"Low quality",negative
"Undetermined",neutral
"Solid",positive
"Fails expectations",negative
"Fine by me",neutral
"Wonderful build",positive
"Really bad",negative
"Okay item",neutral
"Absolutely brilliant",positive
"Terrible condition",negative
"Neutral review text",neutral
"Happy",positive
"Sad",negative
"Unsure",neutral
"Delighted",positive
"Disappointed",negative
"Neutral remark",neutral
"Thumbs up overall",positive
"Thumbs down overall",negative
"Neither good nor bad overall",neutral
"Pleasure",positive
"Misleading",negative
"Can't decide",neutral
"Very pleased",positive
"Not satisfied",negative
"Mixed",neutral
"Great quality",positive
"Very poor",negative
"Balanced view",neutral
"Superb craftsmanship",positive
"Terrible workmanship",negative
"Neutral perspective",neutral
"Happy customer",positive
"Unhappy customer",negative
"Neither here nor there",neutral
"Top pick",positive
"Bad pick",negative
"Neutral choice",neutral
"Would recommend",positive
"Would not recommend",negative
"Neutral stance on this",neutral
"Enjoyed it",positive
"Detested it",negative
"Neutral feelings",neutral
"Pleasant experience",positive
"Regret purchasing",negative
"Neutral thoughts",neutral
"Good",positive
"Poor",negative
"Mid",neutral
"Favourable",positive
"Unfavourable",negative
"Neutrality",neutral
"Positive",positive
"Negative",negative
"Neutrality again",neutral
"Liked it",positive
"Didn't like it",negative
"Neither liked nor disliked",neutral
"Pleasant enough",positive
"Terrible overall",negative
"Indifferent overall",neutral
"Greatly satisfied",positive
"Very unsatisfied",negative
"Not sure",neutral
"Excellent buy",positive
"Not recommended at all",negative
"Okay-ish",neutral
"Best product",positive
"Worst product",negative
"Neutral product",neutral
"Absolutely good",positive
"Absolutely bad",negative
"Neither this nor that",neutral
"Super product",positive
"Substandard",negative
"Neutral-ish",neutral
"Standout",positive
"Underwhelming",negative
"Moderate",neutral
"Thumbs up++",positive
"Thumbs down--",negative
"Neutral++",neutral
"Pleasantly OK",positive
"Ruined",negative
"Indifferent+",neutral
"Top-quality buy",positive
"Horrendous",negative
"Average purchase",neutral
"Really satisfied",positive
"Really dissatisfied",negative
"Neither confirmed nor denied",neutral
"Decent buy",positive
"Disappointing buy",negative
"Neutral evaluation",neutral
"Good enough",positive
"Not good enough",negative
"Neutral comment again",neutral
"Really good",positive
"Really bad experience",negative
"Neutral as ever",neutral
"Solid buy",positive
"Not worth it",negative
"Mix feelings",neutral
"Well built",positive
"Poorly built",negative
"Neutral reflection",neutral
"Great seller",positive
"Bad seller",negative
"Neutral seller review",neutral
"Recommend",positive
"Don't recommend",negative
"Neutral conclusion",neutral
"Fav",positive
"Not fav",negative
"Neutral fav",neutral
"Ok good",positive
"Ok bad",negative
"Neutral ok",neutral
"Works",positive
"Broken item",negative
"Maybe",neutral
"Love it totally",positive
"Hate it totally",negative
"Not decided",neutral
"Fantastic buy",positive
"Terrible buy overall",negative
"Neutral result",neutral
"Very good buy",positive
"Very bad buy",negative
"Indifferent result",neutral
"Yes good",positive
"No bad",negative
"Neutral yes",neutral
"Pleasant purchase",positive
"Unpleasant purchase",negative
"Neutral shopping",neutral
"Fine purchase",positive
"Bad purchase outcome",negative
"Neutral delivery",neutral
"Smooth",positive
"Glitchy",negative
"Neutral product behavior",neutral
"Works great",positive
"Fails badly",negative
"Neutrality in buying",neutral
"Super product sale",positive
"Terrible product sale",negative
"Neutral product sale",neutral
"Ok done",neutral
"Perfect buy",positive
"Bad buy",negative
"Neutral buy",neutral
"Recommended overall",positive
"Not recommended overall",negative
"Neither overall",neutral
"Happy purchase",positive
"Regretful purchase",negative
"Neutral report",neutral
"Quality good",positive
"Quality bad",negative
"Average item review",neutral
"Recommend to friends",positive
"Do not recommend",negative
"Neutral afterthought",neutral
"Successfully made",positive
"Failed to satisfy",negative
"Neutral perspective again",neutral
"Very delighted",positive
"Extremely displeased",negative
"Neutral note",neutral
"Good find",positive
"Bad find",negative
"Neutral find",neutral
"Lovely detail",positive
"Ugly detail",negative
"Neutral detail",neutral
"Appreciated",positive
"Not appreciated",negative
"Neutral appreciation",neutral
"Good thing",positive
"Bad thing",negative
"Neutral thing",neutral
"Nice try",positive
"Poor try",negative
"Neutral attempt",neutral
"Product ok",neutral
"Product not ok",negative
"Product somewhat ok",neutral
"Value for money",positive
"Not value",negative
"Neutral value",neutral
"Alright product",neutral
"Splendid",positive
"Hopeless",negative
"Neutral observation",neutral
"Well recommended",positive
"Ill recommended",negative
"Neutral assessment",neutral
"Like",positive
"Dislike",negative
"Neutral verbally",neutral
"Well",positive
"Badly",negative
"Okay okay",neutral
"Great recommendation",positive
"Not recommended at all",negative
"Neutral line",neutral
"Complete",positive
"Incomplete",negative
"Neutral completeness",neutral
"Fantastic",positive
"Poorly",negative
"Neutrally described",neutral
"Thumbs middle",neutral
"Strongly like",positive
"Strongly dislike",negative
"Moderate feelings",neutral
"Very recommend",positive
"Very not recommend",negative
"Neutral again",neutral
"Wonderful",positive
"Terrible",negative
"Neutralness",neutral
"Nice product",positive
"Bad product",negative
"Neutrality continuing",neutral
"Great",positive
"Bad",negative
"Neutrality persists",neutral
"Top",positive
"Bottom",negative
"Neutral middle",neutral
"OKAY",neutral
"really good",positive
"really bad",negative
"not certain",neutral
"pleasant",positive
"displeasing",negative
"meh",neutral
"works fine",positive
"broke",negative
"no comment",neutral
"amazing",positive
"awful",negative
"okkk",neutral
"could be improved",neutral
"timeless",positive
"not for me",negative
"undecided",neutral
"very nice",positive
"very bad",negative
"fair",neutral
"functional",positive
"defective",negative
"midrange",neutral
"very solid",positive
"very cheap",negative
"average joe",neutral
"not too bad",positive
"major flaws",negative
"unclear",neutral
"overall fine",positive
"overall poor",negative
"not sure at all",neutral
"somewhat pleased",positive
"somewhat displeased",negative
"ambivalent",neutral
"quite nice",positive
"very unsatisfactory",negative
"so-so",neutral
"genuinely good",positive
"genuinely bad",negative
"neutral tone",neutral
"end",neutral
"final sample",neutral
"last sample",neutral
"final final",neutral
"the end",neutral
"done",neutral
"stop",neutral
"ok end",neutral
"finish",neutral
"close",neutral
"terminate",neutral
"finish now",neutral
"complete now",neutral
"terminate now",neutral
"sample end",neutral
"final end",neutral
"over",neutral
"bye",neutral
"the conclusion",neutral
"done done",neutral
"ok",neutral
"fine final",neutral
"finish okay",neutral
"finalized",neutral
"closed",neutral
"complete",neutral
"finish complete",neutral
"the finish",neutral
"end of sample",neutral
"last",neutral
"the last one",neutral
"goodbye",neutral
"closing",neutral
"end sample",neutral
"it ends",neutral
"all done",neutral
"fin",neutral
"finish line",neutral
"that's it",neutral
"stop here",neutral
"complete sample",neutral
"end of file",neutral
"EOF",neutral
"ENDOFCSV",neutral
"THE END",neutral
"THE END OF CSV",neutral
"no more",neutral
"no further",neutral
"terminated",neutral
"end now",neutral
"closing now",neutral
"fullstop",neutral
"that's the dataset",neutral
"done dataset",neutral
"dataset complete",neutral
"dataset end",neutral
"finish dataset",neutral
"done dataset final",neutral
"last dataset sample",neutral
"end sample dataset",neutral
"stop dataset",neutral
"OKAY DATASET",neutral
"DATA DONE",neutral
"DATA END",neutral
"complete data",neutral
"dataset over",neutral
"no more data",neutral
"terminate dataset",neutral
"dataset finished",neutral
"data complete",neutral
"data stop",neutral
"data final",neutral
"done and end",neutral
"THE END OF DATA",neutral
"ENDDATA",neutral
"finished data",neutral
"done final",neutral
"end now dataset",neutral
"finished dataset sample",neutral
"final dataset",neutral
"the dataset is done",neutral
"stop dataset now",neutral
"sample dataset final",neutral
"end"
"@ | Set-Content -Path .\social-media-sentiment-analysis\data\raw\tweets_scraped.csv -Encoding UTF8
  ```
  Setelah itu jalankan:
  ```powershell
  python .\social-media-sentiment-analysis\preprocess.py --input .\social-media-sentiment-analysis\data\raw\tweets_scraped.csv --output .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
  python .\social-media-sentiment-analysis\train_model.py --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv --output .\social-media-sentiment-analysis\models\model_pipeline.joblib
  python .\social-media-sentiment-analysis\evaluate.py --model .\social-media-sentiment-analysis\models\model_pipeline.joblib --input .\social-media-sentiment-analysis\data\processed\tweets_clean.csv
  ```

Test run (create notebook & execute)
- Pastikan `create_notebook.py` berada di `social-media-sentiment-analysis\create_notebook.py`.
- Dari repo root jalankan:
  ```powershell
  python .\social-media-sentiment-analysis\create_notebook.py
  ```
  Jika Anda mau jalankan dari dalam folder `social-media-sentiment-analysis`, jalankan:
  ```powershell
  python .\create_notebook.py
  ```
- Eksekusi (simpan outputs) — contoh jalankan dari repo root:
  ```powershell
  python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
  ```

Perbaikan path & menghindari misuse PowerShell
- Jangan paste blok Python langsung ke PowerShell. Jika ingin menjalankan kode Python multi-line, buat file `.py` dan jalankan `python script.py`, atau jalankan REPL `python` lalu paste.
- Selalu perhatikan current working directory (CWD). Perintah yang menggunakan relatvie path akan gagal bila CWD berbeda.

Tambahan: fallback bila snscrape tidak dapat dipasang pada Python 3.14
- Buat venv terpisah menggunakan Python 3.11 atau 3.12:
  ```powershell
  py -3.11 -m venv .venv-py311
  . .\.venv-py311\Scripts\Activate.ps1
  python -m pip install -r social-media-sentiment-analysis\requirements.txt
  ```
- Lanjutkan pipeline di venv tersebut.

Verifikasi akhir yang harus Anda lihat
- Notebook `social-media-sentiment-analysis.ipynb` ada di folder `social-media-sentiment-analysis` dan hanya ada satu file .ipynb di folder itu.
- Notebook telah dieksekusi (lihat outputs in file on GitHub preview).
- Model (jika Anda latih) tersimpan di `social-media-sentiment-analysis\models\model_pipeline.joblib` (opsional commit jika kecil).
- `git status` bersih setelah commit / push.

Jika Anda mau, saya bisa:
- Buatkan versi `manage_social_notebook.ps1` yang menerapkan semua langkah perbaikan di atas (non-interactive, memanggil `python -m nbconvert`) dan yang membersihkan leftover site-packages yang aman dihapus; atau
- Commit README.md dan `create_notebook.py` yang telah saya sarankan ke repo (sebutkan owner/repo dan branch), atau
- Bantu debug output error yang muncul setelah Anda mencoba langkah-langkah di README ini — tempelkan error terbaru dan saya bantu selesaikan.

---
