# Log Interaksi AI, Prompt Engineering, dan Evaluasi Fitur AI (Minggu 10)

## 1. Konfigurasi Prompt AI

### 1. System Prompt
```text
Kamu adalah asisten cerdas terintegrasi pada aplikasi catatan personal (Offline Notes).
Karakteristik respon:
1. Ramah, informatif, dan gunakan Bahasa Indonesia yang baik dan benar.
2. Jawab secara ringkas, to-the-point, dan hindari penjelasan bertele-tele (maksimal 3 paragraf).
3. Batasan keamanan: Jangan pernah meminta atau memproses data rahasia pribadi seperti NIK, nomor telepon, nomor kartu kredit, atau kata sandi.
4. Jika diminta meringkas catatan atau mengekstrak teks, sajikan dalam poin-poin yang terstruktur.
```

### 2. User Prompt (Percakapan & Analisis)
- **Prompt Chat 1:** "Halo! Ada yang bisa kamu bantu untuk aplikasi catatan saya?"
- **Prompt Chat 2:** "Buatkan 3 tips menjaga produktivitas dalam mencatat tugas kuliah."
- **Prompt OCR:** "Ekstrak seluruh teks yang terbaca pada gambar ini secara akurat. Kembalikan hanya teks yang ditemukan tanpa penjelasan tambahan."
- **Prompt Vision:** "Analisis dan jelaskan isi gambar ini secara detail dan jelas untuk tujuan deskripsi konten dan aksesibilitas."
- **Prompt Speech-to-Text:** "Transkripsikan isi rekaman suara ini ke dalam teks secara akurat dalam Bahasa Indonesia."

### 3. Output Awal AI (Generative Output)
```text
Halo! Saya asisten AI pada aplikasi Offline Notes. Saya siap membantu Anda:
1. Meringkas isi catatan panjang atau materi kuliah.
2. Mengekstrak teks dari foto dokumen atau kwitansi (OCR).
3. Mendeskripsikan objek gambar untuk catatan visual.
4. Mengonversi rekaman suara menjadi catatan teks (Speech-to-Text).

Ada yang bisa saya bantu sekarang?
```

---

## 2. Tabel Risiko dan Mitigasi

| No | Kategori Risiko | Potensi Dampak | Strategi Mitigasi yang Diterapkan |
| :--- | :--- | :--- | :--- |
| 1 | Kebocoran data pribadi pengguna | Data sensitif (NIK, telepon, dsb) terekspos ke cloud AI API eksternal | Validasi client-side regex NIK 16 digit dan nomor telepon sebelum request dikirim; peringatan privasi UI; penyimpanan API Key terenkripsi via `FlutterSecureStorage`. |
| 2 | Pembengkakan biaya (cost explosion) | Pemanggilan berulang menghabiskan kuota token berbayar | Menggunakan model hemat berlatensi rendah (`gemini-3.5-flash`); pemanfaatan cache lokal SQLite; debouncing tombol request. |
| 3 | Layanan AI API error / down | Aplikasi macet (*crash*) atau UX pengguna terhenti | Penanganan try-catch menyeluruh; dialog "Layanan AI Sibuk" yang ramah; fallback ke mode offline dan database lokal. |
| 4 | Respon halusinasi / tidak relevan | Informasi keliru ditampilkan ke pengguna | Validasi respon API; instruksi prompt yang spesifik; opsi bagi pengguna untuk mengedit catatan sebelum disimpan ke database. |

---

## 3. Alur Fallback Desain Sistem

```text
[User Request]
       |
       v
[Validasi Privasi Lokal] -- (Mengandung NIK?) --> [Tampilkan Dialog Peringatan]
       |
       | Aman
       v
[Koneksi ke AI Service]
       |
       +---> [Sukses: HTTP 200] ----> [Tampilkan Streaming / Hasil ke UI]
       |
       +---> [Gagal: Timeout/Offline] -> [Dialog Fallback "Layanan AI Sibuk"]
                                           |
                                           v
                                   [Gunakan Mode Catatan Offline]
```
