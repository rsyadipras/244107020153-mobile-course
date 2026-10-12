# Decision Storage

## Keputusan final

- **Preferensi tema:** menggunakan `SharedPreferences`.
- **Catatan:** menggunakan `sqflite` dengan database SQLite.

## Alasan keputusan

1. `SharedPreferences` sesuai untuk data kecil berbentuk key-value, seperti
   `dark_mode` dan `last_opened_at`. Daftar catatan tidak disimpan di
   `SharedPreferences karena tidak efisien untuk CRUD dan data dalam jumlah
   besar.
2. SQLite cocok untuk kebutuhan catatan karena mendukung CRUD, query, dan
   penyimpanan 1000+ catatan.
3. Skema tabel `notes` sudah memiliki `dirty` dan `updated_at` untuk membantu
   proses sinkronisasi offline.
4. `sqflite` dan `SharedPreferences` sudah tersedia serta telah digunakan
   dalam implementasi, sehingga boilerplate tetap lebih kecil.

## Catatan tentang real-time

Implementasi saat ini belum menggunakan stream database. Setelah perubahan,
data diperbarui melalui `reload` atau `invalidate` Riverpod. Karena itu,
aplikasi belum diklaim real-time secara otomatis.