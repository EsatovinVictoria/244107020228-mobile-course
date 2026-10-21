# Bukti verifikasi AI review

## Objek verifikasi

- Project: 07-week-7-clean-architecture.
- Versi kode: PR #2, commit 37f70f95727a5418517a156867067cc5e1c88a6a.
- Status keputusan: saran perbaikan belum diterapkan pada kode yang dipertahankan.

## Reproduksi temuan domain dan local-part

Hasil pemanggilan langsung use case Login dengan repository palsu dan password 123456 pada tahap review awal:

    {"email":"mahasiswa@kampus..ac.id","accepted":true,"repositoryCalls":1}
    {"email":"mahasiswa@.kampus.ac.id","accepted":true,"repositoryCalls":1}
    {"email":"mahasiswa@kampus.ac.id.","accepted":true,"repositoryCalls":1}
    {"email":".mahasiswa@kampus.ac.id","accepted":true,"repositoryCalls":1}
    {"email":"mahasiswa.@kampus.ac.id","accepted":true,"repositoryCalls":1}
    {"email":"maha..siswa@kampus.ac.id","accepted":true,"repositoryCalls":1}

Accepted bernilai true berarti use case menerima input tersebut. RepositoryCalls bernilai 1 menunjukkan bahwa input diteruskan ke repository.

## Cuplikan test verifikasi sementara

Test tambahan terhadap kode PR #2 menghasilkan 19 test lulus dan 10 test gagal. Tujuh kegagalan terkait domain dan tiga terkait posisi titik pada local-part. Test tambahan ini digunakan untuk verifikasi dan tidak disertakan dalam suite project yang dipertahankan.

Perintah pada tahap verifikasi:

    flutter test --no-pub --reporter expanded test/login_test.dart

Cuplikan output asli untuk domain:

    00:00 +10 -1: Login menolak email "mahasiswa@kampus..ac.id" tanpa memanggil repository [E]
      Expected: <Instance of 'AuthFailure'>
        Actual: <null>
         Which: is not an instance of 'AuthFailure'

Cuplikan output asli untuk local-part:

    00:00 +10 -7: Login menolak email ".mahasiswa@kampus.ac.id" tanpa memanggil repository [E]
      Expected: <Instance of 'AuthFailure'>
        Actual: <null>
         Which: is not an instance of 'AuthFailure'

Ringkasan output:

    00:00 +19 -10: Some tests failed.

## Verifikasi cakupan test dan Failure

Hasil pencarian pada kode yang dipertahankan:

    test/login_test.dart:70:    for (final password in ['', '12345']) {
    test/login_test.dart:83:    test('meneruskan email valid dan password enam karakter', () async {
    test/login_test.dart:100:    test('meneruskan failure dari repository', () async {
    test/login_test.dart:101:      const failure = AuthFailure('Login ditolak.');
    test/login_test.dart:108:      expect(result.failure, same(failure));
    lib/features/auth/domain/usecases/login.dart:23:    return _repository.login(email: email, password: password);

Kode menunjukkan bahwa test password lebih dari enam karakter dan variasi email valid belum tersedia. Login meneruskan hasil repository tanpa percabangan menurut subtipe Failure; test yang ada memeriksa identitas failure.

## Verifikasi dependency rule

Perintah dari folder project:

    rg -n '^import.*(package:|/data/|/presentation/)' lib/features/auth/domain

Hasil: tidak ada kecocokan. Domain auth tidak mengimpor package Flutter, Dio, SQLite, maupun implementasi data atau presentation.

## Bukti pemeriksaan mesin pada Praktikum 3

Hasil yang sudah tercatat untuk versi project yang dipertahankan:

    flutter analyze
    No issues found! (ran in 57.4s)

    dart format --set-exit-if-changed .
    Formatted 31 files (0 changed) in 0.59 seconds.

    flutter test
    00:03 +27: All tests passed!

Hasil 27 test merupakan suite project yang dipertahankan. Hasil 19 lulus dan 10 gagal di atas berasal dari test verifikasi sementara untuk membuktikan temuan AI.
