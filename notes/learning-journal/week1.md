# Journal Learning Week 1

## Evolusi Pengembangan Aplikasi Mobile

Native: Akses API perangkat paling optimal (Kotlin/Swift).
Hybrid: Aplikasi berbasis web yang dibungkus kerangka native (Ionic/Cordova).
Cross-platform: Satu basis kode untuk beberapa platform sekaligus (Flutter/React Native). Pemilihan teknologi bergantung pada kebutuhan performa, keahlian tim, dan biaya.

## Arsitektur Flutter & Peran Dart

Struktur Arsitektur -> Framework (Widget & API), Engine (Rendering & Grafis), dan Embedder (Penghubung ke sistem operasi).
Peran Dart -> Menggunakan mode JIT (Just-In-Time) untuk kecepatan iterasi saat pengembangan, dan AOT (Ahead-Of-Time) untuk performa maksimal saat deploy.

## Widget Tree & Struktur Proyek

Konsep Deklaratif: UI dibuat berdasarkan kondisi state saat ini. Seluruh komponen berbentuk widget yang tersusun secara hierarkis (Widget Tree)

- `MaterialApp` -> fondasi seluruh aplikasi
- `Scaffold` -> struktur dasar setelah fondasi(`MaterialApp`)
- `Column` -> posisi susunan elemen dari atas terlebih dahulu menuju ke bawah dan berada setelah `Scaffold`
- Text -> salah satu elemen yang ada di dalam `Column` yang fungsinya untuk menampilkan teks.

Struktur Direktori Kunci:

- `lib/`: Lokasi kode utama aplikasi (lib/main.dart sebagai entry point).
- `pubspec.yaml`: Manajemen dependensi, aset, dan metadata proyek.
- `test/`: Tempat pengujian unit dan widget.
- `android/, ios/, web/`: Konfigurasi spesifik tiap target platform.

## Hot Reload vs Hot Restart

Hot Reload: refresh aplikasi dengan cepat ketika ada perubahan kode tanpa harus mematikan state, baik untuk melihat perubahan langsung, seperti modifikasi UI, dsb.

Hot Restart: memulai ulang aplikasi secara keseluruhan.

## Dasar Dart & Null Safety

Sistem Tipe Data: Bertipe statis dengan dukungan tipe inferensi (tanpa sebut tipe data). Gunakan kata kunci `final` untuk nilai yang bersifat inisialisasi sekali (_single-assignment_).

Null Safety: Secara bawaan variabel tidak boleh bernilai _null (non-nullable)_. Tanda `?` digunakan jika nilai memang diizinkan _null_, dan hindari penggunaan operator `!` tanpa kepastian data.
