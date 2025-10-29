<#
Helper: jalankan collect_hasil.py, stage hasil & skrip, commit, set remote (opsional) dan push.
#>

param(
    [string[]]$Patterns = @("social-media-sentiment-analysis\results\**\*"),
    [string]$Out = "files\social-media-sentiment-analysis",
    [string]$RemoteUrl = "https://github.com/yirassssindaba-coder/Python-realm.git",
    [switch]$IncludeIgnored
)

function ExitWithMessage($msg, $code=1) {
    Write-Error $msg
    exit $code
}

# 1) prechecks
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { ExitWithMessage "git tidak ditemukan. Install Git lalu jalankan ulang." }
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { ExitWithMessage "python tidak ditemukan. Pastikan Python tersedia di PATH." }

$repoRoot = Get-Location
Write-Host "Working folder: $repoRoot"

# 2) run python script
$pyScript = Join-Path $repoRoot "scripts\collect_hasil.py"
if (-not (Test-Path $pyScript)) { ExitWithMessage "File scripts\collect_hasil.py tidak ditemukan." }

# build arguments as flat array
$argList = @()
foreach ($p in $Patterns) { $argList += "-p"; $argList += $p }
$argList += "-o"; $argList += $Out

# Start-Process requires a single-level array; compose it with script path first
$startArgs = @($pyScript) + $argList

Write-Host "Running: python $($startArgs -join ' ')"
$proc = Start-Process -FilePath python -ArgumentList $startArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput ".\collect_hasil_stdout.txt" -RedirectStandardError ".\collect_hasil_stderr.txt"
if ($proc -eq $null) { ExitWithMessage "Gagal memulai proses Python." 2 }
if ($proc.ExitCode -ne 0) {
    Write-Host "collect_hasil.py failed (exit code $($proc.ExitCode)). See collect_hasil_stderr.txt"
    if (Test-Path .\collect_hasil_stderr.txt) { Get-Content .\collect_hasil_stderr.txt | ForEach-Object { Write-Host $_ } }
    ExitWithMessage "collect_hasil.py gagal." $proc.ExitCode
} else {
    if (Test-Path .\collect_hasil_stdout.txt) { Get-Content .\collect_hasil_stdout.txt | ForEach-Object { Write-Host $_ } }
}

# 3) Stage results and scripts (respect .gitignore unless IncludeIgnored)
Write-Host "Staging output folder and helper scripts..."
if ($IncludeIgnored) {
    Write-Warning "IncludeIgnored di-set: akan mencoba menambahkan file yang di-ignore (tidak disarankan untuk .venv)."
    git add --all
} else {
    # stage output folder and helpers explicitly to avoid accidentally adding .venv
    git add -- "$Out" 2>$null
    git add -- "scripts/collect_hasil.py" "scripts/run_and_commit_results.ps1" "README_COLLECT_RESULTS.md" 2>$null
}

if (Test-Path .gitignore) { git add -- ".gitignore" 2>$null }

# 4) Commit if changes
$status = git status --porcelain
if ($status -and $status.Trim().Length -gt 0) {
    $msg = "Add collected results and helper scripts: $(Get-Date -Format u)"
    git commit -m $msg
    if ($LASTEXITCODE -ne 0) { ExitWithMessage "git commit gagal. Periksa output." }
    Write-Host "Committed: $msg"
} else {
    Write-Host "Tidak ada perubahan untuk di-commit."
}

# 5) Ensure branch 'main'
$branch = git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -eq 0 -and $branch.Trim() -ne "main") {
    git branch -M main
    Write-Host "Branch renamed to main"
}

# 6) Set remote origin (add or update)
$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    if ($existing.Trim() -ne $RemoteUrl.Trim()) {
        Write-Host "Setting origin to $RemoteUrl"
        git remote set-url origin $RemoteUrl
    } else { Write-Host "Origin already set." }
} else {
    git remote add origin $RemoteUrl
    Write-Host "Origin added: $RemoteUrl"
}

# 7) Sync & push
Write-Host "Fetching origin..."
git fetch origin

# ensure we can rebase/push: check for unstaged changes
$unstaged = git status --porcelain
if ($unstaged -and $unstaged.Trim().Length -gt 0) {
    Write-Warning "Terdapat perubahan lokal yang belum di-commit. Silakan commit atau stash terlebih dahulu."
    Write-Host $unstaged
    ExitWithMessage "Hentikan: commit/stash lokal terlebih dahulu." 4
}

$revlist = git rev-list --left-right --count origin/main...main 2>$null
if ($LASTEXITCODE -eq 0 -and $revlist) {
    $parts = $revlist -split '\s+'
    if ($parts.Length -eq 2) {
        $originOnly = [int]$parts[0]; $localOnly = [int]$parts[1]
        Write-Host "Commits (origin-only, local-only): $originOnly, $localOnly"
        if ($originOnly -gt 0) {
            Write-Host "Remote ahead; running git pull --rebase origin main..."
            git pull --rebase origin main
            if ($LASTEXITCODE -ne 0) { ExitWithMessage "git pull --rebase gagal. Selesaikan konflik manual." 2 }
        }
    }
}

Write-Host "Pushing to origin/main..."
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Warning "git push gagal. Jika ditolak, jalankan manual: git fetch origin; git pull --rebase origin main; selesaikan konflik; git push -u origin main"
    exit 3
}

Write-Host "Selesai: hasil telah dikumpulkan, di-commit, dan dipush ke $RemoteUrl"