# 12-week-12-testing-quality-assurance

## Tujuan Pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa diharapkan mampu:
1. Menentukan bagian aplikasi yang perlu diuji dengan pengujian unit, widget, atau integrasi.
2. Menulis pengujian unit untuk logika bisnis dan kasus tepi menggunakan pola Arrange, Act, Assert.
3. Menguji tampilan serta interaksi widget Flutter tanpa ketergantungan jaringan.
4. Memisahkan dependensi dengan kontrak abstrak agar kode mudah diuji menggunakan fake repository.
5. Menjalankan pengujian integrasi serta menggunakan cakupan kode sebagai bahan evaluasi kualitas.

---

## Strategi Pengujian Aplikasi Flutter

### 1. Memilih Jenis Pengujian yang Tepat

| Jenis Pengujian | Ruang Lingkup Pemeriksaan | Contoh pada Aplikasi Offline Notes |
| :--- | :--- | :--- |
| Unit Test | Satu fungsi, validator, atau service tanpa merender UI | Validasi judul catatan kosong, spasi saja, batas 100 karakter, dan logika NoteService |
| Widget Test | Tampilan dan interaksi komponen UI Flutter secara terisolasi | Dialog tambah catatan menampilkan pesan error saat input tidak valid dan menampilkan daftar saat valid |
| Integration Test | Alur aplikasi lengkap dari awal hingga akhir pada perangkat atau emulator | Pengguna membuka aplikasi, menguji validasi kosong, menyimpan catatan baru, lalu mencarinya di daftar |

### 2. Merancang Kode agar Mudah Diuji

Logika bisnis yang tercampur langsung di dalam widget atau terikat erat pada SQLite menyulitkan pengujian terpisah. Pada project 05-week-5-local-storage-offline-first dilakukan pemisahan tanggung jawab berikut:
- Validator domain murni pada lib/domain/validators/note_validator.dart (isValidNoteTitle dan validateNoteTitle).
- Kontrak abstrak NoteRepositoryContract pada lib/domain/repositories/note_repository_contract.dart yang diimplementasikan oleh NoteRepository.
- Service NoteService pada lib/domain/usecases/load_notes.dart yang menerima NoteRepositoryContract melalui konstruktor agar mudah disubstitusi dengan FakeNoteRepositoryContract saat pengujian.
- Widget NotesPage pada lib/pages/notes_page.dart dilengkapi Key eksplisit (add_note_fab, note_title_field, note_body_field, save_note_button) dan menampilkan pesan error validasi inline pada dialog tambah catatan.

---

## Praktikum: Test Suite Fitur Utama Catatan

### 1. Skenario Perilaku yang Diuji

1. Skenario Sukses Logika dan Asinkron: Judul valid dengan spasi tepi diterima, NoteService memangkas spasi dan meneruskan penyimpanan ke repository.
2. Skenario Kasus Tepi (Boundary dan Whitespace): Input kosong, hanya spasi atau tab, panjang tepat 100 karakter (lulus), dan 101 karakter (ditolak).
3. Skenario Kegagalan (Error Propagation): Ketika repository melempar Exception, NoteService meneruskan kegagalan tersebut dan NotesPage menampilkan pesan error beserta tombol Coba lagi, tidak diam-diam berubah menjadi daftar kosong.
4. Skenario Interaksi Widget Form: Membuka dialog tambah catatan, menekan Simpan dengan input spasi saja sehingga pesan Judul catatan tidak boleh kosong muncul, lalu mengisi data valid hingga catatan tampil di daftar.
5. Skenario Alur Utama Integrasi: Alur end-to-end mulai dari membuka aplikasi, memicu validasi kosong, menambah catatan baru, hingga menyaringnya melalui kolom pencarian.

### 2. Contoh Implementasi Kontrak dan Fake Repository

```dart
abstract interface class NoteRepositoryContract {
  Future<List<Note>> fetchNotes();
  Future<Note> addNote({required String title, String body = ''});
  Future<void> deleteNote(int id);
  Future<int> countDirty();
  Future<void> markAllSynced();
  Future<Note?> fetchNoteById(int id);
  Future<List<Note>> searchNotes(String query);
}
```

### 3. Pengujian Integrasi (integration_test/app_test.dart)

Paket integration_test ditambahkan pada dev_dependencies di pubspec.yaml. Pengujian alur utama diletakkan pada integration_test/app_test.dart menggunakan IntegrationTestWidgetsFlutterBinding.ensureInitialized().

Perintah eksekusi pada perangkat atau emulator:

```bash
flutter test integration_test/app_test.dart -d <device_id>
```

---

## Hasil Pengujian, Analisis, dan Cakupan Kode

Seluruh pemeriksaan dijalankan pada direktori project 05-week-5-local-storage-offline-first.

### 1. Formatter (dart format)

```text
Formatted lib\pages\notes_page.dart
Formatted 34 files in 0.20 seconds.
```

### 2. Static Analysis (dart analyze)

```text
Analyzing 05-week-5-local-storage-offline-first...
No issues found!
```

### 3. Automated Unit dan Widget Tests (flutter test --coverage)

```text
00:00 +0: AiService Unit Tests
00:03 +33: ChatScreen Widget Tests
00:04 +34: MultimodalScreen Widget Tests
00:05 +36: NotesPage Widget Tests (Validasi, Interaksi, Error)
00:07 +43: NotesPage Search Widget Test
00:10 +52: Empty State Widget Test
00:13 +54: App renders Offline Notes title
00:15 +55: All tests passed!
```

Sebanyak 55 dari 55 unit dan widget tests lulus 100% (mencakup test baru pada test/note_validation_and_service_test.dart dan test/note_form_widget_test.dart).

### 4. Evaluasi Cakupan Kode (coverage/lcov.info)

Ringkasan cakupan total: 651 dari 1104 baris tercakup (59.0%).

Rincian per komponen utama:
- lib/domain/validators/note_validator.dart: 7/7 (100.0%)
- lib/domain/usecases/load_notes.dart: 7/7 (100.0%)
- lib/domain/usecases/search_notes.dart: 8/8 (100.0%)
- lib/data/local/note.dart: 17/17 (100.0%)
- lib/widgets/note_tile.dart: 11/11 (100.0%)
- lib/pages/notes_page.dart: 120/141 (85.1%)
- lib/ai/ai_service.dart: 100/137 (73.0%)
- lib/features/multimodal_screen.dart: 172/255 (67.5%)
- lib/features/chat_screen.dart: 137/229 (59.8%)
- lib/pages/posts_page.dart: 43/76 (56.6%)

### 5. Status Integration Test dan Temuan Belum Terselesaikan

Perintah yang dijalankan:

```bash
flutter test integration_test/app_test.dart -d windows
```

Kendala yang ditemukan saat eksekusi:
1. Pada target desktop Windows, toolchain C++ Visual Studio belum terpasang (Unable to find suitable Visual Studio toolchain), dan belum ada emulator atau perangkat Android yang aktif sehingga integration_test/app_test.dart belum dapat dieksekusi langsung di perangkat pada sesi ini. Berkas pengujian integrasi sudah lolos dart analyze tanpa issue dan siap dijalankan segera ketika emulator Android tersedia.
2. Pada laporan cakupan kode, berkas database lokal dan sinkronisasi (lib/data/local/db.dart 0.0%, lib/data/repositories/note_repository.dart 2.4%, lib/data/sync.dart 0.0%) serta halaman detail (lib/pages/note_detail_page.dart 0.0%) belum tercakup karena membutuhkan inisialisasi sqflite_common_ffi untuk pengujian SQLite in-memory di lingkungan desktop.

---

## Tugas

- [x] Menambahkan unit test untuk logika bisnis dan kasus tepi (test/note_validation_and_service_test.dart).
- [x] Memisahkan kontrak repository dan membuat fake repository untuk skenario sukses serta error.
- [x] Menambahkan widget test untuk tampilan awal, input tidak valid, simpan sukses, dan error state (test/note_form_widget_test.dart).
- [x] Menambahkan satu pengujian integrasi alur utama (integration_test/app_test.dart) beserta catatan perintah dan kendala eksekusi perangkat.
- [x] Menjalankan flutter test --coverage, dart analyze, dan mencatat hasil serta temuan yang belum terselesaikan pada README.md dan docs/test-plan-and-coverage.md.

---

## Refleksi

### 1. Bug apa yang paling mungkin terlewat tanpa pengujian yang Anda tulis?

Jawaban: Terdapat dua bug nyata yang terdeteksi langsung saat menulis pengujian pada sesi ini. Pertama, pada implementasi awal dialog tambah catatan, validasi judul kosong hanya melakukan return diam-diam tanpa memberi umpan balik pesan error kepada pengguna. Kedua, saat mencoba membersihkan TextEditingController di blok finally tepat setelah showDialog selesai, pengujian widget menangkap exception TextEditingController was used after being disposed karena animasi penutupan dialog masih berjalan satu hingga dua frame setelah Future pop kembali. Tanpa widget test, bug lifecycle controller tersebut akan lolos dari pengecekan manual dan berpotensi menyebabkan crash saat rilis.

### 2. Bagian mana yang perlu fake, dan bagaimana fake itu membuat pengujian lebih konsisten?

Jawaban: Bagian yang perlu digantikan oleh fake adalah lapisan akses data dan dependensi eksternal, yaitu NoteRepositoryContract (SQLite lokal) serta layanan jaringan/AI (AiService dan FlutterSecureStorage). Dengan menggunakan FakeNoteRepositoryContract yang menyimpan daftar catatan di memori dan memiliki properti error opsional, pengujian dapat mensimulasikan kondisi awal kosong, daftar terisi, maupun kegagalan database secara deterministik dalam hitungan milidetik tanpa bergantung pada file database fisik perangkat atau koneksi internet.

### 3. Apa perbedaan nilai yang diberikan pengujian widget dan pengujian integrasi pada fitur Anda?

Jawaban: Pengujian widget memverifikasi perilaku antarmuka dan interaksi pengguna pada satu halaman atau dialog secara cepat dan terisolasi menggunakan fake repository, misalnya memastikan pesan error validasi muncul ketika tombol Simpan ditekan dengan input spasi saja. Sebaliknya, pengujian integrasi memeriksa bagaimana seluruh lapisan nyata aplikasi—mulai dari inisialisasi main(), ProviderScope, routing GoRouter, penyimpanan persisten, hingga perpindahan antar komponen pencarian dan daftar—bekerja bersama secara utuh sebagai satu kesatuan di perangkat target.

---

## Referensi

- Slide Minggu 12: Pengujian dan Jaminan Kualitas: https://jti-polinema.github.io/flutter-codelab/00-slides/Week_12_Testing_Quality_Assurance.html
- Testing Flutter apps: https://docs.flutter.dev/testing/overview
- Introduction to widget testing: https://docs.flutter.dev/cookbook/testing/widget/introduction
- Integration testing: https://docs.flutter.dev/testing/integration-tests
- Dart test package: https://pub.dev/packages/test
