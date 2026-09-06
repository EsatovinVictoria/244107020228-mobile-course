# 02-week-2-declarative-ui-responsive-design

## Tujuan:
1. Menjelaskan prinsip declarative UI dan hubungan antara widget, konfigurasi, serta state.
2. Menggunakan StatelessWidget, StatefulWidget, Container, Row, Column, dan Expanded.
3. Membedakan komponen Material 3 dan Cupertino untuk kebutuhan platform yang berbeda.
4. Membangun layout responsif untuk ukuran layar mobile dan tablet.
5. Menerapkan theme, dark mode, styling, dan aksesibilitas dasar.

## Fitur Utama
Responsif Design

## Layout Sederhana (Warm-up)
1. Menghapus Expanded para baris nama, kemudian mengamati peringatan overflow, dan mengembalikannya setelah itu.

    Bukti screenshot:

    ![Hapus Expanded](screenshots/4_hapus_expanded.png)

2. Mengganti mainAxisSize: MainAxisSize.min menjadi nilai default (max) dan mengamati perubahan tinggi kartu.

    Bukti screenshot:

    ![Mengganti mainAxisSize](screenshots/4_mainAxisSize.png)

3. Menambahkan satu baris data email baru.

    Bukti screenshot:

    ![Tambah Baris email](screenshots/4_tambahEmail.png)

## Dashboard Responsif
1. Menyiapkan project, run, memodifikasi kode program untuk widget statis (stateless widget).

    Bukti screenshot:

    ![Preparation](screenshots/5_preparation.png)

2. Menambahkan interaksi StatefulWidget dan Cupertino Switch.

    Terlihat pada tampilan aplikasi kini memiliki sebuah switch yang dimana apabila switch untuk logo bulan, maka tampilan berubah menjadi dark mode. Sedangkan ketika di toggle menjadi off, maka tampilan aplikasi menjadi light mode.

    Bukti screenshot:

    ![Stateful dan Cupertino Light](screenshots/5_lightMode.png)

    ![Stateful dan Cupertino Dark](screenshots/5_darkMode.png)

    Perbandingan dengan Switch Adaptive:

    ![Switch Adaptive Light](screenshots/5_switchDark.png)

    ![Switch Adaptive Dark](screenshots/5_switchDark.png)

    Terlihat perbedaan pada Cupertino dan Switch Adaptive adalah warna untuk toggle light mode dan dark mode.

## Eksperimen Layout

1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.

    Pada kasus ini, saya mengganti nilai breakpoint yang semula 700 menjadi 400 sesuai dengan kode program berikut:

    final columns = constraints.maxWidth >= 400 ? 2 : 1;

    Hal ini berarti breakpoint untuk memecah digunakan 2 kolom atau 1 kolom pada tampilan UI yang semula untuk perangkat dengan lebar layar minimal 700 pixel menjadi 400 pixel, Sehingga tampilan untuk perangkat dengan resolusi 412x915 menjadi 2 kolom sesuai dengan gambar berikut.

    ![Tampilan Breakpoint Diubah](screenshots/5_breakpointDiubah.png)

2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.

    Pada soal ini, kode program diubah agar tampilan aplikasi diubah statis menjadi dark mode saja sesuai kode program berikut:
    
    themeMode: ThemeMode.dark

    ![Tema Gelap](screenshots/5_darkOnlyTheme.png)

    kemudian dikembalikan lagi menjadi setelan default dari perangkat (perangkat saya memiliki tema gelap), sesuai dengan kode program berikut:

    themeMode: ThemeMode.system,

    ![Tema Sesuai Sistem Perangkat](screenshots/5_systemTheme.png)

3. Uji aplikasi dengan ukuran layar emulator yang berbeda.

    Berikut merupakan tampilan apliklasi pada perangkat iPhone SE. Terlihat bahwa tampilan pada iPhone SE, kolom yang ditampilkan hanya 1 kolom, dan default dari tema sistem adalah tema gelap.

    ![Tampilan iPhone SE](screenshots/5_tampilanAplikasiIPhoneSE.png)

4. Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

    Menambahkan kode program semantics pada toggle mode gelap dan terang sesuai dengan kode program berikut:

    Semantics(
        label: 'Opsi Mode Gelap',
        hint: 'Geser Untuk Mengubah Tema Aplikasi',
        toggled: isDark,
        child: Switch.adaptive(
        value: isDark, 
        onChanged: onDarkChange,
    ),

    ![Tampilan Semantics](screenshots/5_semantics.png)

## Tugas Utama
Mengembangkan dashboard menjadi Academic Overview sesuai dengan ketentuan.
Berikut merupakan tampilan aplikasi setelah dikembangkan.

![Tampilan Setelah Dikembangkan](screenshots/6_tugasUtama.png)

## AI Prompt Challenge
Menggunakan AI (Gemini) untuk membandingkan dua alternatif tata letak.

1. Prompt Desain

    Prompt: Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya.

    Jawaban: 
    Kedua pendekatan ini memiliki keunggulan yang berbeda tergantung pada target perangkat dan tingkat fleksibilitas layout yang dibutuhkan.

    a. Trade-Off Responsif

    --> LayoutBuilder + Column/GridView Dynamic

    Kelebihan: Sangat adaptif terhadap perubahan ukuran layar (breakpoint). Memastikan tampilan di perangkat seluler (portrait) tidak sesak, sekaligus memanfaatkan ruang kosong pada tablet atau desktop (landscape).

    Kekurangan: Rasio childAspectRatio: 2.6 pada GridView tetap bisa menyebabkan konten terpotong (overflow) jika ukuran font pengguna dinaikkan secara ekstrem pada layar berukuran tanggung.

    --> GridView Standar (Tanpa Breakpoint)

    Kelebihan: Penulisan kode lebih sederhana dan langsung menangani scrolling bawaan secara optimal.

    Kekurangan: Layout terlihat terlalu rapat pada layar kecil atau terlalu renggang/gepeng pada layar besar jika jumlah kolom tidak disesuaikan dengan maxWidth.


    b. Trade-Off Aksesibilitas (Accessibility & A11y)

    --> Skalabilitas Teks (Text Scaling)

    Pada GridView yang menggunakan childAspectRatio, meningkatkan ukuran font sistem (misal: fitur Accessibility pada Android/iOS) sering kali memicu error Yellow-Black Striped Overflow karena tinggi card dikunci oleh rasio.

    Pendekatan layout berbasis Column atau Flex murni jauh lebih ramah aksesibilitas karena tinggi widget dapat mengembang (auto-expand) mengikuti ukuran teks.

    --> Navigasi Screen Reader (TalkBack / VoiceOver)

    GridView secara otomatis membacakan informasi struktur kisi kepada pengguna tunanetra (misal: "Menampilkan item 1 dari 4 dalam kolom 1 baris 1").

    Penggunaan LayoutBuilder yang dikombinasikan dengan pembungkus Semantics (seperti pada switch tema di kode Anda) memperjelas konteks elemen interaktif saat berpindah dari mode 1 kolom ke 2 kolom.

    Keputusan dipilih: 

    Alasan Teknis:

    Bukti Verifikasi:

2. Prompt Penguatan Konsep

    Prompt: 

    Jawaban: 

    Keputusan dipilih: 

    Alasan Teknis:

    Bukti Verifikasi:

3. Verification Prompt

    Prompt: 

    Jawaban: 

    Keputusan dipilih: 

    Alasan Teknis:

    Bukti Verifikasi:

4. Dokumentasi
