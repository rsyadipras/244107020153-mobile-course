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
