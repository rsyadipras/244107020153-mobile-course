## Perbandingan berdasarkan kriteria

| Teknologi | Kompleksitas query | Kebutuhan relasi | Reaktivitas (stream) | Type-safety | Ukuran boilerplate | Kemudahan testing |
|---|---|---|---|---|---|---|
| **SharedPreferences** | Sangat rendah; hanya baca/tulis primitive berdasarkan key. Tidak cocok untuk `WHERE`, sort, join, atau pagination. | Tidak ada. | Tidak menyediakan stream perubahan data; perubahan biasanya diteruskan manual ke state management. | Rendah; tipe dibatasi pada `bool`, `int`, `double`, `String`, dan list `String`, tetapi key dan cast tetap manual. | **Paling kecil** untuk beberapa flag. | Mudah untuk repository jika akses plugin di-inject atau dibungkus adapter; pengujian integrasi memerlukan plugin/platform. |
| **Hive** | Rendah sampai sedang; lookup key cepat, tetapi filter/sort kompleks umumnya dilakukan di Dart dan dapat memerlukan scan box. | Tidak ada foreign key/join; relasi dibuat dan dijaga oleh kode aplikasi. | Baik untuk perubahan box melalui `box.watch()`; integrasi stream perlu dipetakan ke model aplikasi. | Sedang sampai tinggi setelah membuat `TypeAdapter`; schema tidak seketat SQL dan migrasi field perlu dirancang. | Kecil sampai sedang; perlu adapter, box, dan aturan migrasi. | Baik dengan box sementara/in-memory atau path database sementara; perlu menguji adapter dan migrasi. |
| **sqflite (SQLite)** | **Tinggi**; SQL mendukung `WHERE`, index, full-text/search tertentu, sort, pagination, aggregate, dan transaction. | Baik; SQLite mendukung foreign key, tetapi query join dan mapping ditulis manual. | Tidak built-in. Setelah mutation, aplikasi harus reload/invalidate atau membuat mekanisme stream sendiri. | Rendah sampai sedang; SQL dan `Map<String, Object?>` tidak diverifikasi saat compile time. | Sedang; perlu SQL schema, migration, mapping map/model, dan repository. | Baik; database dapat memakai file sementara atau in-memory, tetapi perlu fixture dan pengujian migration/query. |
| **Drift** | **Tinggi** dengan query SQL/DSL, index, pagination, transaction, aggregate, dan join. | Sangat baik; relasi dan query kompleks dapat didefinisikan pada tabel/DAO. | **Sangat baik**; `watch()` menghasilkan stream yang otomatis memperbarui saat tabel terkait berubah. | **Paling tinggi**; tabel, kolom, query result, dan DAO dihasilkan sebagai kode Dart bertipe. | Sedang sampai tinggi; ada definisi tabel, generator, DAO, dan migration strategy. | Sangat baik; query DAO dapat diuji dengan database sementara/in-memory dan hasilnya bertipe. |

## Trade-off setiap pilihan

### SharedPreferences

**Kelebihan:** API sederhana, dependency ringan, cocok untuk flag tema,
onboarding, atau pilihan pengguna yang hanya berupa primitive. Nilai preferensi
tidak perlu diperlakukan sebagai entitas yang dicari atau direlasikan.

**Kekurangan:** menyimpan daftar 1000 catatan sebagai satu JSON/string akan
membuat seluruh data harus dibaca dan ditulis ulang, tidak atomik per catatan,
tidak efisien untuk pencarian/pagination, dan rawan konflik saat data berubah.
Karena itu SharedPreferences hanya untuk preferensi, bukan database catatan.

### Hive

**Kelebihan:** penyimpanan key-value lokal yang cepat, API Dart-first, dan
`box.watch()` dapat memberi reaktivitas tanpa menulis SQL. Untuk aplikasi
catatan yang sederhana dan tanpa relasi, Hive dapat mengurangi kode.

**Kekurangan:** query relasional, join, aggregate, dan constraint tidak menjadi
kekuatan Hive. Filter/sort dapat berubah menjadi scan seluruh box di Dart.
Type-safety juga bergantung pada `TypeAdapter`, dan perubahan model harus
memiliki strategi migrasi/kompatibilitas sendiri. Untuk catatan yang kelak
memiliki tag, lampiran, atau sinkronisasi, model key-value lebih cepat menjadi
kode aplikasi yang kompleks.

### sqflite (SQLite)

**Kelebihan:** SQLite matang, transaksional, mendukung index dan query
relasional, serta cocok untuk ribuan catatan. SQL memudahkan optimasi yang
jelas, misalnya index pada `updated_at` atau pagination dengan `LIMIT`.
Dependencynya juga sudah digunakan proyek ini.

**Kekurangan:** `sqflite` adalah lapisan plugin yang relatif tipis. Developer
harus menjaga SQL, migration, nama kolom, dan konversi `Map` ke model secara
manual. Stream perubahan tidak tersedia secara otomatis; Riverpod pada
implementasi saat ini harus melakukan `reload()`/`invalidate()` setelah CRUD.
Kesalahan nama kolom atau tipe hasil query biasanya baru terlihat saat runtime.

### Drift

**Kelebihan:** mempertahankan kekuatan SQLite tetapi menambahkan schema/query
yang dikompilasi, generated data class, DAO, migration hooks, dan reactive
query (`watch`). Ini paling cocok bila daftar catatan harus selalu konsisten
setelah tambah/edit/hapus, atau bila fitur berkembang menjadi pencarian,
tagging, folder, dan sinkronisasi offline-first.

**Kekurangan:** generator menambah dependency dan langkah build, sehingga
setup awal serta migration lebih besar daripada sqflite langsung. Untuk
aplikasi yang hanya menyimpan beberapa row sederhana, boilerplate Drift dapat
terasa berlebihan. Tim juga harus memahami generated code dan menjaga versi
schema.

## Skema untuk 1000+ catatan

### Kotak entitas

```text
+---------------------------+
| notes                     |
+---------------------------+
| id           INTEGER  PK  |
| title        TEXT     NN  |
| body         TEXT     NN  |
| created_at   INTEGER  NN  |  epoch milliseconds
| updated_at   INTEGER  NN  |  epoch milliseconds
| dirty        INTEGER  NN  |  0 = synced, 1 = local change
+---------------------------+
| INDEX(updated_at DESC)    |
| INDEX(dirty)              |
+---------------------------+

            (opsional, jika ada tag)
                         1       N
+-------------------+           +-------------------+
| tags              |           | note_tags         |
+-------------------+           +-------------------+
| id INTEGER PK     |<--------->| note_id INTEGER FK|
| name TEXT UNIQUE  |      N  1 | tag_id  INTEGER FK|
+-------------------+           +-------------------+
                              PK(note_id, tag_id)
```

`created_at` dipisahkan dari `updated_at` agar urutan pembuatan dan urutan
perubahan tidak tercampur. `dirty` mempertahankan kebutuhan sinkronisasi
offline-first pada implementasi sekarang. Waktu dapat disimpan sebagai
integer epoch milliseconds agar sorting dan perbandingan tidak bergantung pada
format string; jika tetap memakai ISO-8601 seperti kode saat ini, pastikan
seluruh nilai menggunakan format dan timezone yang konsisten.

### SQL minimal

```sql
CREATE TABLE notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  dirty      INTEGER NOT NULL DEFAULT 1 CHECK (dirty IN (0, 1))
);

CREATE INDEX notes_updated_at_idx
  ON notes (updated_at DESC, id DESC);

CREATE INDEX notes_dirty_idx
  ON notes (dirty);
```

Untuk 1000+ catatan, jangan mengambil seluruh body jika layar hanya
menampilkan daftar judul. Gunakan query proyeksi kolom, pagination stabil, dan
index:

```sql
SELECT id, title, updated_at, dirty
FROM notes
ORDER BY updated_at DESC, id DESC
LIMIT 50 OFFSET 0;
```

Pada data yang terus bertambah, cursor pagination biasanya lebih stabil
daripada `OFFSET` besar:

```sql
SELECT id, title, updated_at, dirty
FROM notes
WHERE updated_at < :lastUpdatedAt
   OR (updated_at = :lastUpdatedAt AND id < :lastId)
ORDER BY updated_at DESC, id DESC
LIMIT 50;
```

Dengan Drift, tabel dan query di atas didefinisikan sebagai `Table`/DAO lalu
daftar dapat diekspos sebagai `watch()`; dengan sqflite, SQL dan pemetaan
`Map<String, Object?>` tetap harus ditulis serta diuji manual. Keduanya tetap
menggunakan SQLite yang sama, sehingga keputusan Drift terutama meningkatkan
keamanan tipe, reaktivitas, dan maintainability, bukan mengganti mesin
penyimpanannya.