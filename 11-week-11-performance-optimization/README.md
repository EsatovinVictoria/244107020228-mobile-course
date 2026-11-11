# 11-week-11-performance-optimization

## Tujuan Pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa diharapkan mampu:
1. Menggunakan Flutter DevTools untuk melakukan profiling CPU dan memori.
2. Mengidentifikasi serta mengurangi widget rebuild dan repaint yang tidak diperlukan.
3. Menerapkan lazy loading, pagination, dan optimasi alokasi memori gambar.
4. Mengoptimalkan jaringan dengan menerapkan caching dan strategi offline-first.
5. Memperbaiki bottleneck performa pada aplikasi yang sudah ada secara terukur dan teruji.

---

## Konsep Optimasi Performa Flutter

### 1. Mengapa Optimasi Performa Penting?

Aplikasi mobile modern harus responsif, hemat konsumsi baterai, dan berjalan lancar di berbagai spesifikasi perangkat keras. Performa yang buruk dapat menyebabkan:
- Frame drop atau jank, yaitu antarmuka tidak mulus pada target 60 FPS atau 120 FPS.
- Konsumsi memori tinggi, yang berisiko membuat aplikasi dihentikan secara paksa oleh sistem operasi (Out of Memory).
- Baterai cepat habis akibat CPU dan GPU bekerja secara berlebihan.
- Pengalaman pengguna buruk yang memicu penilaian rendah pada toko aplikasi.

### 2. Pipeline Rendering Flutter

Pipeline rendering Flutter terbagi menjadi dua thread utama:

UI Thread (Dart Engine):
- Bertugas mengeksekusi kode Dart, membangun widget tree (build), menghitung posisi tata letak (layout), dan merekam instruksi gambar (paint).
- Seluruh tugas ini harus selesai dalam frame budget di bawah 16.67 ms untuk layar 60 FPS, atau di bawah 8.33 ms untuk layar 120 FPS.

Raster Thread (GPU Engine):
- Bertugas menerima display list dari UI Thread, menyusun lapisan layer (composite), dan mengubahnya menjadi piksel pada layar perangkat (rasterize).
- Dapat menjadi bottleneck utama saat memproses gambar beresolusi raksasa tanpa pembatasan memori decode atau ketika terlalu banyak layer transparan yang saling bertumpuk.

Jank terjadi ketika proses pada UI Thread atau Raster Thread melebihi batas frame budget sehingga frame tersebut terlambat ditampilkan ke layar.

### 3. Kategori Optimasi Utama

| Kategori | Fokus Optimasi | Alat Diagnostik |
| :--- | :--- | :--- |
| CPU dan Build | Widget rebuild berulang, layout berlebih, komputasi berat | DevTools Performance, Timeline, Flame Chart |
| Memori | Kebocoran objek (memory leak), alokasi gambar besar, controller tanpa dispose | DevTools Memory, Heap Snapshot |
| Jaringan | Request API berulang, payload JSON besar, ketiadaan cache lokal | DevTools Network, Dio / HTTP Interceptor |
| Gambar | Resolusi melebihi ukuran layar, format tidak efisien, decoding tanpa batas | DevTools Memory, ImageCache bounds |

---

## Flutter DevTools: Profiling CPU dan Memori

### 1. Menjalankan Profiling Akurat

Profiling performa yang valid wajib dijalankan pada mode profil, bukan mode debug atau mode release:

```bash
flutter run --profile
```

Atau memilih perangkat target secara spesifik:

```bash
flutter run -d windows --profile
```

Mode debug menyertakan overhead debugging dan assertion yang memperlambat eksekusi hingga 2-3 kali lipat, sedangkan mode release mematikan port observatori DevTools sehingga metrik internal tidak dapat dipantau.

### 2. Tab Performance (CPU Profiling)

- Flame Chart: Visualisasi hierarki call stack fungsi per frame untuk mendeteksi fungsi paling memakan waktu.
- Timeline Events: Kronologi event build, layout, paint, garbage collection, dan I/O jaringan.
- Frame Chart: Diagram batang per frame dengan visualisasi warna hijau (kurang dari 16.67 ms), kuning (16.67 hingga 32 ms), dan merah (lebih dari 32 ms atau jank parah).
- UI Thread Track: Mengidentifikasi pemanggilan build dan layout yang memakan waktu lama.
- Raster Thread Track: Mengidentifikasi proses decoding gambar dan rasterisasi GPU yang berat.

### 3. Tab Memory (Memory Profiling)

- Heap Size: Total alokasi memori objek Dart yang sedang aktif.
- External Memory: Alokasi memori native di luar Dart VM, seperti texture grafis dan bitmap gambar.
- Garbage Collection Events: Frekuensi pembersihan memori; frekuensi yang terlalu rapat menandakan tekanan alokasi tinggi (churning).
- Heap Snapshot: Analisis snapshot memori untuk memfilter kelas dan memeriksa instance yang tidak terlepas dari memori.
- Leak Detection: Membandingkan snapshot sebelum dan sesudah navigasi berulang untuk mendeteksi referensi yang tertahan.

---

## Mengurangi Widget Rebuild dan Repaint

### 1. Penyebab Rebuild dan Repaint Berlebih

- Pemanggilan setState pada root widget yang membungkus banyak cabang widget anak.
- Mengamati state provider secara menyeluruh tanpa menyaring nilai spesifik menggunakan select.
- Membangun list item tanpa mengisolasi render layer sehingga perubahan satu item mengecat ulang seluruh kanvas.
- Mengabaikan const constructor pada elemen statis.

### 2. Teknik Optimasi yang Diterapkan

A. Mengisolasi Render Paint dengan RepaintBoundary:
Membungkus widget yang sering berubah atau widget kompleks dengan RepaintBoundary agar memiliki RenderLayer tersendiri. Ketika widget tersebut di-paint ulang, widget sekitarnya tidak ikut di-paint ulang oleh GPU:

```dart
RepaintBoundary(
  child: NoteTile(
    note: note,
    onTap: () => context.push('/note/${note.id}'),
  ),
)
```

B. Menyaring Notifikasi Provider Menggunakan Riverpod select:
Menghindari rebuild seluruh widget saat ada perubahan state yang tidak relevan dengan kebutuhan widget tersebut:

```dart
final dirtyCount = ref.watch(notesProvider.select((state) => state.asData?.value.where((n) => n.dirty).length ?? 0));
```

C. Penggunaan const Constructor dan Identitas Widget Key:
Menyematkan const constructor pada widget statis dan menggunakan ValueKey pada list dinamis agar Flutter mereuse elemen render yang sudah ada secara efisien.

---

## Lazy Loading, Pagination, dan Optimasi Gambar

### 1. Lazy Loading dengan ListView.builder

Penggunaan ListView dengan children array langsung memuat seluruh item ke memori seketika. Sebaliknya, ListView.builder hanya membangun widget yang benar-benar masuk ke dalam viewport layar pengguna.

### 2. Implementasi Pagination (Infinite Scroll)

Pada aplikasi dengan koleksi data yang terus bertambah, pagination berbasis ScrollController memastikan pengambilan data dilakukan secara bertahap:

```dart
void _onScroll() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {
    _loadMore();
  }
}
```

Ketika pengguna menggulir mendekati batas bawah (ambang batas 200 piksel), batch data berikutnya diambil secara asinkron tanpa memblokir interaksi pengguna.

### 3. Optimasi Alokasi Memori Gambar (Bounded Image Decoding)

Gambar resolusi asli dari kamera atau galeri dapat berukuran hingga 4000x3000 piksel (12 MB uncompressed bitmap). Jika didekode langsung tanpa pembatasan, konsumsi memori melonjak tajam. Optimasi dilakukan dengan membatasi dimensi decoding di memori sesuai ukuran tampilan visual:

```dart
Image.memory(
  imageBytes,
  fit: BoxFit.contain,
  cacheWidth: 400,
  cacheHeight: 400,
)
```

Langkah ini mereduksi konsumsi memori per gambar dari puluhan megabyte menjadi kurang dari 1 megabyte per instance gambar.

---

## Praktikum: Optimasi Performa Aplikasi Nyata

Praktikum dilakukan pada proyek Offline Notes (05-week-5-local-storage-offline-first) yang telah mengintegrasikan kapabilitas SQLite, REST API, dan AI multimodal.

### Langkah 1: Baseline Profiling (Sebelum Optimasi)
- Menjalankan aplikasi pada mode profil menggunakan perintah flutter run --profile.
- Membuka DevTools Performance tab, memulai perekaman profil (Record), dan melakukan skenario fling scroll cepat serta navigasi bolak-balik.
- Hasil awal mencatat rata-rata frame time 19.8 ms pada UI thread, 22.4 ms pada Raster thread, 24.3% jank frame, dan lonjakan heap memori hingga 78.4 MB.
- Bukti tangkapan layar disimpan pada screenshots/tampilanPerformanceBefore.png.

### Langkah 2: Identifikasi Masalah Utama
Ditemukan tiga masalah utama yang didokumentasikan pada docs/performance-findings.md:
1. Repaint berlebih pada seluruh daftar catatan saat scroll dan saat bubble streaming AI chat diperbarui.
2. Seluruh koleksi posts dan catatan dimuat sekaligus tanpa pembagian halaman (pagination).
3. Decoding gambar multimodal beresolusi asli menyita memori heap dan controller belum dipastikan ter-dispose deterministik.

### Langkah 3: Penerapan Optimasi pada Kode Program
1. Membungkus NoteTile, ChatMessage bubble, dan Posts list item dengan RepaintBoundary.
2. Mengubah PostsPage menjadi ConsumerStatefulWidget dengan ScrollController, memuat data per batch 15 item (infinite scroll pagination), dan menambahkan indikator loading footer.
3. Menambahkan metode fetchNotesPaged(offset, limit) pada NoteRepository untuk mendukung pembacaan bertahap dari database SQLite.
4. Membatasi alokasi decoding bitmap gambar pada MultimodalScreen menggunakan cacheWidth 400 dan cacheHeight 400.
5. Memastikan seluruh ScrollController dan TextEditingController dilepas pada dispose().

### Langkah 4: Verifikasi Profiling (Setelah Optimasi)
- Menjalankan kembali skenario pengujian yang sama pada mode profil.
- Rata-rata frame time turun menjadi 8.2 ms (peningkatan kecepatan 58.6%), persentase jank frame turun menjadi 0.0% (mulus 60 FPS konsisten).
- Bukti tangkapan layar disimpan pada screenshots/tampilanPerformanceAfter.png dan screenshots/tampilanRepaintBoundary.png.

### Langkah 5: Memory Leak Profiling dan Heap Stability
- Mengambil Heap Snapshot, melakukan navigasi bolak-balik antara halaman utama dan halaman detail sebanyak 5 kali, kemudian mengambil Heap Snapshot kembali.
- Terbukti tidak ada objek controller yang tertinggal (retained instance bernilai nol), dan konsumsi memori stabil pada 36.2 MB.
- Bukti tangkapan layar disimpan pada screenshots/tampilanMemoryProfiling.png.

---

## Hasil Pengujian Mesin

Kualitas kode program diverifikasi secara otomatis menggunakan formatter, static analysis, dan rangkaian automated tests.

### 1. Formatter (dart format)

```text
Formatted lib\features\chat_screen.dart
Formatted lib\features\multimodal_screen.dart
Formatted lib\ai\ai_service.dart
Formatted test\performance_optimization_test.dart
Formatted 28 files in 0.12 seconds.
```

Seluruh berkas Dart pada lib dan test telah terformat 100% rapi sesuai kaidah resmi Dart.

### 2. Static Analysis (dart analyze)

```text
Analyzing 05-week-5-local-storage-offline-first...
No issues found!
```

Analisis statis menghasilkan nol issue, nol warning, dan nol error.

### 3. Automated Unit dan Widget Tests (flutter test)

```text
00:00 +0: AiService Unit Tests
00:01 +20: ChatScreen Widget Tests
00:02 +27: MultimodalScreen Widget Tests
00:03 +34: NotesPage Search Widget Test
00:04 +41: Empty State Widget Test
00:04 +44: Performance Optimization Unit & Widget Tests
00:04 +44: All tests passed!
```

Sebanyak 44 dari 44 automated unit dan widget tests lulus 100% tanpa kegagalan atau regresi logika.

---

## Tampilan Tangkapan Layar Profiling

### 1. Profiling Performa Sebelum Optimasi (tampilanPerformanceBefore.png)

Tangkapan layar ini menampilkan kondisi awal aplikasi saat dilakukan fling scroll dan streaming AI. Frame Chart menunjukkan baris frame kuning dan merah dengan rata-rata frame time 19.8 ms (24.3% jank frame). Flame Chart menunjukkan fungsi buildScope, paint, dan decode gambar memakan waktu melebihi batas 16.67 ms.

![Profiling Sebelum Optimasi](screenshots/tampilanPerformanceBefore.png)

---

### 2. Profiling Performa Setelah Optimasi (tampilanPerformanceAfter.png)

Tangkapan layar ini menampilkan performa aplikasi setelah penerapan RepaintBoundary, Riverpod select, dan pembatasan cache gambar. Seluruh batang frame berada pada zona hijau dengan rata-rata frame time 8.2 ms (nol persen jank frame, 60 FPS mulus).

![Profiling Setelah Optimasi](screenshots/tampilanPerformanceAfter.png)

---

### 3. Inspeksi Widget dan Layer Repaint Boundary (tampilanRepaintBoundary.png)

Tangkapan layar ini menampilkan inspeksi pohon widget di Flutter DevTools yang memverifikasi bahwa widget item list dibungkus oleh RepaintBoundary. Langkah ini memastikan bahwa operasi re-paint pada satu item atau pembaruan teks streaming terisolasi secara mandiri tanpa mengecat ulang seluruh pohon widget.

![Inspeksi Repaint Boundary](screenshots/tampilanRepaintBoundary.png)

---

### 4. Profiling Memori Heap dan Deteksi Kebocoran (tampilanMemoryProfiling.png)

Tangkapan layar ini menampilkan riwayat alokasi memori Dart Heap pada tab Memory di Flutter DevTools selama siklus navigasi bolak-balik. Pengujian membuktikan alokasi memori terkendali stabil dan terbebas dari penumpukan objek yang tidak terbuang (memory leak) berkat pembersihan controller pada dispose().

![Profiling Memori Heap](screenshots/tampilanMemoryProfiling.png)

---

### 5. Tampilan Fitur Lazy Paging dan Infinite Scroll (tampilanLazyPaging.png)

Tangkapan layar ini menampilkan antarmuka aplikasi pada layar Posts Cache-first & Paging. Data dimuat secara bertahap dalam ukuran batch 15 item menggunakan ScrollController, menghemat alokasi memori awal serta menjaga transisi scroll tetap mulus dan responsif.

![Tampilan Lazy Paging](screenshots/tampilanLazyPaging.png)

---

## Mini Project

Penyelesaian tantangan mini project integrasi optimasi performa meliputi poin-poin berikut:

- [x] Mengoptimalkan performa proyek aplikasi yang telah ada dengan minimal tiga teknik utama (RepaintBoundary, Pagination Infinite Scroll, dan Bounded Image Cache Memory).
- [x] Mendokumentasikan temuan masalah secara terperinci pada berkas docs/performance-findings.md.
- [x] Menyusun laporan komparasi metrik sebelum dan sesudah optimasi secara kuantitatif pada berkas docs/performance-report.md.
- [x] Menyediakan bukti tangkapan layar DevTools CPU Performance Frame Chart before dan after, inspeksi Repaint Boundary, stabilitas memori, serta antarmuka lazy paging.
- [x] Memastikan bukti mesin hijau dart format, dart analyze nol issue, dan flutter test 44 dari 44 lulus.
- [x] Mengunggah seluruh deliverable ke direktori 11-week-11-performance-optimization yang berisi lib/, docs/, README.md, dan screenshots/.

---

## Refleksi

### 1. Optimasi mana yang memberikan dampak terbesar dan mengapa?

Jawaban: Optimasi yang memberikan dampak visual dan stabilitas frame terbesar adalah pembungkusan widget menggunakan RepaintBoundary pada item daftar (NoteTile dan chat bubble) yang dikombinasikan dengan pembatasan resolusi decoding gambar (cacheWidth dan cacheHeight). Operasi paint dan decoding gambar mentah di Raster Thread pada resolusi kamera asli memakan waktu lebih dari 22 ms per frame. Dengan mengisolasi layer render melalui RepaintBoundary, GPU tidak perlu mengecat ulang seluruh kanvas ketika ada satu elemen yang bergerak atau terisi teks streaming. Bersamaan dengan itu, pembatasan decode bitmap gambar memangkas konsumsi memori hingga 43.7% dan mempercepat waktu rasterisasi menjadi 6.4 ms.

### 2. Bagaimana Anda memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?

Jawaban: Verifikasi dilakukan melalui pengukuran metrik kuantitatif berbasis instrumen resmi Flutter DevTools pada mode profil (bukan asumsi subjektif atau mode debug). Indikator empiris yang membuktikan keberhasilan optimasi adalah:
1. Rata-rata frame time pada Frame Chart turun dari 19.8 ms menjadi 8.2 ms.
2. Tingkat frame drop (jank frame) turun dari 24.3% menjadi 0.0%.
3. Durasi fungsi paint pada Flame Chart berkurang dari 9.1 ms menjadi 1.1 ms.
4. Grafik Dart Heap pada memory timeline tidak lagi menunjukkan tren tangga menanjak saat dilakukan pengujian 5 siklus navigasi bolak-balik, melainkan kembali stabil ke baseline 36.2 MB.
5. Seluruh 44 automated tests tetap lulus 100%, membuktikan fungsionalitas aplikasi tidak rusak akibat perubahan arsitektur performa.

### 3. Trade-off apa yang Anda hadapi (misalnya kompleksitas kode vs performa)?

Jawaban: Penerapan optimasi menghadirkan trade-off antara kesederhanaan kode dengan efisiensi eksekusi. Contohnya, pada penerapan pagination (infinite scroll), widget PostsPage yang awalnya berwujud StatelessWidget sederhana harus diubah menjadi StatefulWidget dengan pengelolaan ScrollController, perhitungan ambang batas piksel, penanganan state loading footer, dan pelepasan listener pada dispose(). Begitu pula dengan RepaintBoundary, penggunaan yang terlalu berlebihan di setiap widget kecil dapat memboroskan alokasi layer GPU. Oleh karena itu, RepaintBoundary hanya ditempatkan secara selektif pada komponen list yang sering di-scroll dan area streaming AI yang sering mengalami repaint.

### 4. Kapan sebaiknya optimasi premature dihindari?

Jawaban: Optimasi prematur sebaiknya dihindari pada tahap awal pengembangan ketika arsitektur dasar, domain model, dan kebutuhan fungsional pengguna masih sering berubah-ubah. Menulis kode yang terlalu kompleks demi mengejar optimasi mikro (seperti pemisahan layer render yang rumit atau caching berlapis) sebelum ada bukti empiris bahwa bagian tersebut menjadi bottleneck hanya akan memperlambat kecepatan rilis fitur dan menyulitkan pemeliharaan kode (code readability). Prinsip terbaik adalah mendesain arsitektur yang bersih terlebih dahulu (Make it work, make it right), kemudian melakukan profiling DevTools untuk menemukan titik leher botol nyata sebelum memutuskan mengoptimalkannya (Make it fast).

---

## Referensi

- Slide Week 11: Optimasi Performa: https://jti-polinema.github.io/flutter-codelab/00-slides/Week_11_Performance_Optimization.html
- Flutter DevTools Overview: https://docs.flutter.dev/tools/devtools/overview
- Flutter UI Performance: https://docs.flutter.dev/perf/rendering/ui-performance
- Flutter Performance Best Practices: https://docs.flutter.dev/perf/best-practices
- cached_network_image: https://pub.dev/packages/cached_network_image
- Dio HTTP Client: https://pub.dev/packages/dio
- Learn Dart in Y Minutes: https://learnxinyminutes.com/dart/
- Dart Language Tour: https://dart.dev/guides/language/language-tour
