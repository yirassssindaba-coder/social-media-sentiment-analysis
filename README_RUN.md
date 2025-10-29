```text
How to run deploy-final-fixed.ps1 (quick)

1) Save the script file to:
   C:\Users\ASUS\Desktop\python-project-remote\deploy-final-fixed.ps1

2) Open PowerShell (regular user).

3) Run the script (safe one-time bypass if ExecutionPolicy blocks):
   powershell -ExecutionPolicy Bypass -File "C:\Users\ASUS\Desktop\python-project-remote\deploy-final-fixed.ps1"

   Or change directory and run directly:
   cd "C:\Users\ASUS\Desktop\python-project-remote"
   .\deploy-final-fixed.ps1

4) If the script stops and says "git pull --rebase stopped with errors" and prints conflicting files:
   - For each file listed by 'git status --porcelain' fix the conflict in your editor (remove <<<< markers)
   - Then run:
       git add path\to\that\file
       git rebase --continue
   - Repeat until rebase finishes, then:
       git push -u origin main

5) Authentication:
   - For HTTPS: use your GitHub username and a Personal Access Token (PAT) as the password when prompted.
   - For SSH: set $UseSSH = $true in the script and ensure your public key is added to GitHub.

Notes:
- This script avoids PowerShell parsing pitfalls (no angle-bracket placeholders).
- It will not force-push automatically; you must resolve conflicts manually, then re-run the script or push.
