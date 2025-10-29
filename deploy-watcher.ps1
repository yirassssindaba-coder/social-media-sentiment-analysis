# deploy-watcher.ps1
# Watcher: otomatis git add/commit/pull(rebase)/push saat ada perubahan di folder proyek.
# Save to: C:\Users\ASUS\Desktop\python-project-remote\deploy-watcher.ps1
# Run: powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\deploy-watcher.ps1"

$ProjectPath = "C:\Users\ASUS\Desktop\python-project-remote"
$LogFile = Join-Path $ProjectPath "deploy-watcher.log"
$DebounceSeconds = 5

function Log($text) {
    $time = (Get-Date).ToString("u")
    "$time `t $text" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    Write-Host $text
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git not found in PATH. Install Git first."
    exit 1
}
if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path not found: $ProjectPath"
    exit 1
}

Set-Location -Path $ProjectPath
Log "Starting deploy-watcher on $ProjectPath"

# debounce timer
$lastEvent = Get-Date
$timer = $null

# function to sync repo
function Sync-Git {
    Log "==== Sync-Git START ===="
    # stage everything (gitignore will still exclude ignored files)
    git add --all 2>&1 | Out-String | ForEach-Object { Log $_.Trim() }

    $status = git status --porcelain
    if ($status -and $status.Trim().Length -gt 0) {
        $msg = "Auto: sync changes - $(Get-Date -Format u)"
        git commit -m $msg 2>&1 | Out-String | ForEach-Object { Log $_.Trim() }
        Log "Committed changes."
    } else {
        Log "No changes to commit."
    }

    # fetch & rebase (safe)
    git fetch origin 2>&1 | Out-String | ForEach-Object { Log $_.Trim() }
    $pull = git pull --rebase origin main 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "git pull --rebase returned non-zero:"
        $pull | Out-String | ForEach-Object { Log $_.Trim() }
        Log "Stop automatic push. Resolve conflicts manually and then run 'git rebase --continue' and 'git push -u origin main'."
        return
    } else {
        Log "Pull/rebase OK."
    }

    # push
    git push -u origin main 2>&1 | Out-String | ForEach-Object { Log $_.Trim() }
    if ($LASTEXITCODE -eq 0) {
        Log "Push succeeded."
    } else {
        Log "Push failed or rejected. See above output. You may need to run: git fetch origin; git pull --rebase origin main; resolve; git push"
    }
    Log "==== Sync-Git END ===="
}

# FileSystemWatcher
$fsw = New-Object System.IO.FileSystemWatcher $ProjectPath -Property @{
    IncludeSubdirectories = $true
    NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, DirectoryName'
    Filter = '*.*'
}

$onChange = {
    $global:lastEvent = Get-Date
    if ($timer -ne $null) {
        # reset timer
        $null = $timer.Dispose()
    }
    # create a new timer to run Sync-Git after debounce seconds without new events
    $timer = [System.Timers.Timer]::new($DebounceSeconds * 1000)
    $timer.AutoReset = $false
    $timer.add_Elapsed({
        try {
            Sync-Git
        } catch {
            Log "Error in Sync-Git: $_"
        } finally {
            $timer.Dispose()
            $timer = $null
        }
    })
    $timer.Start()
    Log "Filesystem change detected. Debouncing for $DebounceSeconds seconds..."
}

# Register events
$createdReg = Register-ObjectEvent $fsw Created -Action $onChange
$changedReg = Register-ObjectEvent $fsw Changed -Action $onChange
$deletedReg = Register-ObjectEvent $fsw Deleted -Action $onChange
$renamedReg = Register-ObjectEvent $fsw Renamed -Action $onChange

# Start watcher
$fsw.EnableRaisingEvents = $true
Log "Watcher is running. Press Ctrl+C to stop."

# Keep script running until Ctrl+C
try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    # cleanup
    Unregister-Event -SourceIdentifier $createdReg.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $changedReg.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $deletedReg.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $renamedReg.Name -ErrorAction SilentlyContinue
    $fsw.Dispose()
    Log "Watcher stopped."
}