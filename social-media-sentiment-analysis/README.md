```markdown
# social-media-sentiment-analysis — Full Setup & Troubleshooting (PowerShell-safe)

This README collects and consolidates all previous instructions into one clear, copy‑pasteable, PowerShell‑safe guide. It covers:

- environment setup (venv),
- installing Jupyter + data science packages (permanent in venv),
- creating sample data,
- quick training to produce a model the notebook will load,
- creating & executing the single-cell notebook so GitHub preview shows outputs,
- safe Git workflow (fetch/rebase, resolving non-fast-forward pushes),
- handling untracked `models/` and `figures/` directories,
- safely stopping Jupyter processes (no literal `<PID>`),
- best practices (.gitignore, not committing venv or large data),
- common troubleshooting.

Run each block one at a time from the project root. Example project root:
`C:\Users\ASUS\Desktop\python-project`

Important notes
- Always run commands from repo root unless stated otherwise.
- Activate the virtual environment before running Python installs or scripts.
- Do not paste multi-line Python directly to PowerShell prompt — save to .py and run `python script.py` or use a heredoc pattern.
- When a command example shows a path, use that exact path or your adjusted path; do NOT type placeholders like `<PID>`.

---

## Quick reference — what will be in your repo
Recommended files / folders inside `social-media-sentiment-analysis/`:
- create_notebook.py           (writes final notebook with one code cell)
- create_sample_data.py       (creates sample CSV for testing)
- train_quick.py              (quick trainer that produces models/model_pipeline.joblib)
- preprocess.py               (optional / production training)
- train_model.py              (optional / production training)
- evaluate.py                 (produces evaluation figures)
- visualize.py                (optional plotting helpers)
- requirements.txt
- social-media-sentiment-analysis.ipynb  (final executed notebook)
- data/                       (ignored by default)
- models/                     (ignored by default)
- figures/                    (optional, often ignored)
- README.md

Recommended root `.gitignore` includes:
```
.venv/
venv/
social-media-sentiment-analysis/data/
social-media-sentiment-analysis/models/
.ipynb_checkpoints/
__pycache__/
*.pyc
```

---

## 0) Start here — set location
```powershell
Set-Location 'C:\Users\ASUS\Desktop\python-project'
Get-Location
```

---

## 1) Create & activate virtualenv (recommended `.venv`)
```powershell
py -3 -m venv .venv
. .\.venv\Scripts\Activate.ps1

# verify
python --version
python -m pip --version
```

---

## 2) Install required packages (inside venv; do NOT use `--user`)
If you have `social-media-sentiment-analysis\requirements.txt`:
```powershell
python -m pip install --upgrade pip setuptools wheel
python -m pip install -r social-media-sentiment-analysis\requirements.txt
```

If not, install a minimal set:
```powershell
python -m pip install --upgrade pip setuptools wheel
python -m pip install nbformat nbconvert jupyter ipykernel nltk pandas scikit-learn joblib matplotlib seaborn tqdm
# optional: snscrape (may be problematic on Python 3.14)
python -m pip install snscrape
```

Enable widgets (classic notebook):
```powershell
jupyter nbextension enable --py widgetsnbextension --sys-prefix
python -c "import nltk; nltk.download('vader_lexicon', quiet=True)"
```

If you encounter WinError 32 (file lock) while installing:
- Close VS Code, terminals, browsers, Jupyter servers.
- Check running Jupyter processes and stop them (see section "Stop Jupyter safely" below).
- Restart Windows if necessary, then run install again.

---

## 3) Create sample data (recommended for testing)
Use the generator script to avoid pasting long CSV:
```powershell
python .\social-media-sentiment-analysis\create_sample_data.py
# -> creates social-media-sentiment-analysis\data\raw\tweets_scraped.csv
```

If you prefer a small manual file, copy `data/raw/sample_tweets.csv` to `data/raw/tweets_scraped.csv`.

---

## 4) Quick train to produce model that notebook expects
Save and run the quick training script `train_quick.py` (provided separately). From repo root:
```powershell
python .\social-media-sentiment-analysis\train_quick.py
```
Expected outcome:
- A model file created at:
  `social-media-sentiment-analysis\models\model_pipeline.joblib`
- Terminal output showing training progress and a classification report.

If file exists, verify:
```powershell
Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib
```
True means model exists.

---

## 5) Verify model can predict (quick check)
Run a small verification script (safe heredoc approach):
```powershell
python - <<'PY'
import joblib
from pathlib import Path
p = Path("social-media-sentiment-analysis/models/model_pipeline.joblib")
if not p.exists():
    print("Model not found at", p)
    raise SystemExit(1)
pipe = joblib.load(p)
samples = [
    "I absolutely love this! Highly recommend.",
    "This is ok, nothing special.",
    "Terrible experience, will never buy again."
]
print("Predictions:", list(pipe.predict(samples)))
PY
```

---

## 6) Create & execute final notebook (one code cell)
Write the notebook (helper `create_notebook.py` should create `social-media-sentiment-analysis/social-media-sentiment-analysis.ipynb` with a single code cell that loads NLTK VADER and attempts to load the pipeline from common paths). Then execute it so outputs are embedded:

From repo root:
```powershell
python .\social-media-sentiment-analysis\create_notebook.py

# Execute notebook and save outputs into file (run from repo root)
python -m nbconvert --to notebook --inplace --execute "social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb" --ExecutePreprocessor.timeout=120
```

Open the notebook in JupyterLab or VS Code to confirm the output shows VADER output and model predictions (not the "No trained model..." message).

---

## 7) Stop Jupyter safely (no literal placeholders)
If you need to stop running Jupyter processes before reinstalling or updating packages, run these safe commands — copy/paste exactly:

```powershell
# Detect jupyter processes
$pj = Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path

if ($null -eq $pj -or $pj.Count -eq 0) {
  Write-Host "No Jupyter processes found."
} else {
  Write-Host "Jupyter processes found:"
  $pj | Format-Table -AutoSize
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

Alternative by name:
```powershell
Get-Process -Name jupyter-lab,jupyter-notebook -ErrorAction SilentlyContinue | Select-Object Id,ProcessName
Stop-Process -Name jupyter-lab -Force -ErrorAction SilentlyContinue
Stop-Process -Name jupyter-notebook -Force -ErrorAction SilentlyContinue
```

Do NOT run `Stop-Process -Id <PID>` with angle brackets. Use numeric IDs returned by `Get-Process`.

---

## 8) Git: handle untracked models/figures & .gitignore
Decide whether to track models/figures or ignore them. Recommended: ignore.

Add ignore entries and stop tracking if previously tracked:
```powershell
# Add to .gitignore if missing
$entry1 = "social-media-sentiment-analysis/models/"
$entry2 = "social-media-sentiment-analysis/figures/"
if (-not (Select-String -Path .\.gitignore -Pattern $entry1 -SimpleMatch -Quiet)) { Add-Content .\.gitignore $entry1 }
if (-not (Select-String -Path .\.gitignore -Pattern $entry2 -SimpleMatch -Quiet)) { Add-Content .\.gitignore $entry2 }

# Stop tracking if they were tracked earlier (does not delete local files)
git rm -r --cached --ignore-unmatch social-media-sentiment-analysis/models
git rm -r --cached --ignore-unmatch social-media-sentiment-analysis/figures

git add .gitignore
git commit -m "chore: ignore models and figures directories"
git push origin main
```

If you intentionally want to commit small models/figures, add them explicitly:
```powershell
git add social-media-sentiment-analysis/models/
git add social-media-sentiment-analysis/figures/
git commit -m "chore: add small model and figures"
git push origin main
```

---

## 9) Git: resolve non-fast-forward push (rejected push)
If `git push` is rejected with `non-fast-forward`, follow this safe flow:

```powershell
# from repo root
git fetch origin
git checkout main

# Recommended: rebase your local commits onto origin/main
git pull --rebase origin main

# resolve any conflicts if Git stops for conflicts:
# - edit files to remove conflict markers
# - then:
git add .\path\to\resolved-file.py
git rebase --continue

# After rebase finishes:
git push origin main
```

If you prefer merge:
```powershell
git pull origin main
# fix conflicts if any, then:
git add .\path\to\resolved-file.py
git commit -m "Resolve merge conflicts"
git push origin main
```

If you earlier stashed work, reapply it:
```powershell
git stash list
git stash pop    # check conflicts and resolve if necessary
```

If you see credential helper warnings (`git: 'credential-manager-core' is not a git command`), install Git Credential Manager for Windows or set a helper you have:
```powershell
git config --global credential.helper manager-core
# or install GCM from https://aka.ms/gcm/windows
```

---

## 10) Final commit checklist & commands
Only commit code, notebook (executed), README, requirements — avoid committing venv/data/models unless intended.

Example final steps:
```powershell
# ensure up-to-date
git fetch origin
git pull --rebase origin main

# add files (example set)
git add social-media-sentiment-analysis\*.py
git add social-media-sentiment-analysis\social-media-sentiment-analysis.ipynb
git add README.md
git add requirements.txt

git commit -m "chore: add sentiment analysis pipeline, sample data generator, quick training, and executed notebook"
git push origin main
```

---

## 11) Common troubleshooting quick list
- `No trained model...` in notebook: run `train_quick.py` to create `models/model_pipeline.joblib` and re-execute the notebook (nbconvert).
- `pip install` WinError 32: close processes using .venv\Scripts\*, stop Jupyter processes (see step 7), or restart Windows.
- `snscrape` errors on Python 3.14: either install snscrape from GitHub or use Python 3.11/3.12 venv. Or use sample CSV to avoid scraping.
- Encoding artifacts (â€”): save .py and .ipynb as UTF‑8 (most editors default to UTF-8).

---

## If you are still blocked
Run and paste the outputs of the following commands here (I will inspect and provide exact next commands):
1. `git status --porcelain=1 --branch`
2. `git log --oneline HEAD..origin/main`
3. `Get-Process *jupyter* -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path`
4. `Test-Path .\social-media-sentiment-analysis\models\model_pipeline.joblib` (True/False)

I will analyze those outputs and tell you the precise steps to finish the workflow and get the notebook showing model predictions.

---

Thank you — this README consolidates the full, safe, PowerShell‑compatible workflow so you can create sample data, train a quick model, embed the outputs into a one‑cell notebook, and commit/push your project without the common pitfalls you encountered earlier.
```
