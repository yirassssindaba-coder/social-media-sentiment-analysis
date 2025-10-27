# Social Media Sentiment Analysis — README

Versi ini menyediakan README.md lengkap dan siap pakai untuk disimpan di folder `social-media-sentiment-analysis`. README ini berisi langkah-langkah PowerShell yang aman untuk:
- Menyimpan README ke folder target
- Memeriksa `.gitignore` dan file besar
- (Opsional) menyiapkan Git LFS
- Menjalankan notebook untuk menghasilkan file di folder `results`
- Men-stage, commit, dan push perubahan ke remote dengan cara yang aman

PENTING: Saya tidak mengubah repositori Anda. Semua perintah di bawah harus dijalankan sendiri di mesin lokal Anda. Baca seluruh README ini sebelum menjalankan perintah. Jalankan baris per baris dari root repo (contoh path root yang dipakai di petunjuk): `C:\Users\ASUS\Desktop\python-project`

Catatan Penting — Bacaan Awal
- Saya TIDAK akan mengubah repo Anda dari sini. Perintah di bawah untuk Anda jalankan sendiri.
- Jangan gabungkan perintah dengan `&&`/`||` di PowerShell (gunakan `;` jika perlu).
- Jangan jalankan perintah yang Anda tidak pahami — tanyakan jika ragu.
- Jangan pakai placeholder seperti `<...>` — ganti dengan path/angka nyata jika ada.
- Jika repo Anda menggunakan branch selain `main`, ganti semua contoh `main` sesuai branch Anda.

1) Menyimpan README.md ke folder target
Deskripsi: Simpan README lengkap ini secara otomatis ke file `social-media-sentiment-analysis/README.md` menggunakan PowerShell. Jalankan dari root repo.

PowerShell — simpan README:
    # Jalankan dari root repo, contoh:
    # Set-Location 'C:\Users\ASUS\Desktop\python-project'

    # Pilih salah satu metode:

    # 1) Cara manual singkat: buat file README.md dan tempelkan isi markdown ini.
    # 2) Cara otomatis: simpan seluruh konten README ini melalui here-string.
    #    Perhatikan: jika Anda menggunakan cara ini, pastikan string di dalam @' ... '@
    #    berisi seluruh markdown yang ingin ditulis (ini dokumen itu sendiri).

    $readme = @'
    # Social Media Sentiment Analysis — README

    (Tempatkan seluruh isi README ini di antara penanda here-string jika Anda ingin menulis file secara otomatis.)
    '@

    Set-Content -Path '.\social-media-sentiment-analysis\README.md' -Value $readme -Encoding UTF8
    Write-Host "README.md tersimpan di social-media-sentiment-analysis\README.md"

Catatan: Anda dapat juga membuat file README.md manual dan menempelkan isi markdown ini langsung.

2) Periksa `.gitignore` agar folder `results` tidak ter-ignore
Deskripsi: Pastikan folder `social-media-sentiment-analysis/results` tidak dikecualikan oleh `.gitignore` jika Anda ingin menyimpan keluaran notebook di sana. Langkah ini memeriksa pola umum, menampilkan isi `.gitignore`, dan memberi opsi backup + pembersihan baris ignore.

PowerShell — pengecekan cepat:
    # lihat apakah ada pattern results
    Select-String -Path .gitignore -Pattern "results","social-media-sentiment-analysis/results" -SimpleMatch -Quiet
    if ($?) {
      Write-Host ".gitignore mungkin mengecualikan results — periksa isinya" -ForegroundColor Yellow
    } else {
      Write-Host ".gitignore tidak mengecualikan results (sementara)." -ForegroundColor Green
    }

    # (opsional) tampilkan isi .gitignore
    Get-Content .\.gitignore

PowerShell — backup & hapus baris yang mengecualikan results (jika perlu):
    Copy-Item .\.gitignore .\.gitignore.bak -Force
    (Get-Content .\.gitignore) |
      Where-Object { $_ -notmatch '(^|/)(results|social-media-sentiment-analysis/results)(/|$)' } |
      Set-Content .\.gitignore
    Write-Host ".gitignore diperbarui (backup .gitignore.bak dibuat)."

3) Periksa file besar di folder `results` (GitHub menolak file > 100 MB)
Deskripsi: Cari file di `results` yang lebih besar dari 100 MB dan putuskan apakah akan memindahkannya atau melacaknya dengan Git LFS sebelum di-commit.

PowerShell — cari file >100MB:
    Get-ChildItem -Path "social-media-sentiment-analysis\results" -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Length -gt 100MB } |
      Select-Object FullName, @{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}

Tindakan jika ditemukan file >100MB:
- Pindahkan file besar keluar dari repo, atau
- Gunakan Git LFS untuk melacak file besar (langkah 4).

4) (Opsional) Setup Git LFS untuk file besar
Deskripsi: Jika Anda perlu menyimpan file besar di dalam repo, gunakan Git LFS untuk melacaknya. Pastikan remote mendukung LFS dan Anda memahami batasan kuota.

PowerShell — inisialisasi Git LFS dan track:
    git lfs install
    git lfs track "social-media-sentiment-analysis/results/**"
    git add .gitattributes
    git commit -m "chore: track results via git-lfs" 2>$null

Catatan: Pastikan tim/remote Anda setuju menggunakan LFS (paket/kuota).

5) Stage & commit README.md dan file lain yang diinginkan
Deskripsi: Stage file README, notebook, dan hasil di folder results (hanya jika sudah siap). Jalankan tiap baris secara terpisah.

PowerShell — stage:
    git add ".\social-media-sentiment-analysis\README.md"
    git add "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb"  # jika ingin turut di-stage
    # stage results (hanya jika sudah siap dan tidak berisi file >100MB)
    git add "social-media-sentiment-analysis/results/*"

PowerShell — verifikasi staged:
    git status --porcelain=1 --branch

PowerShell — commit:
    git commit -m "docs: add README for social-media-sentiment-analysis"

Catatan: Jika `nothing to commit`, periksa kembali `git status` dan jalankan `git add` untuk file yang belum ter-stage.

6) Sinkronisasi dengan remote & push (aman)
Deskripsi: Selalu fetch + rebase sebelum push agar Anda tidak menimpa perubahan remote tanpa sengaja. Jika Anda menggunakan branch selain `main`, ganti nama branch sesuai.

PowerShell — fetch, rebase, push:
    git fetch origin
    git pull --rebase --autostash origin main
    # jika rebase minta resolusi konflik: perbaiki file, git add <file>, git rebase --continue
    git push origin main

PowerShell — jika perlu menimpa remote (gunakan hanya jika paham risikonya):
    git push --force-with-lease origin main

7) Menjalankan notebook untuk menghasilkan tabel / outputs (menulis ke folder `results`)
Deskripsi: Aktifkan virtual environment, instal dependensi, dan eksekusi notebook menggunakan nbconvert atau papermill. Pilih metode yang sesuai kebutuhan (inplace atau menghasilkan file output baru).

PowerShell — aktifkan virtualenv:
    # contoh PowerShell activation (.venv)
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # jika perlu
    .\.venv\Scripts\Activate.ps1

PowerShell — instal dependensi:
    python -m pip install -r requirements.txt

PowerShell — eksekusi notebook (nbconvert — inplace):
    python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --inplace

PowerShell — eksekusi notebook (papermill — output terpisah):
    pip install papermill
    papermill "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb"

PowerShell — periksa folder results setelah eksekusi:
    Get-ChildItem -Path "social-media-sentiment-analysis\results" -Recurse | Select-Object FullName,Length

8) Commit & push hasil (folder `results`)
Deskripsi: Setelah memastikan tidak ada file >100MB dan results sudah siap, stage, commit, dan rebase/push ke remote.

PowerShell — stage & commit results:
    git add "social-media-sentiment-analysis/results/*"
    git commit -m "chore: add results outputs from notebook execution"
    git pull --rebase origin main
    git push origin main

Catatan: Jika ada konflik saat rebase: perbaiki file yang konflik, `git add <file>`, lalu `git rebase --continue`.

9) Verifikasi remote (web UI atau clone sementara)
Deskripsi: Pastikan hasil benar-benar ter-push ke remote. Anda bisa memeriksa lewat web UI atau clone ke folder sementara untuk verifikasi.

Web UI:
Buka: https://github.com/yirassssindaba-coder/python-project/tree/main/social-media-sentiment-analysis/results

PowerShell — clone sementara & periksa file list:
    cd $env:TEMP
    git clone https://github.com/yirassssindaba-coder/python-project.git tmp-check
    cd tmp-check
    git ls-files "social-media-sentiment-analysis/results" | Select-Object -First 200

10) Opsi Tambahan yang Saya Bisa Bantu
Deskripsi: Pilih salah satu opsi dan saya sediakan file/perintah yang langsung bisa Anda jalankan.

Pilihan:
- "Simpan di folder" — skrip PowerShell lengkap untuk menyimpan README.md di `social-media-sentiment-analysis` dan melakukan dry-run yang menampilkan file yang akan distage serta file >100MB.
- "Simpan & commit" — saya tampilkan perintah persis untuk menulis file dan commit (Anda jalankan sendiri).
- "Buat skrip" — saya kirim file `stage_results_and_push.ps1` (kode) yang dapat Anda simpan dan eksekusi untuk melakukan langkah-langkah otomatis (atau versi dry-run).

Sebutkan pilihan Anda dan saya akan menyediakan konten skrip / perintah yang diinginkan.

Tips Keamanan & Troubleshooting
- Selalu buat backup sebelum memodifikasi `.gitignore`.
- Jangan push file >100MB tanpa LFS.
- Jika rebase menghasilkan konflik: perbaiki, `git add <file>`, `git rebase --continue`.
- Jika Anda menggunakan branch selain `main`, ganti `main` pada semua perintah `pull/push` sesuai nama branch Anda.
- Jika PowerShell menolak menjalankan skrip, gunakan `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` (hanya untuk sesi ini) dan pastikan Anda paham risikonya.

Terima kasih — README ini sudah disusun ulang tanpa fence block, dan blok kode diganti menjadi blok yang diindentasikan agar tidak menggunakan tanda ``` . Jika Anda ingin, saya dapat:
- Menyimpan file ini ke folder `social-media-sentiment-analysis` (beri perintah "Simpan di folder"),
- Menyediakan skrip `.ps1` untuk otomatisasi ("Buat skrip"), atau
- Menampilkan versi yang siap di-commit dengan perintah yang harus dijalankan ("Simpan & commit").
