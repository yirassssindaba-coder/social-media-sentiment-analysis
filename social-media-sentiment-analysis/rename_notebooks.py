#!/usr/bin/env python3
"""
rename_notebooks.py

Cari file notebook yang namanya dimulai dengan 'Untitled' (mis. Untitled.ipynb, Untitled1.ipynb, Untitled (1).ipynb)
dan ubah namanya menjadi <nama-folder>.ipynb (contoh: social-media-sentiment-analysis.ipynb).
Default: dry-run (hanya menampilkan rencana). Gunakan --apply untuk benar-benar mengganti nama.

Perubahan penting:
- Abaikan .ipynb_checkpoints dan folder yang ditentukan.
- Abaikan file Untitled yang berada langsung di root repo (tidak membuat root.ipynb).
- Tidak memanggil sys.exit sehingga tidak memunculkan SystemExit di Jupyter.
- Aman dijalankan di Jupyter karena menggunakan parse_known_args().
"""
import os
import argparse
import re
import sys
from pathlib import Path

# Direktori yang diabaikan
IGNORED_DIRS = {'.git', '__pycache__', '.ipynb_checkpoints'}

def find_notebooks(root):
    root_path = Path(root).resolve()
    matches = []
    pattern = re.compile(r'^Untitled.*\.ipynb$', re.IGNORECASE)
    for dirpath, dirnames, filenames in os.walk(root):
        # skip ignored dirs
        dirnames[:] = [d for d in dirnames if d not in IGNORED_DIRS]
        for f in filenames:
            if pattern.match(f):
                p = Path(dirpath) / f
                matches.append(p)
    return matches

def unique_target_for_planning(src_path: Path, base_name: str, used_targets: set):
    parent = src_path.parent
    stem = Path(base_name).stem
    suffix = Path(base_name).suffix or ".ipynb"
    candidate = base_name
    i = 0
    # Pastikan unik baik terhadap filesystem maupun rencana yang sudah ada
    while (parent / candidate).exists() or str(parent / candidate) in used_targets:
        i += 1
        candidate = f"{stem}_{i}{suffix}"
    return parent / candidate

def plan_renames(root):
    notebooks = find_notebooks(root)
    planned = []
    used_targets = set()
    root_path = Path(root).resolve()

    for nb in notebooks:
        # Abaikan Untitled yang berada langsung di root repo (mencegah root.ipynb)
        try:
            if nb.parent.resolve() == root_path:
                # skip root-level Untitled files
                continue
        except Exception:
            pass

        folder_name = nb.parent.name or 'root'
        target_name = f"{folder_name}.ipynb"
        target = unique_target_for_planning(nb, target_name, used_targets)

        # Jika source sama dengan target, lewati
        try:
            if nb.resolve() == target.resolve():
                continue
        except Exception:
            pass

        planned.append((nb, target))
        used_targets.add(str(target))
    return planned

def do_rename(planned):
    for src, dst in planned:
        dst.parent.mkdir(parents=True, exist_ok=True)
        src.rename(dst)
        print(f"Renamed: {src} -> {dst}")

def main(argv=None):
    parser = argparse.ArgumentParser(description="Rename Untitled*.ipynb to <folder>.ipynb (default: dry-run).")
    parser.add_argument('--root', default='.', help='Root folder to search (default: current dir)')
    parser.add_argument('--apply', action='store_true', help='Actually rename the files. If not set, script runs in dry-run mode.')

    # Ignore extra args added by ipykernel/jupyter (e.g. -f <path>)
    if argv is None:
        args, _unknown = parser.parse_known_args()
    else:
        args = parser.parse_args(argv)

    planned = plan_renames(args.root)
    if not planned:
        print("Tidak ditemukan file Untitled*.ipynb (atau hanya ada di root yang diabaikan). Tidak ada perubahan.")
        return 0

    print("Rencana penggantian nama:")
    for src, dst in planned:
        print(f"  {src} -> {dst}")

    if not args.apply:
        print("\nDry-run selesai. Untuk menerapkan perubahan, jalankan skrip dengan opsi --apply")
        return 0

    do_rename(planned)
    print(f"\nSelesai. {len(planned)} file diubah.")
    return 0

if __name__ == '__main__':
    # Jangan gunakan sys.exit(...) agar tidak memunculkan SystemExit di Jupyter
    main()