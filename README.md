<#
.SYNOPSIS
  Safe PowerShell script to set-location to a local project folder, create basic files if missing,
  and perform a safe Git sync (add/commit/fetch + pull --rebase + push) to a remote GitHub repo.

.DESCRIPTION
  This script implements the steps in your "Sinkronisasi Project ke GitHub (PowerShell safe)" document.
  It is idempotent and conservative: it will not force-push or force-add ignored files unless you explicitly ask.
  Use -WhatIf to preview some operations where appropriate.

.PARAMETER RepoDir
  Full path to the local project folder. Default: C:\Users\ASUS\Desktop\python-project-remote

.PARAMETER RepoUrl
  Remote repository URL to set as origin if not set (or different). Default uses the example repo from your doc.

.PARAMETER CommitMessage
  Commit message to use when there are staged changes (default "Initial commit: add project files").

.PARAMETER ForceAddPaths
  Array of paths to force-add even if matched by .gitignore (use sparingly). Example: -ForceAddPaths ".venv" "data/bigfile.zip"

.PARAMETER NoRebase
  If set, script will use `git pull --no-rebase` (merge) instead of `git pull --rebase origin main`.

.EXAMPLE
  pwsh -ExecutionPolicy Bypass -File .\deploy-clean.ps1
  pwsh -ExecutionPolicy Bypass -File .\deploy-clean.ps1 -RepoDir "C:\path\to\repo" -Entrypoint "scripts\run_sentiment.py" -ForceAddPaths ".venv"

.NOTES
  - Run as normal user (no need for Administrator).
  - This script will echo instructions if rebase results in conflicts and will stop; resolve conflicts manually then continue.
#>

param(
    [string]$RepoDir = "C:\Users\ASUS\Desktop\python-project-remote",
    [string]$RepoUrl = "https://github.com/yirassssindaba-coder/myproject.git",
    [string]$CommitMessage = "Initial commit: add project files",
    [string[]]$ForceAddPaths = @(),
    [switch]$NoRebase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = (Get-Date).ToString("s")
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
}

# 1) Validate and Set-Location
if (-not (Test-Path -Path $RepoDir)) {
    Write-Log "RepoDir not found: $RepoDir" "ERROR"
    throw "Directory does not exist: $RepoDir"
}
Set-Location -Path $RepoDir
Write-Log "Working directory: $(Get-Location)"

# 2) Ensure git available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Log "git not found in PATH. Install Git and re-run." "ERROR"
    throw "git not found"
}
Write-Log "git found: $(git --version | Out-String).Trim()"

# 3) Show current git status / remotes
try {
    git status --porcelain 2>$null | Out-Null
} catch {
    Write-Log "Not a git repository yet (no .git). Initializing local repo..." "WARN"
    git init
}

Write-Log "Current remotes:"
git remote -v | ForEach-Object { Write-Log "  $_" }

# 4) Create basic files if missing (README.md, .gitignore, LICENSE)
if (-not (Test-Path README.md)) {
    " # myproject`n`nProject generated on $(Get-Date -Format u)" | Set-Content -Path README.md -Encoding UTF8
    Write-Log "README.md created"
} else { Write-Log "README.md exists" }

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
    Write-Log ".gitignore created"
} else { Write-Log ".gitignore exists" }

if (-not (Test-Path LICENSE)) {
@'
Copyright (c) 1999 Robee

Permission is hereby granted, free of charge, to any person obtaining a copy...
'@ | Set-Content -Path LICENSE -Encoding UTF8
    Write-Log "LICENSE created"
} else { Write-Log "LICENSE exists" }

# 5) Stage changes
Write-Log "Staging all changes..."
git add --all

# 6) Optionally force-add specified ignored paths
if ($ForceAddPaths -and $ForceAddPaths.Count -gt 0) {
    foreach ($p in $ForceAddPaths) {
        Write-Log "Force-adding path: $p"
        git add -f -- $p
    }
}

# 7) Commit if there are changes
$status = git status --porcelain
if ($status -and $status.Trim().Length -gt 0) {
    Write-Log "Changes detected, creating commit..."
    git commit -m $CommitMessage
    Write-Log "Commit created."
} else {
    Write-Log "Nothing to commit (working tree clean)."
}

# 8) Ensure branch main
$currentBranch = (git rev-parse --abbrev-ref HEAD) -replace "`n",""
if ($LASTEXITCODE -ne 0) {
    Write-Log "Unable to determine current branch" "ERROR"
    throw "git rev-parse failed"
}
if ($currentBranch -ne "main") {
    Write-Log "Renaming or switching branch to 'main' (current: $currentBranch)"
    git branch -M main
    Write-Log "Now on branch: main"
} else {
    Write-Log "Already on branch: main"
}

# 9) Configure remote origin
$existingOrigin = $null
try { $existingOrigin = git remote get-url origin 2>$null } catch {}
if ($existingOrigin) {
    Write-Log "Existing origin: $existingOrigin"
    if ($existingOrigin -ne $RepoUrl) {
        Write-Log "Updating origin to: $RepoUrl"
        git remote set-url origin $RepoUrl
    } else {
        Write-Log "Origin already set to target URL."
    }
} else {
    Write-Log "Adding origin: $RepoUrl"
    git remote add origin $RepoUrl
}

# 10) Fetch remote refs
Write-Log "Fetching from origin..."
git fetch origin

# 11) Pull with rebase (or merge if NoRebase specified)
if ($NoRebase) {
    Write-Log "Pulling (merge) from origin/main..."
    $pullOutput = git pull origin main 2>&1
} else {
    Write-Log "Pulling with rebase from origin/main..."
    $pullOutput = git pull --rebase origin main 2>&1
}

if ($LASTEXITCODE -ne 0) {
    Write-Warning "git pull reported an error:"
    Write-Host $pullOutput
    Write-Host ""
    Write-Host "If there are conflicts: resolve them, then run:"
    Write-Host "    git add `"<path-to-resolved-file>`""
    Write-Host "    git rebase --continue   # if you used rebase"
    Write-Host "Or abort rebase with: git rebase --abort"
    throw "Pull failed or rebase produced conflicts. Manual resolution required."
} else {
    Write-Log "Pull/rebase successful."
}

# 12) Push to origin/main (no force)
Write-Log "Pushing to origin main..."
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Log "Push failed. To overwrite remote (risky) use:" "WARN"
    Write-Host "    git push --force-with-lease origin main"
    throw "git push failed"
} else {
    Write-Log "Push succeeded. Repository synchronized."
}

# 13) Final notes to user
Write-Log "Sync complete. Review logs above for details. If you want automatic LFS for large files, run:"
Write-Host "    git lfs install"
Write-Host "    git lfs track \"*.zip\"  # example"
Write-Host "Then commit .gitattributes and push."
