# Results Summary Generator — README

Skrip PowerShell ini memindai folder hasil (results), membuat halaman viewer per-file (CSV → tabel rapi, IPYNB → HTML via nbconvert atau fallback), dan menghasilkan index HTML (Hasil - Index Global) yang rapi untuk ditampilkan di browser. README ini menjelaskan tujuan skrip, prasyarat, konfigurasi, dan cara menjalankannya.

Ringkasan singkat:
- Input: folder results lokal yang berisi file (.csv, .ipynb, .html, dll.).
- Output: folder summary (di samping folder results) berisi:
  - viewer-<hash>.html untuk tiap file (preview rapi)
  - per-folder pages (summary-...html)
  - index.html (Hasil - Index Global)
- Behavior: mendeteksi Python / Jupyter (opsional) untuk menautkan ke JupyterLab atau menggunakan nbconvert; berperilaku defensif jika dependensi tidak ada.

---

## Prasyarat
- PowerShell (Windows PowerShell 5+ atau PowerShell Core).
- Git/Tidak wajib untuk skrip ini — hanya PowerShell + (opsional) Python/nbconvert jika Anda ingin mengonversi notebook ke HTML.
- (Opsional) Python + nbconvert untuk konversi .ipynb ke HTML jika Anda tidak ingin menggunakan fallback sederhana.
- Pastikan path yang ditetapkan pada konfigurasi ada dan dapat diakses oleh user.

---

## Konfigurasi
Di bagian atas skrip ada blok CONFIG yang dapat Anda ubah:
- `$ResultsRoot` — path folder hasil yang ingin dipindai (contoh: `C:\Users\ASUS\Desktop\python-project-remote\results`)
- `$OutFolderName` — nama folder output ringkasan (dibuat di parent folder ResultsRoot; default berisi timestamp)
- `$MaxRecent` — jumlah file terbaru yang ditampilkan di index global
- `$TextPreviewMaxChars` — batas karakter preview untuk file teks
- `$CsvPreviewMaxRows` — baris maksimum ditampilkan pada preview CSV

---

## Cara menjalankan (penting)
- Paste utuh ke PowerShell (interactive). JANGAN simpan sebagai `.ps1` — paste langsung ke prompt.
- Atau: simpan sebagai file `.ps1` dan jalankan jika Anda lebih nyaman menjalankan file (perhatikan kebijakan execution policy).

Berikut instruksi yang harus dipaste langsung (teks di bawah ini disertakan agar Anda dapat menempel utuh ke PowerShell):

```
Paste the entire block below directly into an interactive PowerShell session (do NOT save as .ps1 if you intend to paste).
This script scans a results folder, builds per-file viewer pages (CSV -> pretty table, IPYNB -> nbconvert or fallback),
and produces an index HTML (Hasil - Index Global). It's defensive and avoids parser issues with Windows path strings.
Edit the CONFIG section at the top to match your environment before pasting.
```

Setelah itu, paste seluruh skrip PowerShell (blok di bawah) ke prompt PowerShell Anda. Skrip akan menulis output ke folder baru (bernama `results_summary-<timestamp>`) di parent folder `ResultsRoot`. Setelah selesai, buka `index.html` di folder output menggunakan browser atau klik `explorer "<OutRoot>"` pada pesan akhir.

---

## Skrip (paste seluruh blok berikut ke PowerShell interactive)
```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ====== CONFIG (sesuaikan jika perlu) ======
$ResultsRoot = "C:\Users\ASUS\Desktop\python-project-remote\results"   # <-- ubah bila perlu
$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$OutFolderName = "results_summary-$timestamp"
$MaxRecent = 200
$TextPreviewMaxChars = 20000
$CsvPreviewMaxRows = 500
$CreateSelectCmdFiles = $false
# ============================================

# ====== Logging helpers ======
function LogInfo([string]$m)  { Write-Host "[INFO]  $m" -ForegroundColor Green }
function LogWarn([string]$m)  { Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function LogError([string]$m) { Write-Host "[ERROR] $m" -ForegroundColor Red }

LogInfo "Starting results summary generator..."

# ====== Common helpers ======
function HtmlEscape([string]$s) {
    if ($null -eq $s) { return "" }
    return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'","&#39;")
}
function Make-RelativeHref([string]$fromFilePath,[string]$toFilePath) {
    try {
        $fromDir = Split-Path -Parent $fromFilePath
        if (-not $fromDir) { return ("file:///" + ($toFilePath -replace '\\','/')) }
        $base = New-Object System.Uri ((Resolve-Path $fromDir).ProviderPath + [IO.Path]::DirectorySeparatorChar)
        $target = New-Object System.Uri ((Resolve-Path $toFilePath).ProviderPath)
        $rel = $base.MakeRelativeUri($target).ToString()
        $rel = [System.Uri]::UnescapeDataString($rel) -replace '/','/'
        return ("./" + $rel)
    } catch {
        return ("file:///" + ($toFilePath -replace '\\','/'))
    }
}
function FileToFileUri([string]$path) { return "file:///" + ($path -replace '\\','/') }
function FileToFolderUri([string]$path) { $p = ($path -replace '\\','/'); if ($p -notlike '*/') { $p = $p + '/' }; return "file:///" + $p }
function SimpleHash([string]$input) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($input)
    $hash = $md5.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash)).Replace("-","").ToLower()
}

# ====== ENV checks & prepare output ======
if (-not (Test-Path $ResultsRoot)) {
    LogError ("Results root not found: " + $ResultsRoot)
    LogInfo "No output generated. Fix $ResultsRoot and run again."
    return
}
$parent = Split-Path -Parent $ResultsRoot
$OutRoot = Join-Path $parent $OutFolderName
try {
    if (-not (Test-Path $OutRoot)) { New-Item -ItemType Directory -Path $OutRoot | Out-Null }
    LogInfo ("Output folder: " + $OutRoot)
} catch {
    LogError ("Unable to create output folder: " + $_.Exception.Message); return
}

# Detect Python and nbconvert availability
$PY = $null
try { $cmd = Get-Command python -ErrorAction SilentlyContinue; if ($cmd) { $PY = $cmd.Source } } catch {}
if (-not $PY) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe"
    )
    foreach ($c in $candidates) { if (-not $PY -and (Test-Path $c)) { $PY = $c } }
}
if ($PY) { LogInfo ("Python found: " + $PY); try { & $PY --version 2>$null | ForEach-Object { LogInfo ("Python version: " + $_) } } catch {} } else { LogWarn "Python not found; local notebook conversion may be skipped." }

# Jupyter server detection (optional) - used to generate JupyterLab open links
function Get-JupyterServers {
    $servers = @()
    try {
        if (Get-Command jupyter -ErrorAction SilentlyContinue) {
            $out = & jupyter server list 2>$null
            foreach ($line in $out) {
                $l = $line.Trim()
                if ($l -match '^(https?://\S+)\s+::\s+(.+)$') {
                    $servers += @{ url = $matches[1].TrimEnd('/'); root = $matches[2].Trim(); raw = $l }
                } elseif ($l -match '^(https?://\S+)\s+') {
                    $servers += @{ url = $matches[1].TrimEnd('/'); root = $null; raw = $l }
                }
            }
        }
    } catch { }
    return $servers
}
function Make-JupyterLabUrlForFile([string]$filePath) {
    try {
        $resolved = (Resolve-Path -LiteralPath $filePath -ErrorAction SilentlyContinue).ProviderPath
        if (-not $resolved) { return $null }
        $servers = Get-JupyterServers
        if (-not $servers -or $servers.Count -eq 0) { return $null }
        $best = $null; $bestLen = -1
        foreach ($s in $servers) {
            if (-not $s.root) { continue }
            $rootRes = (Resolve-Path -LiteralPath $s.root -ErrorAction SilentlyContinue).ProviderPath
            if (-not $rootRes) { continue }
            if ($resolved.StartsWith($rootRes, [System.StringComparison]::InvariantCultureIgnoreCase)) {
                if ($rootRes.Length -gt $bestLen) { $best = $s; $bestLen = $rootRes.Length }
            }
        }
        if (-not $best) {
            $fallback = $servers | Where-Object { $_.root -eq $null } | Select-Object -First 1
            if ($fallback) { $best = $fallback }
        }
        if (-not $best) { return $null }
        if ($best.root) {
            $rootRes = (Resolve-Path -LiteralPath $best.root -ErrorAction SilentlyContinue).ProviderPath
            $relative = $resolved.Substring($rootRes.Length).TrimStart('\','/')
            $segments = $relative -split '[\\/]'
            $segments = $segments | ForEach-Object { [System.Uri]::EscapeDataString($_) }
            return ($best.url.TrimEnd('/') + "/lab/tree/" + ($segments -join '/'))
        } else {
            return $best.url
        }
    } catch {
        return $null
    }
}

# ====== CSS used in generated pages ======
$Css = @"
:root{--bg:#f7f7fb;--card:#ffffff;--muted:#5b6170;--accent:#0b84ff;--accent-2:#5b21b6;--border:#e7e9ee;--radius:10px}
body{font-family:Segoe UI,Arial;background:var(--bg);color:#0b1220;margin:20px}
.container{max-width:1200px;margin:0 auto}
.header{display:flex;justify-content:space-between;align-items:center}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:16px;margin-top:18px}
.card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:12px;box-shadow:0 6px 16px rgba(16,24,40,0.06)}
.meta{color:var(--muted);font-size:0.9rem}
.path{font-family:Consolas,monospace;font-size:0.85rem;color:#334155;word-break:break-all;margin-top:8px}
.actions{display:flex;gap:8px;margin-top:10px;flex-wrap:wrap}
.btn{padding:8px 10px;border-radius:8px;text-decoration:none;color:#fff}
.btn.green{background:#10b981}
.btn.secondary{background:#6b7280}
.btn.orange{background:#ff6b00}
.viewer-iframe{width:100%;height:70vh;border:1px solid var(--border);border-radius:8px}
.table{border-collapse:collapse;width:100%;max-width:100%}
.table th,.table td{border:1px solid #bbb;padding:6px 8px;text-align:left}
.table th{background:#f4f6f8}
.notice{color:var(--muted);margin-bottom:8px}
"@

# ====== Create-ViewerPage function ======
function Create-ViewerPage([System.IO.FileInfo]$file, [string]$outRoot, [string]$css, [int]$textPreviewMaxChars, [int]$csvPreviewMaxRows, [bool]$createSelectCmd) {
    LogInfo ("Creating viewer: " + $file.FullName)
    $fullPath = $file.FullName
    $hash = SimpleHash($fullPath)
    $viewerName = "viewer-$hash.html"
    $viewerPath = Join-Path $outRoot $viewerName

    $nameEsc = HtmlEscape($file.Name)
    $size = "{0:N0}" -f $file.Length
    $mod = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    $ext = $file.Extension.ToLowerInvariant()
    $fileUri = FileToFileUri $fullPath
    $folderUri = FileToFolderUri (Split-Path -Parent $fullPath)
    $jupyterUrl = $null
    if ($ext -in @(".csv",".ipynb")) { $jupyterUrl = Make-JupyterLabUrlForFile $fullPath }

    $contentHtml = "<div class='notice'>No preview</div>"
    try {
        if ($ext -in @(".html",".htm")) {
            $folder = Split-Path -Parent $fullPath
            $items = @(Get-ChildItem -Path $folder -File -ErrorAction SilentlyContinue | Sort-Object Name)
            $tbl = "<div class='notice'>Ringkasan folder: " + (HtmlEscape((Split-Path $folder -Leaf))) + "</div>"
            $tbl += "<table class='table'><thead><tr><th>Name</th><th>Rel</th><th>Size</th><th>Modified</th></tr></thead><tbody>"
            foreach ($it in $items) {
                $itName = HtmlEscape($it.Name)
                $itRel = HtmlEscape($it.Name)
                $itSize = "{0:N0}" -f $it.Length
                $itMod = $it.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                $itemViewer = Join-Path $outRoot ("viewer-" + (SimpleHash $it.FullName) + ".html")
                if (-not (Test-Path $itemViewer)) {
                    $ph = "<!doctype html><html><body><h3>Viewer placeholder for " + (HtmlEscape($it.Name)) + "</h3><p><a href='" + (FileToFileUri $it.FullName) + "'>Open original</a></p></body></html>"
                    try { Set-Content -Path $itemViewer -Value $ph -Encoding UTF8 } catch {}
                }
                $itJ = $null
                if ($it.Extension.ToLower() -in @(".csv",".ipynb")) { $itJ = Make-JupyterLabUrlForFile $it.FullName }
                $itLink = if ($itJ) { $itJ } else { Make-RelativeHref -fromFilePath $viewerPath -toFilePath $itemViewer }
                $tbl += "<tr><td><a href='$itLink' target='_blank'>$itName</a></td><td>$itRel</td><td>$itSize</td><td>$itMod</td></tr>"
            }
            $tbl += "</tbody></table>"
            $contentHtml = $tbl

        } elseif ($ext -eq ".csv") {
            if ($jupyterUrl) {
                $contentHtml = "<div class='notice'>JupyterLab detected — redirecting...</div><script>setTimeout(function(){ window.location.href='" + $jupyterUrl + "'; },400);</script><div style='margin-top:12px'><a class='btn orange' href='" + $jupyterUrl + "' target='_blank'>Buka di JupyterLab</a> <a class='btn green' href='" + $fileUri + "' target='_blank'>Buka file asli</a></div>"
            } else {
                try {
                    $rows = Import-Csv -LiteralPath $fullPath -ErrorAction Stop
                    $count = $rows.Count
                    $previewRows = if ($count -gt $csvPreviewMaxRows) { $rows | Select-Object -First $csvPreviewMaxRows } else { $rows }
                    $headers = if ($previewRows.Count -gt 0) { $previewRows[0].PSObject.Properties | ForEach-Object { $_.Name } } else { @() }
                    $table = "<div class='notice'>Preview CSV: menampilkan " + ([int]$previewRows.Count) + " dari " + $count + " baris</div><div style='overflow:auto'><table class='table'><thead><tr>"
                    foreach ($h in $headers) { $table += "<th>" + (HtmlEscape $h) + "</th>" }
                    $table += "</tr></thead><tbody>"
                    foreach ($r in $previewRows) {
                        $table += "<tr>"
                        foreach ($h in $headers) {
                            $cell = $null
                            try { $cell = $r.PSObject.Properties[$h].Value } catch { $cell = $null }
                            if ($null -eq $cell) { $cell = "" }
                            $table += "<td>" + (HtmlEscape ([string]$cell)) + "</td>"
                        }
                        $table += "</tr>"
                    }
                    $table += "</tbody></table></div><div style='margin-top:12px'><a class='btn green' href='" + $fileUri + "' target='_blank'>Buka file asli</a></div>"
                    $contentHtml = $table
                } catch {
                    $contentHtml = "<div class='notice'>Gagal menampilkan CSV: " + (HtmlEscape $_.Exception.Message) + "</div>"
                }
            }

        } elseif ($ext -eq ".ipynb") {
            if ($jupyterUrl) {
                $contentHtml = "<div class='notice'>JupyterLab detected — redirecting...</div><script>setTimeout(function(){ window.location.href='" + $jupyterUrl + "'; },400);</script><div style='margin-top:12px'><a class='btn orange' href='" + $jupyterUrl + "' target='_blank'>Buka di JupyterLab</a> <a class='btn green' href='" + $fileUri + "' target='_blank'>Buka file asli</a></div>"
            } else {
                if (-not $PY) {
                    $contentHtml = "<div class='notice'>Python not found; cannot convert notebook locally. Install Python & nbconvert or run JupyterLab.</div>"
                } else {
                    $convName = "notebook-$hash.html"
                    $convPath = Join-Path $outRoot $convName
                    $pyScript = @'
import sys, nbformat
from nbconvert import HTMLExporter
nb = nbformat.read(sys.argv[1], as_version=4)
exp = HTMLExporter()
body, resources = exp.from_notebook_node(nb)
sys.stdout.write(body)
'@
                    $tmp = Join-Path $env:TEMP ("nb2html-" + [System.Guid]::NewGuid().ToString() + ".py")
                    try {
                        Set-Content -Path $tmp -Value $pyScript -Encoding UTF8
                        $nbOut = & $PY $tmp $fullPath 2>&1
                        if ($LASTEXITCODE -ne 0 -or ($nbOut -match '^Traceback' -or $nbOut -match '^ERROR')) {
                            $contentHtml = "<div class='notice'>Conversion error: " + (HtmlEscape($nbOut)) + "</div>"
                        } else {
                            Set-Content -Path $convPath -Value $nbOut -Encoding UTF8
                            $relConv = Make-RelativeHref -fromFilePath $viewerPath -toFilePath $convPath
                            $contentHtml = "<div class='notice'>Menampilkan notebook hasil konversi.</div><iframe class='viewer-iframe' src='" + $relConv + "'></iframe><div style='margin-top:12px'><a class='btn green' href='" + $fileUri + "' target='_blank'>Buka file asli</a></div>"
                        }
                    } catch {
                        $contentHtml = "<div class='notice'>Failed converting notebook: " + (HtmlEscape $_.Exception.Message) + "</div>"
                    } finally { Remove-Item -Path $tmp -ErrorAction SilentlyContinue }
                }
            }

        } else {
            try {
                $raw = Get-Content -LiteralPath $fullPath -Raw -ErrorAction Stop
                if ($raw.Length -gt $textPreviewMaxChars) { $preview = $raw.Substring(0,$textPreviewMaxChars) + "`n`n--- (terpotong) ---" } else { $preview = $raw }
                $contentHtml = "<div class='precontent'>" + (HtmlEscape($preview)) + "</div><div style='margin-top:12px'><a class='btn green' href='" + $fileUri + "' target='_blank'>Buka file asli</a></div>"
            } catch {
                $contentHtml = "<div class='notice'>Cannot read file: " + (HtmlEscape $_.Exception.Message) + "</div>"
            }
        }
    } catch {
        $contentHtml = "<div class='notice'>Error preparing viewer: " + (HtmlEscape $_.Exception.Message) + "</div>"
    }

    $pageHtml = @"
<!doctype html>
<html lang='id'>
<head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Viewer - $nameEsc</title><style>$css</style></head>
<body>
<div class='container'>
  <div class='header'><div><h2>Viewer: $nameEsc</h2><div class='meta'>Ukuran: $size bytes · Dimodifikasi: $mod</div></div></div>
  <div style='margin-top:10px'>$contentHtml</div>
  <div style='margin-top:18px' class='footer small'>Dibuat: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') — viewer</div>
</div>
</body>
</html>
"@

    try {
        Set-Content -Path $viewerPath -Value $pageHtml -Encoding UTF8
        LogInfo ("Wrote viewer: " + $viewerPath)
        return $viewerName
    } catch {
        LogError ("Failed to write viewer " + $viewerPath + " : " + $_.Exception.Message)
        return $null
    }
}

# ====== Prepare pages list (guaranteed defined) ======
$pages = @()
$pages += [pscustomobject]@{ Title = "ROOT - File tingkat atas"; FolderPath = $ResultsRoot; FileName = "index-root.html" }
$folders = @(Get-ChildItem -Path $ResultsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
foreach ($f in $folders) {
    $safe = ($f.Name -replace '[^A-Za-z0-9_.-]','_')
    $fname = ("summary-{0}.html" -f $safe)
    $pages += [pscustomobject]@{ Title = $f.Name; FolderPath = $f.FullName; FileName = $fname }
}

# Gather root files (top-level)
$rootFiles = @(Get-ChildItem -Path $ResultsRoot -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)

# ====== Generate per-folder pages & viewers ======
foreach ($p in $pages) {
    try {
        $folderPath = $p.FolderPath
        $pageFile = Join-Path $OutRoot $p.FileName
        if ($folderPath -eq $ResultsRoot) { $files = $rootFiles } else { $files = @(Get-ChildItem -Path $folderPath -File -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending) }

        $cards = ""
        foreach ($file in $files) {
            try {
                $viewerName = Create-ViewerPage -file $file -outRoot $OutRoot -css $Css -textPreviewMaxChars $TextPreviewMaxChars -csvPreviewMaxRows $CsvPreviewMaxRows -createSelectCmd:$CreateSelectCmdFiles
                if (-not $viewerName) { continue }
                $viewerPath = Join-Path $OutRoot $viewerName
                $relToViewer = Make-RelativeHref -fromFilePath $pageFile -toFilePath $viewerPath
                $nameEsc = HtmlEscape($file.Name)
                $size = "{0:N0}" -f $file.Length
                $mod = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                $fullPathEsc = HtmlEscape($file.FullName)
                $initial = if ($nameEsc -and $nameEsc.Length -ge 1) { $nameEsc.Substring(0,1) } else { "" }
                $fileUri = FileToFileUri $file.FullName
                $folderUri = FileToFolderUri (Split-Path -Parent $file.FullName)

                $jurl = $null
                if ($file.Extension.ToLower() -in @(".csv",".ipynb")) { $jurl = Make-JupyterLabUrlForFile $file.FullName }
                $viewerLink = if ($jurl) { $jurl } else { $relToViewer }
                $jbuttonHtml = if ($jurl) { "<a class='btn orange' href='" + $jurl + "' target='_blank'>Buka di JupyterLab</a>" } else { "" }

                $cards += @"
<div class='card'>
  <div style='display:flex;align-items:center;gap:12px'>
    <div style='width:48px;height:48px;border-radius:8px;background:linear-gradient(135deg,var(--accent),var(--accent-2));color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700'>$initial</div>
    <div style='flex:1'>
      <div style='font-weight:600;'><a href='$viewerLink' target='_blank'>$nameEsc</a></div>
      <div class='meta'>$size bytes · $mod</div>
    </div>
  </div>
  <div class='path'>$fullPathEsc</div>
  <div class='actions'>
    $jbuttonHtml
    <a class='btn green' href='$fileUri' target='_blank'>Buka file asli</a>
    <a class='btn secondary' href='$folderUri' target='_blank'>Buka folder</a>
  </div>
</div>
"@
            } catch {
                LogWarn ("Skipping file " + $file.FullName + " due to error: " + $_.Exception.Message)
                continue
            }
        }

        if (-not $cards) { $cards = "<div class='card small'>(tidak ada file)</div>" }

        $nav = "<div class='nav'><strong>Halaman:</strong> <span class='pages-list'>"
        foreach ($q in $pages) { $nm = HtmlEscape($q.Title); $href = $q.FileName; if ($href -eq $p.FileName) { $nav += "<a class='active' href='" + $href + "'>$nm</a>" } else { $nav += "<a href='" + $href + "'>$nm</a>" } }
        $nav += "</span></div>"

        $titleEsc = HtmlEscape($p.Title)
        $generated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $pageHtml = @"
<!doctype html>
<html lang='id'>
<head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Ringkasan - $titleEsc</title><style>$Css</style></head>
<body>
<div class='container'>
  <div class='header'><div><h2>Ringkasan: $titleEsc</h2><div class='meta'>Dibuat: $generated</div></div></div>
  $nav
  <div class='grid'>$cards</div>
  <div class='footer small'>Catatan: klik nama file untuk membuka tampilan sesuai jenis. JupyterLab diprioritaskan bila tersedia.</div>
</div>
</body>
</html>
"@

        try { Set-Content -Path $pageFile -Value $pageHtml -Encoding UTF8; LogInfo ("Wrote page: " + $pageFile) } catch { LogError ("Failed to write page " + $pageFile + " : " + $_.Exception.Message) }
    } catch {
        LogWarn ("Skipping page entry due to error: " + $_.Exception.Message)
        continue
    }
}

# ====== Global index ======
$globalIndexPath = Join-Path $OutRoot "index.html"
$allFiles = @(Get-ChildItem -Path $ResultsRoot -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
$topFiles = $allFiles | Select-Object -First $MaxRecent

$allCards = ""
foreach ($f in $topFiles) {
    try {
        $hash = SimpleHash($f.FullName); $viewerName = "viewer-$hash.html"; $viewerPath = Join-Path $OutRoot $viewerName
        if (-not (Test-Path $viewerPath)) {
            Create-ViewerPage -file $f -outRoot $OutRoot -css $Css -textPreviewMaxChars $TextPreviewMaxChars -csvPreviewMaxRows $CsvPreviewMaxRows -createSelectCmd:$CreateSelectCmdFiles | Out-Null
        }
        $relToViewer = Make-RelativeHref -fromFilePath $globalIndexPath -toFilePath (Join-Path $OutRoot $viewerName)
        $nameEsc = HtmlEscape($f.Name); $size = "{0:N0}" -f $f.Length; $mod = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"); $fullPathEsc = HtmlEscape($f.FullName)
        $initial = if ($nameEsc -and $nameEsc.Length -ge 1) { $nameEsc.Substring(0,1) } else { "" }
        $openFolderUri = FileToFolderUri (Split-Path -Parent $f.FullName); $fileUri = FileToFileUri $f.FullName
        $jurl = $null; if ($f.Extension.ToLower() -in @(".csv",".ipynb")) { $jurl = Make-JupyterLabUrlForFile $f.FullName }
        $viewerLink = if ($jurl) { $jurl } else { $relToViewer }
        $jbuttonHtml = if ($jurl) { "<a class='btn orange' href='" + $jurl + "' target='_blank'>Buka di JupyterLab</a>" } else { "" }

        $allCards += @"
<div class='card'>
  <div style='display:flex;align-items:center;gap:12px'>
    <div style='width:48px;height:48px;border-radius:8px;background:linear-gradient(135deg,var(--accent),var(--accent-2));color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700'>$initial</div>
    <div style='flex:1'>
      <div style='font-weight:600'><a href='$viewerLink' target='_blank'>$nameEsc</a></div>
      <div class='meta'>$size bytes · $mod</div>
    </div>
  </div>
  <div class='path'>$fullPathEsc</div>
  <div class='actions'>
    $jbuttonHtml
    <a class='btn green' href='$fileUri' target='_blank'>Buka file asli</a>
    <a class='btn secondary' href='$openFolderUri' target='_blank'>Buka folder</a>
  </div>
</div>
"@
    } catch {
        LogWarn ("Skipping top-file entry due to error: " + $_.Exception.Message)
        continue
    }
}

if (-not $allCards) { $allCards = "<div class='card small'>(tidak ada file)</div>" }

$pagesListHtml = "<div class='pages-list'>"
foreach ($p in $pages) { $titleEsc = HtmlEscape($p.Title); $href = "./" + [System.Uri]::EscapeUriString($p.FileName); $pagesListHtml += "<a href='$href'>$titleEsc</a>" }
$pagesListHtml += "</div>"

$globalHtml = @"
<!doctype html>
<html lang='id'>
<head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Hasil - Index Global</title><style>$Css</style></head>
<body>
<div class='container'>
  <div class='header'><div><h2>Hasil - Index Global</h2><div class='meta'>Dibuat: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div></div></div>
  <div class='nav'><strong>Halaman:</strong>$pagesListHtml</div>
  <h3>File terbaru (maks $MaxRecent)</h3>
  <div class='grid'>$allCards</div>
  <div class='footer small'>Klik nama file untuk membuka tampilan sesuai jenis. Untuk CSV/IPYNB, JupyterLab diprioritaskan jika tersedia.</div>
</div>
</body>
</html>
"@

try { Set-Content -Path $globalIndexPath -Value $globalHtml -Encoding UTF8; LogInfo ("Wrote global index: " + $globalIndexPath) } catch { LogError ("Failed to write global index: " + $_.Exception.Message) }

LogInfo "DONE. Open the summary folder and open index.html"
Write-Host ""
Write-Host ("  explorer " + $OutRoot)
```

---

## Hasil
- Folder output: `\<parent-of-results>\results_summary-<timestamp>\`
- Di dalamnya: `index.html` (Hasil - Index Global), halaman `summary-*.html` per folder, dan `viewer-*.html` per file (preview).
- Buka `index.html` di browser untuk menelusuri hasil secara rapi.

---

## Troubleshooting singkat
- Jika skrip berhenti karena path tidak ditemukan: periksa nilai `$ResultsRoot`.
- Jika notebook tidak terkonversi: pastikan Python + nbconvert terpasang, atau jalankan JupyterLab dan biarkan tautan "Buka di JupyterLab" bekerja.
- Jika halaman kosong: cek apakah folder `ResultsRoot` berisi file — skrip hanya memproses file yang ditemukan.

---

Jika Anda mau, saya bisa:
- Menambahkan syntax highlighting untuk tampilan notebook/code pada viewer pages.
- Menyimpan thumbnail gambar untuk CSV/HTML agar lebih cepat dimuat pada index.
- Menambahkan opsi CLI sehingga skrip bisa dijalankan dengan parameter (mis. `-Source` `-Out`).
