\# RUNME — Social Media Sentiment Analysis



Tujuan  

Dokumen ini menjelaskan langkah-langkah singkat dan dapat langsung dijalankan (PowerShell) untuk men-setup environment, menjalankan notebook/script di folder `social-media-sentiment-analysis`, menghasilkan keluaran ke folder `results`, serta menyimpan file RUNME.md ke repo dan memasukkannya ke Git. Dokumen dibuat agar mudah disalin, disimpan, dan dicetak.



Lokasi target (contoh)

\- Root repo contoh: `C:\\Users\\ASUS\\Desktop\\python-project`

\- Folder project: `C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis`

\- Lokasi RUNME.md yang disarankan:  

&nbsp; `C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis\\RUNME.md`



Penting sebelum menjalankan

\- Jalankan setiap baris per baris di PowerShell (jangan gabungkan dengan `\&\&`/`||`; gunakan `;` jika perlu).

\- Jangan jalankan perintah yang Anda tidak pahami.

\- Jika branch utama Anda bukan `main`, ganti `main` pada perintah git.

\- Pastikan Anda berada di mesin lokal yang memiliki akses ke repo dan internet (untuk pip/git lfs).



1\) Simpan RUNME.md ke folder repo

Simpan dokumen ini langsung sebagai file RUNME.md pada lokasi project. Pilih salah satu metode:



Cara A — manual (direkomendasikan)

1\. Buka editor (VS Code, Notepad).

2\. Salin seluruh isi file ini dan Save As ke:

&nbsp;  `C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis\\RUNME.md`



Cara B — salin dari file sumber

1\. Buka PowerShell dan jalankan (sesuaikan path sumber):

```powershell

$targetDir = 'C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis'

if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }

$sourcePath = 'C:\\path\\to\\your\\RUNME\_source.md'  # GANTI dengan path nyata

if (Test-Path $sourcePath) {

&nbsp; Copy-Item -Path $sourcePath -Destination (Join-Path $targetDir 'RUNME.md') -Force

&nbsp; Write-Host "RUNME.md disalin ke $targetDir"

} else {

&nbsp; Write-Host "Sumber tidak ditemukan: $sourcePath" -ForegroundColor Yellow

}

```



Cara C — buat file kosong lalu edit

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis'

if (-not (Test-Path '.\\RUNME.md')) { New-Item -Path '.\\RUNME.md' -ItemType File -Force }

notepad .\\RUNME.md   # atau: code .\\RUNME.md untuk VS Code

```



2\) Persyaratan dasar (prerequisites)

\- Git terpasang dan terkonfigurasi (user.name, user.email).

\- Python 3.8+ (atau versi yang sesuai project).

\- (Opsional) Git LFS jika Anda menyimpan file besar.

\- Virtual environment (direkomendasikan .venv di root repo).



3\) Buat dan aktifkan virtual environment

Jalankan dari root repo:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'



\# buat virtualenv jika belum ada

python -m venv .venv



\# aktifkan (PowerShell)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # bila perlu

.\\.venv\\Scripts\\Activate.ps1



\# verifikasi Python

python --version

pip --version

```



4\) Instal dependensi

Jika ada file requirements.txt di root atau di folder project, instal:

```powershell

\# contoh: requirements di root or di folder social-media-sentiment-analysis

python -m pip install --upgrade pip

if (Test-Path '.\\requirements.txt') {

&nbsp; python -m pip install -r .\\requirements.txt

}

if (Test-Path '.\\social-media-sentiment-analysis\\requirements.txt') {

&nbsp; python -m pip install -r .\\social-media-sentiment-analysis\\requirements.txt

}

```



5\) Periksa .gitignore dan file besar

Pastikan folder `results` tidak di-ignore dan tidak ada file >100MB:

```powershell

\# dari root repo

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'



\# cek .gitignore untuk results

Select-String -Path .gitignore -Pattern "results","social-media-sentiment-analysis/results" -SimpleMatch -Quiet

if ($?) { Write-Host ".gitignore mungkin mengecualikan results — periksa .gitignore" -ForegroundColor Yellow } else { Write-Host ".gitignore tidak mengecualikan results (sementara)." -ForegroundColor Green }



\# cari file besar >100MB

Get-ChildItem -Path "social-media-sentiment-analysis\\results" -Recurse -File -ErrorAction SilentlyContinue |

&nbsp; Where-Object { $\_.Length -gt 100MB } |

&nbsp; Select-Object FullName, @{Name='MB';Expression={\[math]::Round($\_.Length/1MB,2)}}

```



Jika ada file >100MB, pindahkan atau aktifkan Git LFS (langkah 6).



6\) (Opsional) Setup Git LFS

Jika Anda perlu melacak file besar:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

git lfs install

git lfs track "social-media-sentiment-analysis/results/\*\*"

git add .gitattributes

git commit -m "chore: track results via git-lfs" 2>$null

```

Periksa kuota LFS di remote sebelum mendorong banyak file besar.



7\) Menjalankan notebook untuk menghasilkan outputs (folder `results`)

Pilih salah satu metode untuk mengeksekusi notebook dan menghasilkan keluaran di folder `results`.



Metode A — nbconvert (sederhana, inplace)

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\\social-media-sentiment-analysis.ipynb" --inplace

```



Metode B — papermill (lebih andal; bisa parameterisasi)

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

python -m pip install papermill

papermill "social-media-sentiment-analysis\\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\\social-media-sentiment-analysis-output.ipynb"

```



Metode C — jalankan script Python (jika repo memiliki script runner)

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis'

python run\_analysis.py   # contoh, ganti dengan nama script yang ada

```



Setelah selesai, periksa hasil:

```powershell

Get-ChildItem -Path "social-media-sentiment-analysis\\results" -Recurse | Select-Object FullName,Length

```



8\) Commit \& push RUNME.md dan hasil (aman)

Langkah-langkah berikut menjalankan git secara aman. Jalankan baris per baris dari root repo.



\- Stage RUNME.md dan file lain:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

git add ".\\social-media-sentiment-analysis\\RUNME.md"

\# optional add notebook

if (Test-Path ".\\social-media-sentiment-analysis\\social-media-sentiment-analysis-output.ipynb") {

&nbsp; git add ".\\social-media-sentiment-analysis\\social-media-sentiment-analysis-output.ipynb"

}

\# stage results (hanya jika sudah yakin dan tidak ada file >100MB)

if (Test-Path ".\\social-media-sentiment-analysis\\results") {

&nbsp; git add "social-media-sentiment-analysis/results/\*"

}

```



\- Verifikasi dan commit:

```powershell

git status --porcelain=1 --branch

git commit -m "docs: add RUNME for social-media-sentiment-analysis"

```



\- Sinkronisasi remote \& push (safe):

```powershell

git fetch origin

git pull --rebase --autostash origin main

\# resolve conflicts if prompted: fix files, git add <file>, git rebase --continue

git push origin main

```



Jika Anda benar-benar perlu memaksa push (hati-hati):

```powershell

git push --force-with-lease origin main

```



9\) Verifikasi di remote

\- Buka web browser ke path project di GitHub untuk memeriksa RUNME.md dan results:

&nbsp; `https://github.com/yirassssindaba-coder/python-project/tree/main/social-media-sentiment-analysis`



\- Atau clone ke folder sementara:

```powershell

cd $env:TEMP

git clone https://github.com/yirassssindaba-coder/python-project.git tmp-check

cd tmp-check

git ls-files "social-media-sentiment-analysis" | Select-Object -First 200

```



10\) Troubleshooting singkat

\- Jika PowerShell menolak menjalankan skrip: jalankan `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` (hanya untuk sesi ini).

\- Jika `git commit` menghasilkan "nothing to commit": periksa `git status` untuk memastikan file benar-benar telah `git add`.

\- Jika notebook gagal dieksekusi: periksa error traceback di notebook, pastikan dependensi terinstal dan data input tersedia.

\- Jika file >100MB tertambahkan: batalkan commit, hapus file dari staging, gunakan Git LFS atau pindahkan file.



Kontak \& opsi lanjutan

\- Saya bisa membuatkan skrip PowerShell (`create\_runme\_and\_push.ps1`) yang:

&nbsp; - Menyalin RUNME dari sumber lokal (jika ada),

&nbsp; - Menjalankan dry‑run (menampilkan file yang akan distage dan file >100MB),

&nbsp; - (Opsional) melakukan git add/commit/push otomatis.



Jika Anda ingin skrip tersebut, ketik:  

\- "Buat skrip salin RUNME" — saya kirimkan kode `.ps1` yang menyalin + dry‑run.  

\- "Buat skrip salin \& commit RUNME" — saya kirimkan `.ps1` yang juga menjalankan git add/commit/push (opsional, berisiko).



Terima kasih — file RUNME.md ini dibuat agar mudah disalin dan langsung disimpan ke lokasi project Anda. Ikuti langkah baris‑per‑baris di atas untuk menjalankan notebook dan menyimpan hasil ke Git dengan aman.

