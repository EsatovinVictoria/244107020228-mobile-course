# AI Service & Chat Architecture Design

## 1. Ikhtisar Arsitektur

Fitur asisten percakapan cerdas pada aplikasi catatan offline diintegrasikan dengan mengedepankan prinsip Clean Architecture, keamanan data, dan responsivitas interaksi:

```text
+--------------------------------------------------------+
|                      Presentation                      |
|           ChatScreen & _buildStreamingBubble           |
+--------------------------------------------------------+
                           |
                           v
+--------------------------------------------------------+
|                       Service                          |
|         AiService (ask & askStream SSE parser)         |
+--------------------------------------------------------+
             |                                  |
             v                                  v
+------------------------+          +--------------------+
|  FlutterSecureStorage  |          | Google Gemini API  |
|  (Keystore Terenkripsi)|          | (streamGenerate)   |
+------------------------+          +--------------------+
```

## 2. Detail Komponen

### 1. AiService (`lib/ai/ai_service.dart`)
- Mengenkapsulasi komunikasi HTTP ke endpoint Google Gemini API (`https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`).
- Membaca kunci API secara otomatis dari `FlutterSecureStorage` dengan key `ai_api_key`.
- Menyediakan method `ask` untuk komunikasi batch standar dan `askStream` untuk pemrosesan Server-Sent Events (SSE) berlatensi rendah.
- Menerima injeksi dependensi `client` dan `storage` opsional untuk kemudahan unit testing.

### 2. ChatScreen (`lib/features/chat_screen.dart`)
- Menampilkan pesan dalam bentuk bubble chat dua arah (pengguna dan AI).
- Mengelola subscription stream dan memperbarui buffer tampilan secara realtime (typewriter streaming effect).
- Melindungi privasi pengguna dengan mendeteksi pola nomor NIK (16 digit) dan nomor telepon sebelum prompt dikirim.
- Menyediakan dialog konfigurasi API key terintegrasi.

## 3. Matriks Pengujian Otomatis

| Kategori | Target Pengujian | Ekspektasi | Hasil |
| :--- | :--- | :--- | :--- |
| Unit Test | AiService (tanpa API key) | Melempar Exception "API key tidak tersedia" | Lulus |
| Unit Test | AiService (HTTP 200) | Mengembalikan teks respons kandidat | Lulus |
| Unit Test | AiService (HTTP 401) | Melempar Exception status code | Lulus |
| Unit Test | AiService Key Management | Menyimpan, membaca, dan menghapus API key | Lulus |
| Unit Test | AiService SSE Streaming | Mem-parsing chunk data SSE dan memancarkan teks | Lulus |
| Widget Test | ChatScreen Layout | Menampilkan AppBar, Banner Privasi, dan Empty State | Lulus |
| Widget Test | ChatScreen Interaksi | Mengirim teks dan menampilkan gelembung streaming | Lulus |
| Widget Test | ChatScreen Deteksi NIK | Memunculkan dialog peringatan privasi saat ada NIK | Lulus |
