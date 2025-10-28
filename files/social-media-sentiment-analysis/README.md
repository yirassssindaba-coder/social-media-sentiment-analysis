# files/social-media-sentiment-analysis

Folder ini berisi hasil-hasil (results, models, data) dari sub-proyek
social-media-sentiment-analysis, disimpan di path:
files/social-media-sentiment-analysis/

Rekomendasi struktur di dalam folder ini:
- results/   -> grafik, CSV, JSON hasil analisis
- models/    -> model serialized (.pkl, .h5, dsb.)
- data/      -> salinan data raw/processed (jika perlu)

Catatan:
- Jangan commit file >100 MB tanpa Git LFS.
- Gunakan skrip `scripts/collect_hasil.py` untuk menyalin file dari folder proyek ke sini.
  Contoh:
  python .\scripts\collect_hasil.py -p ''social-media-sentiment-analysis\results\**\*'' -o files\social-media-sentiment-analysis
