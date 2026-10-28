# 09-week-9-ai-assisted-development

## Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, mahasiswa mampu:
1. Menjelaskan workflow AI-assisted development (Prompt, Generate, Verify, Test, Refactor, Explain).
2. Menulis prompt dan konteks yang efektif untuk fitur Flutter kecil menggunakan Formula 5 Slot.
3. Mengenali halusinasi dan keterbatasan AI pada kode Flutter (misal API kadaluarsa pada Riverpod 3).
4. Melakukan debugging dan refactoring kode hasil usulan AI ke struktur Clean Architecture.
5. Menguji kode hasil AI secara komprehensif menggunakan flutter analyze dan unit/widget test.
6. Mendokumentasikan interaksi AI, prompt, keputusan terima/tolak, dan bukti uji pada docs/ai-log.md.

---

## Konsep Workflow AI dan Halusinasi

### 1. Siklus 6 Langkah (Generate sampai Explain)

Alur kerja AI-assisted development terdiri dari 6 tahapan:
1. Prompt: menulis instruksi jelas beserta konteks proyek.
2. Generate: AI mengusulkan potongan kode.
3. Verify: memeriksa kode, mengecek file, dan memvalidasi ketersediaan API nyata.
4. Test: menjalankan flutter analyze dan pengujian unit/widget test.
5. Refactor: menata ulang kode agar sesuai kaidah Clean Architecture dan standar versi library.
6. Explain: memahami alur logika sehingga developer mampu menjelaskan kode tanpa membuka AI.

AI berperan mengusulkan kode, sedangkan keputusan teknis dan validasi sepenuhnya berada di tangan developer. Menerima usulan AI secara mentah tanpa verifikasi disebut vibe coding, yang berisiko menimbulkan bug terselubung dan pembengkakan biaya pemeliharaan aplikasi.

### 2. Pemetaan Area Kemampuan AI

- Area Kuat: Pembuatan kode boilerplate, pola umum, draf unit test, dan draf dokumentasi. Sikap: manfaatkan untuk efisiensi, namun tetap uji kebenaran logikanya.
- Area Lemah: Penggunaan API versi terbaru dengan breaking changes, logika bisnis spesifik, dan struktur state yang kompleks. Sikap: lakukan verifikasi manual ke dokumentasi resmi atau file pubspec.lock.
- Area Berbahaya: Penanganan token autentikasi, query SQL mentah, dan aturan keamanan. Sikap: jangan menyertakan secret atau data sensitif ke AI, tulis dan audit bagian ini secara manual.

### 3. Tiga Pola Halusinasi Flutter

1. Method Fiktif: AI membuat method atau getter yang tidak pernah ada pada SDK atau package yang digunakan.
2. Package Kadaluarsa: AI menggunakan sintaks library versi lama yang sudah tidak didukung pada versi package aktif (misalnya mengusulkan StateProvider pada flutter_riverpod versi 3).
3. Logika Yakin Tapi Salah: AI menyusun logika yang tampak meyakinkan namun keliru (misalnya filter pencarian case-sensitive atau penggabungan string query SQL yang rentan injection).

---

## Praktikum 1: Prompt dan Context Engineering

Praktikum ini menerapkan penambahan fitur pencarian catatan (search notes) dan tampilan kosong (empty state) pada project 05-week-5-local-storage-offline-first.

### 1. Penerapan Formula 5 Slot

Satu prompt yang efektif memenuhi lima slot informasi:
1. Peran: Senior Flutter dan Clean Architecture Developer.
2. Konteks: Project 05-week-5-local-storage-offline-first, Flutter 3, flutter_riverpod 3.4.3, SQLite sqflite 2.4.4, model Note(id, title, body, updatedAt, dirty), dan NoteRepository.
3. Tugas: Tambahkan fungsi searchNotes pada NoteRepository, integrasikan TextField pencarian pada NotesPage, dan tampilkan Empty State jika hasil pencarian kosong.
4. Batas: Dilarang memanggil SQLite langsung dari widget, jangan gunakan package fiktif, gunakan NotifierProvider Riverpod 3 (bukan StateProvider), dan pertahankan skema tabel database.
5. Output: Kode repository, provider dan widget UI, serta minimal 3 test case (pencarian cocok, case-insensitive, dan empty state).

### 2. Komparasi Prompt Buruk vs Prompt Baik

Prompt Buruk:
"buatkan search notes yang keren di flutter dengan sqlite dan riverpod"

Kelemahan: Sangat ambigu. AI tidak mengetahui model data yang dipakai, berpotensi memanggil database langsung dari widget UI sehingga merusak arsitektur, dan tidak menghasilkan pengujian otomatis.

Prompt Baik:
"Tambah search judul notes pada project 05-week-5-local-storage-offline-first. Arsitektur: presentation -> repository. Jangan panggil SQLite dari widget. Gunakan NotifierProvider (Riverpod 3.x), dukung pencarian case-insensitive, sertakan empty state dan unit/widget test."

Kelebihan: Memberikan batasan teknis yang spesifik, mematuhi separation of concerns, serta menuntut adanya bukti uji otomatis.

### 3. Beri Konteks, Bukan Secret

- Informasi yang disertakan: Struktur folder project, potongan kode NoteRepository dan model Note, serta versi library dari pubspec.yaml.
- Informasi yang tidak disertakan: Token autentikasi, kredensial backend, file lingkungan (.env), atau file repository yang tidak relevan.

---

## Implementasi dan Deteksi Halusinasi AI

### 1. Halusinasi yang Ditemukan dan Solusinya

Pada draf usulan awal, AI mengusulkan penggunaan StateProvider untuk mengelola kata kunci pencarian. Saat dijalankan pada compiler Dart, proses build gagal karena StateProvider sudah dihapus pada flutter_riverpod versi 3.x yang digunakan oleh project.

Kode usulan AI tersebut direfaktor menggunakan SearchQueryNotifier yang mewarisi Notifier dari Riverpod 3.x, kemudian didaftarkan melalui NotifierProvider.

### 2. Kode Hasil Refactoring

Berikut potongan fungsi pencarian pada NoteRepository (lib/data/repositories/note_repository.dart):

```dart
Future<List<Note>> searchNotes(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return fetchNotes();
  }

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

Berikut provider pencarian dan filtered list pada NotesPage (lib/pages/notes_page.dart):

```dart
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesState = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return notesState.whenData((notes) {
    if (query.isEmpty) return notes;
    return notes
        .where((n) => n.title.toLowerCase().contains(query))
        .toList();
  });
});
```

---

## Hasil Pengujian dan Tampilan Aplikasi

### 1. Bukti Pemeriksaan Mesin

Pemeriksaan dijalankan pada direktori project 05-week-5-local-storage-offline-first:
- dart format: 20 file diperiksa, 0 changed.
- flutter analyze: No issues found! (0 issues).
- flutter test: Seluruh 11 test lulus (All tests passed!), mencakup 4 test bawaan dan 7 test pencarian serta widget test interaktif.

### 2. Tampilan Hasil Uji Manual

Berikut merupakan tampilan halaman utama catatan dengan kolom pencarian:

![Tampilan Utama](screenshots/p1_tampilanUtama.png)

Berikut merupakan tampilan ketika catatan berhasil ditemukan berdasarkan kata kunci pencarian:

![Catatan Ditemukan](screenshots/p1_tampilanDitemukan.png)

Berikut merupakan tampilan Empty State ketika kata kunci pencarian tidak ditemukan:

![Tampilan Tidak Ada](screenshots/p1_tampilanTidakAda.png)

---

## Dokumentasi Log AI

Catatan lengkap prompt, evaluasi usulan, dan log verifikasi dicatat pada docs/ai-log.md.
