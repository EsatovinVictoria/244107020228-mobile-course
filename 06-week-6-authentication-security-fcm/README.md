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