# Laporan Temuan Profiling Performa (Performance Findings)

## 1. Lingkungan dan Metrik Baseline Profiling

Profiling awal dilakukan menggunakan Flutter DevTools pada mode profil (flutter run --profile) untuk memperoleh pengukuran akurat tanpa overhead debugging.

### Skenario Uji Profiling
1. Membuka halaman utama Offline Notes dengan dataset lebih dari 100 catatan.
2. Melakukan scroll cepat (fling scroll) naik dan turun pada daftar catatan.
3. Menjalankan fitur interaksi AI Streaming Chat dengan menerima respon teks panjang.
4. Membuka fitur AI Multimodal (Vision dan OCR) dengan gambar foto resolusi tinggi.
5. Melakukan navigasi bolak-balik antara halaman daftar catatan dan halaman detail sebanyak 5 kali.

### Data Metrik Baseline (Sebelum Optimasi)
- Target frame budget: 16.67 ms per frame (standar 60 FPS).
- Rata-rata frame time (UI Thread): 19.8 ms (terjadi frame drop / jank).
- Rata-rata frame time (Raster Thread): 22.4 ms saat render gambar kamera.
- Persentase jank frame: 24.3% (terdiri atas frame kuning 16-32 ms dan frame merah >32 ms).
- Konsumsi Dart Heap Memory: 42.6 MB (baseline) melonjak hingga 78.4 MB saat manipulasi gambar.
- GC (Garbage Collection) event: Frekuensi GC tinggi (rata-rata 1 GC setiap 3.2 detik saat scroll cepat).
- Top fungsi pada Flame Chart:
  1. RenderParagraph.paint dan RenderFlex.paint (re-painting seluruh baris list item).
  2. BuildOwner.buildScope (rebuild widget tree yang terlalu luas pada notifikasi provider).
  3. ImageLoader.instantiateImageCodec (decoding gambar resolusi penuh di Raster Thread).

---

## 2. Identifikasi Tiga Masalah Bottleneck Utama

Berdasarkan analisis visual Flame Chart dan Memory Profiler pada Flutter DevTools, ditemukan tiga masalah performa utama:

### Masalah 1: Rebuild dan Repaint Berlebih pada List Item dan Bubble Chat
- Gejala pada DevTools: Muncul bar merah berulang pada UI Thread dan Raster Thread saat scroll dan saat respon streaming AI diterima.
- Analisis Teknis:
  Widget NoteTile dan bubble pesan pada ChatScreen belum diisolasi layer rendering-nya. Setiap kali satu frame teks baru tiba dari Server-Sent Events (SSE) AI, state lokal memicu setState yang me-repaint seluruh canvas ListView, termasuk bubble pesan lama yang sebenarnya statis.
- Dampak: UI thread menghabiskan lebih dari 18 ms hanya untuk merekonstruksi dan mengecat ulang elemen yang tidak mengalami perubahan visual.

### Masalah 2: Ketiadaan Mekanisme Pagination (Infinite Scroll) pada List Data
- Gejala pada DevTools: Waktu layout meningkat tajam seiring bertambahnya jumlah data catatan dan data posts dari remote API.
- Analisis Teknis:
  Seluruh dataset dimuat sekaligus dari database SQLite ke dalam memori aplikasi. Meskipun ListView.builder hanya me-render widget dalam viewport, struktur data di memori dan kalkulasi scroll extent tetap memproses seluruh list array. Tidak ada pembagian halaman (pagination) dan fetch-on-demand saat pengguna mendekati batas bawah list.
- Dampak: Konsumsi memori inisial tinggi dan terjadi lag sesaat (hitch) saat pertama kali membuka halaman atau saat melakukan query pencarian.

### Masalah 3: Potensi Memory Leak pada Controller dan Konsumsi Memori Gambar yang Tidak Dibatasi
- Gejala pada DevTools: Memory Heap graph menunjukkan grafik tangga yang terus menanjak dan tidak turun kembali setelah navigasi bolak-balik 5 kali.
- Analisis Teknis:
  1. ScrollController dan FocusNode pada form pencarian dan form chat belum dipastikan ter-dispose secara deterministik saat widget di-unmount.
  2. Pada layar MultimodalScreen, pemuatan gambar dari galeri atau kamera menggunakan resolusi asli sensor (misalnya 3000x4000 piksel), yang didekode langsung ke bitmap tanpa pembatasan memCacheWidth atau memCacheHeight.
- Dampak: Terjadi penahanan alokasi memori (retained memory) dan tekanan berat pada GPU rasterizer yang memicu GC berkali-kali.

---

## 3. Rencana Aksi Optimasi Terpilih
1. Penerapan RepaintBoundary dan optimasi Riverpod select untuk mengisolasi area repaint dan merebuild hanya widget yang terdampak.
2. Penerapan ScrollController dengan pagination (infinite scroll) dan lazy loading bertahap (batch per 15-20 item).
3. Pembersihan ketat lifecycle controller pada dispose() serta pembatasan resolusi decoding memori bitmap gambar (cacheWidth dan cacheHeight).
