# 06-week-6-authentication-security-fcm

## Tujuan 

1. Menjelaskan alur autentikasi (Firebase Auth / JWT / OAuth / Google Login) dan perbedaan ID token vs access token vs refresh token;
2. Menyimpan token secara aman dengan secure storage serta menerapkan token refresh otomatis;
3. Menjelaskan arsitektur FCM: app server, Firebase, dan perangkat;
4. Meminta notification permission dan mengelola token lifecycle (getToken, onTokenRefresh);
5. Membedakan notification payload vs data payload serta perilakunya pada state foreground, background, dan terminated;
6. Menangani klik notifikasi (deep link dengan GoRouter) dan topic messaging;
7. Menerapkan prinsip keamanan dasar aplikasi mobile (tidak menyimpan secret di kode, tidak log token).

## Praktikum 1: Login + Secure Storage + Token Refresh

Menyiapkan project

Menyimpan token yang aman

Membuat repository auth

Membut dio dengan refresh otomatis

Membuat provider auth dan guard route

Berikut merupakan tampilan aplikasi untuk pertama kalinya

![Tampilan Awal](screenshots/p1_tampilanAwal.png)

Berikut merupakan tampilan ketika menginputkan kridensial yang salah

![Tampilan Login Gagal](screenshots/p1_tampilanGagalLogin.png)

Berikut merupakan tampilan setelah berhasil login dengan valid

![Tampilan Login Berhasil](screenshots/p1_tampilanLoginBerhasil.png)

Berikut merupakan bukti routingnya berhasil setelah melakukan login

![Tampilan Routing Berhasil](screenshots/p1_tampilanPengumuman.png)

Setelah keluar dari aplikasi, lalu masuk kembali, akan langsung diarahkan ke beranda, sehingga tidak perlu login ulang.

## Praktikum 2: Firebase Cloud Messaging

Mendaftarkan aplikasi ke firebase

berikut merupakan tampilan dari firebase

![Tampilan Firebase](screenshots/p2_tampilanFirebase.png)

![Tampilan Firebase](screenshots/p2_tampilanSetelahDipasangFirebase.png)

Meminta izin notifikasi

Berikut merupakan tampilan ketika meminta izin notifikasi dari aplikasi

![Tampilan Izin Notifikasi](screenshots/p2_tampilanIzinNotifikasi.png)

Mmebuat toke lifecycle

Berikut merupakan tampilan debug untuk token

![Tampilan Debug Token](screenshots/p2_halamanDebug.png)

Menguji kirim pertama

Buka Firebase Console -> Messaging -> buat campaign notifikasi percobaan.
Masukkan title dan body, targetkan aplikasi Android Anda.
Kirim saat aplikasi dalam state background: banner sistem harus muncul. Klik banner: aplikasi terbuka.
Catat hasilnya sebagai bukti screenshots/fcm-console-test.png.

Berikut merupakan tampilan pada firebase untuk push notifications pertama

![Tampilan Push Notification](screenshots/p2_tampilanPengirimanNotifikasi.png)

Berikut merupakan tampilan notifikasi, dan aplikasi yang dibuka setelah notifikasi diklik

![Tampilan Notifikasi](screenshots/p2_tampilanNotifikasi.png)

![Tampilan Notifikasi Terbuka](screenshots/p2_tampilanSetelahNotifikasDiklik.png)

## Praktikum 3: Payload, Tiga App State, Klik dan Topik

Membuat Background Handler Top-Level

Menambahkan fungsi firebaseMessagingBackgroundHandler() pada file lib/messaging/push_service.dart. Fungsi diletakkan di luar kelas dan diberi anotasi @pragma('vm:entry-point').

Mendaftarkan handler melalui registerBackgroundHandler() pada main() sebelum menjalankan aplikasi. Handler digunakan untuk mencatat pesan background tanpa mengakses tampilan atau melakukan navigasi.

Membuat Tiga Handler dengan Payload Gabungan

Menggunakan payload gabungan yang berisi notification untuk judul dan isi notifikasi, serta data untuk menentukan halaman tujuan.

Menambahkan Custom data berikut saat mengirim notifikasi melalui Firebase Console:

| Key | Value |
| --- | --- |
| route | /pengumuman/3 |
| id | 3 |

Menguji Kondisi Foreground

Membuka aplikasi dan membiarkannya tampil di layar, kemudian mengirim notifikasi dari Firebase Console.

Berikut merupakan tampilan notifikasi lokal saat aplikasi berada di foreground.

![Notifikasi Foreground](screenshots/p3_foregroundTampilanNotifikasiLocal.png)

Mengetuk notifikasi untuk membuka halaman pengumuman dengan ID 3.

![Halaman Setelah Klik Notifikasi Foreground](screenshots/p3_foregroundTampilanSetelahNotifikasiLokalDipencet.png)

Menguji Kondisi Background

Menekan tombol Home pada emulator untuk memindahkan aplikasi ke background, kemudian mengirim notifikasi baru dengan payload yang sama.

Berikut merupakan tampilan notifikasi sistem saat aplikasi berada di background.

![Notifikasi Background](screenshots/p3_backgroundTampilanNotifikasi.png)

Mengetuk notifikasi untuk membuka halaman pengumuman dengan ID 3.

![Halaman Setelah Klik Notifikasi Background](screenshots/p3_backgroundTampilanNotifikasiDIKlik.png)

Menguji Kondisi Terminated

Menutup aplikasi dengan menggeser kartu Campus Notify pada Recent Apps, kemudian mengirim notifikasi baru dengan payload yang sama.

Berikut merupakan tampilan notifikasi ketika aplikasi sudah ditutup.

![Notifikasi Terminated](screenshots/p3_terminatedTampilanNotifikasi.png)

Mengetuk notifikasi untuk menjalankan aplikasi dan membuka halaman pengumuman dengan ID 3

![Halaman Setelah Klik Notifikasi Terminated](screenshots/p3_terminatedTampilanSetelahDiklik.png)

### Matriks Pengujian

| State | Yang Diharapkan | Cara Uji | Hasil Pengujian |
| --- | --- | --- | --- |
| Foreground | Notifikasi lokal muncul dan klik membuka /pengumuman/3 | Membuka aplikasi, mengirim pesan, lalu mengetuk notifikasi | Notifikasi diterima dan klik membuka pengumuman ID 3 |
| Background | Notifikasi sistem muncul dan klik membuka /pengumuman/3 | Menekan Home, mengirim pesan, lalu mengetuk notifikasi | Notifikasi diterima dan klik membuka pengumuman ID 3 |
| Terminated | Aplikasi terbuka ke /pengumuman/3 melalui getInitialMessage() | Menutup aplikasi melalui Recent Apps, mengirim pesan, lalu mengetuk notifikasi | Aplikasi berjalan kembali dan membuka pengumuman ID 3 |

Topic Messaging

Menambahkan tombol Subscribe dan Unsubscribe pada halaman Debug untuk mengatur langganan topik pengumuman-kampus.

Menggunakan subscribeToTopic() untuk berlangganan dan unsubscribeFromTopic() untuk berhenti berlangganan.

Berikut merupakan tampilan tombol pengaturan topik pada halaman Debug.

![Halaman Debug Topic Messaging](screenshots/p3_tampilanDebugFCM.png)

Memilih Topic dengan nama pengumuman-kampus sebagai target pengiriman pada Firebase Console.

Uji Topik A: Subscribe

Menekan tombol Subscribe dan menunggu proses berhasil, kemudian mengirim notifikasi berjudul “Uji Topik A”.

Berikut merupakan bukti pengujian saat aplikasi berlangganan topik.

![Pengujian Subscribe Topik A](screenshots/p3_tampilanNotifikasiBerlangganan.png)

Uji Topik B: Unsubscribe

Menekan tombol Unsubscribe dan memastikan status berubah menjadi “Tidak berlangganan pengumuman-kampus”.

Menghapus notifikasi lama, kemudian mengirim pesan baru berjudul “Uji Topik B” ke topik yang sama. Mengamati panel notifikasi dan terminal tanpa melakukan restart aplikasi.

Berikut merupakan panel notifikasi selama pengamatan Uji Topik B.

![Pengamatan Uji Topik B](screenshots/p3_tampilanTidakBerlangganan.png)

Uji Topik C: Subscribe Kembali

Menekan tombol Subscribe kembali, kemudian mengirim pesan baru berjudul “Uji Topik C ke topik yang sama.

Berikut merupakan bukti pengujian setelah berlangganan kembali.

![Pengujian Subscribe Kembali Topik C](screenshots/p3_tampilanNotifikasiBerlanggananLagi.png)

#### Hasil Pengujian Topik

| Pengujian | Status Langganan | Yang Diharapkan | Hasil Pengamatan |
| --- | --- | --- | --- |
| Uji Topik A | Subscribe | Pesan diterima | [Isi sesuai hasil pengujian] |
| Uji Topik B | Unsubscribe | Pesan tidak diterima | [Isi hasil dan durasi pengamatan] |
| Uji Topik C | Subscribe kembali | Pesan kembali diterima | [Isi sesuai hasil pengujian] |