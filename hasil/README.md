# Folder hasil

Folder ini berisi kumpulan hasil perhitungan, data raw, dan data processed yang dikumpulkan
dari seluruh proyek.

Struktur rekomendasi:
- social-media-sentiment-analysis/results/   -> hasil analisis (grafik, csv, json)
- social-media-sentiment-analysis/models/    -> model trained (.pkl, .h5)
- social-media-sentiment-analysis/data/      -> salinan data raw/processed (jika perlu)

Gunakan skrip `scripts/collect_hasil.py` untuk membuat folder ini:
Contoh (PowerShell):
`python .\scripts\collect_hasil.py -p 'social-media-sentiment-analysis\results\**\*' 'social-media-sentiment-analysis\models\**\*' -o hasil`

Catatan penting:
- Jangan commit file >100 MB tanpa Git LFS.
- Jika skrip mengeluarkan "No files matched the given patterns.", sesuaikan pola glob dan jalankan dari root repo.
