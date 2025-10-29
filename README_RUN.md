# Sinkronisasi Project ke GitHub (PowerShell safe)

## Ringkasan
Dokumen ini berisi rangkaian perintah PowerShell yang aman untuk menambahkan, meng‑commit, menyinkronkan, dan mendorong (push) seluruh isi folder proyek
`C:\Users\ASUS\Desktop\python-project-remote` ke repository GitHub Anda. Semua perintah disusun agar kompatibel dengan PowerShell (tanpa operator bash yang tidak tersedia)
dan mencakup langkah sinkronisasi remote (fetch + pull --rebase) untuk menghindari penolakan push karena non‑fast‑forward.

## Prasyarat
- Git terpasang dan tersedia di PATH (`git --version`).
- Akses ke repository remote (HTTPS atau SSH). Untuk HTTPS disarankan menggunakan Personal Access Token (PAT).
- Jalankan PowerShell sebagai user biasa (tidak perlu Administrator).

## Catatan Penting
- Skrip/perintah tidak akan melakukan force-push secara otomatis. Hindari `--force` kecuali Anda memahami risikonya.
- Disarankan untuk tidak memasukkan virtual environment (`.venv` / `venv`) ke repo. Gunakan `requirements.txt` atau `environment.yml` sebagai gantinya.
- Perintah dapat dicopy–paste langsung ke PowerShell. Jika ExecutionPolicy mencegah menjalankan skrip, gunakan `-ExecutionPolicy Bypass` saat memanggil file `.ps1`.

## Langkah singkat (copy → paste ke PowerShell)

### 1) Masuk folder dan cek Git tersedia
```powershell
cd "C:\Users\ASUS\Desktop\python-project-remote"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error "git tidak ditemukan. Instal Git terlebih dahulu."; exit 1 }
git status
git remote -v
```

### 2) Buat file dasar jika perlu (PowerShell-safe)
```powershell
# README
if (-not (Test-Path README.md)) { Set-Content -Path README.md -Value "# myproject" -Encoding UTF8; Write-Host "README.md dibuat" } else { Write-Host "README.md sudah ada" }

# .gitignore
if (-not (Test-Path .gitignore)) {
@'
__pycache__/
.venv/
venv/
*.py[cod]
*.pyo
*.pyd
*.egg-info/
dist/
build/
.env
.ipynb_checkpoints/
.vscode/
.idea/
*.sqlite3
.DS_Store
'@ | Set-Content -Path .gitignore -Encoding UTF8
    Write-Host ".gitignore dibuat"
} else { Write-Host ".gitignore sudah ada" }

# LICENSE
if (-not (Test-Path LICENSE)) {
@'
Copyright (c) 1999 Robee

Permission is hereby granted, free of charge, to any person obtaining a copy...
'@ | Set-Content -Path LICENSE -Encoding UTF8
    Write-Host "LICENSE dibuat"
} else { Write-Host "LICENSE sudah ada" }
```

### 3) Tambahkan semua perubahan dan commit (hanya jika ada perubahan)
```powershell
git add --all

# Periksa perubahan secara aman
$status = git status --porcelain
if ($status -and $status.Trim().Length -gt 0) {
    git commit -m "Initial commit: add project files"
    Write-Host "Commit berhasil."
} else {
    Write-Host "Nothing to commit (working tree clean)."
}
```

### 4) Pastikan branch utama bernama `main` (aman)
```powershell
$current = git rev-parse --abbrev-ref HEAD
if ($LASTEXITCODE -ne 0) { Write-Error "Gagal menentukan branch saat ini"; exit 1 }
if ($current -ne "main") {
    git branch -M main
    Write-Host "Branch diganti menjadi main"
} else {
    Write-Host "Sudah di branch main"
}
```

### 5) Set remote `origin` jika perlu (ganti URL sesuai repo Anda)
```powershell
$target = "https://github.com/yirassssindaba-coder/myproject.git"
# Jika ingin pakai SSH: $target = "git@github.com:yirassssindaba-coder/myproject.git"

# Jika origin belum ada, tambahkan; jika ada, tampilkan dan ganti jika perlu
$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Existing origin: $existing"
    if ($existing -ne $target) {
        # ganti origin hanya jika berbeda
        git remote set-url origin $target
        Write-Host "Origin diubah menjadi $target"
    } else {
        Write-Host "Origin sudah mengarah ke $target"
    }
} else {
    git remote add origin $target
    Write-Host "Origin ditambahkan: $target"
}
```

### 6) Sinkronkan dengan remote lalu push (aman — rebase direkomendasikan)
```powershell
# Ambil referensi remote dulu
git fetch origin

# Coba rebase lokal di atas origin/main (lebih bersih). Jika gagal karena konflik, Anda akan diberi tahu.
$rebaseResult = git pull --rebase origin main 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "git pull --rebase mengembalikan error:"
    Write-Host $rebaseResult
    Write-Host "Jika muncul konflik: buka file yang konflik, selesaikan, lalu jalankan:"
    Write-Host "    git add `"<path-to-resolved-file>`""
    Write-Host "    git rebase --continue"
    Write-Host "Atau batalkan rebase dengan: git rebase --abort"
    exit 1
} else {
    Write-Host "Rebase/pull sukses. Sekarang push ke origin/main..."
    git push -u origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Push berhasil."
    } else {
        Write-Error "Push gagal. Jika memang ingin menimpa remote (RISIKO), jalankan: git push --force-with-lease origin main"
        exit 1
    }
}
```

## Memaksa menambahkan file/folder yang di-ignore
Jika Anda benar‑benar perlu memasukkan folder yang disebutkan di `.gitignore` (mis. `.venv`), lakukan salah satu:
- Hapus entri terkait dari `.gitignore`, lalu:
```powershell
git add --all
git commit -m "Add previously ignored files"
git push -u origin main
```
- Atau paksa tanpa mengubah `.gitignore` (tidak direkomendasikan untuk venv):
```powershell
git add -f path\to\ignored-folder-or-file
git commit -m "Force add ignored file/folder (not recommended)"
git push -u origin main
```

## File besar (>100 MB) — Gunakan Git LFS
```powershell
git lfs install
git lfs track "*.zip"       # contoh pattern
git add .gitattributes
git add path\to\largefile
git commit -m "Add large files with LFS"
git push origin main
```

## Troubleshooting singkat
- Push ditolak ("fetch first" / "non‑fast‑forward"): jalankan:
```powershell
git fetch origin
git pull --rebase origin main
# jika konflik: edit file, lalu:
git add "<path-to-resolved-file>"
git rebase --continue
git push -u origin main
```
- Jika PowerShell menolak menjalankan skrip: tambahkan `-ExecutionPolicy Bypass` saat memanggil file `.ps1`.
- Jika muncul peringatan CRLF/LF: jalankan `git config core.autocrlf true` pada Windows.
- Untuk membersihkan entri duplikat `branch.main.remote`:
```powershell
git config --local --unset-all branch.main.remote
git config --local branch.main.remote origin
```

## Rekomendasi praktik
- Jangan commit virtualenv; gunakan `requirements.txt` / `environment.yml`.
- Gunakan Git LFS untuk file biner besar.
- Jangan memaksa (`-f`) menambahkan file sensitif (credential, kunci pribadi).
- Sebelum melakukan operasi massal, verifikasi dengan `git status --porcelain` dan `git log --oneline -n 5`.

## Lanjutan (opsional)
Jika Anda ingin saya membuat:
- file PowerShell `deploy-clean.ps1` yang otomatis menjalankan langkah-langkah di atas, atau
- watcher (`deploy-watcher.ps1`) yang memonitor perubahan dan men‑sync otomatis,  
sebutkan pilihan Anda dan saya akan sediakan file `.ps1` lengkap siap pakai.

---
