# Social Media Sentiment Analysis — README

Ringkasan  
Dokumen ini memberi instruksi ringkas dan aman (PowerShell) untuk memperbaiki kondisi Git yang menyebabkan banyak perubahan/pelepasan file (termasuk .venv), menyelesaikan rebase yang sedang berjalan, menghentikan pelacakan virtual environment, dan memastikan README / RUNME disimpan dan di-push ke remote tanpa error. Jalankan perintah baris-per-baris dan baca seluruh bagian sebelum mengeksekusi.

PENTING: semua perintah harus dijalankan di mesin Anda. Jika Anda ragu, jangan jalankan; salin hasil `git status` dan minta bantuan. Contoh root repo di sini:
`C:\Users\ASUS\Desktop\python-project`  
Target project folder:
`C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

Ringkasan masalah yang sering muncul (dari log Anda)
- Rebase sedang berjalan: "You are currently editing a commit while rebasing..."
- Banyak file .venv tercatat sebagai deleted/modified (tidak ingin commit venv ke repo)
- .gitignore/backup dan file lain berubah
- Git LFS diinisialisasi, tetapi rebase belum selesai

Tujuan dokumen ini
1. Aman menyelesaikan atau membatalkan rebase sehingga working tree kembali ke keadaan stabil.
2. Membatalkan/menyembunyikan perubahan tidak diinginkan (.venv) dan berhenti melacak folder venv.
3. Commit perubahan dokumentasi (README / RUNME) dan push ke remote tanpa error.
4. Memberi opsi untuk membersihkan file besar jika sudah terkomit ke history.

Ikuti langkah berikut dalam urutan yang diberikan. Jalankan tiap baris per baris di PowerShell.

---

## A — Periksa status rebase saat ini (JANGAN LANGSUNG KOMIT)
Dari root repo:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git status --porcelain=1 --branch
git rev-parse --abbrev-ref HEAD
```
Baca output. Jika Anda melihat pesan rebase (You are currently rebasing / editing a commit), lanjut ke bagian B. Jika tidak ada rebase, lanjut ke bagian C.

---

## B — Jika rebase sedang berjalan: pilih satu opsi (lanjutkan atau batalkan)
Catatan: jika Anda memodifikasi commit yang sedang digabungkan dan memang ingin menyelesaikannya, pilih "Lanjutkan". Jika Anda tidak sengaja memicu rebase atau tidak yakin, pilih "Abort" untuk kembali ke keadaan sebelum rebase.

B1) Untuk menyelesaikan rebase (jika Anda sudah membuat perubahan yang ingin di-commit)
- Stage perubahan yang relevan (jangan stage .venv). Contoh:
```powershell
# stage only safe files (README, RUNME, notebook outputs)
git add -N .  # optional: prepare index
git add .\social-media-sentiment-analysis\README.md
git add .\social-media-sentiment-analysis\RUNME.md
# jika ada file lain yang memang ingin di-commit, git add <file>
git status --porcelain=1 --branch
# lalu continue rebase
git rebase --continue
```
Jika rebase menolak karena konflik, perbaiki konflik di file yang tercantum, lalu:
```powershell
git add <file-yang-diperbaiki>
git rebase --continue
```

B2) Untuk membatalkan rebase (lebih aman bila Anda tidak yakin)
```powershell
git rebase --abort
# lalu verifikasi status
git status --porcelain=1 --branch
```
Setelah abort, working tree akan dikembalikan ke keadaan sebelum rebase dimulai.

---

## C — Pastikan .venv tidak dilacak lagi dan pulihkan file yang tidak sengaja dihapus/di-stage
Jika .venv telah terlanjur tercatat sebagai perubahan (modified/deleted) Anda harus:
1. Mengembalikan file .venv dari index/working tree (jika terhapus dari working tree karena rebase/commit), atau
2. Menghentikan pelacakan .venv (agar tidak muncul lagi).

Langkah aman:

C1) Jika Anda ingin membatalkan semua perubahan ter-stage dan restore working tree ke HEAD:
```powershell
# HATI-HATI: ini membatalkan perubahan lokal yang belum di-commit
# Jalankan hanya jika Anda tidak butuh perubahan lokal yang belum disimpan
git reset --hard HEAD
```
Jika Anda ingin menyimpan perubahan lokal tetapi menghapus staging:
```powershell
git reset
# ini membatalkan staging, tidak menghapus file di working tree
```

C2) Jangan commit .venv — tambahkan aturan .gitignore dan remove dari index
- Tambahkan `.venv/` ke `.gitignore` (jika belum ada) dan commit perubahan .gitignore.
```powershell
# dari root repo
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# tambahkan .venv ke .gitignore jika belum ada
if (-not (Select-String -Path .gitignore -Pattern '(^|/)\.venv(/|$)' -SimpleMatch -Quiet) ) {
  Add-Content -Path .gitignore -Value "`n# ignore virtual environment`n.venv/"
  Write-Host ".venv/ ditambahkan ke .gitignore"
} else {
  Write-Host ".venv/ sudah ada di .gitignore"
}

# hapus venv dari index (git akan tetap membiarkan folder di working tree lokal)
git rm -r --cached --ignore-unmatch "social-media-sentiment-analysis/.venv" || Write-Host "No cached venv to remove"
git add .gitignore
git commit -m "chore: stop tracking .venv and update .gitignore" || Write-Host "Nothing to commit for .gitignore"
```

Catatan: git rm --cached hanya menghapus file dari index (tracking); file tetap ada di disk. Jika beberapa file .venv sudah ter-commit dan Anda perlu menghapusnya dari history, lihat bagian "Hapus file besar dari history" di bawah.

C3) Jika file .venv hilang dari working tree dan Anda perlu memulihkan environment:
- Jangan restore .venv dari repo — buat ulang virtualenv:
```powershell
# buat ulang venv lokal
Set-Location 'C:\Users\ASUS\Desktop\python-project'
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt   # jika ada
```

---

## D — Commit README / RUNME dan push (urutan aman)
Setelah rebase diselesaikan atau abort, dan setelah .venv di-untrack, lakukan commit dokumen dengan aman.

1) Stage dan commit file dokumentasi saja:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git add .\social-media-sentiment-analysis\README.md
git add .\social-media-sentiment-analysis\RUNME.md
git status --porcelain=1 --branch
git commit -m "docs: add/update README and RUNME for social-media-sentiment-analysis"
```

2) Fetch & rebase remote, lalu push:
```powershell
git fetch origin
git pull --rebase --autostash origin main
# jika rebase meminta resolusi konflik: perbaiki file, git add <file>, git rebase --continue
git push origin main
```

Jika Anda bekerja di branch lain, ganti `main` dengan nama branch Anda.

---

## E — Jika file besar sudah ter-commit ke history (lebih lanjut / opsional)
Jika file .venv atau file >100MB sudah pernah di-commit (masuk ke history remote), Anda perlu membersihkannya dari history menggunakan BFG atau git filter-repo. Ini operasi berisiko karena memodifikasi history — koordinasikan dengan tim.

Contoh ringkas (gunakan BFG jar):
1. Install BFG (https://rtyley.github.io/bfg-repo-cleaner/).
2. Jalankan:
```bash
# contoh (linux/macos) — pada Windows gunakan Git Bash atau adaptasi
bfg --delete-folders .venv --delete-files '*.pyc' --no-blob-protection
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force-with-lease origin main
```
JANGAN jalankan ini tanpa memahami konsekuensi — ini menulis ulang history.

---

## F — Periksa lagi status & bersihkan sisa
Setelah semua langkah:
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
git status --porcelain=1 --branch
git ls-files | Select-String '\.venv' -SimpleMatch -Quiet
if ($LASTEXITCODE -eq 0) { Write-Host "Masih ada file .venv yang ter-track — periksa ulang" -ForegroundColor Yellow } else { Write-Host ".venv tidak ter-track." -ForegroundColor Green }
```

---

## Ringkasan urutan perintah yang aman (ceklist singkat)
1. Periksa status: `git status --porcelain=1 --branch`
2. Jika rebase berjalan dan Anda tidak ingin melanjutkan: `git rebase --abort`
3. Tambahkan .venv ke .gitignore, hapus dari index: `git rm -r --cached social-media-sentiment-analysis/.venv`
4. Commit .gitignore change.
5. Stage & commit README/RUNME.
6. `git pull --rebase --autostash origin main`
7. `git push origin main`

---

Jika Anda mau, saya bisa:
- Hasilkan skrip PowerShell `.ps1` yang menjalankan urutan di atas dengan opsi interaktif (tanya sebelum `rebase --abort`, sebelum `git rm --cached`, sebelum `push`).
- Atau bantu menyiapkan instruksi untuk membersihkan history bila file besar sudah masuk ke remote.

Apa yang Anda inginkan sekarang: saya buatkan skrip `.ps1` interaktif, atau Anda akan menjalankan perintah manual satu-per-satu?  
```
