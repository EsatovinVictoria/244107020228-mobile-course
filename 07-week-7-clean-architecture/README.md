# 07-week-7-clean-architecture

## Tujuan

1. Menjelaskan prinsip SOLID dan separation of concerns dengan contoh kode Flutter.
2. Membedakan struktur feature-first vs layer-first beserta trade-off-nya.
3. Menjelaskan tiga layer (presentation, domain, data) dan aturan dependensi (dependensi mengarah ke dalam).
4. Membedakan entity vs model serta peran repository, use case, dan dependency injection.
5. Merefactor project Minggu 5/6 menjadi struktur feature-first yang terpisah layer-nya.
6. Menguji use case dengan repository palsu tanpa database atau jaringan sungguhan.

## Praktikum 1: Audit Layer Project Lama

| File | Layer saat ini | Masalah / Catatan Audit |
| --- | --- | --- |
| pages/home_page.dart | Presentation | Sudah berfokus pada tampilan, navigasi, dan pemanggilan logout melalui notifier. Tidak ditemukan akses Dio, database, penyimpanan token, parsing JSON, atau pemformatan tanggal di widget. Navigasi sudah menggunakan konstanta AppRoutes. Tidak ditemukan pelanggaran pemisahan layer pada file ini. |
| data/api_client.dart | Data / Infrastruktur jaringan | Mengatur Dio, header autentikasi, dan interceptor refresh token. Masih bergantung pada kelas konkret AuthRepository dan TokenStore. Base URL masih berupa alamat contoh yang ditulis langsung dalam kode. Retry setelah respons 401 belum memiliki batas percobaan sehingga berisiko melakukan refresh berulang. Belum ada pengaturan untuk mencegah beberapa request 401 melakukan refresh secara bersamaan. Pemakaian API client perlu ditelusuri pada file lain untuk memastikan widget tidak mengaksesnya langsung. |
| providers/auth_provider.dart | Presentation (state) + DI | Provider membuat TokenStore dan AuthRepository secara langsung serta menyediakan Dio. AuthNotifier membaca, menyimpan, dan menghapus token langsung melalui TokenStore, sehingga pengelolaan sesi masih bercampur dengan pengelolaan state UI. |
| data/auth_repository.dart | Data + model sesi + logika autentikasi | AuthRepository berupa kelas konkret tanpa interface domain terpisah. AuthSession, validasi input, serta simulasi login dan refresh masih berada dalam satu file. |


Menandai tiga pelanggaran klasik, dengan melakukan grep di project.

Berikut merupakan hasil tiga pola pelanggaran klasik

![Tiga Pelanggaran Klasik](screenshots/p1_widgetMenyentuhDatabase.png)

![Tiga Pelanggaran Klasik](screenshots/p1_logikaBisnisDiBuild.png)

![Tiga Pelanggaran Klasik](screenshots/p1_instansiasiManualDIbocor.png)

Pencarian dilakukan menggunakan Select-String pada PowerShell karena rg belum tersedia.

| Pemeriksaan | Lokasi pencarian | Hasil | Catatan |
| --- | --- | --- | --- |
| Akses jaringan/database/penyimpanan langsung pada widget | lib/pages | Tidak ditemukan | Tidak ada kode yang cocok dengan pola pencarian. |
| Pengolahan data pada widget | lib/pages | Tidak ditemukan | Tidak ditemukan DateFormat, jsonDecode, atau .toIso8601String. |
| Instansiasi manual repository atau Dio | lib/pages, lib/providers | auth_provider.dart, baris 13: return AuthRepository(); | Repository konkret dibuat dalam provider yang masih satu file dengan notifier autentikasi. Wiring dependency akan dipisahkan dari pengelolaan state. |

Pembuatan repository dalam provider DI tidak otomatis merupakan pelanggaran. Temuan ini menjadi bahan refactor karena penyusunan dependency dan notifier masih berada dalam satu file. Tidak adanya kecocokan pada pencarian lain juga belum menjamin seluruh pemisahan layer sudah benar.


Gambar struktur target

Refactor difokuskan pada fitur auth yang sudah tersedia pada Campus Notify. Struktur berikut merupakan rencana.

```text
lib/
├── main.dart
├── routes.dart
├── core/
│   ├── failures.dart
│   └── network/
│       ├── api_client.dart
│       └── api_errors.dart
├── features/
│   └── auth/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── auth_session.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── check_auth_session.dart
│       │       ├── login.dart
│       │       └── logout.dart
│       ├── data/
│       │   ├── datasources/
│       │   │   └── token_store.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── di/
│       │   └── auth_providers.dart
│       └── presentation/
│           ├── providers/
│           │   └── auth_state_provider.dart
│           └── pages/
│               └── login_page.dart
├── messaging/
│   └── push_service.dart
└── pages/
    ├── announcement_page.dart
    ├── debug_page.dart
    └── home_page.dart
```

AuthSession menjadi entity domain, AuthRepository menjadi kontrak, dan AuthRepositoryImpl menyediakan implementasinya. TokenStore tetap berada pada data. Penyusunan dependency ditempatkan pada folder di, sedangkan notifier dan halaman login berada pada presentation.

Fitur pengumuman dan messaging tetap dipertahankan. Tidak ada fitur notes baru yang ditambahkan.


## Praktikum 2: Domain dan Data per Fitur

Menerapkan pemisahan domain dan data pada fitur auth yang sudah tersedia di Campus Notify. Implementasi autentikasi tetap menggunakan simulasi seperti pada project Minggu 6.

Membuat entity murni

Membuat AuthSession pada lib/features/auth/domain/entities/auth_session.dart untuk menyimpan access token dan refresh token. Entity tidak mengimpor Flutter atau plugin serta tidak melakukan mapping data.

Membuat failure dan kontrak repository

Membuat lib/core/failures.dart yang berisi Failure, LocalFailure, NetworkFailure, dan AuthFailure. Failure digunakan untuk menyampaikan kegagalan melalui pesan tanpa meneruskan exception mentah ke presentation.

Membuat interface AuthRepository pada lib/features/auth/domain/repositories/auth_repository.dart. Kontrak menyediakan operasi checkSession, login, refresh, dan logout.

Hasil operasi menggunakan record Dart yang memuat data hasil dan Failure. Implementasi penyimpanan serta proses autentikasi tidak diletakkan pada kontrak domain.

Membuat implementasi data

Menyalin TokenStore ke lib/features/auth/data/datasources/token_store.dart. File lama pada lib/data/token_store.dart tetap dipertahankan sementara karena masih digunakan oleh provider lama.

Membuat AuthRepositoryImpl pada lib/features/auth/data/repositories/auth_repository_impl.dart untuk mengimplementasikan kontrak AuthRepository. TokenStore diberikan melalui constructor agar dependency penyimpanan tidak dibuat langsung di dalam repository.

Repository menangani pembacaan sesi, penyimpanan token setelah login dan refresh, serta penghapusan token saat logout. Kegagalan penyimpanan dikembalikan sebagai LocalFailure.

Model belum dibuat karena autentikasi masih menggunakan simulasi dan belum memerlukan mapping respons API. Data sesi menggunakan entity AuthSession. Mapping akan ditempatkan pada data layer ketika integrasi API diterapkan.

Membuat use case

Membuat use case pada lib/features/auth/domain/usecases untuk menyediakan operasi autentikasi melalui kontrak repository.

| File | Fungsi |
| --- | --- |
| check_auth_session.dart | Memeriksa keberadaan sesi melalui repository. |
| login.dart | Memvalidasi email dan panjang password sebelum memanggil repository untuk login. |
| logout.dart | Memanggil repository untuk menghapus sesi login. |

Use case Login memiliki aturan validasi sehingga input yang tidak valid tidak diteruskan ke repository. CheckAuthSession dan Logout saat ini meneruskan operasi repository untuk menyediakan alur pemanggilan yang konsisten.

Berikut merupakan struktur domain dan data fitur auth setelah file dibuat.

![Struktur Domain dan Data Auth](screenshots/p2_strukturSetelahRefactor.png)

Melakukan pemeriksaan kode

Menjalankan dart format dan flutter analyze. Memperbaiki saran prefer_initializing_formals dengan menggunakan constructor AuthRepositoryImpl(this._tokenStore).

Berikut merupakan hasil pemeriksaan static analysis setelah perbaikan.

![Hasil Flutter Analyze](screenshots/p2_flutterAnalyze.png)

Memeriksa import pada domain menggunakan Select-String. Pencarian import package digunakan untuk memastikan domain tidak bergantung pada Flutter atau plugin.

Berikut merupakan hasil pemeriksaan import domain.

![Pemeriksaan Import Domain](screenshots/p2_pemeriksaanImportDomain.png)

Pada tahap ini, domain dan data baru belum dihubungkan ke presentation. Aplikasi masih menggunakan provider dan repository lama. Penyusunan DI, penghubungan notifier ke use case, serta penghapusan file lama dilakukan pada Praktikum 3.

## Praktikum 3: Presentation, DI, dan Verifikasi

Menghubungkan domain dan data fitur auth ke presentation menggunakan Riverpod. Refactor dilakukan pada fitur autentikasi yang sudah tersedia di Campus Notify.

Membuat dependency injection dengan Riverpod

Membuat lib/features/auth/di/auth_providers.dart untuk menyusun dependency TokenStore, AuthRepositoryImpl, dan use case autentikasi.

Provider repository menggunakan kontrak AuthRepository, sedangkan implementasinya menggunakan AuthRepositoryImpl. Use case menerima kontrak repository sehingga implementasi dapat diganti dengan repository palsu saat pengujian.

| Provider | Fungsi |
| --- | --- |
| tokenStoreProvider | Menyediakan penyimpanan token. |
| authRepositoryProvider | Menyediakan implementasi melalui kontrak AuthRepository. |
| checkAuthSessionProvider | Menyediakan use case pemeriksaan sesi. |
| loginUseCaseProvider | Menyediakan use case login. |
| logoutUseCaseProvider | Menyediakan use case logout. |

Membuat lib/di/app_providers.dart untuk menyediakan API client dan PushService yang digunakan lintas halaman. DebugPage dan main.dart memperoleh PushService melalui provider.

Menghubungkan notifier ke use case

Membuat lib/features/auth/presentation/providers/auth_state_provider.dart untuk mengelola state autentikasi.

AuthNotifier memanggil CheckAuthSession, Login, dan Logout melalui provider. Pembacaan, penyimpanan, serta penghapusan token dilakukan oleh repository, sehingga notifier tidak mengakses TokenStore secara langsung.

Notifier menyediakan state loading, berhasil, dan gagal untuk ditampilkan oleh halaman. Pesan Failure diteruskan sebagai pesan kesalahan tanpa menampilkan exception penyimpanan mentah.

Memisahkan halaman dari pengelolaan data

Memindahkan halaman login dari lib/pages/login_page.dart ke lib/features/auth/presentation/pages/login_page.dart.

LoginPage membaca authStateProvider dan memanggil notifier ketika tombol Login ditekan. Validasi email dan panjang password berada pada use case Login, sedangkan penyimpanan sesi berada pada data layer.

Memperbarui import pada main.dart dan HomePage agar menggunakan provider autentikasi yang baru.

Mengubah DebugPage agar memperoleh PushService melalui pushServiceProvider. Pesan kegagalan subscribe dan unsubscribe ditampilkan menggunakan pesan ramah pengguna.

Merapikan file lama

Memindahkan API client dan pemetaan pesan kesalahan ke lib/core/network. API client menerima callback pengelolaan sesi yang dihubungkan melalui DI.

Menghapus provider, repository, penyimpanan token, dan halaman login lama setelah seluruh pemanggilan menggunakan struktur baru.

Berikut merupakan struktur folder sebelum dan sesudah setelah penghubungan presentation dan DI.

![Struktur Setelah Refactor](screenshots/p3_strukturSebelumRefactor.png)

![Struktur Setelah Refactor](screenshots/p3_strukturSesudahRefactor.png)

Melakukan verifikasi dependency rule

Menjalankan pencarian menggunakan Select-String pada PowerShell karena rg belum tersedia.

| Pemeriksaan | Lokasi pencarian | Hasil |
| --- | --- | --- |
| Akses data mentah pada presentation | lib/features/auth/presentation dan lib/pages | Tidak ditemukan kecocokan dengan pola pencarian. |
| Import package pada domain | lib/features/auth/domain | Tidak ditemukan. |
| Import package pada failure domain | lib/core/failures.dart | Tidak ditemukan. |

Pemeriksaan domain dilakukan pada lib/features/auth/domain dan lib/core/failures.dart. Folder lib/core/network merupakan infrastruktur jaringan yang menggunakan Dio sehingga tidak termasuk bagian domain murni.

Berikut merupakan hasil pemeriksaan presentation.

![Pemeriksaan Presentation](screenshots/p3_presentationAksesDataMentah.png)

Berikut merupakan hasil pemeriksaan import domain dan failure.

![Pemeriksaan Domain](screenshots/p3_domainDanFailureDariImportPackage.png)

Tidak adanya kecocokan menunjukkan bahwa pola yang diperiksa tidak ditemukan. Pemeriksaan ini dilengkapi dengan peninjauan alur dependency pada kode.

Melakukan static analysis dan pengujian otomatis

Menjalankan flutter analyze setelah penghubungan seluruh file untuk memeriksa kesalahan dan peringatan kode.

Berikut merupakan hasil static analysis terbaru.

![Hasil Flutter Analyze](screenshots/p3_flutterAnalyze.png)

Menjalankan flutter test. Enam pengujian routeFromMessage berhasil dengan hasil All tests passed.

Pengujian mencakup rute pengumuman valid, rute Home, payload kosong, tipe route yang tidak sesuai, penolakan rute tidak valid, dan pemilihan tujuan ketika route berbeda dengan id.

Berikut merupakan hasil pengujian otomatis.

![Hasil Flutter Test](screenshots/p3_flutterTest.png)

Pengujian yang tersedia saat ini memverifikasi parsing rute notifikasi. Pengujian use case auth menggunakan repository palsu belum ditambahkan.

Melakukan pengujian manual

Menjalankan aplikasi pada emulator Android dan mencoba alur fitur untuk membandingkan perilaku sebelum serta setelah refactor. Autentikasi masih menggunakan simulasi seperti pada Minggu 6.

| Fitur | Cara pengujian | Hasil yang diharapkan | Hasil aktual |
| --- | --- | --- | --- |
| Login gagal | Memasukkan email tanpa @ atau password kurang dari enam karakter. | Pesan kesalahan muncul dan tetap di halaman login. | Belum dicatat. |
| Login berhasil | Memasukkan mahasiswa@kampus.ac.id dan password 123456. | Halaman Home terbuka. | Belum dicatat. |
| Sesi login | Menutup dan membuka kembali aplikasi setelah login. | Sesi tersimpan dan halaman Home terbuka. | Belum dicatat. |
| Logout | Menekan tombol logout pada Home. | Kembali ke halaman login. | Belum dicatat. |
| Pengumuman | Menekan Buka Pengumuman. | Halaman pengumuman dengan ID 1 terbuka. | Belum dicatat. |
| Notifikasi | Mengirim dan mengeklik notifikasi pada foreground, background, dan terminated. | Notifikasi membuka tujuan sesuai payload. | Belum dicatat. |
| Topik | Menekan Subscribe dan Unsubscribe pada Debug FCM. | Operasi berhasil dan status topik berubah. | Belum dicatat. |

Membandingkan tampilan sebelum dan setelah refactor

Menggunakan project Minggu 6 sebagai kondisi sebelum refactor dan project Minggu 7 sebagai kondisi setelah refactor.

Berikut merupakan tampilan login sebelum dan setelah refactor.

![Login Sebelum Refactor](screenshots/p3_loginBefore.png)

![Login Setelah Refactor](screenshots/p3_refactorTampilanLogin.png)

Berikut merupakan tampilan Home sebelum dan setelah refactor.

![Home Sebelum Refactor](screenshots/p3_homeBefore.png)

![Home Setelah Refactor](screenshots/p3_refactorTampilanUtama.png)

Dan berikut merupakan tampilan notifiksi pada state foreground.

![Notifikasi Foreground](screenshots/p3_refactorTampilanNotifikasiForeground.png)

Berikut merupakan struktur folder sebelum refactor.

![Struktur Sebelum Refactor](screenshots/p3_strukturSebelumRefactor.png)

Perbandingan digunakan untuk memastikan tampilan dan perilaku aplikasi tetap sama setelah susunan kode dipisahkan menjadi domain, data, presentation, dan DI.