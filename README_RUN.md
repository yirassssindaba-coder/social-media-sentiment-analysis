```markdown
# push-clean-to-python-realm — Petunjuk menjalankan (singkat & aman)

Tujuan:
- Mengganti origin remote menjadi https://github.com/yirassssindaba-coder/Python-realm.git
- Menghapus .venv dari index, memastikan .venv tidak ikut dipush
- Memperbarui/menambahkan .gitignore
- Commit cleanup dan push ke origin/main
- Menunjukkan file besar (>=100MB) dan petunjuk Git LFS bila perlu

Langkah cepat — copy & paste semua baris ini di PowerShell:

1) Cadangkan folder (opsional tapi sangat disarankan)
```powershell
cd "C:\Users\ASUS\Desktop"
Compress-Archive -Path "python-project-remote\*" -DestinationPath "python-project-remote-backup.zip"
```

2) Pastikan file skrip dan .gitignore sudah disimpan di folder proyek:
- push-clean-to-python-realm.ps1
- .gitignore

3) Jalankan skrip (HTTPS default)
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\push-clean-to-python-realm.ps1"
```

4) Jika ingin pakai SSH (pastikan SSH key sudah ditambahkan di GitHub)
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\push-clean-to-python-realm.ps1" -UseSSH
```

5) Jika Anda sengaja mau memaksa include file/folder yang di-ignore (tidak disarankan untuk .venv):
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\push-clean-to-python-realm.ps1" -IncludeIgnored
```

6) Verifikasi setelah selesai:
```powershell
cd "C:\Users\ASUS\Desktop\python-project-remote"
git status --short
git log --oneline -n 5
git remote -v
```
Buka juga repo di browser:
https://github.com/yirassssindaba-coder/Python-realm

7) Jika push ditolak (fetch first / non-fast-forward), jalankan manual:
```powershell
git fetch origin
git pull --rebase origin main
# jika muncul konflik:
# edit file -> git add "<path-to-file>" -> git rebase --continue
git push -u origin main
```

Catatan keamanan dan ukuran repo:
- Jangan commit .venv ke repository publik; itu membuat repo besar dan menyalin file biner yang tidak perlu.
- Gunakan requirements.txt sebagai ganti menyertakan virtualenv.
- Untuk file >100MB gunakan Git LFS.

Jika Anda ingin, saya bisa:
- Menyusun satu baris perintah untuk dijalankan sekarang yang melakukan backup -> run script -> verify,
- Atau memandu Anda secara interaktif jika skrip menghasilkan error (paste output PowerShell di sini).
```
