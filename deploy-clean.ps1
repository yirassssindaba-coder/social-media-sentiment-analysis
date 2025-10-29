<#
deploy-clean.ps1
Purpose:
  Keep C:\Users\ASUS\Desktop\python-project-remote synchronized with
  https://github.com/yirassssindaba-coder/myproject.git: add any newly created files/folders,
  commit them (only if there are changes), sync with origin (fetch + rebase) and push to origin/main.
  This script intentionally follows the exact user-approved sequence but hardened so it runs
  repeatedly without PowerShell parsing errors and handles common Git edge cases safely.

Usage:
  - Save to: C:\Users\ASUS\Desktop\python-project-remote\deploy-clean.ps1
  - Run from any PowerShell: & "C:\Users\ASUS\Desktop\python-project-remote\deploy-clean.ps1"
  - Or cd into project and run: .\deploy-clean.ps1

Notes:
  - This script will NOT force-push by default. If remote contains commits you don't have,
    it will attempt a rebase and stop for manual conflict resolution if needed.
  - For HTTPS authentication use a GitHub Personal Access Token when prompted.
  - For SSH set $target to SSH form and ensure your public key is added to GitHub.
#>

# Configuration
$ProjectPath = "C:\Users\ASUS\Desktop\python-project-remote"
$target = "https://github.com/yirassssindaba-coder/myproject.git"   # change to SSH if you'd prefer

function Run-Git {
    param([string[]]$Args)
    $cmdLine = "git " + ($Args -join ' ')
    Write-Host $cmdLine -ForegroundColor DarkGray
    $output = & git @Args 2>&1
    $code = $LASTEXITCODE
    if ($output -is [array]) { $outText = ($output -join "`n") } else { $outText = [string]$output }
    return [pscustomobject]@{ Code = $code; Output = $outText }
}

# Ensure git installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git not found in PATH. Install Git and re-run."
    exit 1
}

# Change to project folder
if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path not found: $ProjectPath"
    exit 1
}
Set-Location -Path $ProjectPath
Write-Host "Working folder: $(Get-Location)" -ForegroundColor Cyan

# Recommend consistent line endings on Windows to avoid repeated warnings
Run-Git -Args @('config', '--local', 'core.autocrlf', 'true') | Out-Null

# Ensure user.name/email set locally (safe defaults)
$userName = Run-Git -Args @('config', '--local', '--get', 'user.name')
if ($userName.Code -ne 0 -or [string]::IsNullOrWhiteSpace($userName.Output)) {
    Run-Git -Args @('config', '--local', 'user.name', 'Robee 1999') | Out-Null
    Run-Git -Args @('config', '--local', 'user.email', 'your-email@example.com') | Out-Null
    Write-Host "Set local git user.name and user.email (edit if needed)." -ForegroundColor Yellow
}

# Create base files if missing (only if absent)
if (-not (Test-Path README.md)) {
    Set-Content -Path README.md -Value "# myproject" -Encoding UTF8
    Write-Host "README.md dibuat"
} else { Write-Host "README.md sudah ada" }

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
    Write-Host ".gitignore dibuat"
} else { Write-Host ".gitignore sudah ada" }

if (-not (Test-Path LICENSE)) {
@'
Copyright (c) 1999 Robee

Permission is hereby granted, free of charge, to any person obtaining a copy...
'@ | Set-Content -Path LICENSE -Encoding UTF8
    Write-Host "LICENSE dibuat"
} else { Write-Host "LICENSE sudah ada" }

# Ensure repository initialized
$inside = Run-Git -Args @('rev-parse','--is-inside-work-tree')
if ($inside.Code -ne 0 -or $inside.Output.Trim() -ne 'true') {
    $init = Run-Git -Args @('init')
    if ($init.Code -ne 0) { Write-Error "git init failed: $($init.Output)"; exit $init.Code }
    Write-Host "Git repository initialized."
} else {
    Write-Host "Git repository detected."
}

# Add all (respect .gitignore) and commit only if there are changes
$add = Run-Git -Args @('add','--all')
if ($add.Code -ne 0) { Write-Warning "git add returned non-zero: $($add.Output)" }

$status = Run-Git -Args @('status','--porcelain')
if ($status.Output -and $status.Output.Trim().Length -gt 0) {
    # Compose informative commit message including timestamp and summary of changed files
    $summary = ($status.Output -split "`n" | Select-Object -First 10) -join "; "
    $msg = "Update: add/modify files - $(Get-Date -Format u)"
    $commit = Run-Git -Args @('commit','-m',$msg)
    if ($commit.Code -ne 0) {
        Write-Error "git commit failed: $($commit.Output)"
        exit $commit.Code
    } else {
        Write-Host "Commit created: $msg"
    }
} else {
    Write-Host "Nothing to commit (working tree clean)."
}

# Ensure current branch is main (safe rename)
$branch = Run-Git -Args @('rev-parse','--abbrev-ref','HEAD')
if ($branch.Code -ne 0) {
    Write-Warning "Cannot determine current branch: $($branch.Output)"
} else {
    $current = $branch.Output.Trim()
    if ($current -ne 'main') {
        $br = Run-Git -Args @('branch','-M','main')
        if ($br.Code -ne 0) { Write-Warning "Could not rename branch to main: $($br.Output)" } else { Write-Host "Branch set to main." }
    } else {
        Write-Host "Already on branch 'main'."
    }
}

# Clean up duplicate branch.main.remote entries if present (avoid multiple values)
$remoteEntries = & git config --local --get-all branch.main.remote 2>$null
if ($LASTEXITCODE -eq 0 -and $remoteEntries) {
    $count = ($remoteEntries -split "`n").Count
    if ($count -gt 1) {
        Write-Host "Multiple branch.main.remote entries found ($count), cleaning up..."
        & git config --local --unset-all branch.main.remote
        & git config --local branch.main.remote origin
        Write-Host "Normalized branch.main.remote to single value 'origin'."
    }
}

# Ensure origin exists and points to target
$remoteGet = Run-Git -Args @('remote','get-url','origin')
if ($remoteGet.Code -eq 0) {
    $existing = $remoteGet.Output.Trim()
    Write-Host "Existing origin: $existing"
    if ($existing -ne $target) {
        $set = Run-Git -Args @('remote','set-url','origin',$target)
        if ($set.Code -ne 0) { Write-Error "Failed to set origin: $($set.Output)"; exit $set.Code }
        Write-Host "Origin updated to $target"
    } else {
        Write-Host "Origin already set to target."
    }
} else {
    $addRemote = Run-Git -Args @('remote','add','origin',$target)
    if ($addRemote.Code -ne 0) { Write-Error "Failed to add origin: $($addRemote.Output)"; exit $addRemote.Code }
    Write-Host "Added origin $target"
}

# Fetch latest refs from origin
$fetch = Run-Git -Args @('fetch','origin')
if ($fetch.Code -ne 0) {
    Write-Warning "git fetch returned non-zero: $($fetch.Output)"
}

# Try to rebase local onto origin/main (safe, keeps history linear)
$pull = Run-Git -Args @('pull','--rebase','origin','main')
if ($pull.Code -ne 0) {
    Write-Warning "git pull --rebase returned non-zero:"
    Write-Host $pull.Output
    Write-Host ""
    Write-Host "If there are conflicts: open the conflicting files, resolve them, then run:"
    Write-Host "  git add <resolved-file>"
    Write-Host "  git rebase --continue"
    Write-Host "Or to abort rebase and return to prior state:"
    Write-Host "  git rebase --abort"
    Write-Host "After resolving, re-run this script or run: git push -u origin main"
    exit $pull.Code
}

# Push to origin/main
$push = Run-Git -Args @('push','-u','origin','main')
if ($push.Code -eq 0) {
    Write-Host "Push succeeded."
    exit 0
} else {
    Write-Warning "git push returned non-zero: $($push.Output)"
    # If push failed because remote contains work, advise safe resolution
    if ($push.Output -match 'fetch first' -or $push.Output -match 'non-fast-forward') {
        Write-Host "Remote contains commits not present locally. Resolve by running:"
        Write-Host "  git fetch origin"
        Write-Host "  git pull --rebase origin main"
        Write-Host "Resolve conflicts if any, then run: git push -u origin main"
    } else {
        Write-Host "If you understand the risks and want to overwrite remote, run:"
        Write-Host "  git push --force-with-lease origin main"
    }
    exit $push.Code
}