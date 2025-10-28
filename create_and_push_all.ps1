<#
.SYNOPSIS
  Inisialisasi/commit semua file di C:\Users\ASUS\Desktop\python-project dan (opsional) push ke remote.

.PARAMETER RepoRoot
  Root folder proyek. Default: C:\Users\ASUS\Desktop\python-project

.PARAMETER RemoteUrl
  URL remote repository (HTTPS). Jika kosong, skrip hanya commit lokal.

.PARAMETER AutoPush
  Jika diset, skrip akan mencoba push tanpa menunggu konfirmasi interaktif (masih akan abort jika file >100MB ditemukan).
#>

param(
  [string]$RepoRoot = 'C:\Users\ASUS\Desktop\python-project',
  [string]$RemoteUrl = '', 
  [switch]$AutoPush
)

function Prompt-YesNo($msg, $defaultYes=$true) {
  if ($AutoPush) { return $true }
  $yn = Read-Host "$msg `n(Y)es/(N)o"
  if (-not $yn) { return $defaultYes }
  return $yn.ToLower().StartsWith('y')
}

# 1) Cek path
if (-not (Test-Path $RepoRoot)) {
  Write-Host "Repo root tidak ditemukan: $RepoRoot" -ForegroundColor Red
  exit 1
}
Set-Location $RepoRoot

# 2) Pastikan git tersedia
try {
  git --version *> $null
} catch {
  Write-Host "Git tidak ditemukan di PATH. Install Git dahulu: https://git-scm.com/" -ForegroundColor Red
  exit 1
}

# 3) Inisialisasi git jika perlu
if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
  Write-Host "Menginisialisasi repositori git di $RepoRoot"
  git init
} else {
  Write-Host "Repositori git sudah ada di $RepoRoot"
}

# 4) Update atau buat .gitignore dengan entri aman
$gitignorePath = Join-Path $RepoRoot '.gitignore'
$recommended = @(
  "# local python env",
  ".venv/",
  "venv/",
  "# bytecode",
  "__pycache__/",
  "*.pyc",
  "# jupyter checkpoints",
  ".ipynb_checkpoints/",
  "# OS files",
  ".DS_Store",
  "# logs",
  "*.log"
)
if (-not (Test-Path $gitignorePath)) {
  $recommended -join "`r`n" | Out-File -FilePath $gitignorePath -Encoding UTF8
  Write-Host "Membuat .gitignore dengan entri standar (.venv/ dll.)"
} else {
  $content = Get-Content $gitignorePath -Raw
  $changed = $false
  foreach ($line in $recommended) {
    if ($content -notmatch [regex]::Escape($line)) {
      Add-Content -Path $gitignorePath -Value $line
      $changed = $true
    }
  }
  if ($changed) { Write-Host ".gitignore diperbarui" } else { Write-Host ".gitignore sudah mengandung entri rekomendasi" }
}

# 5) Jika .venv pernah ter-track, hapus dari index (tetap ada di disk)
$venvRel = '.venv'
$tracked = $false
try {
  git ls-files --error-unmatch $venvRel 2>$null
  if ($LASTEXITCODE -eq 0) { $tracked = $true }
} catch {}
if ($tracked) {
  Write-Host "Menghapus .venv yang ter-track dari index (git rm --cached)..." -ForegroundColor Yellow
  git rm -r --cached --ignore-unmatch $venvRel
  # stage .gitignore change
  git add .gitignore
  if ((git diff --cached --name-only) -ne $null) {
    git commit -m "chore: stop tracking .venv and update .gitignore"
  }
}

# 6) Cek file besar (>100MB)
$bigFiles = Get-ChildItem -Path $RepoRoot -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -gt 100MB } |
  Select-Object FullName,@{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}}

if ($bigFiles.Count -gt 0) {
  Write-Host "Ditemukan file >100MB (GitHub/HTTP push akan gagal). Daftar:" -ForegroundColor Yellow
  $bigFiles | Format-Table -AutoSize
  if (-not (Prompt-YesNo "Apakah Anda ingin melanjutkan (commit mungkin gagal saat push)? (disarankan: gunakan git lfs atau pindahkan file keluar repo)")) {
    Write-Host "Batal karena ada file besar. Pindahkan atau gunakan Git LFS terlebih dahulu." -ForegroundColor Red
    exit 1
  }
}

# 7) Stage semua file sesuai .gitignore
Write-Host "Men-stage semua file sesuai .gitignore..."
git add .

# Perlihatkan apa yang akan di-commit
$staged = git diff --cached --name-only
if (-not $staged) {
  Write-Host "Tidak ada perubahan yang di-stage (nothing to commit)." -ForegroundColor Yellow
} else {
  Write-Host "File yang di-stage:"
  $staged
  if (Prompt-YesNo "Lanjut commit perubahan di atas? (Y/N)") {
    git commit -m "chore: add/update project files"
  } else {
    Write-Host "Commit dibatalkan oleh pengguna." -ForegroundColor Yellow
  }
}

# 8) Remote handling (opsional)
if ($RemoteUrl) {
  $hasOrigin = $false
  try {
    $current = git remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0) { $hasOrigin = $true }
  } catch {}

  if (-not $hasOrigin) {
    Write-Host "Menambahkan remote origin => $RemoteUrl"
    git remote add origin $RemoteUrl
  } else {
    if ($current -ne $RemoteUrl) {
      Write-Host "Remote origin saat ini: $current" -ForegroundColor Yellow
      if (Prompt-YesNo "Ganti URL origin menjadi $RemoteUrl ?") {
        git remote set-url origin $RemoteUrl
        Write-Host "Remote origin diperbarui."
      } else {
        Write-Host "Membiarkan remote origin tidak berubah."
      }
    } else {
      Write-Host "Remote origin sudah sesuai."
    }
  }

  # Push changes: cari branch saat ini dan push
  $branch = (git rev-parse --abbrev-ref HEAD).Trim()
  if (-not $branch -or $branch -eq '') { $branch = 'main' }

  # Pastikan ada upstream atau push dengan -u
  if (Prompt-YesNo "Lanjutkan untuk push ke origin/$branch ? (Anda mungkin diminta kredensial / PAT)") {
    try {
      # fetch & rebase to minimize conflicts
      git fetch origin 2>$null
      # try pull --rebase if remote branch exists
      $remoteBranches = git ls-remote --heads origin $branch
      if ($remoteBranches) {
        Write-Host "Menarik perubahan remote dan rebase (origin/$branch)..." -ForegroundColor Cyan
        git pull --rebase --autostash origin $branch
      }
      Write-Host "Mencoba push ke origin/$branch..."
      git push -u origin $branch
      Write-Host "Push selesai." -ForegroundColor Green
    } catch {
      Write-Host "Push gagal. Jika muncul error credential, gunakan Personal Access Token (PAT) atau jalankan 'gh auth login' lalu ulangi." -ForegroundColor Red
    }
  } else {
    Write-Host "Push dibatalkan oleh pengguna."
  }
} else {
  Write-Host "Tidak ada RemoteUrl disediakan. Hanya melakukan commit lokal." -ForegroundColor Yellow
}

Write-Host "Selesai. Periksa 'git status' atau buka repository di remote untuk memverifikasi." -ForegroundColor Green