# Folder hasil

Folder ini berisi kumpulan hasil perhitungan, data raw, dan data processed yang dikumpulkan
dari seluruh proyek.

Struktur:
- raw/           -> salinan data mentah
- processed/     -> data yang telah diproses
- outputs/       -> hasil model, pickles, prediksi, dsb.

Gunakan skrip `scripts/collect_hasil.py` untuk membangun folder ini dari pola file di repo:
Contoh (PowerShell):
`python .\scripts\collect_hasil.py -p ''data/raw/*.csv'' ''data/processed/*.csv'' ''outputs/**/*.pkl'' -o hasil`

Catatan:
- Jangan commit file >100 MB tanpa Git LFS.
- Jika skrip tidak menemukan file, cek pola glob dan jalankan dari root repo.
