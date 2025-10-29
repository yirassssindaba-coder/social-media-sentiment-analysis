# deploy-to-github.ps1 (README)
Versi: v2

Ringkasan
--------
Copilot telah menyusun ulang alur PowerShell untuk meng-upload project lokal ke GitHub sehingga tidak menimbulkan error yang muncul sebelumnya (mis. penggunaan operator bash `||`, here-doc `<<'EOF'`, token `<` di PowerShell, dan pemanggilan `git` yang salah).  
File utama: `deploy-to-github.ps1` — sebuah skrip PowerShell aman yang bisa dijalankan dari folder proyek Anda.

Apa yang diperbaiki dan kenapa sekarang aman
------------------------------------------
- Semua konstruk bash yang tidak kompatibel dengan PowerShell (seperti `||`, `<<'EOF'`, dan penggunaan `<` dalam konteks redirection) dihilangkan dan diganti dengan konstruk PowerShell yang benar.
- Fungsi internal `Run-Git` menangkap output dan exit code dari `git` sehingga skrip tahu kapan perintah `git` gagal atau sukses, dan tidak salah mengira output sebagai kondisi boolean.
- Commit hanya dilakukan bila ada perubahan (menggunakan `git status --porcelain`), sehingga tidak muncul error "nothing to commit".
- Penambahan atau penggantian remote `origin` dilakukan hanya setelah pengecekan. Remote tidak akan di-overwrite kecuali Anda menjalankan skrip dengan parameter `-ForceRemoteReplace`.
- Skrip dibuat idempotent: jika file sudah ada atau repo sudah diinit, skrip tetap melanjutkan tanpa error.

Lokasi file yang disarankan
--------------------------
Simpan skrip di:
```
C:\Users\ASUS\Desktop\python-project-remote\deploy-to-github.ps1
```
Lalu jalankan PowerShell dari folder proyek atau cd ke folder tersebut sebelum menjalankan skrip.

Cara pakai (contoh langsung)
----------------------------
Dari PowerShell (jalankan dari folder proyek):
- Default (HTTPS):
```powershell
.\deploy-to-github.ps1
```
- Gunakan SSH:
```powershell
.\deploy-to-github.ps1 -UseSSH
```
- Ganti origin secara paksa:
```powershell
.\deploy-to-github.ps1 -ForceRemoteReplace
```

Isi dan tujuan skrip (singkat)
------------------------------
- Membuat file dasar bila belum ada: `README.md`, `.gitignore`, `LICENSE`.
- Menginisialisasi repo git bila belum di-init.
- Menambah file (respect `.gitignore`) dan membuat commit hanya bila ada perubahan.
- Memastikan branch utama bernama `main` (rename jika perlu).
- Menambahkan atau memeriksa `origin` (HTTPS default atau SSH bila `-UseSSH`).
- Melakukan `git push -u origin main`. Jika push awal gagal, skrip mencoba `fetch` + `pull --rebase` lalu push ulang, dan memberi instruksi bila konflik perlu diselesaikan secara manual.

Perintah singkat manual (jika tidak ingin memakai skrip)
-------------------------------------------------------
1. Masuk folder proyek:
```powershell
cd "C:\Users\ASUS\Desktop\python-project-remote"
```
2. Periksa status & remote:
```powershell
git status
git remote -v
```
3. Buat file dasar (PowerShell-safe):
```powershell
Set-Content -Path README.md -Value "# myproject" -Encoding UTF8

@'
__pycache__/
.venv/
venv/
*.py[cod]
'@ | Set-Content -Path .gitignore -Encoding UTF8

@'
Copyright (c) 1999 Robee
'@ | Set-Content -Path LICENSE -Encoding UTF8
```
4. Tambah dan commit (hanya bila ada perubahan):
```powershell
git add --all
if ((git status --porcelain) -ne "") { git commit -m "Initial commit: add project files" } else { Write-Host "Nothing to commit" }
```
5. Pastikan branch `main`:
```powershell
$current = git rev-parse --abbrev-ref HEAD
if ($current -ne "main") { git branch -M main }
```
6. Set atau ganti remote origin:
```powershell
git remote get-url origin 2>$null
git remote set-url origin https://github.com/yirassssindaba-coder/myproject.git
git push -u origin main
```

Troubleshooting umum
--------------------
- Error "The token '||' is not a valid statement separator": jangan gunakan `||` di PowerShell. Gunakan blok `if` atau periksa `$LASTEXITCODE` / `$?`.
- Error "Missing file specification after redirection operator" atau "The '<' operator is reserved for future use": artinya Anda menempelkan sintaks here-doc bash (`<<`) di PowerShell. Di PowerShell gunakan here-string `@'... '@` atau `Set-Content`.
- Error "nothing to commit": jalankan `git status --porcelain` untuk melihat perubahan; commit hanya bila ada perubahan.
- Error saat push (auth/network): pastikan:
  - Untuk HTTPS: gunakan Personal Access Token (PAT) sebagai password saat diminta.
  - Untuk SSH: buat key (`ssh-keygen -t ed25519 -C "you@example.com"`), lalu tambahkan isi `id_ed25519.pub` ke GitHub > Settings > SSH and GPG keys.
- Peringatan "warning: branch.main.remote has multiple values": ini berarti konfigurasi git lokal memiliki entri `branch.main.remote` lebih dari satu. Untuk membersihkan, periksa dengan:
```powershell
git config --local --get-all branch.main.remote
git config --local --unset-all branch.main.remote
git config --local branch.main.remote origin
```
(gunakan hati-hati; hanya ubah config jika Anda paham.)

Catatan untuk file besar
-----------------------
Jika repo berisi file >100MB, gunakan Git LFS:
```powershell
git lfs install
git lfs track "*.zip"
git add .gitattributes
git add path\to\large-file
git commit -m "Add large files with LFS"
git push origin main
```

Jika ada error lagi
-------------------
Paste output lengkap dari perintah yang gagal (cukup `git status`, `git remote -v`, dan output error terakhir). Dengan output itu Copilot akan membantu koreksi langkah-langkah berikutnya.

Langkah berikutnya yang bisa saya bantu
--------------------------------------
- Menyesuaikan `RemoteUrl` jika repository target berbeda.
- Membuat panduan membuat Personal Access Token (PAT) dan cara menggunakannya pada push HTTPS.
- Panduan membuat SSH key, memverifikasi koneksi SSH (`ssh -T git@github.com`), dan memasang key ke akun GitHub.
- Membersihkan peringatan konfigurasi git lokal seperti "branch.main.remote has multiple values".

Penutup
-------
Jalankan `deploy-to-github.ps1` dari folder proyek atau gunakan perintah manual di atas. Jika Anda ingin, saya bisa menghasilkan file `deploy-to-github.ps1` lengkap (isi skrip) di sini juga agar Anda bisa langsung menyalin & simpan ke file.