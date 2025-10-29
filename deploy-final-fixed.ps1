<#
deploy-final-fixed.ps1
Safe, copy-paste PowerShell script to add/commit/push all files in:
C:\Users\ASUS\Desktop\python-project-remote

What it does (summary)
- Ensures git is installed and changes to the project folder.
- Creates README.md, .gitignore, LICENSE if missing.
- Initializes repo if needed.
- Sets local git user.name/email if missing.
- Stages all changes and commits only if there are changes.
- Ensures branch is 'main'.
- Ensures origin remote is set to your target URL (HTTPS by default).
- Fetches origin, checks divergence, attempts a safe rebase if remote has commits,
  otherwise pushes local commits to origin/main.
- If a rebase results in conflicts, it prints the list of conflicting files and exact
  commands to resolve them (no placeholder angle brackets).

Usage
- Save to: C:\Users\ASUS\Desktop\python-project-remote\deploy-final-fixed.ps1
- Run from PowerShell:
    powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\deploy-final-fixed.ps1"
  or:
    cd "C:\Users\ASUS\Desktop\python-project-remote"
    .\deploy-final-fixed.ps1
#>

# --- Configuration (edit only if you must) ---
$ProjectPath = "C:\Users\ASUS\Desktop\python-project-remote"
$RemoteHttps = "https://github.com/yirassssindaba-coder/myproject.git"
$UseSSH = $false    # Set to $true to use SSH instead of HTTPS
if ($UseSSH) { $target = "git@github.com:yirassssindaba-coder/myproject.git" } else { $target = $RemoteHttps }

# --- Helpers ---
function Run-Command {
    param([string[]]$Cmd)
    # Run command array with & and capture stdout/stderr and exit code
    $output = & @Cmd 2>&1
    $code = $LASTEXITCODE
    if ($output -is [array]) { $text = ($output -join "`n") } else { $text = [string]$output }
    return @{ Code = $code ; Output = $text }
}

# Print and run a git subcommand (array form)
function Run-Git {
    param([string[]]$Args)
    $full = @('git') + $Args
    Write-Host "Running: git $($Args -join ' ')" -ForegroundColor DarkGray
    return Run-Command -Cmd $full
}

# --- 0) Preconditions ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git not found in PATH. Install Git and re-run this script."
    exit 1
}

if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path not found: $ProjectPath"
    exit 1
}

Set-Location -Path $ProjectPath
Write-Host "Working folder: $(Get-Location)" -ForegroundColor Cyan

# Recommend consistent CRLF behaviour on Windows
& git config --local core.autocrlf true 2>$null | Out-Null

# --- 1) Create base files if not present ---
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

# --- 2) Initialize git repo if needed ---
$inside = Run-Git -Args @('rev-parse','--is-inside-work-tree')
if ($inside.Code -ne 0 -or $inside.Output.Trim() -ne 'true') {
    Write-Host "Not inside a git repository. Running git init..."
    $init = Run-Git -Args @('init')
    if ($init.Code -ne 0) {
        Write-Error "git init failed: $($init.Output)"
        exit $init.Code
    } else {
        Write-Host "git init succeeded."
    }
} else {
    Write-Host "Inside an existing git repository."
}

# --- 3) Ensure local user.name/email (local config) ---
$userName = Run-Git -Args @('config','--local','--get','user.name')
if ($userName.Code -ne 0 -or [string]::IsNullOrWhiteSpace($userName.Output)) {
    Run-Git -Args @('config','--local','user.name','Robee 1999') | Out-Null
    Run-Git -Args @('config','--local','user.email','your-email@example.com') | Out-Null
    Write-Host "Set local git user.name and user.email (edit if needed)." -ForegroundColor Yellow
} else {
    Write-Host "Local git user.name is: $($userName.Output.Trim())"
}

# --- 4) Stage all changes ---
$add = Run-Git -Args @('add','--all')
if ($add.Code -ne 0) {
    Write-Warning "git add returned non-zero: $($add.Output)"
} else {
    Write-Host "Staged all changes."
}

# --- 5) Commit only if there are changes ---
$status = Run-Git -Args @('status','--porcelain')
if ($status.Output -and $status.Output.Trim().Length -gt 0) {
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
        $ren = Run-Git -Args @('branch','-M','main')
        if ($ren.Code -ne 0) {
            Write-Warning "Failed to rename branch to main: $($ren.Output)"
        } else {
            Write-Host "Branch renamed to main."
        }
    } else {
        Write-Host "Already on branch 'main'."
    }
}

# --- 7) Normalize duplicate branch.main.remote values (if present) ---
$remoteEntries = & git config --local --get-all branch.main.remote 2>$null
if ($LASTEXITCODE -eq 0 -and $remoteEntries) {
    $list = $remoteEntries -split "`n"
    if ($list.Count -gt 1) {
        Write-Host "Multiple branch.main.remote entries found ($($list.Count)), normalizing..."
        & git config --local --unset-all branch.main.remote
        & git config --local branch.main.remote origin
        Write-Host "Normalized branch.main.remote to 'origin'."
    }
}

# --- 8) Ensure remote origin is set correctly ---
$remoteGet = Run-Git -Args @('remote','get-url','origin')
if ($remoteGet.Code -eq 0) {
    $existing = $remoteGet.Output.Trim()
    Write-Host "Existing origin: $existing"
    if ($existing -ne $target) {
        Write-Host "Updating origin to: $target"
        $setUrl = Run-Git -Args @('remote','set-url','origin',$target)
        if ($setUrl.Code -ne 0) { Write-Error "Failed to set origin: $($setUrl.Output)"; exit $setUrl.Code }
    } else {
        Write-Host "Origin already set to target."
    }
} else {
    Write-Host "Adding origin: $target"
    $addRemote = Run-Git -Args @('remote','add','origin',$target)
    if ($addRemote.Code -ne 0) { Write-Error "Failed to add origin: $($addRemote.Output)"; exit $addRemote.Code }
}

# --- 9) Fetch origin ---
$fetch = Run-Git -Args @('fetch','origin')
if ($fetch.Code -ne 0) {
    Write-Warning "git fetch returned non-zero: $($fetch.Output)"
} else {
    Write-Host "Fetched origin."
}

# --- 10) Check divergence and decide action ---
# Try to get counts of commits unique to origin/main and unique to local main.
$revlist = Run-Git -Args @('rev-list','--left-right','--count','origin/main...main')
if ($revlist.Code -eq 0) {
    $parts = $revlist.Output.Trim() -split '\s+'
    if ($parts.Count -eq 2) {
        $originOnly = [int]$parts[0]   # commits only in origin/main
        $localOnly  = [int]$parts[1]   # commits only in local main
        Write-Host "Commits (origin-only, local-only): $originOnly, $localOnly"
        if ($originOnly -gt 0) {
            Write-Host "Remote has commits you don't have. Attempting 'git pull --rebase origin main'..."
            $pull = Run-Git -Args @('pull','--rebase','origin','main')
            if ($pull.Code -ne 0) {
                Write-Warning "git pull --rebase stopped with errors:"
                Write-Host $pull.Output
                # Show conflicting files (if any)
                $conflicts = & git status --porcelain 2>$null | Select-String -Pattern '^[U|A|D|M|R]{1,2}' -SimpleMatch
                if ($conflicts) {
                    Write-Host ""
                    Write-Host "Conflicting or unmerged files (from 'git status --porcelain'):"
                    & git status --porcelain
                    Write-Host ""
                    Write-Host "To resolve conflicts, for each file shown as unmerged run these commands:"
                    Write-Host "  git add <path-to-conflicted-file>"
                    Write-Host "  git rebase --continue"
                    Write-Host "If you want to abort rebase and return to the previous state:"
                    Write-Host "  git rebase --abort"
                } else {
                    Write-Host "No unmerged files shown by 'git status --porcelain'. Inspect the pull output above."
                }
                exit $pull.Code
            } else {
                Write-Host "Rebase completed successfully."
            }
        } else {
            Write-Host "No remote-only commits detected; safe to push local changes (if any)."
        }
    } else {
        Write-Warning "Unexpected output from rev-list: $($revlist.Output)"
    }
} else {
    Write-Warning "Cannot run rev-list or origin/main might not exist yet. Proceeding to push attempt."
}

# --- 11) Push to origin/main ---
$push = Run-Git -Args @('push','-u','origin','main')
if ($push.Code -ne 0) {
    Write-Warning "git push returned non-zero: $($push.Output)"
    if ($push.Output -match 'fetch first' -or $push.Output -match 'non-fast-forward' -or $push.Output -match 'rejected') {
        Write-Host "Push was rejected because remote contains commits not present locally."
        Write-Host "Recommended safe steps (run these manually):"
        Write-Host "  git fetch origin"
        Write-Host "  git pull --rebase origin main"
        Write-Host "  (resolve conflicts if any, then) git push -u origin main"
    } else {
        Write-Host "If you truly want to overwrite remote (risky): git push --force-with-lease origin main"
    }
    exit $push.Code
} else {
    Write-Host "Push succeeded. All changes are on origin/main." -ForegroundColor Green
}

Write-Host "Done."