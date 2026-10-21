# Simulasi perbaikan pesan commit

| Commit | Sebelum | Sesudah (usulan) | Alasan |
| --- | --- | --- | --- |
| a2ce411 | fix: revising refactor, testing, & refleksi | refactor(fcm): remove route helper and complete week 6 report | Diff menghapus helper _notificationRoute yang pemakaiannya sudah digantikan oleh parser rute pada commit sebelumnya, serta melengkapi refleksi dan bukti pengujian. Pesan baru menjelaskan perubahan konkret dan scope-nya. Commit ini tidak menambahkan kode test baru. |
| 34fc2fa | feat: Complete Refactor & Refleksi | feat(fcm): add token registration status and route parser tests | Diff menambahkan status registrasi token berdasarkan hasil request, parser rute beserta test, konstanta rute, dan pemetaan error API. Tipe feat dapat dipertahankan karena terdapat penambahan perilaku yang terlihat pengguna. Pesan lama tidak menjelaskan perubahan tersebut. |
| 531bff1 | chore: snapshot before clean architecture and complete praktikum 1 - audit layer project lama | chore(week7): set up project baseline and document layer audit | Commit menambahkan baseline project Minggu 7 dan dokumentasi audit layer sebelum refactor. Pesan baru lebih ringkas serta menyebut scope dan tujuan perubahan. |

