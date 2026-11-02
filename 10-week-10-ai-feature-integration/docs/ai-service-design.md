# AI Service & Multimodal Architecture Design

## 1. Ikhtisar Arsitektur

Fitur kecerdasan buatan pada aplikasi catatan offline diintegrasikan dengan mengedepankan prinsip Clean Architecture, integrasi multimodal, dan keamanan data:

```text
+--------------------------------------------------------+
|                      Presentation                      |
|         ChatScreen & MultimodalScreen (OCR/Vision/STT) |
+--------------------------------------------------------+
                           |
                           v
+--------------------------------------------------------+
|                       Service                          |
|         AiService (ask, askStream, recognizeText,      |
|           describeImage, speechToText)                 |
+--------------------------------------------------------+
             |                                  |
             v                                  v
+------------------------+          +--------------------+
|  FlutterSecureStorage  |          | Google Gemini API  |
|  (Keystore Terenkripsi)|          | (gemini-3.5-flash) |
+------------------------+          +--------------------+
```

## 2. Detail Komponen

### 1. AiService (`lib/ai/ai_service.dart`)
- Mengenkapsulasi komunikasi HTTP ke endpoint Google Gemini API (`https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent`).
- Membaca kunci API secara otomatis dari `FlutterSecureStorage` dengan key `ai_api_key`.
- Menyediakan method `ask` untuk chat batch standar dan `askStream` untuk pemrosesan Server-Sent Events (SSE) berlatensi rendah.
- **Kemampuan Multimodal Baru:**
  - `recognizeText(imageFile)`: Melakukan ekstraksi teks visual (OCR) dari gambar dokumen, KTM, atau kwitansi belanja via payload `inlineData`.
  - `describeImage(imageFile, {prompt})`: Menganalisis konteks visual gambar untuk deskripsi produk, identifikasi objek, dan aksesibilitas.
  - `speechToText(audioFile)`: Mengonversi rekaman suara ke teks tertulis dalam Bahasa Indonesia.
- Menerima injeksi dependensi `client` dan `storage` opsional untuk kemudahan pengujian unit test independen.

### 2. ChatScreen (`lib/features/chat_screen.dart`)
- Menampilkan pesan dalam bentuk bubble chat dua arah (pengguna dan AI).
- Mengelola subscription stream dan memperbarui buffer tampilan secara realtime (typewriter streaming effect).
- Melindungi privasi pengguna dengan mendeteksi pola nomor NIK (16 digit) dan nomor telepon sebelum prompt dikirim.
- Menyediakan dialog konfigurasi API key terintegrasi serta akses cepat ke AI Tools.

### 3. MultimodalScreen (`lib/features/multimodal_screen.dart`)
- Menyediakan antarmuka 3 tab terpadu: OCR Teks, Vision (Image Understanding), dan Speech-to-Text.
- Mendukung input kamera dan galeri melalui package `image_picker` serta tombol muat sampel untuk pengujian di simulator/emulator.
- Terintegrasi langsung dengan repository catatan lokal (`NoteRepository`) melalui Riverpod: hasil OCR, analisis gambar, atau transkripsi audio dapat disimpan langsung ke database SQLite hanya dengan 1 klik.

## 3. Matriks Pengujian Otomatis

| Kategori | Target Pengujian | Ekspektasi | Hasil |
| :--- | :--- | :--- | :--- |
| Unit Test | AiService (tanpa API key) | Melempar Exception "API key tidak tersedia" | Lulus |
| Unit Test | AiService (HTTP 200) | Mengembalikan teks respons kandidat | Lulus |
| Unit Test | AiService (HTTP 401) | Melempar Exception status code | Lulus |
| Unit Test | AiService Key Management | Menyimpan, membaca, dan menghapus API key | Lulus |
| Unit Test | AiService SSE Streaming | Mem-parsing chunk data SSE dan memancarkan teks | Lulus |
| Unit Test | AiService recognizeText (OCR) | Mengirim inlineData base64 dan mengembalikan teks OCR | Lulus |
| Unit Test | AiService describeImage (Vision)| Mengirim inlineData gambar dengan custom prompt analisis | Lulus |
| Unit Test | AiService speechToText (STT) | Mengirim inlineData audio dan mengembalikan transkripsi | Lulus |
| Widget Test | ChatScreen Layout | Menampilkan AppBar, Banner Privasi, dan Empty State | Lulus |
| Widget Test | ChatScreen Interaksi | Mengirim teks dan menampilkan gelembung streaming | Lulus |
| Widget Test | ChatScreen Deteksi NIK | Memunculkan dialog peringatan privasi saat ada NIK | Lulus |
| Widget Test | MultimodalScreen TabBar | Menampilkan 3 tab: OCR Teks, Vision, Speech-to-Text | Lulus |
| Widget Test | MultimodalScreen Switch Tab | Berpindah ke tab Vision dan memvalidasi UI | Lulus |
| Widget Test | MultimodalScreen OCR & Save | Ekstrak teks sampel dan simpan otomatis ke SQLite | Lulus |
| Widget Test | MultimodalScreen STT Action | Konversi rekaman suara sampel dan tampilkan transkripsi | Lulus |
