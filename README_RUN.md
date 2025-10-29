```text
Push entire folder to GitHub — Instructions

What this provides:
- A safe PowerShell script (push-all-to-github.ps1) that stages, commits (only if needed),
  syncs with origin (fetch + pull --rebase if remote has changes) and pushes to origin/main.
- The script accepts parameters to use SSH, to include ignored files (force-add), and to replace origin URL.

Before you run:
1. Decide which remote repository to use:
   - myproject (HTTPS): https://github.com/yirassssindaba-coder/myproject.git
   - or Python-realm (SSH): git@github.com:yirassssindaba-coder/Python-realm.git
   If you want to push to Python-realm via SSH, run the script with -UseSSH and ensure your SSH key is added to GitHub.

2. Recommended: keep virtualenv (.venv / venv) in .gitignore and do NOT include it in the repo.
   Instead run:
     pip freeze > requirements.txt
   and commit requirements.txt only.

3. For files larger than 100MB, use Git LFS:
   git lfs install
   git lfs track "*.zip"
   git add .gitattributes
   git add path\to\largefile
   git commit -m "Add large files with LFS"
   git push origin main

Running the script:
- Default (uses remote URL embedded in the script):
  powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\push-all-to-github.ps1"

- Use SSH remote (make sure your SSH key is configured on GitHub):
  powershell -ExecutionPolicy Bypass -File "...\push-all-to-github.ps1" -UseSSH

- Force-include ignored files (NOT recommended for .venv):
  powershell -ExecutionPolicy Bypass -File "...\push-all-to-github.ps1" -IncludeIgnored

- Replace origin URL if needed:
  powershell -ExecutionPolicy Bypass -File "...\push-all-to-github.ps1" -ForceRemoteReplace

If you want me to:
- tailor the default $RemoteUrl in the script to be git@github.com:yirassssindaba-coder/Python-realm.git instead of myproject,
- or produce a short README.md that you can commit to the repo automatically,
tell me which remote (myproject OR Python-realm) and whether you prefer SSH or HTTPS.
```
