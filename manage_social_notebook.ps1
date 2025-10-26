<#
PowerShell helper to run the full sequence described by user:
- run from repo root
- sync main, commit tracked changes
- ensure only one notebook in social-media-sentiment-analysis
- create/overwrite single-cell notebook
- remove duplicates, execute notebook, commit outputs
- fix .gitignore and stop tracking venv
Usage:
.\manage_social_notebook.ps1 -RepoRoot "C:\path\to\repo" -RemoteUrl "https://github.com/owner/repo.git" -NonInteractive
#>

param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$RemoteUrl = "",
  [switch]$NonInteractive
)

function Confirm-OrAbort([string]$msg) {
  if ($NonInteractive) { Write-Host "[NonInteractive] $msg"; return $true }
  $r = Read-Host "$msg [y/N]"
  return $r -match '^(y|Y)(es)?$'
}

Set-Location $RepoRoot
Write-Host "Working directory: $(Get-Location)"

# 1) Show git status
git status
git branch --show-current
git remote -v

# 2) Optionally set remote
if ($RemoteUrl -ne "") {
  Write-Host "Setting origin to $RemoteUrl"
  git remote set-url origin $RemoteUrl
  git remote -v
}

# 3) Sync main
git fetch origin
git checkout main
if ($LASTEXITCODE -ne 0) {
  if (git ls-remote --heads origin main) {
    git checkout -B main origin/main
  } else {
    git checkout -B main
  }
}
git pull origin main

# 4) Stage & commit tracked changes
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  if (Confirm-OrAbort "Commit tracked changes with message 'feat: add/update social-media-sentiment-analysis project'?") {
    git commit -m "feat: add/update social-media-sentiment-analysis project"
    git push origin main
  } else { Write-Host "Skipped committing tracked changes." }
} else { Write-Host "No tracked changes." }

# 5) If Untitled1.ipynb exists, rename
$untitled = "social-media-sentiment-analysis\Untitled1.ipynb"
$finalNb = "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb"
if (Test-Path $untitled) {
  if (Confirm-OrAbort "Rename Untitled1.ipynb -> social-media-sentiment-analysis.ipynb and commit?") {
    git mv $untitled $finalNb
    git commit -m "chore: rename Untitled1.ipynb -> social-media-sentiment-analysis.ipynb"
    git push origin main
  } else { Write-Host "Skipped rename." }
} else {
  Write-Host "No Untitled1.ipynb found."
}

# 6) Create/overwrite notebook with create_notebook.py (placed in folder)
$createScript = Join-Path $RepoRoot "social-media-sentiment-analysis\create_notebook.py"
if (-not (Test-Path $createScript)) {
  Write-Host "create_notebook.py not found at $createScript. Please add it to the folder."
} else {
  if (Confirm-OrAbort "Run create_notebook.py to (over)write the final notebook?") {
    python $createScript
    git add $finalNb
    if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
      git commit -m "chore: create social-media-sentiment-analysis.ipynb with requested content"
      git push origin main
    } else { Write-Host "No changes from create_notebook.py to commit." }
  } else { Write-Host "Skipped creating notebook." }
}

# 7) Remove duplicate files commonly found
$dupes = @(
  "social-media-sentiment-analysis\social-media-sentiment-analysis.py",
  "social-media-sentiment-analysis\social_media_sentiment_analysis.py",
  "social-media-sentiment-analysis\Untitled.ipynb",
  "social-media-sentiment-analysis\Untitled1.ipynb"
)
$removedAny = $false
foreach ($f in $dupes) {
  git rm --ignore-unmatch $f 2>$null
  if (Test-Path $f) {
    if (Confirm-OrAbort "Remove local duplicate file $f?") {
      Remove-Item $f -Force -ErrorAction SilentlyContinue
      Write-Host "Removed local file: $f"
      $removedAny = $true
    } else { Write-Host "Kept $f" }
  }
}
git add -A
if ($removedAny -and -not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  if (Confirm-OrAbort "Commit duplicate removals?") {
    git commit -m "chore: remove duplicate files in social-media-sentiment-analysis"
    git push origin main
  } else { Write-Host "Skipped commiting duplicate removals." }
}

# 8) Execute notebook (nbconvert) to persist outputs
if (Confirm-OrAbort "Install nbformat/nbconvert/jupyter/nltk (user) if needed and execute the notebook now?") {
  python -m pip install --user nbformat nbconvert jupyter nltk | Out-Null
  if (Test-Path $finalNb) {
    jupyter nbconvert --to notebook --inplace --execute $finalNb --ExecutePreprocessor.timeout=120
    if ($LASTEXITCODE -ne 0) { Write-Host "nbconvert returned non-zero exit code." }
    git add $finalNb
    if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
      if (Confirm-OrAbort "Commit executed notebook outputs?") {
        git commit -m "chore: execute notebook and record outputs"
        git push origin main
      } else { Write-Host "Skipped committing executed notebook." }
    } else { Write-Host "No output changes to commit." }
  } else { Write-Host "Notebook not found: $finalNb" }
} else { Write-Host "Skipped notebook execution." }

# 9) Fix .gitignore and stop tracking venv
$venvPath = "social-media-sentiment-analysis/venv"
$gitignorePath = ".\.gitignore"
git rm -r --cached --ignore-unmatch $venvPath 2>$null
if (Test-Path ".\gitignore" -PathType Leaf -ErrorAction SilentlyContinue) {
  if (-not (Test-Path $gitignorePath)) {
    Move-Item ".\gitignore" $gitignorePath -Force
  } else { Remove-Item ".\gitignore" -Force }
}
if (-not (Test-Path $gitignorePath)) { New-Item -Path $gitignorePath -ItemType File -Force | Out-Null }
$found = Select-String -Path $gitignorePath -Pattern $venvPath -SimpleMatch -Quiet
if (-not $found) {
  Add-Content -Path $gitignorePath -Value $venvPath
  git add $gitignorePath
  if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
    if (Confirm-OrAbort "Commit .gitignore changes?") {
      git commit -m "chore: add venv to .gitignore and stop tracking venv"
      git push origin main
    }
  }
}

# 10) Remove/ignore rename_notebooks.py helper
$renameHelper = "social-media-sentiment-analysis/rename_notebooks.py"
git rm --ignore-unmatch $renameHelper 2>$null
git add -A
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
  if (Confirm-OrAbort "Commit removal of rename_notebooks.py if tracked?") {
    git commit -m "chore: remove local rename_notebooks helper"
    git push origin main
  }
}
$entry = $renameHelper
if (-not (Select-String -Path $gitignorePath -Pattern $entry -SimpleMatch -Quiet)) {
  if (Confirm-OrAbort "Add rename helper to .gitignore?") {
    Add-Content $gitignorePath $entry
    git add $gitignorePath
    git commit -m "chore: ignore local rename_notebooks helper"
    git push origin main
  }
}

# 11) Final verification
git status
git branch --show-current
git remote -v
Get-ChildItem -Path .\social-media-sentiment-analysis\ -File | Select-Object Name
Write-Host "Script complete."