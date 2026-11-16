# Rencana Pengujian dan Evaluasi Cakupan Kode (Minggu 12)

## 1. Daftar Skenario Perilaku yang Diuji

| Kategori | Nama File Pengujian | Skenario Perilaku | Hasil yang Diharapkan | Status |
| :--- | :--- | :--- | :--- | :--- |
| Unit (Logika) | test/note_validation_and_service_test.dart | Judul valid dengan spasi tepi | isValidNoteTitle bernilai true, validateNoteTitle mengembalikan null | Lulus |
| Unit (Kasus Tepi) | test/note_validation_and_service_test.dart | Input string kosong atau spasi saja | isValidNoteTitle bernilai false, mengembalikan pesan error wajib isi | Lulus |
| Unit (Batas Panjang) | test/note_validation_and_service_test.dart | Panjang 100 karakter vs 101 karakter | 100 karakter diterima, 101 karakter ditolak dengan pesan batas maksimal | Lulus |
| Unit (Asinkron Sukses) | test/note_validation_and_service_test.dart | NoteService.loadNotes dan createNote via FakeNoteRepositoryContract | Data catatan kembali sesuai mock dan spasi judul terpotong | Lulus |
| Unit (Kegagalan) | test/note_validation_and_service_test.dart | Repository melempar Exception saat loadNotes | Exception diteruskan ke pemanggil, tidak berubah menjadi list kosong | Lulus |
| Widget (Tampilan Awal) | test/note_form_widget_test.dart | Render NotesPage dengan daftar catatan kosong | Judul Offline Notes, teks Belum ada catatan., dan FAB tambah tampil | Lulus |
| Widget (Input Invalid) | test/note_form_widget_test.dart | Tekan Simpan saat judul hanya spasi | Dialog tetap terbuka dan pesan Judul catatan tidak boleh kosong tampil | Lulus |
| Widget (Sukses Simpan) | test/note_form_widget_test.dart | Isi judul & isi valid lalu tekan Simpan | Dialog tertutup, catatan baru tampil pada daftar utama | Lulus |
| Widget (Error State) | test/note_form_widget_test.dart | Fake repository gagal memuat catatan | Pesan Gagal memuat catatan lokal dan tombol Coba lagi tampil | Lulus |
| Integrasi (End-to-End) | integration_test/app_test.dart | Buka aplikasi, validasi kosong, tambah catatan, lalu cari catatan | Alur penuh dari validasi hingga pencarian berjalan terpadu | Siap Perangkat |

---

## 2. Evaluasi Cakupan Kode (flutter test --coverage)

Pengujian cakupan dijalankan menggunakan perintah flutter test --coverage pada direktori 05-week-5-local-storage-offline-first yang menghasilkan berkas coverage/lcov.info.

Ringkasan metrik total: 651 dari 1104 baris tercakup (59.0%).

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

Bagian yang belum tercakup penuh dan menjadi temuan lanjutan:
- lib/data/local/db.dart (0.0%), lib/data/repositories/note_repository.dart (2.4%), lib/data/sync.dart (0.0%): bergantung pada SQLite native sehingga belum diuji dengan sqflite_common_ffi di unit test.
- lib/pages/note_detail_page.dart (0.0%) dan lib/pages/settings_page.dart (13.8%): memerlukan penambahan widget test navigasi halaman detail dan toggle pengaturan.

---

## 3. Catatan Eksekusi Integration Test

Perintah yang dijalankan:
flutter test integration_test/app_test.dart -d windows

Hasil dan kendala yang diamati:
Proses build desktop Windows gagal dengan pesan Unable to find suitable Visual Studio toolchain, dan belum ada emulator atau perangkat fisik Android yang terhubung saat pengujian dilakukan. Skrip integration_test/app_test.dart telah terverifikasi bersih oleh dart analyze (0 issues) dan siap dijalankan pada emulator/perangkat Android dengan perintah:
flutter test integration_test/app_test.dart -d <device_id>
