# AI review vs keputusan

## Objek review

- Agent: Codex.
- PR: #2, fix(auth): reject invalid email addresses and add tests.
- Commit yang direview: 37f70f95727a5418517a156867067cc5e1c88a6a.
- Project: 07-week-7-clean-architecture.
- Output awal AI: ai-review-output-awal.md.
- Bukti verifikasi: ai-verification-bukti.md.
- Status: temuan 1 sampai 4 diterima sebagai rekomendasi dan belum diterapkan pada kode; usulan temuan 5 ditolak.

## Prompt asli

    Review PR Flutter ini sebagai senior Flutter dev.
    Konteks: feature-first Clean Architecture (presentation -> domain <- data),
    Riverpod, GoRouter, SQLite + Dio.
    Fokus: kebenaran, arsitektur, dan test. Abaikan style.
    Berikan 5 temuan teratas + level (blocker/saran)
    + alasan + usulan potongan kode perbaikan.

Prompt menyebut SQLite, tetapi pubspec.yaml project ini tidak mencantumkan dependency SQLite. Project menggunakan Riverpod, GoRouter, dan Dio.

## Verifikasi dan keputusan

| No. | Usulan AI dan level | Hasil verifikasi | Keputusan final dan alasan teknis |
| --- | --- | --- | --- |
| 1 | Saran: periksa label domain email. | Terbukti. Domain dengan label kosong, tanda hubung pada tepi label, karakter garis miring, dan label 64 karakter tidak ditolak pada test verifikasi sementara. Cuplikan bukti: ai-verification-bukti.md. | Diterima sebagai rekomendasi, belum diterapkan. Pemeriksaan label domain diperlukan agar input tersebut ditolak sebelum repository dipanggil. Batas label 63 karakter perlu diuji pada sisi diterima dan ditolak bila saran diterapkan. |
| 2 | Saran: periksa posisi titik pada local-part tanpa tanda kutip. | Terbukti. Test penolakan .mahasiswa@kampus.ac.id, mahasiswa.@kampus.ac.id, dan maha..siswa@kampus.ac.id gagal pada versi PR #2. Bukti: ai-verification-bukti.md. | Diterima sebagai rekomendasi, belum diterapkan. Posisi titik pada local-part tanpa tanda kutip perlu diperiksa, sambil mempertahankan bentuk valid yang sudah didukung. Usulan ini belum merupakan parser lengkap seluruh format alamat email. |
| 3 | Saran: tambahkan test password lebih dari enam karakter. | Celah cakupan test terbukti. Test project mencakup panjang 0, 5, dan 6 karakter. Password tujuh karakter diterima pada verifikasi sementara. Ini bukan bug perilaku saat ini. | Diterima sebagai rekomendasi, belum diterapkan. Test tambahan dapat melindungi aturan minimal enam karakter dari regresi menjadi aturan tepat enam karakter. |
| 4 | Saran: tambahkan variasi email valid. | Celah cakupan test terbukti. Test sukses project hanya menggunakan mahasiswa@kampus.ac.id. Plus-tag dan subdomain diterima pada verifikasi sementara. | Diterima sebagai rekomendasi, belum diterapkan. Test variasi email diperlukan untuk menjaga bentuk valid yang sudah didukung saat validator diperketat. |
| 5 | Saran: ulangi test penerusan Failure dengan LocalFailure. | Test project hanya memakai AuthFailure. Login mengembalikan hasil repository secara langsung tanpa percabangan berdasarkan subtipe Failure. Test yang ada sudah memeriksa identitas failure. | Ditolak. Mengulang test forwarding untuk setiap subtipe tidak memverifikasi jalur eksekusi berbeda. Pemetaan kegagalan penyimpanan menjadi LocalFailure lebih tepat diuji pada AuthRepositoryImpl. Penolakan usulan ini tidak berarti penanganan kegagalan penyimpanan sudah teruji. |

## Dependency rule dan style

- Usulan validasi menggunakan Dart murni dan tetap berada pada domain melalui use case Login.
- Domain tetap bergantung pada kontrak AuthRepository.
- Pencarian import package, data, dan presentation pada domain auth tidak menemukan kecocokan.
- Usulan test menggunakan flutter_test pada folder test, bukan pada domain.
- Tidak ada usulan yang memerlukan import Flutter, Dio, atau SQLite ke domain.
- Lima temuan membahas perilaku dan cakupan test, bukan nitpick style yang dapat diselesaikan formatter.

## Bukti verifikasi

Dua kelompok temuan kebenaran dibuktikan melalui pemanggilan langsung use case dan test verifikasi sementara terhadap kode PR #2. Hasil test sementara adalah 19 lulus dan 10 gagal: tujuh terkait domain dan tiga terkait posisi titik pada local-part.

Cuplikan hasil reproduksi, test gagal, pemeriksaan kode, dan dependency rule disimpan pada ai-verification-bukti.md. Test verifikasi sementara tidak disertakan pada kode project yang dipertahankan.

## Hasil pemeriksaan project yang dipertahankan

Hasil pemeriksaan pada Praktikum 3:

- flutter analyze: No issues found.
- dart format --set-exit-if-changed .: 31 file diperiksa, 0 changed.
- flutter test: seluruh 27 test lulus, termasuk 14 test Login.

Bukti hasil pemeriksaan tersebut dicatat pada ai-verification-bukti.md. Penerimaan rekomendasi pada dokumen ini belum berarti implementasinya sudah dilakukan.
