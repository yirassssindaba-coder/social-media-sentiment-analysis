#!/usr/bin/env python3
"""
Skrip untuk mengumpulkan file hasil ke folder 'files/social-media-sentiment-analysis'
di root repo.

Contoh (PowerShell):
  python .\scripts\collect_hasil.py -p 'social-media-sentiment-analysis\results\**\*' -o files\social-media-sentiment-analysis

Jalankan dari root repo (direktori yang berisi .git).
"""
import argparse
import shutil
from pathlib import Path
import sys

def gather(patterns, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    copied = []
    repo_root = Path.cwd()
    for pat in patterns:
        matches = list(repo_root.glob(pat))
        for m in matches:
            if m.is_file():
                try:
                    rel = m.relative_to(repo_root)
                except Exception:
                    rel = Path(m.name)
                dest = out_dir / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(m, dest)
                copied.append(str(rel))
    return copied

def main():
    parser = argparse.ArgumentParser(description="Collect result files into a folder")
    parser.add_argument("--patterns", "-p", nargs="+", required=True,
                        help="Glob patterns to collect, e.g. 'social-media-sentiment-analysis\\results\\**\\*'")
    parser.add_argument("--out", "-o", default="files\\social-media-sentiment-analysis", help="Output folder name")
    args = parser.parse_args()

    copied = gather(args.patterns, args.out)
    if not copied:
        print("No files matched the given patterns.", file=sys.stderr)
        sys.exit(2)
    print(f"Copied {len(copied)} files into {args.out}:")
    for c in copied:
        print(" -", c)

if __name__ == "__main__":
    main()