# AI Log: Prompt, Generate, Verify, Test, Refactor, Explain

Dokumen ini mencatat seluruh eksperimen interaksi AI dalam pengembangan fitur pencarian (*search*) catatan dan tampilan kosong (*empty state*) pada project **`05-week-5-local-storage-offline-first`**.

---

## 1. Objek Fitur dan Konteks Proyek

- **Proyek Target:** `05-week-5-local-storage-offline-first` (Aplikasi Offline Notes berbasis SQLite dan Riverpod).
- **Fitur Baru:** Pencarian catatan berdasarkan judul (*Search Title Notes*) dan penanganan status tanpa hasil (*Empty State*).
- **File Terdampak:**
  - `lib/data/repositories/note_repository.dart`
  - `lib/pages/notes_page.dart`
  - `test/note_search_test.dart`

---

## 2. Formula 5 Slot Prompting

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

## 5. Keputusan Refactoring & Solusi Akhir

Berdasarkan prinsip *Verify -> Test -> Refactor*, usulan AI diperbaiki secara sadar:

1. **Refactoring Riverpod 3:**
   Mengganti `StateProvider` dengan `NotifierProvider` menggunakan `SearchQueryNotifier`:
   ```dart
   class SearchQueryNotifier extends Notifier<String> {
     @override
     String build() => '';

     void setQuery(String value) => state = value;
     void clear() => state = '';
   }

   final searchQueryProvider =
       NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
   ```
2. **Reactivity & Separasi Layer:**
   Membuat `filteredNotesProvider` yang mengamati `notesProvider` (asinkron) dan menyaring data secara reaktif berdasarkan `searchQueryProvider`.
3. **Keamanan SQLite:**
   Pada `NoteRepository`, pencarian diimplementasikan dengan *parameterized query* dan `LOWER()`:
   ```dart
   Future<List<Note>> searchNotes(String query) async {
     final trimmed = query.trim();
     if (trimmed.isEmpty) return fetchNotes();

     final db = await _openDb();
     final rows = await db.query(
       'notes',
       where: 'LOWER(title) LIKE ?',
       whereArgs: ['%${trimmed.toLowerCase()}%'],
       orderBy: 'updated_at DESC',
     );
     return rows.map(Note.fromMap).toList();
   }
   ```
4. **Empty State Responsif:**
   Jika `notes.isEmpty` dan `searchQuery` terisi, antarmuka menampilkan ikon `Icons.search_off` dengan pesan informatif: *"Tidak ada catatan dengan kata kunci tersebut."*.

---

## 6. Bukti Verifikasi Mesin

### 1. Static Analysis (`flutter analyze`)
```text
Analyzing 05-week-5-local-storage-offline-first...              
No issues found! (ran in 56.4s)
```

### 2. Format Code (`dart format`)
```text
Formatted 20 files (0 changed) in 0.06 seconds.
```

### 3. Automated Tests (`flutter test`)
```text
00:00 +0: Search Notes Repository & Provider Logic searchNotes mengembalikan seluruh catatan jika query kosong
00:00 +1: Search Notes Repository & Provider Logic searchNotes menyaring catatan berdasarkan kecocokan judul
00:00 +2: Search Notes Repository & Provider Logic searchNotes bersifat case-insensitive
00:00 +3: Search Notes Repository & Provider Logic searchNotes menghasilkan list kosong jika kata kunci tidak ditemukan
00:00 +4: Search Notes Repository & Provider Logic filteredNotesProvider bereaksi terhadap perubahan searchQueryProvider
00:00 +5: fromMap aman terhadap field yang hilang
00:00 +6: NotesPage Search Widget Test menampilkan search field dan menyaring tampilan catatan secara interaktif
...
00:02 +11: All tests passed!
```
Total **11 pengujian otomatis lulus 100%**, mencakup repository unit test, provider logic test, dan full widget test interaksi pencarian.

