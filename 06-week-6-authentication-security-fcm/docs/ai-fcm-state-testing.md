## Hasil Pengujian FCM Tiga App State

Pengujian menggunakan Firebase Console dengan payload gabungan
`notification + data`. Data route yang digunakan:

```json
{
  "route": "/pengumuman/3",
  "id": "3"
}
```

| State      | Cara uji                                            | Hasil yang diharapkan                                                    | Hasil aktual | Bukti                                         |
| ---------- | --------------------------------------------------- | ------------------------------------------------------------------------ | ------------ | --------------------------------------------- |
| Foreground | Aplikasi terbuka, kirim pesan dari Firebase Console | Local notification muncul; klik menuju `/pengumuman/3`                   | Berhasil     | [Foreground](../screenshots/Foreground_1.mp4) |
| Background | Tekan Home, kirim pesan, klik banner sistem         | Banner sistem muncul; klik menuju `/pengumuman/3`                        | Berhasil     | [Background](../screenshots/Background-1.mp4) |
| Terminated | Swipe-close aplikasi, kirim pesan, klik banner      | Aplikasi dibuka melalui `getInitialMessage()` dan menuju `/pengumuman/3` | Berhasil     | [Terminated](../screenshots/Terminated_1.mp4) |

### Titik kode yang diverifikasi

- Foreground: `PushService.listen()` dan `_showForegroundNotification()`
  pada `lib/messaging/push_service.dart`.
- Background click: listener `FirebaseMessaging.onMessageOpenedApp`.
- Terminated click: `PushService.handleTerminated()` dengan
  `FirebaseMessaging.instance.getInitialMessage()`.
- Navigasi: `pushService.listen(_router.go)` dan
  `pushService.handleTerminated(_router.go)` pada `lib/main.dart`.

### Catatan payload

Pesan foreground memakai local notification manual karena banner sistem tidak otomatis muncul saat aplikasi terbuka. Pesan background dan terminated memakai notification payload agar Android menampilkan banner sistem. `data.route`digunakan untuk menentukan halaman tujuan.

---
### Hasil AI Clean Architecture

#### Tabel Usulan vs Keputusan Final

| Topik / Komponen         | Usulan AI                                                              | Keputusan Final                                                        | Alasan / Catatan                                                                         |
| ------------------------ | ---------------------------------------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Struktur Folder**      | _Feature-First_ (`lib/features/...`)                                   | _Feature-First_ (`lib/features/...`)                                   | Memudahkan navigasi dan pengembangan modul secara terisolasi.                            |
| **Pemisahan Repository** | Interface di `domain`, Implementasi di `data`                          | Interface di `domain`, Implementasi di `data`                          | Menjaga prinsip _Dependency Inversion_ agar layer domain tidak tergantung detail teknis. |
| **Penggunaan Use Case**  | Khusus logika kompleks (`Login`, `RefreshSession`, `GetAnnouncements`) | Khusus logika kompleks (`Login`, `RefreshSession`, `GetAnnouncements`) | Mencegah _over-engineering_ dan menjaga basis kode tetap bersih dari file satu baris.    |
| **Dependency Injection** | Terpusat menggunakan Riverpod `Provider`                               | Terpusat menggunakan Riverpod `Provider`                               | Memastikan widget terbebas dari pemanggilan konstruktor objek (_decoupling_).            |
| **Service Messaging**    | Bertahan di `lib/messaging/push_service.dart`                          | Dipindah ke `lib/core/messaging/push_service.dart`                     | Agar seluruh utilitas lintas fitur dikelompokkan secara terpusat di dalam folder `core`. |

