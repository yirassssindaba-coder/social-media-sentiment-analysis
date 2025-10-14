# Install & make Jupyter (and missing core packages) permanent for this project
Run these PowerShell blocks from the project root:
C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis

Notes:
- Run blocks one by one (don't paste everything at once).
- venv is used as the persistent environment for this project — packages you install into venv remain installed across sessions.
- The script below also sets SSL_CERT_FILE to certifi permanently for your User environment (so Jupyter extension manager / httpx TLS errors are avoided across restarts).
- You do NOT need Administrator for the User-level changes. If you want Machine-level env changes, run the relevant commands in an elevated PowerShell.

---

## A) Activate venv (make sure you are in project root)
```powershell
# change to project root if needed
Set-Location 'C:\Users\ASUS\Desktop\python-project\social-media-sentiment-analysis'

# dot-source activation (PowerShell)
. .\venv\Scripts\Activate.ps1

# quick checks
python --version
python -c "import sys; print('sys.executable=', sys.executable)"
python -m pip --version
```

---

## B) Upgrade tooling and reinstall Jupyter + core packages into venv (persistent in this venv)
```powershell
# upgrade pip/build tools
python -m pip install --upgrade pip setuptools wheel

# reinstall jupyter core packages and ipykernel so console_scripts wrappers are rewritten
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel

# install missing Jupyter core packages (ipywidgets, notebook, qtconsole) persistently in venv
python -m pip install --upgrade ipywidgets notebook qtconsole

# widget support for classic notebook (if you ever use classic notebook)
python -m pip install --upgrade widgetsnbextension
# enable widgets extension (sys-prefix ensures it installs to the current venv kernel environment)
jupyter nbextension enable --py widgetsnbextension --sys-prefix

# verify imports & versions (one line per check)
python -c "import ipywidgets; print('ipywidgets', getattr(ipywidgets,'__version__','n/a'))"
python -c "import notebook; print('notebook', getattr(notebook,'__version__','n/a'))"
python -c "import qtconsole; print('qtconsole', getattr(qtconsole,'__version__','n/a'))"
python -c "import jupyterlab; print('jupyterlab', getattr(jupyterlab,'__version__','n/a'))"

# show jupyter core summary
jupyter --version
```

---

## C) Recreate/repair CLI launchers if they were pointing to a wrong python path
```powershell
# list jupyter-related launchers in venv
Get-ChildItem .\venv\Scripts\*jupyter* -Force | Select-Object Name,FullName

# if you still got "Unable to create process" errors earlier, remove the corrupted wrappers and reinstall
Remove-Item .\venv\Scripts\jupyter.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-lab.exe -Force -ErrorAction SilentlyContinue
Remove-Item .\venv\Scripts\jupyter-notebook.exe -Force -ErrorAction SilentlyContinue

# reinstall to rewrite wrappers correctly
python -m pip install --upgrade --force-reinstall jupyter jupyterlab ipykernel

# re-check
Get-ChildItem .\venv\Scripts\*jupyter* -Force | Select-Object Name,FullName
```

---

## D) Register kernel (so Jupyter UI selects this venv) — persistent for the user
```powershell
python -m ipykernel install --user --name "social_media_sentiment" --display-name "Python (social-media-sentiment)"
jupyter kernelspec list
```

---

## E) Make SSL_CERT_FILE persistent (recommended) — sets CA bundle to certifi for your User env
```powershell
# install certifi (in venv) and obtain path
python -m pip install --upgrade certifi
$cert = & python -c "import certifi; print(certifi.where())"
Write-Host "certifi bundle at: $cert"

# set for this session (immediate)
$env:SSL_CERT_FILE = $cert

# persist for the User (so future sessions and Jupyter server runs use it)
[Environment]::SetEnvironmentVariable('SSL_CERT_FILE',$cert,'User')
Write-Host "SSL_CERT_FILE set permanently for User to: $cert"
```

If you prefer NOT to persist SSL_CERT_FILE, remove the last line and keep only the session setting.

---

## F) Freeze requirements (optional, persistent file)
```powershell
python -m pip freeze > .\requirements.txt
Get-Content .\requirements.txt -TotalCount 20
```

---

## G) Start JupyterLab (verify no errors)
```powershell
# stop old server if running (Ctrl+C)
python -m jupyter lab

# if any issues, run debug for verbose logs:
# python -m jupyter lab --debug
```

---

## What this does and why it's permanent
- All pip installs above target the activated venv; packages are installed into the venv directory and remain installed until you remove the venv — that is the "permanent" project environment.
- Reinstalling with --force-reinstall rewrites the console_scripts launchers (.exe wrappers) so they point to this venv's python executable.
- Registering the ipykernel with --user creates a persistent kernelspec for your user that Jupyter will list across sessions.
- Setting SSL_CERT_FILE in the User environment makes the cert path available to new processes (including Jupyter) after you open a new shell (or reboot).

If any block errors, copy the full error text here and I will help fix that specific step.
