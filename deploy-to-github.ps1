<#
deploy-to-github.ps1
Safe PowerShell script to initialize (if needed), add files, commit (only if there are changes),
set branch to main, set remote (HTTPS or SSH), and push to origin/main.

Usage examples (run from project folder):
  # HTTPS (default)
  .\deploy-to-github.ps1

  # SSH
  .\deploy-to-github.ps1 -UseSSH

  # Force replace existing origin remote with the chosen URL
  .\deploy-to-github.ps1 -ForceRemoteReplace

This script avoids bash-only operators (||, <<, <) and uses PowerShell-safe constructs.
#>

param(
    [string]$ProjectPath = ".",
    [string]$RemoteUrl = "https://github.com/yirassssindaba-coder/myproject.git",
    [switch]$UseSSH,
    [switch]$ForceRemoteReplace
)

function Run-Git {
    param([string[]]$Args)
    # Compose display string
    $cmdLine = "git " + ($Args -join ' ')
    Write-Host $cmdLine -ForegroundColor DarkGray

    # Run git and capture output and exit code
    $output = & git @Args 2>&1
    $code = $LASTEXITCODE

    # Normalize output to single string
    if ($output -is [array]) {
        $outText = ($output -join "`n")
    } else {
        $outText = [string]$output
    }

    return [pscustomobject]@{ Code = $code; Output = $outText }
}

# Ensure git exists
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git not found in PATH. Install Git or open a shell with git available."
    exit 1
}

# Move to project folder
Set-Location -Path $ProjectPath

Write-Host "Working folder: $(Get-Location)" -ForegroundColor Cyan

# Create base files if missing
if (-not (Test-Path README.md)) {
    "# myproject" | Set-Content -Path README.md -Encoding UTF8
    Write-Host "Created README.md"
} else {
    Write-Host "README.md exists"
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
    Write-Host ".gitignore exists"
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
    Write-Host "LICENSE exists"
}

# Initialize repo if needed
$inside = Run-Git -Args @('rev-parse', '--is-inside-work-tree')
if ($inside.Code -ne 0 -or $inside.Output -notmatch 'true') {
    $r = Run-Git -Args @('init')
    if ($r.Code -ne 0) { Write-Error "git init failed: $($r.Output)"; exit $r.Code }
    Write-Host "Initialized git repository"
} else {
    Write-Host "Git repository already initialized"
}

# Set local user.name/email if not set
$userName = Run-Git -Args @('config', '--get', 'user.name')
if ($userName.Code -ne 0 -or [string]::IsNullOrWhiteSpace($userName.Output)) {
    Run-Git -Args @('config', 'user.name', 'Robee 1999') | Out-Null
    Run-Git -Args @('config', 'user.email', 'your-email@example.com') | Out-Null
    Write-Host "Set local git user.name and user.email (edit if needed)"
} else {
    Write-Host "Local git user.name is: $($userName.Output.Trim())"
}

# Add all files (respect .gitignore)
$rAdd = Run-Git -Args @('add', '--all')
if ($rAdd.Code -ne 0) {
    Write-Warning "git add returned non-zero code: $($rAdd.Output)"
}

# Check if there are changes to commit using porcelain
$status = Run-Git -Args @('status', '--porcelain')
if ($status.Output -and ($status.Output.Trim().Length -gt 0)) {
    $rCommit = Run-Git -Args @('commit', '-m', 'Initial commit: add project files')
    if ($rCommit.Code -ne 0) {
        Write-Error "git commit failed: $($rCommit.Output)"
        exit $rCommit.Code
    } else {
        Write-Host "Commit created."
    }
} else {
    Write-Host "Nothing to commit (working tree clean)."
}

# Ensure current branch is main
# Determine current branch name
$branch = Run-Git -Args @('rev-parse', '--abbrev-ref', 'HEAD')
if ($branch.Code -eq 0) {
    $curBranch = $branch.Output.Trim()
    if ($curBranch -ne 'main') {
        $r = Run-Git -Args @('branch', '-M', 'main')
        if ($r.Code -ne 0) {
            Write-Warning "Could not rename branch to main: $($r.Output)"
        } else {
            Write-Host "Branch renamed to main"
        }
    } else {
        Write-Host "Current branch already 'main'"
    }
} else {
    Write-Warning "Cannot determine current branch: $($branch.Output)"
}

# Remote handling
if ($UseSSH) {
    $targetRemote = "git@github.com:yirassssindaba-coder/myproject.git"
} else {
    $targetRemote = $RemoteUrl
}

# Check if origin exists
$remoteGet = Run-Git -Args @('remote', 'get-url', 'origin')
if ($remoteGet.Code -eq 0) {
    $existing = $remoteGet.Output.Trim()
    Write-Host "Existing origin: $existing"
    if ($ForceRemoteReplace) {
        $r = Run-Git -Args @('remote', 'set-url', 'origin', $targetRemote)
        if ($r.Code -ne 0) { Write-Error "Failed to set origin URL: $($r.Output)"; exit $r.Code }
        Write-Host "Replaced origin with $targetRemote"
    } else {
        Write-Host "Leaving existing origin (use -ForceRemoteReplace to replace)."
    }
} else {
    $r = Run-Git -Args @('remote', 'add', 'origin', $targetRemote)
    if ($r.Code -ne 0) { Write-Error "Failed to add origin: $($r.Output)"; exit $r.Code }
    Write-Host "Added origin $targetRemote"
}

# Push to origin main
$push = Run-Git -Args @('push', '-u', 'origin', 'main')
if ($push.Code -eq 0) {
    Write-Host "Push succeeded."
    exit 0
} else {
    Write-Warning "Initial push failed: $($push.Output)"
    Write-Host "Trying fetch + pull --rebase then push again..."
    $fetch = Run-Git -Args @('fetch', 'origin')
    if ($fetch.Code -ne 0) { Write-Error "git fetch failed: $($fetch.Output)"; exit $fetch.Code }

    $pull = Run-Git -Args @('pull', '--rebase', 'origin', 'main')
    if ($pull.Code -ne 0) {
        Write-Warning "git pull --rebase failed: $($pull.Output)"
        Write-Host "Resolve conflicts manually (git status) then run: git push -u origin main"
        exit $pull.Code
    }

    $push2 = Run-Git -Args @('push', '-u', 'origin', 'main')
    if ($push2.Code -ne 0) {
        Write-Error "Second push attempt failed: $($push2.Output)"
        Write-Host "If you know what you're doing and want to overwrite remote, run:"
        Write-Host "  git push -u --force origin main"
        exit $push2.Code
    } else {
        Write-Host "Push after rebase succeeded."
        exit 0
    }
}