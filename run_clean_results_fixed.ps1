<#
Run this from repo root (C:\Users\ASUS\Desktop\python-project)
Purpose: keep one CSV/HTML/XLSX in social-media-sentiment-analysis/results (prefer 'consolidated' or newest),
move other tracked results to external backup, stage deletions, commit & push.
#>

# ---------- Configuration ----------
$repoRoot = (Get-Location).Path
$resultsRel = 'social-media-sentiment-analysis/results'
$results = Join-Path $repoRoot $resultsRel

# ---------- Safety checks ----------
if (-not (Test-Path $results)) {
  Write-Host "Folder results not found: $results" -ForegroundColor Red
  return
}
if (Test-Path .git\rebase-merge) {
  Write-Host "Interactive rebase detected. Resolve (git rebase --continue or --abort) before running this script." -ForegroundColor Yellow
  return
}

# ---------- external backup ----------
$stamp = Get-Date -Format yyyyMMdd_HHmmss
$extBackup = Join-Path $env:USERPROFILE ("Desktop\results_external_backup_$stamp")
New-Item -ItemType Directory -Path $extBackup -Force | Out-Null
Write-Host "External backup: $extBackup"

# ---------- get tracked files under results ----------
$tracked = git ls-files -- "$resultsRel/**" 2>$null | ForEach-Object { $_.Trim() }
if (-not $tracked) { Write-Host "No tracked files under $resultsRel (nothing to change)." -ForegroundColor Yellow }

# ---------- helper: select one file to keep per extension ----------
function Select-Keep {
  param(
    [string[]]$trackedList,
    [string]$ext
  )
  if (-not $trackedList) { return $null }

  # Find tracked files matching extension (git ls-files returns paths with '/')
  $pattern = "*.$ext"
  $matches = $trackedList | Where-Object { $_ -like $pattern }
  if (-not $matches) { return $null }

  # Prefer filenames containing 'consolidated' (case-insensitive)
  $preferred = $matches | Where-Object { $_ -match '(?i)consolidated' }
  if ($preferred) { $candidates = $preferred } else { $candidates = $matches }

  # Map to FileInfo to compare LastWriteTime
  $items = $candidates | ForEach-Object {
    $path = Join-Path $repoRoot $_
    if (Test-Path $path) { Get-Item $path } else { $null }
  } | Where-Object { $_ -ne $null } | Sort-Object LastWriteTime -Descending

  if ($items) {
    $full = $items[0].FullName
    $rel = $full.Substring($repoRoot.Length).TrimStart('\','/')
    return ($rel -replace '\\','/')
  } else {
    return $null
  }
}

# ---------- select keep files ----------
$csvKeep  = Select-Keep -trackedList $tracked -ext 'csv'
$htmlKeep = Select-Keep -trackedList $tracked -ext 'html'
$xlsxKeep = Select-Keep -trackedList $tracked -ext 'xlsx'
if (-not $xlsxKeep) { $xlsxKeep = Select-Keep -trackedList $tracked -ext 'xls' }

$keep = @()
if ($csvKeep)  { $keep += $csvKeep }
if ($htmlKeep) { $keep += $htmlKeep }
if ($xlsxKeep) { $keep += $xlsxKeep }

Write-Host "Will keep (relative git paths):" -ForegroundColor Cyan
if ($keep) { $keep | ForEach-Object { Write-Host " - $_" } } else { Write-Host " (none selected)" -ForegroundColor Yellow }

# ---------- move tracked files NOT in keep to external backup ----------
$toMove = $tracked | Where-Object { $keep -notcontains $_ }
if (-not $toMove) {
  Write-Host "No tracked files to remove from results." -ForegroundColor Green
} else {
  foreach ($rel in $toMove) {
    $src = Join-Path $repoRoot ($rel -replace '/','\')
    if (-not (Test-Path $src)) {
      Write-Host "Source not found (skipping): $src" -ForegroundColor Yellow
      continue
    }
    $dest = Join-Path $extBackup ($rel -replace '/','\')
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Move-Item -LiteralPath $src -Destination $dest -Force
    Write-Host "Moved: $rel -> $dest"
  }
}

# ---------- Stage deletions/additions and commit ----------
if (Test-Path ".gitignore") { git add .gitignore 2>$null }
git add --all -- $resultsRel

Write-Host "`nStaged changes preview:"
git diff --cached --name-status

git commit -m "chore(results): keep one CSV/HTML/XLSX; move other tracked outputs to external backup ($stamp)" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Commit did not create new changes (maybe nothing staged)." -ForegroundColor Yellow
} else {
  Write-Host "Committed changes."
}

# ---------- sync with remote ----------
git fetch origin
git pull --rebase --autostash origin main
if ($LASTEXITCODE -ne 0) {
  Write-Host "Pull/rebase failed. Resolve conflicts then run: git rebase --continue" -ForegroundColor Red
  git status
  return
}

git push origin main
if ($LASTEXITCODE -ne 0) {
  Write-Host "Push failed. If you rewrote history and expect to overwrite remote, consider:" -ForegroundColor Yellow
  Write-Host "  git push --force-with-lease origin main"
  return
}

# ---------- final verification ----------
Write-Host "`nDone. Remaining files in results (local):"
Get-ChildItem -Path $results -File -Recurse | Select-Object FullName,@{Name='MB';Expression={[math]::Round($_.Length/1MB,2)}},LastWriteTime
Write-Host "`nExternal backup stored at: $extBackup"
Write-Host "Check remote on GitHub: https://github.com/yirassssindaba-coder/python-project/tree/main/$resultsRel"