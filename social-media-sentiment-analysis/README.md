\# Social Media Sentiment Analysis — README



Ringkasan  

Dokumen ini menjelaskan langkah‑langkah aman (PowerShell) untuk:

\- Menyimpan README.md ke folder repo `social-media-sentiment-analysis`

\- Memeriksa `.gitignore` dan file besar di folder `results`

\- (Opsional) menyiapkan Git LFS untuk file besar

\- Menjalankan notebook untuk menghasilkan keluaran ke folder `results`

\- Men-stage, commit, dan push perubahan ke remote



Semua perintah harus dijalankan sendiri di mesin lokal Anda. Contoh path root repo pada instruksi:  

`C:\\Users\\ASUS\\Desktop\\python-project`  

Target file README.md:  

`C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis\\README.md`



Penting sebelum mulai

\- Jalankan perintah baris-per-baris di PowerShell (jangan gabungkan dengan `\&\&`/`||`; gunakan `;` jika perlu).

\- Jangan jalankan perintah yang Anda tidak pahami.

\- Jika branch utama repo Anda bukan `main`, ganti `main` pada semua perintah git sesuai nama branch Anda.



1\) Menyimpan README.md ke folder repo (cara mudah)

\- Cara A — manual (direkomendasikan)

&nbsp; 1. Buka editor teks (mis. VS Code, Notepad).

&nbsp; 2. Salin seluruh isi README ini (blok markdown di bawah) lalu Save As ke:

&nbsp;    `C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis\\README.md`



\- Cara B — salin file dari lokasi lain (PowerShell, aman; memeriksa keberadaan sumber)

&nbsp; 1. Sesuaikan variabel $sourcePath dengan lokasi file README sumber Anda (contoh di bawah).

&nbsp; 2. Jalankan baris-per-baris ini:



```powershell

$targetDir = 'C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis'

if (-not (Test-Path -Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null; Write-Host "Membuat folder target: $targetDir" } else { Write-Host "Folder target ada: $targetDir" }



\# Ganti contoh path di bawah dengan path file README sumber Anda

$sourcePath = 'C:\\Users\\ASUS\\Downloads\\README\_source.md'



if (Test-Path -Path $sourcePath) {

&nbsp; Copy-Item -Path $sourcePath -Destination (Join-Path $targetDir 'README.md') -Force

&nbsp; Write-Host "Salin berhasil: $sourcePath → $targetDir\\README.md"

} else {

&nbsp; Write-Host "Sumber tidak ditemukan: $sourcePath" -ForegroundColor Yellow

&nbsp; Write-Host "Untuk membuat README baru, buka editor dan simpan konten README ini ke:" -ForegroundColor Yellow

&nbsp; Write-Host $targetDir

}

```



\- Cara C — buat file kosong lalu edit:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project\\social-media-sentiment-analysis'

if (-not (Test-Path '.\\README.md')) { New-Item -Path '.\\README.md' -ItemType File -Force }

\# kemudian buka file dengan editor:

notepad .\\README.md   # atau: code .\\README.md untuk VS Code

```



2\) Periksa `.gitignore` — pastikan folder `results` tidak di-ignore

Jalankan dari root repo (atau sesuaikan lokasi):

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

$patterns = @('results','social-media-sentiment-analysis/results')

$found = Select-String -Path .gitignore -Pattern $patterns -SimpleMatch -ErrorAction SilentlyContinue

if ($found) {

&nbsp; Write-Host ".gitignore mungkin mengecualikan results — periksa isinya" -ForegroundColor Yellow

&nbsp; Get-Content .\\.gitignore

} else {

&nbsp; Write-Host ".gitignore tidak mengecualikan results (sementara)." -ForegroundColor Green

}

\# (Opsional) Hapus baris ignore untuk results (backup .gitignore.bak dibuat)

if ($found) {

&nbsp; Copy-Item .\\.gitignore .\\.gitignore.bak -Force

&nbsp; (Get-Content .\\.gitignore) |

&nbsp;   Where-Object { $\_ -notmatch '(^|/)(results|social-media-sentiment-analysis/results)(/|$)' } |

&nbsp;   Set-Content .\\.gitignore

&nbsp; Write-Host ".gitignore diperbarui (backup .gitignore.bak dibuat)."

}

```



3\) Periksa file besar di folder `results` (GitHub menolak file > 100 MB)

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

$bigFiles = Get-ChildItem -Path "social-media-sentiment-analysis\\results" -Recurse -File -ErrorAction SilentlyContinue |

&nbsp;           Where-Object { $\_.Length -gt 100MB } |

&nbsp;           Select-Object FullName, @{Name='MB';Expression={\[math]::Round($\_.Length/1MB,2)}}

if ($bigFiles) {

&nbsp; $bigFiles | Format-Table -AutoSize

&nbsp; Write-Host "Temukan file >100MB. Pindahkan file tersebut atau gunakan Git LFS sebelum commit." -ForegroundColor Yellow

} else {

&nbsp; Write-Host "Tidak ada file >100MB di folder results." -ForegroundColor Green

}

```



4\) (Opsional) Setup Git LFS untuk file besar

Pastikan remote Anda mendukung Git LFS sebelum menggunakan.

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

git lfs install

git lfs track "social-media-sentiment-analysis/results/\*\*"

git add .gitattributes

git commit -m "chore: track results via git-lfs" 2>$null

```



5\) Stage \& commit README.md dan file lain yang diinginkan

Jalankan baris-per-baris dari root repo:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'



\# Stage README jika ada

$readmePath = '.\\social-media-sentiment-analysis\\README.md'

if (Test-Path $readmePath) { git add $readmePath } else { Write-Host "README.md tidak ditemukan di $readmePath" -ForegroundColor Yellow }



\# (Opsional) stage notebook jika ada

$notebookPath = 'social-media-sentiment-analysis\\social-media-sentiment-analysis.ipynb'

if (Test-Path $notebookPath) { git add $notebookPath }



\# Stage results jika folder ada (pastikan tidak ada file >100MB)

if (Test-Path '.\\social-media-sentiment-analysis\\results') { git add "social-media-sentiment-analysis/results/\*" }



git status --porcelain=1 --branch

git commit -m "docs: add/update README for social-media-sentiment-analysis"

```

Jika output commit mengatakan "nothing to commit", periksa `git status` dan ulangi `git add` untuk file yang belum distage.



6\) Sinkronisasi dengan remote \& push (aman)

Selalu fetch + rebase sebelum push:

```powershell

git fetch origin

git pull --rebase --autostash origin main

\# jika rebase meminta resolusi konflik: perbaiki file, git add <file>, git rebase --continue

git push origin main

\# Jika Anda perlu menimpa remote (gunakan hanya jika paham risikonya):

\# git push --force-with-lease origin main

```

Ganti `main` jika branch Anda berbeda.



7\) Menjalankan notebook untuk menghasilkan outputs (menulis ke folder `results`)

Aktifkan virtualenv, instal dependensi, dan eksekusi notebook:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  # jika perlu

.\\.venv\\Scripts\\Activate.ps1



python -m pip install -r requirements.txt



\# nbconvert (inplace)

python -m nbconvert --to notebook --execute "social-media-sentiment-analysis\\social-media-sentiment-analysis.ipynb" --inplace



\# atau papermill (output terpisah)

pip install papermill

papermill "social-media-sentiment-analysis\\social-media-sentiment-analysis.ipynb" "social-media-sentiment-analysis\\social-media-sentiment-analysis-output.ipynb"

```

Setelah eksekusi, verifikasi file di `results`:

```powershell

Get-ChildItem -Path "social-media-sentiment-analysis\\results" -Recurse | Select-Object FullName,Length

```



8\) Commit \& push hasil (folder `results`)

Pastikan tidak ada file >100MB lalu:

```powershell

Set-Location 'C:\\Users\\ASUS\\Desktop\\python-project'

if (Test-Path '.\\social-media-sentiment-analysis\\results') {

&nbsp; git add "social-media-sentiment-analysis/results/\*"

&nbsp; git commit -m "chore: add results outputs from notebook execution"

&nbsp; git pull --rebase origin main

&nbsp; git push origin main

} else {

&nbsp; Write-Host "Tidak ada folder results untuk di-commit." -ForegroundColor Yellow

}

```



9\) Verifikasi remote (web UI atau clone sementara)

\- Web: buka  

&nbsp; https://github.com/yirassssindaba-coder/python-project/tree/main/social-media-sentiment-analysis/results



\- Atau clone sementara untuk memeriksa:

```powershell

cd $env:TEMP

git clone https://github.com/yirassssindaba-coder/python-project.git tmp-check

cd tmp-check

git ls-files "social-media-sentiment-analysis/results" | Select-Object -First 200

```



10\) Opsi tambahan yang bisa saya bantu

\- "Buat skrip salin" — skrip PowerShell untuk menyalin README dari sumber lokal ke folder repo dan menampilkan dry‑run (file yang akan distage serta file >100MB).  

\- "Buat skrip salin \& commit" — skrip yang juga menjalankan git add/commit/push (opsional; berisiko).  

\- "Dry-run saja" — saya tampilkan daftar file yang akan distage dan file >100MB tanpa melakukan commit.



Tips Keamanan \& Troubleshooting

\- Backup `.gitignore` sebelum mengubahnya.

\- Jangan push file >100MB tanpa Git LFS.

\- Jika rebase menghasilkan konflik: perbaiki file yang konflik, git add <file>, git rebase --continue.

\- Jika PowerShell menolak menjalankan skrip: jalankan `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` (hanya untuk sesi ini) dan pahami risikonya.



Terima kasih — saya sudah merapikan README supaya aman dan bebas error bila Anda mengikuti langkah-langkah di atas. Jalankan perintah baris‑per‑baris di PowerShell; jika Anda mau, saya bisa membuatkan skrip `.ps1` yang otomatis menyalin README dari sumber lokal dan menjalankan dry‑run atau otomatisasi git (sebutkan: "Buat skrip salin", "Buat skrip salin \& commit", atau "Dry-run saja").

