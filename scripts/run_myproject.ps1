<#
.SYNOPSIS
  Setup and run a social-media-sentiment analysis project from GitHub with PowerShell only.

.DESCRIPTION
  - Clones repo (or uses existing clone)
  - Ensures git/python (attempts to install via winget when missing)
  - Creates a venv, installs dependencies (requirements.txt, Pipfile, pyproject.toml)
  - Auto-detects a likely entrypoint script and runs it, storing output in results/
  - Writes logs and handles failures with clear messages

.PARAMETER RepoUrl
  The repository HTTPS URL to clone. Default is the repo from your message.

.PARAMETER Branch
  Branch to checkout (default: main). If branch doesn't exist, tries default branch.

.PARAMETER PythonVersion
  Preferred Python version to ensure (used only when attempting winget install).

.PARAMETER CloneDir
  Local directory name for the repo clone.

.PARAMETER ResultsDir
  Directory where output/results will be placed (created if missing).

.PARAMETER ForceRecreateVenv
  Recreate venv if already exists when set to $true.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\run_myproject.ps1
#>

param(
    [string]$RepoUrl = "https://github.com/yirassssindaba-coder/myproject.git",
    [string]$Branch = "main",
    [string]$PythonVersion = "3.10",
    [string]$CloneDir = "myproject",
    [string]$ResultsDir = "results",
    [switch]$ForceRecreateVenv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message,[string]$Level="INFO")
    $ts = (Get-Date).ToString("s")
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    Add-Content -Path ".\run_myproject.log" -Value $line
}

function Command-Exists {
    param([string]$cmd)
    try {
        $null = Get-Command $cmd -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Try-Install-With-Winget {
    param([string]$packageId)
    if (-not (Command-Exists "winget")) {
        Write-Log "winget not available; cannot install $packageId automatically." "WARN"
        return $false
    }
    try {
        Write-Log "Installing $packageId with winget..."
        winget install --id $packageId --accept-package-agreements --accept-source-agreements -e
        return $true
    } catch {
        Write-Log "winget install failed for $packageId: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

try {
    Remove-Item -Path .\run_myproject.log -ErrorAction SilentlyContinue -Force
} catch {}

Write-Log "START: Setup script for repo $RepoUrl"

# 1) Ensure git exists
if (-not (Command-Exists "git")) {
    Write-Log "git not found on PATH." "WARN"
    if (Try-Install-With-Winget "Git.Git") {
        Write-Log "git installed via winget."
    } else {
        throw "git is required but not installed. Install git and re-run the script."
    }
} else {
    Write-Log "git found."
}

# 2) Clone repository if needed
if (-not (Test-Path -Path $CloneDir)) {
    Write-Log "Cloning repository to .\$CloneDir ..."
    git clone --depth 1 $RepoUrl $CloneDir
    if ($Branch -and $Branch -ne "main") {
        try {
            Push-Location $CloneDir
            git fetch origin $Branch --depth=1
            git checkout $Branch
            Pop-Location
        } catch {
            Write-Log "Could not checkout branch '$Branch'; continuing on default branch." "WARN"
            Pop-Location -ErrorAction SilentlyContinue
        }
    }
} else {
    Write-Log "Directory $CloneDir already exists. Updating remote..."
    Push-Location $CloneDir
    git fetch --all
    git pull --ff-only || Write-Log "git pull failed (non-fatal)." "WARN"
    Pop-Location
}

# 3) Ensure Python exists (prefer system python, otherwise try winget)
$pythonCmd = "python"
if (-not (Command-Exists $pythonCmd)) {
    Write-Log "Python not found on PATH." "WARN"
    # Try winget for python
    if (Try-Install-With-Winget "Python.Python.${PythonVersion}") {
        Write-Log "Python installed via winget. Re-checking PATH..."
    } else {
        # fallback try generic Python.Python
        if (Try-Install-With-Winget "Python.Python") {
            Write-Log "Python installed via winget generic id."
        } else {
            throw "Python is required but not installed and automatic install failed. Install Python $PythonVersion and re-run."
        }
    }
}

# Re-resolve python path
try {
    $pyCmdInfo = Get-Command python -ErrorAction Stop
    $systemPython = $pyCmdInfo.Path
    Write-Log "Using Python executable: $systemPython"
} catch {
    throw "Python not found even after attempted install."
}

# 4) Enter repo
Push-Location $CloneDir

# 5) Virtualenv path
$venvPath = Join-Path -Path (Get-Location) -ChildPath ".venv"

if (Test-Path $venvPath) {
    if ($ForceRecreateVenv) {
        Write-Log "Removing existing venv because ForceRecreateVenv specified..."
        Remove-Item -Recurse -Force -Path $venvPath
    } else {
        Write-Log "Virtual environment already exists at $venvPath"
    }
}

# 6) Create venv if missing
if (-not (Test-Path $venvPath)) {
    Write-Log "Creating virtual environment at $venvPath ..."
    & $systemPython -m venv $venvPath
    if (-not (Test-Path $venvPath)) {
        throw "Failed to create virtual environment at $venvPath"
    }
} 

# 7) Determine python inside venv and pip
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$venvPip = Join-Path $venvPath "Scripts\pip.exe"
if (-not (Test-Path $venvPython)) {
    throw "Venv python not found at $venvPython"
}
Write-Log "Using venv python: $venvPython"

# Upgrade pip
Write-Log "Upgrading pip in venv..."
& $venvPython -m pip install --upgrade pip setuptools wheel | Tee-Object -Variable pipoutput | Out-Null

# 8) Detect dependency file(s)
$requirements = @()
if (Test-Path "requirements.txt") { $requirements += "requirements.txt" }
if (Test-Path "Pipfile") { $requirements += "Pipfile" }
if (Test-Path "pyproject.toml") { $requirements += "pyproject.toml" }
if (Test-Path "environment.yml") { $requirements += "environment.yml" }

if ($requirements.Count -eq 0) {
    Write-Log "No dependency file found (requirements.txt / Pipfile / pyproject.toml / environment.yml)." "WARN"
    Write-Log "Continuing without installing project dependencies — may fail if dependencies are required."
} else {
    Write-Log "Found dependency files: $($requirements -join ', ')"
    if ($requirements -contains "requirements.txt") {
        Write-Log "Installing from requirements.txt..."
        & $venvPip install -r "requirements.txt" 2>&1 | Tee-Object -Variable pip_install_out | Out-Null
    } elseif ($requirements -contains "Pipfile") {
        Write-Log "Pipfile detected — installing pipenv and dependencies..."
        & $venvPip install pipenv
        if (Command-Exists "pipenv") {
            & pipenv install --deploy --ignore-pipfile
        } else {
            Write-Log "pipenv not available in PATH; attempting pipenv via venv..."
            & $venvPython -m pipenv install --deploy --ignore-pipfile
        }
    } elseif ($requirements -contains "pyproject.toml") {
        Write-Log "pyproject.toml detected — attempting to install project in editable mode..."
        & $venvPip install -e .
    } elseif ($requirements -contains "environment.yml") {
        Write-Log "environment.yml detected. This script does not manage conda installs. Please create an environment manually or provide requirements.txt."
    }
}

# 9) Find candidate entrypoint scripts (common names)
Write-Log "Searching for likely entrypoint scripts..."
$patterns = @("scripts\run_sentiment.py","scripts\run.py","scripts\run_sentiment*.py","run_sentiment.py","run.py","main.py","app.py","src\main.py","analyze.py","analyse.py","sentiment.py","sentiment_analysis.py")
$candidates = @()

foreach ($p in $patterns) {
    $found = Get-ChildItem -Path . -Recurse -File -Include $p -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -Unique
    if ($found) { $candidates += $found }
}

# As fallback, find any python files under scripts/ or top-level
if ($candidates.Count -eq 0) {
    $scriptsDir = Join-Path (Get-Location) "scripts"
    if (Test-Path $scriptsDir) {
        $candidates += Get-ChildItem -Path $scriptsDir -Filter *.py -File -Recurse | Select-Object -ExpandProperty FullName
    }
}
if ($candidates.Count -eq 0) {
    $candidates += Get-ChildItem -Path . -Filter *.py -File -Recurse | Select-Object -ExpandProperty FullName | Where-Object { $_ -notmatch "\\.venv\\" } | Select-Object -First 10
}

if ($candidates.Count -eq 0) {
    Write-Log "No Python scripts found to run. Please provide the path to the main script (e.g. scripts/run_sentiment.py)." "ERROR"
    Pop-Location
    throw "No entrypoint scripts found."
}

Write-Log "Candidate scripts found:"
for ($i=0; $i -lt $candidates.Count; $i++) {
    Write-Host " [$i] $($candidates[$i])"
    Add-Content -Path ".\run_myproject.log" -Value "[$i] $($candidates[$i])"
}

# Choose first candidate by default
$entrypoint = $candidates[0]
Write-Log "Selected entrypoint: $entrypoint (first candidate). If this is wrong, re-run script with explicit editing or tell me the exact path."

# Ensure results dir exists
$absResults = Join-Path (Get-Location) $ResultsDir
if (-not (Test-Path $absResults)) { New-Item -ItemType Directory -Path $absResults | Out-Null }
Write-Log "Results will be stored in: $absResults"

# 10) Run entrypoint. Try with --output if it likely accepts it, otherwise fallback to no-args.
$runLogFile = Join-Path (Get-Location) "run_execution.log"
Remove-Item -Path $runLogFile -ErrorAction SilentlyContinue -Force

$attempts = @()
$success = $false

# Attempt 1: common --output argument
try {
    Write-Log "Attempting to run: python $entrypoint --output $absResults"
    & $venvPython $entrypoint --output $absResults *> $runLogFile 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Script finished successfully with --output argument."
        $success = $true
    } else {
        Write-Log "Script returned exit code $LASTEXITCODE for --output attempt." "WARN"
    }
} catch {
    Write-Log "Attempt with --output failed: $($_.Exception.Message)" "WARN"
}

# Attempt 2: run without args (if first failed)
if (-not $success) {
    try {
        Write-Log "Attempting to run: python $entrypoint (no args)"
        & $venvPython $entrypoint *> $runLogFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Script finished successfully without args."
            $success = $true
        } else {
            Write-Log "Script returned exit code $LASTEXITCODE for no-args attempt." "WARN"
        }
    } catch {
        Write-Log "Attempt without args failed: $($_.Exception.Message)" "ERROR"
    }
}

if ($success) {
    Write-Log "Execution completed successfully. Check $absResults for outputs and run_execution.log for details."
} else {
    Write-Log "Both execution attempts failed. See run_execution.log and run_myproject.log for details." "ERROR"
    Write-Host "---- Execution log (tail) ----"
    if (Test-Path $runLogFile) {
        Get-Content $runLogFile -Tail 200
    } else {
        Write-Host "(no run log produced)"
    }
    Pop-Location
    throw "Script execution failed. Inspect run_execution.log and run_myproject.log"
}

# leave repo dir
Pop-Location

Write-Log "END: run_myproject.ps1 completed."