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