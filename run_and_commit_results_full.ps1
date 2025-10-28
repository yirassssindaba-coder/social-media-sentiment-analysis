<#
Run and commit results for social-media-sentiment-analysis
Usage:
  Save to C:\Users\ASUS\Desktop\python-project\run_and_commit_results_full.ps1
  From PowerShell run:
    Set-Location 'C:\Users\ASUS\Desktop\python-project'
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    .\run_and_commit_results_full.ps1        # interaktif
    .\run_and_commit_results_full.ps1 -AutoConfirm -Branch main  # non-interaktif

Behaviour:
 - membuat/aktifkan virtualenv .venv (jika belum ada)
 - install dependencies (requirements.txt dan project requirements)
 - memastikan kernel tersedia untuk papermill
 - menjalankan notebook (via papermill) → menyimpan output ke social-media-sentiment-analysis/results
 - memeriksa file besar (>100MB) dan menanyakan apakah ingin track dengan Git LFS
 - memperbarui .gitignore (ungkap results) dan .gitattributes (jika LFS dipilih)
 - menghapus tracking .venv/__pycache__ dari index jika perlu
 - stage hasil di results, commit, pull --rebase --autostash, push (atau force-with-lease jika diperlukan)
#>

param(
  [string]$RepoPath = ".",
  [string]$Branch = "main",
  [switch]$AutoConfirm
)

function Abort($msg) { Write-Host $msg -ForegroundColor Red; exit 1 }

Set-Location $RepoPath

# 0) basic checks
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Abort "git not found. Install Git and retry." }
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { Abort "python not found. Install Python and retry." }

# ensure repo safe.directory to avoid dubious ownership errors
$repoFull = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { Abort "Not a git repository (run from repo root)." }
git config --global --add safe.directory $repoFull 2>$null

# 1) Ensure not mid-rebase
if (Test-Path ".git\rebase-merge" -or Test-Path ".git\rebase-apply") {
  Write-Host "Interactive rebase detected. Resolve rebase (--continue or --abort) before running this script." -ForegroundColor Yellow
  git status
  exit 1
}

# 2) prepare venv
$venvPath = Join-Path $repoFull ".venv"
if (-not (Test-Path $venvPath)) {
  Write-Host "Creating virtual environment .venv..."
  python -m venv .venv
}
# activate for current process
$activate = Join-Path $venvPath "Scripts\Activate.ps1"
if (Test-Path $activate) {
  Write-Host "Activating .venv"
  . $activate
} else {
  Write-Host "Warning: venv activation script not found at $activate" -ForegroundColor Yellow
}

# 3) install dependencies
Write-Host "Upgrading pip & installing dependencies..."
python -m pip install --upgrade pip setuptools wheel
if (Test-Path ".\requirements.txt") {
  python -m pip install -r .\requirements.txt
}
if (Test-Path ".\social-media-sentiment-analysis\requirements.txt") {
  python -m pip install -r .\social-media-sentiment-analysis\requirements.txt
}
# ensure papermill / nbconvert / ipykernel exist
python -m pip install papermill nbconvert nbformat ipykernel jupyter

# register kernel name 'python3' (safe)
python -m ipykernel install --user --name python3 --display-name "Python 3" 2>$null

# 4) run notebook(s) to produce outputs into results
$projectNb = 'social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb'
$outputNb  = 'social-media-sentiment-analysis\social-media-sentiment-analysis-output.ipynb'
$resultsDir = Join-Path $repoFull 'social-media-sentiment-analysis\results'
if (-not (Test-Path $resultsDir)) { New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null }

if (-not (Test-Path $projectNb)) {
  Write-Host "Notebook not found: $projectNb. Attempting to run any scripts in social-media-sentiment-analysis/scripts..." -ForegroundColor Yellow
  # fallback: run any scripts that produce results
  if (Test-Path ".\social-media-sentiment-analysis\scripts") {
    Get-ChildItem -Path ".\social-media-sentiment-analysis\scripts" -Filter '*.py' -File | ForEach-Object {
      Write-Host "Running script: $($_.FullName)"
      python $_.FullName
    }
  } else {
    Write-Host "No notebook or scripts found to run. Exiting." -ForegroundColor Red
    exit 1
  }
} else {
  Write-Host "Running notebook via papermill..."
  # run nyalakan kernel explicit
  papermill $projectNb $outputNb --kernel python3
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Papermill failed. Try running nbconvert execute as fallback..." -ForegroundColor Yellow
    python -m nbconvert --to notebook --execute $projectNb --output $outputNb
    if ($LASTEXITCODE -ne 0) { Abort "Notebook execution failed. Inspect errors." }
  }
  Write-Host "Notebook executed, output saved to $outputNb"
}

# 5) list produced files
Write-Host "`nFiles in results (preview):" -ForegroundColor Cyan
Get-ChildItem -Path $resultsDir -File -Recurse | Select-Object FullName,@{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}},LastWriteTime | Sort-Object MB -Descending | Format-Table -AutoSize

# 6) Check for large files (>100MB)
$big = Get-ChildItem -Path $resultsDir -File -Recurse | Where-Object { $_.Length -gt 100MB }
if ($big) {
  Write-Host "`nDetected files >100MB: GitHub won't accept >100MB without LFS." -ForegroundColor Yellow
  $big | Select-Object FullName,@{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize
  if (-not $AutoConfirm) { $useLfs = Read-Host "Enable Git LFS for results folder now? (y/N)" } else { $useLfs = "y" }
} else {
  $useLfs = "n"
}

# 7) Configure Git LFS if chosen
if ($useLfs -match '^[Yy]') {
  if (-not (Get-Command git-lfs -ErrorAction SilentlyContinue)) {
    Write-Host "git-lfs not found in PATH; attempting 'git lfs' command which may still work if installed with Git." -ForegroundColor Yellow
  }
  git lfs install 2>$null
  git lfs track "social-media-sentiment-analysis/results/**" 2>$null
  if (-not (Test-Path ".gitattributes")) { New-Item -Path ".gitattributes" -ItemType File -Force | Out-Null }
  if (-not (Get-Content .gitattributes -Raw | Select-String -Quiet "social-media-sentiment-analysis/results/\*\*")) {
    Add-Content .gitattributes "social-media-sentiment-analysis/results/** filter=lfs diff=lfs merge=lfs -text"
  }
  git add .gitattributes
  git commit -m "chore: track results with git-lfs" 2>$null
}

# 8) Ensure results are not ignored: add negation to .gitignore
if (-not (Test-Path ".gitignore")) { New-Item -Path ".gitignore" -ItemType File -Force | Out-Null }
$gi = Get-Content .gitignore -Raw
$neg1 = "!social-media-sentiment-analysis/results/"
$neg2 = "!social-media-sentiment-analysis/results/**"
if ($gi -notmatch [regex]::Escape($neg1) -and $gi -notmatch [regex]::Escape($neg2)) {
  Add-Content .gitignore "`n# Ensure results are tracked`n$neg1`n$neg2"
  Write-Host "Added negation for results in .gitignore"
}

# 9) Remove tracked virtualenv/cache if present (don't delete local files)
$venvRel = 'social-media-sentiment-analysis/venv'
git ls-files --error-unmatch -- $venvRel 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Removing tracked venv from index..."
  git rm -r --cached -- $venvRel
}
# remove __pycache__/pyc if tracked
git ls-files | Where-Object { $_ -like '*__pycache__*' -or $_ -like '*.pyc' } | ForEach-Object { git rm --cached --ignore-unmatch -- "$_" }

# 10) Stage results and housekeeping files
git add --all -- "social-media-sentiment-analysis/results"
git add .gitignore 2>$null
if (Test-Path .gitattributes) { git add .gitattributes 2>$null }

# 11) Show staged
Write-Host "`nStaged files to commit:"
git diff --cached --name-only

if (-not $AutoConfirm) {
  $msg = Read-Host "Enter commit message (default: 'chore(results): add notebook outputs')"
} else {
  $msg = ""
}
if (-not $msg) { $msg = "chore(results): add notebook outputs" }

git commit -m $msg

# 12) Fetch, rebase (autostash), push
git fetch origin
git pull --rebase --autostash origin $Branch
if ($LASTEXITCODE -ne 0) {
  Write-Host "Pull --rebase failed. Resolve conflicts manually." -ForegroundColor Red
  git status
  exit 1
}

git push origin $Branch
if ($LASTEXITCODE -ne 0) {
  Write-Host "Push failed. If error relates to file size, ensure LFS was used. If push rejected (non-fast-forward) and you are sure, run 'git push --force-with-lease origin $Branch'." -ForegroundColor Red
  exit 1
}

Write-Host "`nDone. Results executed, staged, committed and pushed to origin/$Branch" -ForegroundColor Green
Write-Host "Check results on GitHub: https://github.com/yirassssindaba-coder/python-project/tree/$Branch/$resultsRel"