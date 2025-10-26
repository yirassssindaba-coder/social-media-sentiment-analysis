```markdown
# social-media-sentiment-analysis — Fixes for Git push & stopping processes (PowerShell-safe)

This README updates previous instructions to remove the common errors you encountered:
- rejected push (non-fast-forward),
- misuse of `Stop-Process` with literal placeholders (`<PID>`),
- untracked `models/` and `figures/` directories showing in `git status`,
- the credential helper warning.

Follow the sections below and run the commands exactly as shown (one block / one step at a time). Do not paste angle-bracket placeholders like `<PID>` or `<file>` — use the actual values from the system output or the exact file paths shown.

---

IMPORTANT RULES
- Always run commands from the repository root: `C:\Users\ASUS\Desktop\python-project`
- Activate your virtualenv before running Python-related commands:
  ```powershell
  . .\.venv\Scripts\Activate.ps1
  ```
- When I show how to stop processes, use the exact numeric Ids reported by `Get-Process`. I include safe, copyable commands that automatically stop matching Jupyter processes if found.

---

1) Fix: "rejected (non-fast-forward)" when pushing

Reason: remote/main has commits you don't have locally. Fix by fetching remote, rebasing (recommended), resolving conflicts, then pushing.

Safe step-by-step (run each line, check output before continuing):
```powershell
# 1. Go to repo root
Set-Location 'C:\Users\ASUS\Desktop\python-project'

# 2. Show current status
git status

# 3. Save any uncommitted work (optional)
# If you have uncommitted changes and want to save them temporarily:
git stash push -m "WIP before sync with origin"

# 4. Fetch remote updates
git fetch origin

# 5. Ensure you're on main
git checkout main

# 6. Rebase your local commits onto origin/main (keeps history linear)
git pull --rebase origin main

# 7. If the previous step completed without conflicts, push:
git push origin main
```

If `git pull --rebase origin main` reports conflicts:
- Git will list conflicted files. Open each listed file in your editor, resolve the conflict markers, then:
```powershell
# Example: after you edit and save fixed files
git add .\path\to\resolved-file.py

# Continue rebase
git rebase --continue

# Repeat until rebase finishes, then push
git push origin main
```

If you prefer merge instead of rebase:
```powershell
git pull origin main    # performs fetch + merge
# fix any merge conflicts, then
git add .\path\to\resolved-file.py
git commit -m "Resolve merge conflicts"
git push origin main
```

If you used `git stash` earlier and want your WIP back:
```powershell
git stash list
git stash pop   # applies and removes the most recent stash
# resolve any conflicts, then continue workflow
```

Notes about `credential-manager-core` warning:
- The message "git: 'credential-manager-core' is not a git command" is just a warning that a configured helper is missing. Push still works once you have network/auth configured.
- To avoid the warning, install Git Credential Manager for Windows or set a helper you have:
  ```powershell
  git config --global credential.helper manager-core
  ```
  (If `manager-core` is not installed, install GCM from https://aka.ms/gcm/windows or remove/change the helper.)

---

2) Fix: "Stop-Process : Cannot find a process with the process identifier ..." and misuse of placeholders

Do NOT run `Stop-Process -Id <PID>` literally. Use numeric PIDs that `Get-Process` shows. Use the following safe sequence to detect and stop Jupyter-related processes if they exist.

Safe commands (copy/paste together):
```powershell
# 1) List Jupyter-related processes (if any)
$pj = Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path

# 2) Show what was found
if ($null -eq $pj -or $pj.Count -eq 0) {
  Write-Host "No Jupyter processes found."
} else {
  Write-Host "Jupyter processes found:"
  $pj | Format-Table -AutoSize
  # 3) Stop each process safely
  foreach ($p in $pj) {
    try {
      Write-Host "Stopping PID" $p.Id "ProcessName" $p.ProcessName
      Stop-Process -Id $p.Id -Force -ErrorAction Stop
      Write-Host "Stopped PID" $p.Id
    } catch {
      Write-Host "Failed to stop PID" $p.Id "- " $_.Exception.Message
    }
  }
}
```

Alternative stopping by name (also safe):
```powershell
# stops processes by name if present, no placeholders
Get-Process -Name jupyter-lab,jupyter-notebook -ErrorAction SilentlyContinue | Select-Object Id,ProcessName
Stop-Process -Name jupyter-lab -Force -ErrorAction SilentlyContinue
Stop-Process -Name jupyter-notebook -Force -ErrorAction SilentlyContinue
```

---

3) Untracked `models/` and `figures/` show in `git status` — how to handle

You have two options:
- Option A (recommended): Ignore these directories so they are not tracked by Git (good for large models/artifacts).
- Option B: Add and commit them (only if small and you intentionally want them in repo).

Option A — add to .gitignore and remove from index if previously tracked:
```powershell
# Add to root .gitignore (only if not already present)
$entry1 = "social-media-sentiment-analysis/models/"
$entry2 = "social-media-sentiment-analysis/figures/"

if (-not (Select-String -Path .\.gitignore -Pattern $entry1 -SimpleMatch -Quiet)) {
  Add-Content .\.gitignore $entry1
}
if (-not (Select-String -Path .\.gitignore -Pattern $entry2 -SimpleMatch -Quiet)) {
  Add-Content .\.gitignore $entry2
}

# Stop tracking any previously tracked files in those dirs
git rm -r --cached --ignore-unmatch social-media-sentiment-analysis/models
git rm -r --cached --ignore-unmatch social-media-sentiment-analysis/figures

git add .gitignore
git commit -m "chore: ignore models and figures directories"
git push origin main
```

Option B — add & commit (only for small files you intend to track):
```powershell
git add social-media-sentiment-analysis/models/
git add social-media-sentiment-analysis/figures/
git commit -m "chore: add models and figures (intended)"
git push origin main
```

---

4) Good practice: make a backup branch before complex syncs (already done, example)
```powershell
# Create a backup branch of current main
git checkout -b backup-before-sync
git push origin backup-before-sync

# Go back to main
git checkout main
```

You already created `backup-before-sync` earlier — that's good. You can delete it later if not needed.

---

5) Common mistakes to avoid (summary)
- Do not type literal `<...>` placeholders in PowerShell. Use actual values or the safe scripts above.
- Do not use `--user` when venv is active. Install packages into the venv.
- Use `git pull --rebase origin main` for a linear history, or `git pull origin main` if you prefer merges.
- Avoid `git push --force` unless absolutely necessary and you are certain you won't overwrite collaborators' work. Use `--force-with-lease` only with care.

---

6) If you are still blocked: paste outputs here
Please paste the full output of these three commands exactly as you run them (I will analyze and respond with the precise next commands):
1. `git status --porcelain=1 --branch`
2. `git log --oneline HEAD..origin/main`
3. `Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path`

I will read the outputs and give you the exact next commands to run to resolve conflicts / stop processes and push cleanly.

---
```
```
