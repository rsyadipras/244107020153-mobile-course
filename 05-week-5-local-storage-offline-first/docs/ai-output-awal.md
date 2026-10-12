## Ruang lingkup

Aplikasi memiliki dua jenis data dengan karakter yang berbeda:

1. **Preferensi tema**, misalnya `dark_mode` dan waktu terakhir aplikasi dibuka.
   Datanya sedikit, berbentuk pasangan key-value, dan tidak membutuhkan
   pencarian.
2. **Catatan**, yaitu data CRUD yang dapat berjumlah 1000 atau lebih. Catatan
   berpotensi membutuhkan pengurutan, pencarian, filter, pagination, status
   sinkronisasi, dan relasi tambahan seperti tag.

Di implementasi saat ini, `SharedPreferences` dipakai untuk preferensi dan
`sqflite` + SQLite dipakai untuk catatan. Perbandingan berikut menilai keempat
opsi untuk kedua kebutuhan tersebut.

## Rekomendasi final

| Kebutuhan | Pilihan final | Alasan utama | Trade-off yang diterima |
|---|---|---|---|
| Preferensi tema dan metadata kecil | **SharedPreferences** | Data hanya primitive key-value (`dark_mode`, `last_opened_at`), tidak perlu relasi, query, atau stream database. API paling sederhana dan sudah sesuai dengan `PrefsRepository`. | Tidak ada query/relasi dan perubahan tidak otomatis menjadi stream; notifier tetap memperbarui state setelah `set`. |
| Catatan CRUD untuk 1000+ row | **Drift di atas SQLite** | SQLite memberi query, index, transaction, dan relasi; Drift menambahkan type-safety, DAO, dan stream `watch()` sehingga UI reaktif tanpa reload manual. Ukuran 1000+ catatan masih wajar untuk SQLite. | Setup/generator dan migration lebih besar. Jika scope tugas harus mempertahankan dependency yang sekarang dan belum memerlukan stream, `sqflite` adalah pilihan pragmatis sementara; migrasi ke Drift tetap lebih aman untuk pertumbuhan fitur. |

Rekomendasi ini tidak berarti Hive buruk. Hive adalah pilihan yang masuk akal
untuk model sederhana tanpa relasi dan ketika kecepatan implementasi lebih
penting daripada query relasional. Namun untuk aplikasi Notes yang dapat
berkembang, Drift mengurangi risiko query dan mapping yang tidak sinkron.