# Perbaikan & Instalasi Jupyter (Windows) — README

Dokumentasi ini berisi panduan lengkap untuk memperbaiki masalah instalasi Jupyter/JupyterLab di Windows, termasuk solusi untuk error:
`ERROR: Could not install packages due to an OSError: [WinError 32] The process cannot access the file because it is being used by another process: '...jupyter-lab.exe' -> '...jupyter-lab.exe.deleteme'`

Tujuan:
- Menyediakan langkah-langkah terstruktur untuk membuat environment Python/venv, menginstal paket yang diperlukan, mengatur SSL_CERT_FILE, mendaftarkan kernel, dan — yang penting — melepaskan kunci file yang menyebabkan pip gagal menimpa executable launcher Jupyter (WinError 32).
- Berikan blok PowerShell yang dapat Anda jalankan satu-per-satu dari folder proyek Anda:
  `C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis`

CATATAN PENTING:
- Jalankan tiap blok secara berurutan. Jangan paste semua blok sekaligus.
- Buka PowerShell (gunakan "Run as Administrator" hanya bila saya tandai).
- Jika sebuah blok mengeluarkan error, salin seluruh output error dan tempelkan ke chat agar saya bantu koreksi langkah spesifiknya.

---

## Ringkasan Blok yang Akan Dijalankan
1. Verifikasi lokasi kerja (root proyek).  
2. Periksa nested folder / path.  
3. Perbaiki PATH sementara bila perlu.  
4. Temukan interpreter Python sistem ($PY).  
5. Cek / buat ulang venv.  
6. Atur ExecutionPolicy (CurrentUser) untuk memungkinkan Activate.ps1.  
7. Aktifkan venv dan verifikasi interpreter venv.  
8. Install paket utama untuk Jupyter/data-science.  
9. Set SSL_CERT_FILE permanen (User) menggunakan certifi.  
10. Reinstall Jupyter (blok normal).  
10b. (Baru) Jika muncul WinError 32 -> Jalankan blok perbaikan yang melepaskan kunci file, menghapus `.deleteme`, dan reinstall dengan retry.  
11. Daftarkan kernel ipykernel untuk venv.  
12. Jalankan JupyterLab / verifikasi.

Di bawah ini saya sertakan semua penjelasan singkat dan blok PowerShell yang Anda jalankan. Jika Anda sudah mengikuti sebagian langkah di panduan sebelumnya, cukup jalankan blok 10b (bagian "Release locks") jika muncul WinError 32 saat pip install.

---

## Cara menjalankan (ringkas)
- Buka PowerShell, pindah ke:
  ```
  cd C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis
  ```
- Jalankan blok 1..9 sesuai urutan (blok-blok awal seperti pengecekan venv, instal paket, dsb). Jika pada langkah instal muncul error WinError 32 yang merujuk ke `jupyter-lab.exe.deleteme`, jalankan blok 10b (Release locks) berikut.
- Setelah semua selesai, buka JupyterLab:
  ```
  python -m jupyter lab
  ```

---

## Blok PowerShell penting (jalankan satu-per-satu)
- Gunakan blok ini ketika Anda menghadapi WinError 32. Blok ini mencoba:
  - Menghentikan proses yang mungkin mengunci launcher (opsional: menampilkan proses dahulu).
  - Menghapus file `.deleteme` dan executable yang rusak.
  - Melakukan reinstall jupyter/jupyterlab/ipykernel dengan retry.
  - Menyajikan rekomendasi jika reinstall masih gagal (antivirus, reboot, Process Explorer).

Salin & jalankan hanya blok yang Anda butuhkan (utama: blok 10 dan blok 10b). Jalankan blok 10 terlebih dahulu; jika pip gagal dengan WinError 32, jalankan blok 10b.

```powershell
### BLOCK 10 - Reinstall Jupyter (normal)
Write-Host "=== Block 10: Reinstall Jupyter packages (normal) ===" -ForegroundColor Cyan

# Pastikan venv aktif (jalankan .\venv\Scripts\Activate.ps1 sebelumnya)
# Tampilkan wrapper jupyter di venv Scripts
$venvScripts = Join-Path (Resolve-Path .\venv).ProviderPath "Scripts"
Write-Host "Inspecting venv Scripts folder: $venvScripts"
Get-ChildItem -Path $venvScripts -Filter "*jupyter*" -Force -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTime

# Remove known wrapper files if present (non-fatal)
$wrappers = @("jupyter.exe","jupyter-lab.exe","jupyter-notebook.exe","jupyter-server.exe")
foreach ($w in $wrappers) {
    $p = Join-Path $venvScripts $w
    if (Test-Path $p) {
        try { Remove-Item -LiteralPath $p -Force -ErrorAction Stop; Write-Host "Removed wrapper: $p" -ForegroundColor Green }
        catch { Write-Host "Warning: failed to delete $p : $($_.Exception.Message)" -ForegroundColor Yellow }
    }
    $d = $p + ".deleteme"
    if (Test-Path $d) {
        try { Remove-Item -LiteralPath $d -Force -ErrorAction Stop; Write-Host "Removed .deleteme: $d" -ForegroundColor Green }
        catch { Write-Host "Warning: failed to delete $d : $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

# Reinstall jupyter packages (single attempt)
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel
Write-Host "Block 10 completed. If pip failed with WinError 32, run Block 10b."
```

```powershell
### BLOCK 10b - Release locks & reattempt reinstall (run only if you saw WinError 32)
Write-Host "=== Block 10b: Release locks and retry install ===" -ForegroundColor Cyan

# venv Scripts path
$venvScripts = Join-Path (Resolve-Path .\venv).ProviderPath "Scripts"
Write-Host "Inspecting venv Scripts folder: $venvScripts"

# Helper function to attempt pip installs with retries
function Retry-PipInstall([string[]]$pkgs, [int]$tries=3, [int]$delaySec=3) {
    for ($i=1; $i -le $tries; $i++) {
        Write-Host "pip install attempt $i of $tries for: $($pkgs -join ', ')" -ForegroundColor Cyan
        try {
            python -m pip install --upgrade --force-reinstall $pkgs 2>&1 | Tee-Object -Variable pipOut
            if ($LASTEXITCODE -eq 0) { Write-Host "pip install succeeded." -ForegroundColor Green; return $true }
            else { Write-Host "pip install returned exit code $LASTEXITCODE. Output below:" -ForegroundColor Yellow; $pipOut; Start-Sleep -Seconds $delaySec }
        } catch {
            Write-Host "Exception during pip install: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds $delaySec
        }
    }
    return $false
}

# Find candidate processes that may lock files
$likelyNames = @("jupyter","jupyter-lab","python","pythonw","node")
$found = Get-Process -ErrorAction SilentlyContinue | Where-Object { $likelyNames -contains $_.Name } | Select-Object Id,Name,Path
if ($found) {
    Write-Host "Found potentially relevant processes (will list and then stop them) :" -ForegroundColor Yellow
    $found | Format-Table -AutoSize
    # Prompt user to continue stopping processes
    $ans = Read-Host "Stop these processes now? (Y/N) [recommended Y]"
    if ($ans -match '^[Yy]') {
        foreach ($pr in $found) {
            try { Write-Host "Stopping process Id=$($pr.Id) Name=$($pr.Name)" -ForegroundColor Yellow; Stop-Process -Id $pr.Id -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 300 }
            catch { Write-Host "Could not stop process Id=$($pr.Id) : $($_.Exception.Message)" -ForegroundColor Red }
        }
    } else {
        Write-Host "User declined to stop processes. You can stop them manually (Task Manager) and re-run this block." -ForegroundColor Yellow
    }
} else {
    Write-Host "No matching processes found by name. Continuing..." -ForegroundColor Green
}

# Optional: use handle.exe (Sysinternals) if installed
$handleExe = (Get-Command handle.exe -ErrorAction SilentlyContinue).Source
if (-not $handleExe) {
    $possibleHandlePath = "$env:ProgramFiles\Sysinternals\handle.exe"
    if (Test-Path $possibleHandlePath) { $handleExe = $possibleHandlePath }
}
if ($handleExe) {
    Write-Host "Using handle.exe to find locks on jupyter-lab.exe (may require Admin)..." -ForegroundColor Cyan
    $targetExe = Join-Path $venvScripts "jupyter-lab.exe"
    try { & $handleExe $targetExe 2>&1 | Tee-Object -Variable handleOut; $handleOut | Write-Host } catch { Write-Host "handle.exe invocation failed or requires elevation." -ForegroundColor Yellow }
} else {
    Write-Host "handle.exe not found — skip advanced handle check. Use Process Explorer (Sysinternals) if needed." -ForegroundColor Yellow
}

# Attempt to remove .deleteme and exe (retry)
$exePath = Join-Path $venvScripts "jupyter-lab.exe"
$deleteme = $exePath + ".deleteme"
for ($i=1; $i -le 6; $i++) {
    try {
        if (Test-Path $deleteme) { Write-Host "Attempting to remove $deleteme (try $i)"; Remove-Item -LiteralPath $deleteme -Force -ErrorAction Stop }
        if (Test-Path $exePath)  { Write-Host "Attempting to remove $exePath (try $i)"; Remove-Item -LiteralPath $exePath -Force -ErrorAction Stop }
        break
    } catch {
        Write-Host "Remove attempt $i failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-Sleep -Seconds (1 * $i)
    }
}

# Retry pip install with multiple attempts
$pkgs = @("jupyter","jupyterlab","ipykernel")
$ok = Retry-PipInstall -pkgs $pkgs -tries 3 -delaySec 3
if (-not $ok) {
    Write-Host "Reinstall still failed. Common causes: antivirus locking files, other python processes, or permissions." -ForegroundColor Red
    Write-Host "- Close all IDEs and terminals (VSCode, PyCharm, PowerShell, CMD), stop Jupyter services." -ForegroundColor Yellow
    Write-Host "- Temporarily disable antivirus or add exception for the venv folder." -ForegroundColor Yellow
    Write-Host "- Reboot Windows and re-run this Block (10b)." -ForegroundColor Yellow
} else {
    Write-Host "Reinstall successful." -ForegroundColor Green
}

# List jupyter wrappers present after the attempt
Get-ChildItem -Path $venvScripts -Filter "*jupyter*" -Force -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTime
Write-Host "Block 10b finished."
```

---

## Tips lanjutan & penanganan manual
- Jika 10b tidak menemukan proses tetapi file tetap terkunci, gunakan **Process Explorer** (Sysinternals):  
  1. Download: https://docs.microsoft.com/sysinternals/downloads/process-explorer  
  2. Jalankan sebagai Administrator.  
  3. Tekan Ctrl+F, cari `jupyter-lab.exe` atau `jupyter-lab.exe.deleteme`.  
  4. Process Explorer akan tunjukkan proses yang memegang handle; hentikan proses tersebut, lalu hapus file `.deleteme` dan reinstall pip.

- Jika antivirus/Windows Defender mengunci file:
  - Tambahkan pengecualian untuk folder venv (`.../venv`) ke antivirus, atau nonaktifkan sementara real-time protection saat menginstall.

- Jika semua gagal: reboot Windows (sering kali melepaskan handle) lalu jalankan kembali Block 10b segera setelah boot sebelum membuka editor.

---

## Setelah perbaikan selesai
1. Daftarkan ipykernel untuk venv:
   ```powershell
   python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
   ```
2. Jalankan JupyterLab:
   ```powershell
   python -m jupyter lab
   ```
3. Verifikasi kernel & paket:
   ```powershell
   jupyter kernelspec list
   python -c "import pandas,nltk; print('pandas',pandas.__version__)"
   python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"
   ```

---

## Jika Anda ingin saya buat versi interaktif (konfirmasi sebelum Stop-Process)
Katakan "Saya mau versi interaktif" — saya akan kirimkan varian Block 10b yang menampilkan proses lalu meminta konfirmasi `Y/N` per proses sebelum menghentikannya (lebih aman).

---

Jika Anda sudah siap, jalankan Block 10 terlebih dahulu (atau langsung Block 10b bila Anda sudah melihat WinError 32). Jika ada output error, salin seluruh teks output ke chat — saya akan bantu menganalisis dan memberikan instruksi langkah selanjutnya.   
