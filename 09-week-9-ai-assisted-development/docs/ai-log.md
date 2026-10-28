# AI Log: Prompt, Generate, Verify, Test, Refactor, Explain

Dokumen ini mencatat seluruh eksperimen interaksi AI dalam pengembangan dan verifikasi fitur pencarian (*search*) catatan dan tampilan kosong (*empty state*) pada project **`05-week-5-local-storage-offline-first`**.

---

## 1. Objek Fitur dan Konteks Proyek

- **Proyek Target:** `05-week-5-local-storage-offline-first` (Aplikasi Offline Notes berbasis SQLite dan Riverpod).
- **Fitur Baru:** Pencarian catatan berdasarkan judul (*Search Title Notes*) dan penanganan status tanpa hasil (*Empty State*).
- **File Terdampak:**
  - `lib/data/local/note.dart` (pure domain model & fungsi `filterNotes`)
  - `lib/data/repositories/note_repository.dart`
  - `lib/pages/notes_page.dart`
  - `test/note_search_test.dart`

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

Sesuai instruksi Praktikum 2, dilakukan verifikasi menyeluruh terhadap kode fitur:

1. **Baca Tiap Baris:** Memeriksa logika filter dan mapping data.
2. **Cek Import Domain:** Memastikan `lib/data/local/note.dart` steril tanpa import Flutter, Dio, maupun SQLite:
   ```text
   Imports in note.dart: 0 []
   ```
   Aturan arsitektur terpenuhi 100%.
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

## 6. Keputusan Refactoring & Solusi Akhir

1. **Refactoring Riverpod 3:**
   Mengganti `StateProvider` dengan `NotifierProvider` menggunakan `SearchQueryNotifier`.
2. **Domain Pure Filter Function:**
   Mengekstraksi fungsi `filterNotes` murni ke `lib/data/local/note.dart` tanpa ketergantungan library luar:
   ```dart
   List<Note> filterNotes(List<Note> notes, String query) {
     final trimmed = query.trim().toLowerCase();
     if (trimmed.isEmpty) return notes;
     return notes
         .where((note) => note.title.toLowerCase().contains(trimmed))
         .toList();
   }
   ```
3. **Keamanan SQLite:**
   Pada `NoteRepository`, pencarian diimplementasikan dengan *parameterized query* dan `LOWER()`.
4. **Empty State Responsif:**
   Jika `notes.isEmpty` dan `searchQuery` terisi, antarmuka menampilkan ikon `Icons.search_off` dengan pesan informatif: *"Tidak ada catatan dengan kata kunci tersebut."*.

---

## 7. Bukti Verifikasi Mesin

### 1. Static Analysis (`flutter analyze`)
```text
Analyzing 05-week-5-local-storage-offline-first...              
No issues found! (ran in 10.9s)
```

### 2. Format Code (`dart format`)
```text
Formatted 20 files (0 changed) in 0.09 seconds.
```

### 3. Automated Tests (`flutter test`)
```text
00:00 +0: Search Notes Repository & Provider Logic searchNotes mengembalikan seluruh catatan jika query kosong
00:00 +1: Search Notes Repository & Provider Logic searchNotes menyaring catatan berdasarkan kecocokan judul
00:00 +2: Search Notes Repository & Provider Logic searchNotes bersifat case-insensitive
00:00 +3: Search Notes Repository & Provider Logic searchNotes menghasilkan list kosong jika kata kunci tidak ditemukan
00:00 +4: Search Notes Repository & Provider Logic filteredNotesProvider bereaksi terhadap perubahan searchQueryProvider
00:00 +5: NotesPage Search Widget Test menampilkan search field dan menyaring tampilan catatan secara interaktif
...
00:03 +14: All tests passed!
```
Total **14 pengujian otomatis lulus 100%**, mencakup domain pure function, repository unit test, provider logic test, dan full widget test interaksi pencarian.
