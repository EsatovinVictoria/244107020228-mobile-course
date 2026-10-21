Saya mereview **PR #2, commit 37f70f9**. Hasilnya: **dua kelemahan validasi yang berhasil direproduksi dan tiga saran penambahan test**. Tidak ada blocker yang terbukti terhadap kriteria eksplisit issue #1.

Domain tetap bergantung pada kontrak repository; tidak ditemukan import Flutter/Dio/SQLite pada domain auth. Project ini menggunakan Dio, tetapi tidak mencantumkan dependency SQLite.

**1. Saran — domain email dengan label kosong masih diterima**

Lokasi: login.dart, baris 14.

**Bukti:** pemanggilan use case menerima mahasiswa@kampus..ac.id dan mahasiswa@.kampus.ac.id, kemudian memanggil repository satu kali.

**Alasan:** pola setelah @ mengizinkan titik sebagai bagian karakter bebas. Domain untuk alamat email biasa harus tersusun dari label yang tidak kosong. [RFC 5321, bagian 4.1.2](https://datatracker.ietf.org/doc/html/rfc5321#section-4.1.2)

**Usulan:** tambahkan pemeriksaan label domain sebelum pemanggilan repository:

```dart
final labels = email.split('@').last.split('.');
final labelPattern = RegExp(
  r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$',
);

final validDomain = labels.length >= 2 &&
    labels.every(
      (label) => label.length <= 63 && labelPattern.hasMatch(label),
    );

if (!isEmailValid || !validDomain || password.length < 6) {
  return (
    session: null,
    failure: const AuthFailure('Email atau kata sandi tidak valid'),
  );
}
```

Tambahkan kedua contoh tersebut ke daftar email tidak valid. Test seharusnya memeriksa AuthFailure dan repo.calls = 0.

**2. Saran — posisi titik pada local-part tanpa tanda kutip belum diperiksa**

Lokasi: login.dart, baris 14.

**Bukti:** .mahasiswa@kampus.ac.id, mahasiswa.@kampus.ac.id, dan maha..siswa@kampus.ac.id diterima; repository dipanggil satu kali.

**Alasan:** local-part tanpa tanda kutip tidak boleh memiliki titik di awal, akhir, atau dua titik berurutan. Bentuk quoted local-part memiliki aturan berbeda. [RFC 5322, bagian 3.2.3 dan 3.4.1](https://www.rfc-editor.org/rfc/rfc5322.html#section-3.4.1)

**Usulan:** tambahkan pemeriksaan khusus posisi titik untuk bentuk tanpa tanda kutip:

```dart
final local = email.split('@').first;
final quotedLocal = local.length >= 2 &&
    local.startsWith('"') &&
    local.endsWith('"');

final invalidLocalDots = !quotedLocal &&
    (local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..'));
```

Masukkan invalidLocalDots ke kondisi penolakan:

```dart
if (!isEmailValid || invalidLocalDots || password.length < 6) {
  return (
    session: null,
    failure: const AuthFailure('Email atau kata sandi tidak valid'),
  );
}
```

Potongan ini memperbaiki posisi titik tersebut; belum merupakan validator lengkap seluruh bentuk alamat email.

**3. Saran — penerimaan password lebih dari enam karakter belum dilindungi test**

Lokasi: login_test.dart, baris 70 dan 83.

**Bukti:** test mencakup panjang 0, 5, dan 6. Reproduksi dengan password tujuh karakter berhasil, sehingga ini **kekurangan cakupan test, bukan bug perilaku saat ini**.

**Alasan:** perubahan keliru menjadi aturan “tepat enam karakter” dapat lolos dari test yang tersedia.

**Usulan:**

```dart
test('menerima password tujuh karakter', () async {
  const session = AuthSession(access: 'access', refresh: 'refresh');
  final repo = FakeAuthRepository(session: session);

  final result = await Login(repo).call(
    email: 'mahasiswa@kampus.ac.id',
    password: '1234567',
  );

  expect(result.failure, isNull);
  expect(result.session, same(session));
  expect(repo.receivedPassword, '1234567');
  expect(repo.calls, 1);
});
```

**4. Saran — test sukses hanya menggunakan satu bentuk email**

Lokasi: login_test.dart, baris 83.

**Bukti:** contoh sukses hanya mahasiswa@kampus.ac.id. Reproduksi menunjukkan mahasiswa+kelas@sub.kampus.ac.id juga diterima.

**Alasan:** saat memperketat validator, alamat yang menggunakan plus-tag atau subdomain berisiko ikut ditolak tanpa terdeteksi test.

**Usulan:** di dalam test sukses yang sudah menyediakan session, variasikan email:

```dart
for (final email in [
  'mahasiswa@kampus.ac.id',
  'mahasiswa+kelas@kampus.ac.id',
  'mahasiswa@sub.kampus.ac.id',
]) {
  final repo = FakeAuthRepository(session: session);

  final result = await Login(repo).call(
    email: email,
    password: '123456',
  );

  expect(result.failure, isNull);
  expect(result.session, same(session));
  expect(repo.receivedEmail, email);
  expect(repo.calls, 1);
}
```

Ini saran penguatan test untuk bentuk alamat yang saat ini sudah didukung.

**5. Saran — test penerusan failure belum mencakup kegagalan penyimpanan**

Lokasi: login_test.dart, baris 100.

**Bukti:** test hanya menggunakan AuthFailure. Implementasi AuthRepositoryImpl dapat mengembalikan LocalFailure ketika penyimpanan sesi gagal.

**Alasan:** kontrak domain mengembalikan Failure. Test sebaiknya memastikan kegagalan penyimpanan juga diteruskan tanpa diubah atau dianggap berhasil.

**Usulan:** variasikan failure di dalam test penerusan kegagalan:

```dart
for (final failure in <Failure>[
  const AuthFailure('Login ditolak.'),
  const LocalFailure('Gagal menyimpan sesi login.'),
]) {
  final repo = FakeAuthRepository(failure: failure);

  final result = await Login(repo).call(
    email: 'mahasiswa@kampus.ac.id',
    password: '123456',
  );

  expect(result.session, isNull);
  expect(result.failure, same(failure));
  expect(repo.calls, 1);
}
```

Perilaku penerusan failure saat ini sudah benar; saran ini memperluas cakupan pengujiannya.

Dua temuan pertama saya beri level **saran** karena issue #1 belum merinci cakupan format email yang harus didukung. Perilaku penerimaannya terbukti, sedangkan keputusan memperluas aturan validasi tetap perlu Anda tetapkan.

**Tidak ada kode repository yang saya ubah.** Potongan perbaikan di atas belum diterapkan atau diuji sebagai patch.
