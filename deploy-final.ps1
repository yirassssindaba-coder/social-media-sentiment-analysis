<#
deploy-final.ps1
Purpose:
  Safely add/commit/push all files in C:\Users\ASUS\Desktop\python-project-remote to the remote
  repository (default https://github.com/yirassssindaba-coder/myproject.git).
  This script is idempotent and intended to be run whenever you add or change files locally.
  It will:
    - ensure Git is available
    - change to the project folder
    - create README/.gitignore/LICENSE if missing
    - init the repo if needed
    - set sensible local git config (user.name/email, core.autocrlf)
    - stage all changes, commit only if there are changes
    - ensure branch is 'main'
    - ensure origin remote is set to your repo URL
    - fetch + rebase from origin/main, then push to origin/main
Usage:
  - Save this file to:
      C:\Users\ASUS\Desktop\python-project-remote\deploy-final.ps1
  - Run from PowerShell:
      powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\deploy-final.ps1"
  - Or cd into the project and run:
      .\deploy-final.ps1
Notes:
  - The script will NOT force-push. If remote contains commits you don't have, the script will
    attempt a safe rebase and stop for manual conflict resolution when necessary.
  - For HTTPS authentication use a GitHub Personal Access Token (PAT) as your password when prompted.
  - For SSH set $UseSSH = $true and add your public SSH key to GitHub.
#>

# --- Configuration: change only if you must ---
$ProjectPath = "C:\Users\ASUS\Desktop\python-project-remote"
$RemoteHttps = "https://github.com/yirassssindaba-coder/myproject.git"
$UseSSH = $false    # set to $true if you want to use SSH
if ($UseSSH) { $target = "git@github.com:yirassssindaba-coder/myproject.git" } else { $target = $RemoteHttps }

# --- Helper: run git safely and return output + exit code ---
function Run-Git {
    param([string[]]$Args)
    $cmd = "git " + ($Args -join ' ')
    Write-Host $cmd -ForegroundColor DarkGray
    $output = & git @Args 2>&1
    $code = $LASTEXITCODE
    if ($output -is [array]) { $outText = ($output -join "`n") } else { $outText = [string]$output }
    return @{ Code = $code; Output = $outText }
}

# --- 1) Preconditions ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git tidak ditemukan di PATH. Install Git dan jalankan ulang."
    exit 1
}

if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path tidak ditemukan: $ProjectPath"
    exit 1
}

Set-Location -Path $ProjectPath
Write-Host "Working folder: $(Get-Location)" -ForegroundColor Cyan

# Recommend consistent CRLF behaviour on Windows
& git config --local core.autocrlf true 2>$null

# Ensure local user.name/email are set (only local config)
$userNameCheck = Run-Git -Args @('config','--local','--get','user.name')
if ($userNameCheck.Code -ne 0 -or [string]::IsNullOrWhiteSpace($userNameCheck.Output)) {
    & git config --local user.name "Robee 1999"
    & git config --local user.email "your-email@example.com"
    Write-Host "Set local git user.name and user.email (edit if needed)." -ForegroundColor Yellow
} else {
    Write-Host "Local git user.name is: $($userNameCheck.Output.Trim())"
}

# --- 2) Create base files if they don't exist (no overwrite) ---
if (-not (Test-Path README.md)) {
    Set-Content -Path README.md -Value "# myproject" -Encoding UTF8
    Write-Host "Created README.md"
} else { Write-Host "README.md already exists" }

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
    Write-Host "Created .gitignore"
} else { Write-Host ".gitignore already exists" }

if (-not (Test-Path LICENSE)) {
@'
Copyright (c) 1999 Robee

Permission is hereby granted, free of charge, to any person obtaining a copy...
'@ | Set-Content -Path LICENSE -Encoding UTF8
    Write-Host "Created LICENSE"
} else { Write-Host "LICENSE already exists" }

# --- 3) Initialize repo if needed ---
$inside = Run-Git -Args @('rev-parse','--is-inside-work-tree')
if ($inside.Code -ne 0 -or $inside.Output.Trim() -ne 'true') {
    $r = Run-Git -Args @('init')
    if ($r.Code -ne 0) {
        Write-Error "git init failed: $($r.Output)"
        exit $r.Code
    } else {
        Write-Host "Initialized empty git repository."
    }
} else {
    Write-Host "Already inside a git repository."
}

# --- 4) Stage all changes (respect .gitignore) ---
$add = Run-Git -Args @('add','--all')
if ($add.Code -ne 0) {
    Write-Warning "git add returned non-zero: $($add.Output)"
} else {
    Write-Host "Staged all changes."
}

# --- 5) Commit only if there are changes ---
$status = Run-Git -Args @('status','--porcelain')
if ($status.Output -and $status.Output.Trim().Length -gt 0) {
    $summaryLines = ($status.Output -split "`n" | Select-Object -First 20) -join "; "
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

# --- 6) Ensure branch 'main' ---
$branch = Run-Git -Args @('rev-parse','--abbrev-ref','HEAD')
if ($branch.Code -ne 0) {
    Write-Warning "Cannot determine current branch: $($branch.Output)"
} else {
    $cur = $branch.Output.Trim()
    if ($cur -ne 'main') {
        $br = Run-Git -Args @('branch','-M','main')
        if ($br.Code -ne 0) { Write-Warning "Failed to rename branch to main: $($br.Output)" } else { Write-Host "Branch set to main." }
    } else {
        Write-Host "Already on branch 'main'."
    }
}

# --- 7) Normalize duplicate branch.main.remote entries (if any) ---
$remoteEntriesRaw = & git config --local --get-all branch.main.remote 2>$null
if ($LASTEXITCODE -eq 0 -and $remoteEntriesRaw) {
    $entries = $remoteEntriesRaw -split "`n"
    if ($entries.Count -gt 1) {
        Write-Host "Multiple branch.main.remote entries found ($($entries.Count)) - normalizing to 'origin'..."
        & git config --local --unset-all branch.main.remote
        & git config --local branch.main.remote origin
        Write-Host "Normalized branch.main.remote to 'origin'."
    }
}

# --- 8) Ensure origin remote points to target ---
$remoteGet = Run-Git -Args @('remote','get-url','origin')
if ($remoteGet.Code -eq 0) {
    $existing = $remoteGet.Output.Trim()
    Write-Host "Existing origin: $existing"
    if ($existing -ne $target) {
        $set = Run-Git -Args @('remote','set-url','origin',$target)
        if ($set.Code -ne 0) { Write-Error "Failed to set origin: $($set.Output)"; exit $set.Code } else { Write-Host "Origin updated to $target" }
    } else {
        Write-Host "Origin already set to target."
    }
} else {
    $addRemote = Run-Git -Args @('remote','add','origin',$target)
    if ($addRemote.Code -ne 0) { Write-Error "Failed to add origin: $($addRemote.Output)"; exit $addRemote.Code } else { Write-Host "Added origin $target" }
}

# --- 9) Fetch + rebase + push ---
$fetch = Run-Git -Args @('fetch','origin')
if ($fetch.Code -ne 0) { Write-Warning "git fetch returned non-zero: $($fetch.Output)" } else { Write-Host "Fetched origin." }

$pull = Run-Git -Args @('pull','--rebase','origin','main')
if ($pull.Code -ne 0) {
    Write-Warning "git pull --rebase returned non-zero:"
    Write-Host $pull.Output
    Write-Host ""
    Write-Host "If there are conflicts: open files listed by git, resolve, then run:"
    Write-Host "  git add <resolved-file>"
    Write-Host "  git rebase --continue"
    Write-Host "Or abort rebase with:"
    Write-Host "  git rebase --abort"
    Write-Host "After resolving and finishing rebase, run: git push -u origin main"
    exit $pull.Code
} else {
    Write-Host "Pull/rebase succeeded."
}

$push = Run-Git -Args @('push','-u','origin','main')
if ($push.Code -ne 0) {
    Write-Warning "git push returned non-zero: $($push.Output)"
    if ($push.Output -match 'fetch first' -or $push.Output -match 'non-fast-forward' -or $push.Output -match 'rejected') {
        Write-Host "Remote contains commits you don't have. Resolve by running:"
        Write-Host "  git fetch origin"
        Write-Host "  git pull --rebase origin main"
        Write-Host "Resolve conflicts if any, then run: git push -u origin main"
    } else {
        Write-Host "If you know what you're doing and want to overwrite remote, run:"
        Write-Host "  git push --force-with-lease origin main"
    }
    exit $push.Code
} else {
    Write-Host "Push succeeded. All changes pushed to origin/main." -ForegroundColor Green
}

# --- End ---
Write-Host "deploy-final.ps1 finished successfully."