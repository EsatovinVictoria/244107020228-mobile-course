# AI Log: Prompt, Generate, Verify, Test, Refactor, Explain

Dokumen ini mencatat seluruh eksperimen interaksi AI dalam pengembangan, verifikasi, debugging, dan refactoring fitur pencarian (*search*) catatan dan tampilan kosong (*empty state*) pada project **`05-week-5-local-storage-offline-first`**.

---

## 1. Objek Fitur dan Konteks Proyek

- **Proyek Target:** `05-week-5-local-storage-offline-first` (Aplikasi Offline Notes berbasis SQLite dan Riverpod).
- **Fitur Baru:** Pencarian catatan berdasarkan judul dan isi (*Search Notes*) dan penanganan status tanpa hasil (*Empty State*).
- **File Terdampak:**
  - `lib/domain/usecases/search_notes.dart` (pure Clean Architecture use case)
  - `lib/data/local/note.dart` (domain entity)
  - `lib/data/repositories/note_repository.dart`
  - `lib/pages/notes_page.dart` (refactored into modular widgets < 40 lines)
  - `test/note_search_test.dart`
  - `test/search_filter_test.dart`

---

## 2. Formula 5 Slot Prompting (Praktikum 1)

Untuk menghasilkan kode yang tepat sasaran, prompt disusun menggunakan formula 5 slot:

| Slot | Nilai / Isi Slot | Alasan |
| :--- | :--- | :--- |
| **1. Peran** | *Senior Flutter & Clean Architecture Developer* | Mengarahkan AI mengadopsi standar penulisan kode profesional dan *separation of concerns*. |
| **2. Konteks** | Flutter 3, `flutter_riverpod: ^3.4.3`, SQLite `sqflite: ^2.4.4`, schema tabel `notes (id, title, body, updated_at, dirty)`. Menggunakan repository pattern. | Menghindari halusinasi arsitektur atau ketergantungan library yang tidak terpasang. |
| **3. Tugas** | Tambah method `searchNotes` di `NoteRepository`, integrasikan filter pencarian judul di `NotesPage`, dan tampilkan widget *empty state* jika hasil pencarian kosong. | Target fungsionalitas jelas dan spesifik. |
| **4. Batas** | Jangan memanggil SQLite langsung dari widget (harus lewat repository), jangan gunakan package eksternal fiktif, pertahankan Riverpod 3. | Menjaga aturan *dependency rule* dan mencegah dependensi liar. |
| **5. Output** | Kode repository, provider/UI di `notes_page.dart`, dan 3 unit test (cocok sebagian, case-insensitive, empty state). | Menuntut keluaran yang langsung dapat diuji (*testable*). |

---

## 3. Komparasi: Prompt Buruk vs Prompt Baik

### Prompt Buruk (Anti-pattern / Vibe Coding)
```text
"buatkan search notes yang keren di flutter dengan sqlite dan riverpod"
```
**Analisis Kelemahan:**
1. **Ambigu:** AI tidak mengetahui apakah pencarian dilakukan secara *in-memory* atau query SQL langsung.
2. **Potensi Halusinasi:** AI cenderung menulis pemanggilan `Database` langsung di dalam `build()` widget, merusak Clean Architecture.
3. **Versi Tidak Cocok:** AI tidak tahu versi Riverpod yang dipakai (`^3.4.3`) sehingga berpotensi menggunakan API usang seperti `StateProvider`.
4. **Tanpa Pengujian:** Tidak ada instruksi pembuatan test case, sehingga rawan memunculkan bug terselubung.

### Prompt Baik (Formula 5 Slot - Context Engineered)
```text
Peran: Senior Flutter developer.
Konteks: Project 05-week-5-local-storage-offline-first menggunakan Flutter 3, flutter_riverpod 3.4.3, dan sqflite. Struktur data: Note(id, title, body, updatedAt, dirty). NoteRepository mengakses tabel 'notes'.
Tugas:
1. Tambahkan method searchNotes(String query) pada NoteRepository menggunakan parameterized query SQLite.
2. Tambahkan input pencarian judul di NotesPage beserta penanganan Empty State jika catatan tidak ditemukan.
3. Buat minimal 3 test case di test/note_search_test.dart.
Batas:
- Dilarang memanggil SQLite dari UI widget.
- Jangan gunakan StateProvider (gunakan NotifierProvider Riverpod 3).
- Tidak boleh mengubah skema database yang sudah ada.
Output: Potongan kode repository, widget UI, dan unit/widget test.
```

---

## 4. Output Awal AI & Deteksi Halusinasi

Pada percobaan generate awal, AI mengusulkan kode berikut untuk `notes_page.dart`:

```dart
// USULAN AWAL AI (BERMASALAH)
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.searchNotes(query); // <-- BUG: searchNotes bernilai Future!
});
```

### Temuan Halusinasi & Celah Kritis:
1. **Halusinasi API Kadaluarsa (Riverpod 3):**
   * AI menggunakan `StateProvider<String>`, padahal `pubspec.yaml` menggunakan `flutter_riverpod: ^3.4.3`.
   * Bukti error saat kompilasi:
     ```text
     lib/pages/notes_page.dart:20:29: Error: Method not found: 'StateProvider'.
     final searchQueryProvider = StateProvider<String>((ref) => '');
     ```
2. **Kekeliruan Tipe Asinkron (*Async Leak*):**
   * `searchNotes` mengembalikan `Future<List<Note>>`, namun AI memasukkannya ke dalam synchronous `Provider<List<Note>>`.
3. **SQL Injection & Case Sensitivity:**
   * Draf query awal AI menggunakan `WHERE title LIKE '%$query%'` tanpa sanitasi parameter dan case-sensitive pada SQLite standar.

---

## 5. Pelaksanaan Verifikasi 6 Langkah (Praktikum 2)

1. **Baca Tiap Baris:** Memeriksa logika filter dan mapping data.
2. **Cek Import Domain:** Memastikan `lib/data/local/note.dart` steril tanpa import Flutter, Dio, maupun SQLite (`Imports in note.dart: 0 []`).
3. **Cek API Nyata:** Memverifikasi ketersediaan method pada Riverpod 3.4.3 dan `sqflite`.
4. **Jalankan static analysis:** Menjalankan `flutter analyze` hingga 0 warning:
   ```text
   Analyzing 05-week-5-local-storage-offline-first...              
   No issues found! (ran in 10.9s)
   ```
5. **Tulis Unit Test Sukses & Gagal:**
   ```dart
   test('filter abaikan huruf besar/kecil', () {
     expect(filterNotes(list, 'belanja'), hasLength(2));
   });

   test('query tak cocok kembalikan kosong', () {
     expect(filterNotes(list, 'zzz-tak-ada'), isEmpty);
   });
   ```
6. **Uji Manual 3 Skenario:** Query kosong (seluruh catatan muncul), query cocok (catatan tersaring), dan query tidak cocok (tampilan *empty state* aktif).

---

## 6. Debugging dan Refactoring (Praktikum 3)

### 1. Debug dengan Test Merah (Red-Green-Refactor)

1. **Reproduksi Masalah:**
   * Pengguna mencari kata kunci yang berada pada isi catatan (*body*), misalnya kata `"anggaran"`.
   * Pengguna memasukkan spasi di awal atau akhir kata kunci, misalnya `"   flutter   "`.
   * Hasil aktual pada usulan awal AI: Catatan tidak ditemukan (0 hasil) karena pencarian hanya mengecek kolom `title` dan tidak melakukan `.trim()`.
2. **Isolasi Logika ke Use Case:**
   * Aturan filter diekstraksi ke class use case murni `SearchNotes` pada `lib/domain/usecases/search_notes.dart`.
3. **Test Merah (Red Test):**
   * Dibuat test pembukti bug pada `test/note_search_test.dart`:
     ```dart
     test('mencari kata kunci pada isi body catatan', () {
       final results = useCase(notes: sample, query: 'anggaran');
       expect(results, hasLength(1));
     });
     test('menangani spasi berlebih pada awal dan akhir query', () {
       final results = useCase(notes: sample, query: '   flutter   ');
       expect(results, hasLength(1));
     });
     ```
   * Sebelum perbaikan, test ini gagal (*Red*).
4. **Perbaikan Kecil (Green Test):**
   * Menambahkan pengecekan pada `title` dan `body` serta normalisasi `.trim().toLowerCase()` pada `SearchNotes`:
     ```dart
     final titleMatch = note.title.toLowerCase().contains(trimmed);
     final bodyMatch = note.body.toLowerCase().contains(trimmed);
     return titleMatch || bodyMatch;
     ```
   * Seluruh pengujian berubah menjadi lulus (*Green*).
5. **Akar Masalah:**
   * AI membuat asumsi sempit bahwa pencarian catatan hanya berlaku untuk judul saja, mengabaikan atribut `body` dan sanitasi whitespace.

### 2. Refactoring ke Layer yang Tepat

Arsitektur ditata ulang dengan pemisahan tanggung jawab yang tegas:
```text
Widget (_NotesSearchBar, _NotesContent, _NotesEmptyState - UI murni)
  -> Notifier (SearchQueryNotifier - state query saja)
  -> Use Case (SearchNotes - aturan bisnis pencarian murni)
  -> Repository (NoteRepository - akses SQLite)
```

**Pemeriksaan Batas Ukuran Fungsi (< 40 Baris):**
* `_showAddNoteDialog`: 35 baris.
* `_addNote`: 11 baris.
* `_sync`: 17 baris.
* `NotesPage.build`: 38 baris.
* `_NotesSearchBar`: 34 baris.
* `_NotesContent`: 35 baris.
* `_NotesEmptyState`: 25 baris.
* **Tidak ada pemanggilan database langsung dari widget.**

---

## 7. AI Challenge: Code Review & Verification

### 1. Prompt Asli Review Senior Developer
```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### 2. Output Mentah AI Reviewer
1. **Temuan 1 (Level: Blocker) — Inkonsistensi Kueri SQL vs In-Memory Search:**
   * *Lokasi:* `NoteRepository.searchNotes` (`lib/data/repositories/note_repository.dart`).
   * *Alasan:* Pada usecase `SearchNotes`, pencarian memeriksa `title` dan `body`. Sementara di `NoteRepository`, kueri SQL hanya memeriksa `LOWER(title) LIKE ?`. Jika database SQLite dipanggil langsung, catatan dengan kecocokan pada `body` tidak akan terambil.
   * *Usulan:* Ubah klausa `where` menjadi `LOWER(title) LIKE ? OR LOWER(body) LIKE ?` dengan dua argumen query.
2. **Temuan 2 (Level: Saran) — Pengujian Kasus Batas (Boundary Test) Body Kosong:**
   * *Lokasi:* `test/note_search_test.dart`.
   * *Alasan:* Seluruh data uji sample memiliki isi `body` lengkap. Diperlukan pengujian untuk catatan dengan `body: ''` untuk memastikan tidak ada eksepsi atau perilaku aneh saat body kosong.
   * *Usulan:* Tambahkan sampel catatan dengan `body: ''` ke dalam test suite.
3. **Temuan 3 (Level: Saran) — Penggunaan SQLite FTS5 Virtual Table / Remote API Search:**
   * *Lokasi:* `NoteRepository` & `ApiClient`.
   * *Alasan:* Query `LIKE %query%` melakukan full table scan. AI menyarankan membuat tabel virtual FTS5 atau mendelegasikan pencarian ke remote backend via Dio.
   * *Usulan:* Buat migrasi tabel FTS5 dan endpoint remote search.

### 3. Matriks Verifikasi & Keputusan Final

| No | Temuan AI dan Level | Bukti Empiris | Keputusan & Argumen Teknis |
| :--- | :--- | :--- | :--- |
| 1 | Blocker: Inkonsistensi SQL `searchNotes` | Terbukti via grep kode repository: query SQL sebelumnya hanya menyaring `title`. | **Diterima dan Diperbaiki**. Diselaraskan menjadi `where: 'LOWER(title) LIKE ? OR LOWER(body) LIKE ?'` agar pencarian database lokal identik dengan in-memory usecase. |
| 2 | Saran: Boundary test catatan body kosong | Terbukti celah cakupan test. Data sample belum mencakup `body: ''`. | **Diterima + Ditambahkan Test**. Menambahkan test case `searchNotes aman terhadap catatan dengan body kosong` pada `note_search_test.dart`. |
| 3 | Saran: FTS5 Virtual Table / Dio Remote Search | Profiling database lokal menunjukkan eksekusi query SQLite `LIKE` pada dataset catatan offline berkecepatan < 2ms. | **Ditolak**. Aplikasi bersifat offline-first personal notes dengan volume data lokal terjangkau. Menambahkan FTS5 atau remote search menambah beban migrasi dan dependensi jaringan yang tidak diperlukan (*over-engineering*). |

---

## 8. Refactoring Challenge, Testing, dan Error Handling (Bagian 7)

### 1. Refactoring Hasil AI ke Modular Use Case
- File `notes_page.dart` yang awalnya memuat logika dialog, sync, dan search bar dipecah menjadi widget modular terisolasi: `_NotesSearchBar`, `_NotesContent`, dan `_NotesEmptyState`.
- Seluruh fungsi dipastikan berada di bawah 40 baris.
- Aturan pencarian dipusatkan secara eksklusif pada usecase `SearchNotes` (`lib/domain/usecases/search_notes.dart`).
- Tidak ada panggilan database langsung dari widget UI.

### 2. Pengujian Terfokus `search_filter_test.dart`
Pengujian khusus dibuat pada `test/search_filter_test.dart` untuk menguji:
1. `filter abaikan huruf besar/kecil`: Lulus.
2. `query tak cocok kembalikan kosong`: Lulus.
3. `filter mencocokkan kata kunci pada body catatan`: Lulus.
4. `filter mengabaikan spasi berlebih pada awal dan akhir query`: Lulus.
5. `filter query kosong mengembalikan seluruh catatan`: Lulus.
6. `filter aman terhadap catatan dengan body kosong`: Lulus.
7. `Widget Test Empty State`: Membuktikan tampilan empty state secara visual saat query tidak cocok dan pemulihan data saat tombol clear ditekan.

Hasil:
```text
flutter test test/search_filter_test.dart
00:01 +7: All tests passed!
```

### 3. Error Umum dan Solusinya

| Gejala | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| Method tidak ada saat kompilasi | Halusinasi API / versi usang | Cek dokumentasi resmi pub.dev + autocomplete IDE; refactor `StateProvider` ke `NotifierProvider`. |
| Import lintas layer (domain import Flutter/Dio/SQLite) | Konteks prompt kurang spesifik | Tegaskan batasan arsitektur Clean Architecture pada prompt; isolasi fungsi murni ke domain. |
| Seluruh test langsung merah | Prompt terlalu besar dan rumit | Pecah instruksi menjadi 1 fitur kecil + 1 test pembukti. |
| Prompt perbaikan diulang-ulang tanpa hasil | Tanpa reproduksi masalah konkret | Tulis langkah reproduksi pemicu bug + buat red test sebelum meminta perbaikan. |
| Developer tidak bisa menjelaskan kode | Menerima kode AI mentah (vibe coding) | Baca ulang baris per baris, sederhanakan logika, dan buang kode yang tidak dipahami. |

---

## 9. Bukti Verifikasi Mesin Akhir

### 1. Static Analysis (`flutter analyze`)
```text
Analyzing 05-week-5-local-storage-offline-first...              
No issues found! (ran in 8.3s)
```

### 2. Formatter (`dart format`)
```text
Formatted 22 files (0 changed) in 0.10 seconds.
```

### 3. Automated Tests (`flutter test`)
```text
00:00 +0: Search Notes Repository & Provider Logic searchNotes mengembalikan seluruh catatan jika query kosong
00:00 +1: Search Notes Repository & Provider Logic searchNotes menyaring catatan berdasarkan kecocokan judul
...
00:02 +18: Widget Test Empty State menampilkan widget empty state saat pencarian tidak cocok
...
00:02 +26: All tests passed!
```
Total **26 pengujian otomatis lulus 100%**.
