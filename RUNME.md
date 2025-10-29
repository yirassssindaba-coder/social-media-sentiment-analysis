# Cara menjalankan deploy-final.ps1 untuk menyimpan semua file/folder ke GitHub

Ringkasan:
- Simpan file `deploy-final.ps1` di:
  `C:\Users\ASUS\Desktop\python-project-remote\deploy-final.ps1`
- Jalankan script setiap kali Anda menambah atau mengubah file/folder agar perubahan di-commit dan di-push ke GitHub.

Langkah menjalankan (satu kali, copy & paste):
1. Buka PowerShell.
2. (Opsional) Beralih ke folder proyek:
   ```
   cd "C:\Users\ASUS\Desktop\python-project-remote"
   ```
3. Jalankan script (safe, tidak mengubah ExecutionPolicy permanen):
   ```
   powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\deploy-final.ps1"
   ```
   atau jika sudah berada di folder:
   ```
   .\deploy-final.ps1
   ```

Apa yang script lakukan:
- Mengecek apakah Git tersedia.
- Memastikan berada di folder proyek.
- Membuat `README.md`, `.gitignore`, `LICENSE` jika belum ada (tidak menimpa file yang sudah ada).
- Menginisialisasi repo Git jika belum ada.
- Meng-set `user.name` dan `user.email` (lokal) jika belum ada.
- Menjalankan `git add --all`, lalu `git commit` hanya bila ada perubahan.
- Memastikan branch utama bernama `main`.
- Men-set remote `origin` ke URL yang ditentukan di dalam script.
- Melakukan `git fetch`, `git pull --rebase origin main`, lalu `git push -u origin main`.
- Jika rebase/push menemukan konflik atau penolakan, script menghentikan eksekusi dan memberi instruksi bagaimana menyelesaikannya.

Autentikasi:
- HTTPS: saat diminta username/password gunakan username GitHub & Personal Access Token (PAT) sebagai password.
- SSH: jika ingin menggunakan SSH, set `$UseSSH = $true` di script dan tambahkan public SSH key Anda ke GitHub (Settings → SSH and GPG keys).

Jika terjadi konflik saat `git pull --rebase`:
1. Buka file yang konflik, perbaiki marker `<<<<`, `====`, `>>>>`.
2. Jalankan:
   ```
   git add <file-yang-diselesaikan>
   git rebase --continue
   ```
3. Setelah rebase selesai:
   ```
   git push -u origin main
   ```

Catatan:
- Script tidak akan memaksa menimpa remote (`--force`) — ini lebih aman. Jika Anda benar-benar ingin menimpa remote, lakukan secara manual setelah memahami risikonya:
  ```
  git push --force-with-lease origin main
  ```

Jika Anda ingin, saya bisa:
- Mengubah `$target` di script ke SSH dan menambahkan langkah pembuatan SSH key di README,
- Menambahkan logging ke file, atau
- Membuat versi yang menjalankan otomatis saat ada perubahan (watcher / scheduled task).

Simpan README.md di folder proyek agar menjadi panduan cepat untuk Anda dan tim.
