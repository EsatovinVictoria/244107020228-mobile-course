# Simulasi perbaikan pesan commit

| Commit | Sebelum | Sesudah (usulan) | Alasan |
| --- | --- | --- | --- |
| a2ce411 | fix: revising refactor, testing, & refleksi | refactor(fcm): remove route helper and complete week 6 report | Diff menghapus helper _notificationRoute yang pemakaiannya sudah digantikan oleh parser rute pada commit sebelumnya, serta melengkapi refleksi dan bukti pengujian. Pesan baru menjelaskan perubahan konkret dan scope-nya. Commit ini tidak menambahkan kode test baru. |
| 34fc2fa | feat: Complete Refactor & Refleksi | feat(fcm): add token registration status and route parser tests | Diff menambahkan status registrasi token berdasarkan hasil request, parser rute beserta test, konstanta rute, dan pemetaan error API. Tipe feat dapat dipertahankan karena terdapat penambahan perilaku yang terlihat pengguna. Pesan lama tidak menjelaskan perubahan tersebut. |
| 531bff1 | chore: snapshot before clean architecture and complete praktikum 1 - audit layer project lama | chore(week7): set up project baseline and document layer audit | Commit menambahkan baseline project Minggu 7 dan dokumentasi audit layer sebelum refactor. Pesan baru lebih ringkas serta menyebut scope dan tujuan perubahan. |

## Kesiapan tengah semester

- [x] Struktur feature-first tersedia pada fitur auth dan announcements, dengan pemisahan domain, data, dan presentation.
- [x] Bukti tiga grep sterilitas Minggu 7 tersedia pada ai_grep1.png, ai_grep2.png, dan ai_grep3.png. Pemeriksaan tersebut mencakup akses data mentah pada presentation auth dan halaman, import package pada domain auth serta Failure, dan instansiasi dependency pada presentation.
- [x] flutter analyze menghasilkan No issues found.
- [x] dart format --set-exit-if-changed . memeriksa 31 file dengan 0 changed.
- [x] flutter test berhasil menjalankan 27 test pada Praktikum 3.
- [x] PR #2 berisi perubahan kecil dengan pesan commit yang menjelaskan perbaikan validasi login.
- [x] PR #2 sudah di-merge ke develop setelah self-review dengan keputusan Approve.
- [x] Saran review PR #2 sudah dinilai tidak menghalangi merge. Penambahan test password tujuh karakter dan komentar regex belum diterapkan pada kode.
- [x] Workflow CI pada PR #3 berhasil menjalankan pemeriksaan.
- [x] README memuat cara menjalankan project secara lengkap.
- [x] README memuat status paruh semester dan peta issue/PR.
- [x] Perilaku aplikasi pada Praktikum 3 sudah diuji dan dibandingkan dengan kondisi akhir Minggu 7.
