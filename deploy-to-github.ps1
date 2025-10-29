<#
.SYNOPSIS
Initialize (if needed), add files, commit, set main branch, set remote (HTTPS or SSH), and push to GitHub.
Usage:
  # HTTPS (default)
  .\deploy-to-github.ps1 -RemoteUrl "https://github.com/yirassssindaba-coder/myproject.git"

  # SSH
  .\deploy-to-github.ps1 -UseSSH

Run this script from inside the project folder: cd "C:\Users\ASUS\Desktop\python-project-remote"
#>

param(
    [string]$RemoteUrl = "https://github.com/yirassssindaba-coder/myproject.git",
    [switch]$UseSSH,
    [switch]$ForceRemoteReplace
)

function Run-Git {
    param([string[]]$Args)
    Write-Host "git $($Args -join ' ')" -ForegroundColor DarkGray
    & git @Args
    return $LASTEXITCODE
}

# Pastikan kita di folder proyek
Write-Host "Current folder: $(Get-Location)"

# Buat file dasar jika belum ada
if (-not (Test-Path README.md)) {
    "## myproject" | Set-Content -Path README.md -Encoding UTF8
    Write-Host "Created README.md"
} else {
    Write-Host "README.md already exists"
}

if (-not (Test-Path .gitignore)) {
@'
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd

# Virtual environments
.venv/
venv/
ENV/
env/
env.bak/

# Packaging
*.egg-info/
dist/
build/

# Environment variables
.env
.env.*

# Jupyter
.ipynb_checkpoints/

# IDEs and editors
.vscode/
.idea/

# Database / system
*.sqlite3
.DS_Store

# Logs
*.log
'@ | Set-Content -Path .gitignore -Encoding UTF8
    Write-Host "Created .gitignore"
} else {
    Write-Host ".gitignore already exists"
}

if (-not (Test-Path LICENSE)) {
@'
Copyright (c) 1999 Robee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
'@ | Set-Content -Path LICENSE -Encoding UTF8
    Write-Host "Created LICENSE"
} else {
    Write-Host "LICENSE already exists"
}

# Init repo if needed
if (-not (Test-Path .git\config)) {
    $rc = Run-Git -Args @('init')
    if ($rc -ne 0) { Write-Error "git init failed (exit $rc)"; exit $rc }
    Write-Host "Initialized new git repository"
} else {
    Write-Host "Git repository already initialized"
}

# Set user identity locally if not set (optional)
if (-not (Run-Git -Args @('config', '--get', 'user.name') ) ) {
    Run-Git -Args @('config', 'user.name', 'Robee 1999') | Out-Null
    Run-Git -Args @('config', 'user.email', 'your-email@example.com') | Out-Null
    Write-Host "Set local git user.name and user.email (change as needed)"
}

# Add and commit
Run-Git -Args @('add', '.')
$commitCode = Run-Git -Args @('commit', '-m', 'Initial commit: add project files')
if ($commitCode -ne 0) {
    # commit failed — likely "nothing to commit" or other error
    if (Test-Path .git) {
        Write-Host "Commit returned exit code $commitCode. Likely nothing to commit or commit failed. Run 'git status' to inspect." -ForegroundColor Yellow
    } else {
        Write-Error "Commit failed with exit code $commitCode"
        exit $commitCode
    }
} else {
    Write-Host "Commit successful."
}

# Ensure main branch name
$rc = Run-Git -Args @('branch', '-M', 'main')
if ($rc -ne 0) {
    Write-Host "Could not rename branch to main (exit $rc). It might already be named main." -ForegroundColor Yellow
} else {
    Write-Host "Branch set to main."
}

# Setup remote
if ($ForceRemoteReplace) {
    Run-Git -Args @('remote', 'remove', 'origin') | Out-Null
    Write-Host "Removed existing origin (forced)."
}

# Remove origin if exists and user wants to replace
if ($UseSSH) {
    $remoteUrl = "git@github.com:yirassssindaba-coder/myproject.git"
} else {
    $remoteUrl = $RemoteUrl
}

# If origin exists, set-url; otherwise add
$remotes = (git remote) 2>$null
if ($remotes -and $remotes -match 'origin') {
    Run-Git -Args @('remote', 'set-url', 'origin', $remoteUrl) | Out-Null
    Write-Host "Updated origin to $remoteUrl"
} else {
    Run-Git -Args @('remote', 'add', 'origin', $remoteUrl) | Out-Null
    Write-Host "Added origin $remoteUrl"
}

# Try to push; if fails, attempt to fetch and rebase then push
$pushCode = Run-Git -Args @('push', '-u', 'origin', 'main')
if ($pushCode -eq 0) {
    Write-Host "Push succeeded."
    exit 0
} else {
    Write-Host "Initial push failed with exit code $pushCode. Trying to fetch & rebase remote main, then push again." -ForegroundColor Yellow
    # fetch
    $fetchCode = Run-Git -Args @('fetch', 'origin')
    if ($fetchCode -ne 0) {
        Write-Warning "git fetch failed (exit $fetchCode). Resolve network/auth issues and try again."
        exit $fetchCode
    }

    # Try rebase on origin/main
    $rebaseCode = Run-Git -Args @('pull', '--rebase', 'origin', 'main')
    if ($rebaseCode -ne 0) {
        Write-Warning "git pull --rebase failed (exit $rebaseCode). You might have to resolve conflicts manually. Run 'git status'."
        exit $rebaseCode
    }

    # Try push again
    $push2Code = Run-Git -Args @('push', '-u', 'origin', 'main')
    if ($push2Code -ne 0) {
        Write-Warning "Second push attempt failed (exit $push2Code). If you understand the consequences, you can force-push: git push -u --force origin main"
        exit $push2Code
    } else {
        Write-Host "Push after rebase succeeded."
        exit 0
    }
}