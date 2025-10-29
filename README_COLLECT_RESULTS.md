```markdown
# Cara mengumpulkan hasil (collect_hasil) dan menyimpan ke Git

Tujuan:
- Jalankan `scripts/collect_hasil.py` untuk mengumpulkan hasil ke `files/social-media-sentiment-analysis`.
- Commit hasil dan skrip pendukung lalu push ke remote `https://github.com/yirassssindaba-coder/python-project.git`.

File penting:
- `scripts/collect_hasil.py`  : skrip Python yang Anda lampirkan (mengumpulkan file sesuai pola glob).
- `scripts/run_and_commit_results.ps1` : helper PowerShell untuk menjalankan skrip Python dan otomatis men-commit + push hasil.

Cara singkat (Copy → Paste dalam PowerShell dari root repo):
1. Pastikan berada di root repo (direktori yang berisi `.git`):
   ```powershell
   cd "C:\Users\ASUS\Desktop\python-project-remote"
   ```

2. (Opsional) Lakukan backup cepat:
   ```powershell
   Compress-Archive -Path . -DestinationPath "..\python-project-remote-backup.zip"
   ```

3. Jalankan helper yang akan mengumpulkan hasil, commit, dan push:
   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\scripts\run_and_commit_results.ps1"
   ```

4. Jika Anda ingin menentukan pola sendiri (mis. hanya hasil dari social-media-sentiment-analysis):
   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\scripts\run_and_commit_results.ps1" -Patterns "social-media-sentiment-analysis\results\**\*"
   ```

5. Verifikasi:
   ```powershell
   git status --short
   git log --oneline -n 5
   ```

Catatan penting:
- Skrip ini respek terhadap `.gitignore` Anda — secara default tidak akan menambahkan `.venv` atau file cache.
- Jika Anda perlu memasukkan file yang di-ignore, gunakan parameter `-IncludeIgnored` (TIDAK DIREKOMENDASIKAN untuk `.venv`).
- Jika remote berbeda, parameter `-RemoteUrl` dapat digunakan untuk men-set target remote.
- Jika push ditolak karena remote lebih maju, ikuti instruksi yang tampil:
  - `git fetch origin`
  - `git pull --rebase origin main`
  - selesaikan konflik -> `git rebase --continue`
  - `git push -u origin main`
```
