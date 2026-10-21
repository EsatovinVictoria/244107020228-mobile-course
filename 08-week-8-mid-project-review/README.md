# 08-week-8-mid-project-review

## Tujuan

1. Menjelaskan Git Flow dan strategi branching (main, develop, feature/*, fix/*).
2. Menulis commit dan Pull Request yang berkualitas dan mudah direview.
3. Melakukan peer code review yang konstruktif dengan checklist terstruktur.
4. Menjalankan static analysis dan formatter (flutter analyze, dart format) hingga bersih.
5. Menilai kesiapan project tengah semester dan menindaklanjuti hasil review.
6. Memverifikasi saran review dari AI sebelum diterapkan.

## Praktikum 1: 

1. Menjalankan perintah di repository project Minggu 5-7

Berikut merupakan tampilan ketika menjalankan perintah di repository project Minggu 5-7.

![Screenshot](screenshots/p1_gitLogoneline.png)

![Screenshot](screenshots/p1_gitBranch.png)

![Screenshot](screenshots/p1_gitStatus.png)

2. Membuat branch kerja yang benar

Menjalankan perintah git sesuai pada modul untuk membuat branch yang benar.

![Screenshot](screenshots/p1_membuatBranchDevelop.png)

Membuat branch feature untuk menambahkan branch kerja yang benar.

![Screenshot](screenshots/p1_membuatBranchFeature.png)

3. Memperbaiki satu commit buruk (simulasi)

## Praktikum 2: PR dan peer review

1. Buka PR kecil

Masalah yang diperbaiki adalah validasi Login yang masih menerima email tidak lengkap karena hanya memeriksa keberadaan karakter @.

- Issue: Login validation accepts incomplete email addresses #1
- Branch kerja: fix/1-auth-email-validation
- Target PR: develop
- Pull Request: fix(auth): reject invalid email addresses and add tests #2

Perbaikan dilakukan pada use case Login dengan menambahkan validasi format dasar email. Unit test menggunakan fake repository untuk memeriksa penolakan input tidak valid, penerusan input valid, dan penerusan failure dari repository.

Hasil pemeriksaan:

- dart format: kedua file sudah diformat.
- flutter test test/login_test.dart: 14 test lulus.
- flutter analyze: No issues found.
- flutter test: seluruh 27 test lulus.
- git diff --check: tidak ditemukan masalah whitespace.

2. Review

Review dilakukan secara mandiri melalui self-review pada PR #2.

- Kebenaran input: email tidak valid atau password kurang dari enam karakter menghasilkan AuthFailure tanpa memanggil repository. Test memeriksa session null, jenis failure, dan jumlah pemanggilan repository.
- Kebenaran hasil: input valid diteruskan ke repository, sedangkan session dan failure dari repository dikembalikan kepada pemanggil. Test memeriksa argumen, hasil, dan jumlah pemanggilan.
- Arsitektur: Login bergantung pada kontrak AuthRepository. Tidak ditemukan penambahan ketergantungan pada implementasi data, Firebase, atau widget.
- Test: belum terdapat kasus password lebih dari enam karakter. Saran review adalah menambahkan test password tujuh karakter untuk memastikan input tetap diterima.
- Keterbacaan: regex ditulis langsung dalam Login.call. Saran review adalah memberikan komentar singkat mengenai aturan format dasar yang diperiksa.

Keputusan self-review: Approve.

Perubahan memenuhi kriteria issue #1 dan seluruh pengujian lulus. Saran tambahan dinilai tidak menghalangi merge.

3. Komentar yang konstruktif

Komentar review menggunakan pola observasi, dampak, dan usulan konkret.

Observasi: panjang password yang diuji adalah 0, 5, dan 6 karakter.

Dampak: penerimaan password lebih dari enam karakter belum diuji.

Usulan: tambahkan test password tujuh karakter dengan email valid, kemudian pastikan repository dipanggil satu kali.

4. Tindak lanjut dan merge

PR #2 digabungkan ke develop menggunakan merge commit. PR hanya memiliki satu commit sehingga tidak diperlukan squash untuk merapikan commit perantara.

Saran tambahan pada self-review tidak diterapkan karena dinilai tidak menghalangi merge.

Issue #1 ditutup secara manual sebagai Completed setelah merge. Penutupan otomatis melalui Closes #1 tidak terjadi karena target PR adalah develop, sedangkan default branch repository masih main.

Branch remote dan lokal fix/1-auth-email-validation sudah dihapus. Branch develop lokal sudah diperbarui dan sinkron dengan origin/develop.