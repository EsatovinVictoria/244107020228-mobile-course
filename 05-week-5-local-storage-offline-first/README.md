# 05-week-5-local-storage-offline-first

## Tujuan 

1. Menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL di perangkat.
2. Menyimpan preferensi sederhana (tema, terakhir dibuka) dengan SharedPreferences.
3. Menerapkan CRUD catatan dengan SQLite (sqflite) melalui repository lokal.
4. Menerapkan pola offline-first: cache-first read, dirty flag, dan antrean sinkronisasi.
5. Menampilkan state loading, error, empty, dan success untuk data lokal dengan Riverpod.
6. Menguji repository lokal dengan repository palsu (tanpa database sungguhan).

## Praktikum 1: SharedPreferences

Membuat repository preferensi untuk menyimpan akses key-value terpusat.

Membuat provider dan halaman pengaturan.

Berikut merupakan contoh bukti tmapilan aplikasi untuk page setting untuk tema terang.

![Tampilan Setting](screenshots/p1_tampilanTerang.png)

Dan berikut merupakan untuk tampilan gelapnya.

![Tampilan Setting](screenshots/p1_tampilanGelap.png)

Setelah dilakukan hot restart, maka tampilan aplikasi akan tetap pada mode dark karena digunakan shared preferences.

![Tampilan Setting](screenshots/p1_tampilanSetelahHotRestart.png)

## Praktikum 2: SQLite dan repository catatan

Membuat model catatan.

Membuat pembuka database pada db.dart.

Membuat repository sebagai satu-satunya pintu akses data yang terdapat
pada note_repository.dart.

Membuat halaman catatan offline yang mengambil data melalui
notesProvider dan NoteRepository.

Berikut merupakan tampilan catatan yang telah tersimpan pada SQLite.

![Tampilan Offline Notes](screenshots/p2_tampilanOfflineNotes.png)

Catatan yang sebelumnya ditambahkan tetap tersimpan dan dapat
ditampilkan kembali karena data disimpan pada SQLite melalui
NoteRepository.

## Praktikum 3: Cache-first dan antrean sync

Menggunakan endpoint minggu 4 GET /posts untuk JSON placeholder

Berikut merupakan tampilan catatan setelah diambil data melalui API GET /posts pertama kali, namun tidak terhubung dengan internet.

![Tampilan Offline Notes](screenshots/p3_tampilanKosong.png)

Berikut merupakan tampilannya ketika ditekan refresh dan terhubung dengan internet.

![Tampilan Offline Notes](screenshots/p3_tampilanListAPI.png)

List tersebut tetap tersimpan di SQLite meskipun tidak terhubung dengan internet, dan ketika dilakukan hot restart pada aplikasi nya.

![Tampilan Offline Notes](screenshots/p3_tampilanAplikasiModePesawat.png)

![Tampilan Offline Notes](screenshots/p3_tampilanAplikasiSetelahRestart.png)


Menyinkronisasikan catatan kotor (dirty) 

Berikut merupakan tampilan badge dirty notes beserta jumlah yang masih dirty.

![Tampilan Offline Notes](screenshots/p3_tampilanBadgeDirtyNotesSebelumSync.png)

Berikut merupakan tampilannya setelah dilakukan sync.

![Tampilan Offline Notes](screenshots/p3_tampilanBadgeDirtyNotesSetelahSync.png)


Simulasi offline determinisik

Berikut merupakan tampilan ketika force offline dimatikan.

![Tampilan Offline Notes](screenshots/p3_tampilanForceOfflineMati.png)

Berikut merupakan tampilan ketika force offline dinyalakan.

![Tampilan Offline Notes](screenshots/p3_tampilanForceOfflineNyala.png)

Berikut tampilan ketika dilakukan penambahan notes sebelum sync (Force offline mati).

![Tampilan Offline Notes](screenshots/p3_tampilanForceOfflineSebelumSync.png)

Dan berikut merupaakn tampilan ketika force Offline dimatikan dan dilakukan sync.

![Tampilan Offline Notes](screenshots/p3_tampilanForceOfflineSetelahSync.png)

Saat Force Offline diaktifkan, catatan yang telah tersimpan tetap dapat ditampilkan dan catatan baru dapat disimpan ke SQLite dengan status dirty. Setelah koneksi disimulasikan kembali online dan proses sinkronisasi dijalankan, nilai dirty berubah dari 2 menjadi 0.

## AI Challenge

1. Agent yang dipakai: Copilot

2. Prompt yang digunakan:

    Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
    Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
    untuk dua kebutuhan ini. Requirements:
    - Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
    type-safety, ukuran boilerplate, dan kemudahan testing.
    - Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
    beserta alasannya dalam 1 tabel.
    - Tunjukkan skema tabel/kotak untuk 1000+ catatan.
    Jelaskan trade-off setiap pilihan.

3. Output awal AI:

        ## Perbandingan penyimpanan dan rekomendasi

        Ada dua jenis data pada aplikasi ini: preferensi tema yang berupa beberapa nilai sederhana, dan catatan yang membutuhkan CRUD, pengurutan, filter, status sinkronisasi, serta kemungkinan pertumbuhan menjadi 1000+ baris.

        | Pilihan | Preferensi tema | Catatan 1000+ | Kompleksitas query dan relasi | Reaktivitas (stream) | Type-safety | Boilerplate | Testing dan trade-off |
        | --- | --- | --- | --- | --- | --- | --- | --- |
        | **SharedPreferences** | **Sangat cocok** untuk boolean/string kecil | Tidak direkomendasikan | Key-value; tidak ada query, indeks, atau relasi | Tidak native; perlu memuat ulang atau membungkus perubahan sendiri | Rendah; tipe dibatasi `bool`, `int`, `double`, `String`, dan list string | **Paling kecil** | Mudah di-mock, tetapi rawan typo key dan tidak punya transaksi. Pilihan final untuk preferensi. |
        | **Hive** | Cocok, tetapi berlebihan untuk dua nilai | Cocok untuk objek sederhana dan akses key/value cepat | Query koleksi lebih terbatas; relasi dan query SQL kompleks harus dirancang sendiri | Baik melalui `watch()`/box listener | Sedang; adapter dan field perlu dikelola | Kecil sampai sedang | Cepat dan mudah dites dengan box memory, tetapi migrasi, relasi, dan query laporan lebih manual. |
        | **sqflite (SQLite)** | Bisa, tetapi terlalu berat untuk key-value | **Sangat cocok** untuk CRUD, filter, sort, transaksi, dan indeks | SQL lengkap; relasi perlu dibuat dengan SQL dan foreign key | Tidak built-in; repository perlu memicu refresh atau memakai stream sendiri | Sedang-rendah; map dan SQL berupa string sehingga error banyak muncul saat runtime | Sedang | Mudah dites dengan database in-memory atau fake repository. Trade-off-nya adalah mapping manual dan tidak ada compile-time check untuk query. Pilihan final untuk catatan pada aplikasi ini. |
        | **Drift** | Bisa, tetapi overkill untuk preferensi sederhana | **Sangat cocok** bila query, relasi, dan stream bertambah | SQL dengan abstraksi tabel, join, migrasi, dan indeks | **Sangat baik**; query dapat menghasilkan stream reaktif | **Tinggi**; tabel dan query diverifikasi generator/compiler | Paling besar; membutuhkan generator dan setup build | Sangat kuat untuk aplikasi data-heavy dan mudah dites dengan executor khusus, tetapi menambah dependency, generated code, dan waktu setup. Pilihan upgrade jika domain catatan makin kompleks. |

        ### Rekomendasi final

        | Kebutuhan | Pilihan | Alasan keputusan |
        | --- | --- | --- |
        | Preferensi tema dan `last_opened_at` | **SharedPreferences** | Hanya beberapa nilai key-value, tidak memerlukan query, relasi, stream, atau transaksi. API kecil dan pengujiannya sederhana. |
        | CRUD catatan offline, dirty flag, cache, dan sinkronisasi | **sqflite (SQLite)** | Sudah mendukung query terurut, filter dirty, transaksi, indeks, dan skala 1000+ catatan dengan boilerplate yang masih proporsional. Jika UI nantinya wajib menerima perubahan database sebagai stream dan query/relasi meningkat, migrasikan repository ke **Drift**. |

        ### Skema tabel untuk 1000+ catatan

        SQLite menyimpan catatan sebagai baris, bukan satu JSON besar. Dengan begitu hanya halaman yang diperlukan yang dibaca dan perubahan satu catatan tidak menulis ulang seluruh koleksi.

        ```text
        +------------------+       1       0..N       +----------------------+
        | notes            |-------------------------->| note_tags            |
        +------------------+                           +----------------------+
        | id PK INTEGER    |                           | note_id PK/FK       |
        | title TEXT       |                           | tag_id  PK/FK       |
        | body TEXT        |                           +----------------------+
        | updated_at TEXT  |
        | dirty INTEGER    |       N       0..N       +----------------------+
        +------------------+-------------------------->| tags                 |
                                                                                                        +----------------------+
                                                                                                        | id PK INTEGER        |
                                                                                                        | name TEXT UNIQUE     |
                                                                                                        +----------------------+
        ```

        Untuk versi aplikasi saat ini, tabel minimalnya cukup `notes`; `tags` dan `note_tags` adalah perluasan bila relasi tag dibutuhkan.

        ```sql
        CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL DEFAULT '',
            updated_at TEXT NOT NULL,
            dirty INTEGER NOT NULL DEFAULT 0
        );

        CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
        CREATE INDEX idx_notes_dirty ON notes(dirty);
        ```

        Ambil data 50 baris per halaman agar daftar besar tidak dimuat sekaligus:

        ```sql
        SELECT id, title, body, updated_at, dirty
        FROM notes
        ORDER BY updated_at DESC, id DESC
        LIMIT 50 OFFSET 0;
        ```

        Untuk halaman yang sangat besar, keyset pagination lebih stabil daripada `OFFSET`: gunakan `WHERE (updated_at, id) < (?, ?)` dengan cursor dari baris terakhir. `dirty` tetap dipertahankan agar antrean sinkronisasi dapat mencari `WHERE dirty = 1` tanpa mengganggu catatan lain.

4. AI Verification Checklist

    a. Apakah AI menempatkan daftar catatan di SharedPreferences? (menolak: rapuh untuk koleksi).

        Tidak. AI menyatakan SharedPreferences tidak direkomendasikan untuk 1000+ catatan dan memilihnya hanya untuk preferensi.

    b. Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?

        Ya. Skema notes memiliki dirty dan updated_at. AI juga menyebut WHERE dirty = 1.

    c. Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?

        Ya, penjelasannya cukup tepat. AI menyatakan sqflite tidak memiliki stream built-in, sedangkan Drift mendukung query reaktif/stream.

    d. Apakah estimasi boilerplate AI masuk akal setelah Anda mencoba instalasinya (flutter pub add + migrasi skema)?

        Perlu diverifikasi berdasarkan praktik. SharedPreferences paling sederhana; sqflite membutuhkan database, model/mapping, dan repository. Drift disebut memiliki setup/generator lebih besar. Kamu tidak perlu menginstal Drift hanya jika jobsheet tidak secara eksplisit mewajibkan mencoba semua alternatif; tetapi checklist memang meminta mempertimbangkan pengalaman flutter pub add + migrasi skema.

    e. Keputusan final Anda beserta alasannya, boleh berbeda dari rekomendasi AI selama berargumen.

        SharedPreferences untuk preferensi dan sqflite untuk catatan. Ini sesuai implementasi project saat ini.

