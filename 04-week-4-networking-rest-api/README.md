# 04-week-4-networking-rest-api

## Tujuan 

1. Menjelaskan konsep HTTP, REST API, dan JSON;
2. Memetakan JSON ke model Dart (serialization) dengan aman null;
3. Menerapkan repository pattern dasar sehingga UI tidak memanggil API secara langsung;
4. Mengonfigurasi Dio (base URL, timeout, interceptor) dan menangani error jaringan;

## Praktikum 1: Dio dan model data

Membuat data dengan fromJson aman null

Mengonfigurasi Dio terpusat

Membuat repository sebagai pintu data

## Praktikum 2: Provider dan error handling

Membuat Provider AsyncNotifier dan pesan error ramha pengguna

Membuat UI loading, error, empty, success

Mengentry point dnegan ProviderScope

Uji tigas skenario

1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.

    Ketika aplikasi dijalankan dengan koneksi internet normal, sistem akan menampilkan indikator loading selama proses pengambilan data dari API. Setelah data berhasil diterima, aplikasi akan menampilkan daftar post yang diperoleh melalui endpoint.

    ![Tampilan Loading](screenshots/p2_tampilanLoading.png)

    ![Tampilan awal](screenshots/p2_tampilanAwal.png)

2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.

    Ketika koneksi internet dimatikan dan tombol refresh ditekan, aplikasi akan mencoba mengambil ulang data dari server. Karena tidak terdapat koneksi internet, proses tersebut gagal dan aplikasi menampilkan pesan yang lebih mudah dipahami oleh pengguna, yaitu "Tidak dapat terhubung dengan server. Periksa internet anda", serta menyediakan tombol Coba lagi.

    Setelah koneksi internet dinyalakan kembali dan tombol Coba lagi ditekan, ref.invalidate(postListProvider) akan menjalankan ulang provider sehingga aplikasi mencoba mengambil data kembali. Apabila koneksi telah kembali normal, daftar post akan berhasil ditampilkan kembali.

    ![Tampilan Offline](screenshots/p2_tampilanOffline.png)

3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.

    ada pengujian ini, baseUrl yang sebelumnya mengarah ke server JSONPlaceholder diubah sementara menjadi URL yang salah. Hal tersebut menyebabkan aplikasi tidak dapat terhubung ke server sehingga DioException ditangani oleh fungsi friendlyErrorMessage() dan aplikasi menampilkan pesan error koneksi yang lebih mudah dipahami pengguna.

    Setelah pengujian selesai, baseUrl dikembalikan ke URL yang benar agar aplikasi dapat kembali terhubung ke API dan mengambil data post seperti semula.

    ![Tampilan Error](screenshots/p2_tampilanUrlSalah.png) 

## Praktikum 3: Pagination dasar

Membuat repositori paginated

Membuat notifier dengan state halaman

Membuat UI infinite Scroll

Berikut merupakan tampilan ketika diterapkan pagination.

![Tampilan Pagination](screenshots/p3_pagiantion1.png)

![Tampilan Pagination](screenshots/p3_pagiantion2.png)

Terlihat pada aplikasi yakni pagination telah diterapkan dengan bukti bahwa ketika sebelum discroll hingga batas bawah, maka aplikasi tidka memunculkan 10 item berikutnya, dan hanya menampilkan indikator loading. Setelah discroll hingga batas bawah, maka aplikasi memunculkan 10 item berikutnya.