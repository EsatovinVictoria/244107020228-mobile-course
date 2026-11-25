# 13-week-13-ci-cd-automation

## Tujuan Pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa diharapkan mampu:
1. Menjelaskan alur CI/CD dari commit hingga menghasilkan artefak aplikasi.
2. Membuat workflow GitHub Actions untuk format, analisis statis, pengujian otomatis, dan build Android.
3. Menyimpan APK dan AAB sebagai artefak build yang dapat ditinjau dan diunduh.
4. Menerapkan semantic versioning serta memahami batasan penyimpanan secret dan keamanan pipeline.

---

## Konsep CI/CD dan Alur Kerja

### 1. Continuous Integration dan Continuous Delivery

Continuous integration (CI) menjalankan pemeriksaan kualitas secara otomatis setiap kali perubahan diajukan melalui pull request atau di-push ke branch utama. Continuous delivery (CD) mengotomatiskan penyiapan artefak rilis sehingga proses build dapat direproduksi secara konsisten tanpa ketergantungan pada mesin lokal developer.

Tahapan utama pipeline:
1. Commit atau pull request memicu workflow GitHub Actions.
2. Runner ubuntu-latest mengambil source code, menyiapkan JDK 17, dan menginstal Flutter stable.
3. Pemeriksaan format, analisis statis ketat (--fatal-infos), dan automated tests (--coverage) dijalankan.
4. Jika seluruh pemeriksaan lulus, runner membangun APK dan AAB rilis lalu mengunggah keduanya sebagai artefak android-builds.

### 2. Event, Concurrency, dan Minimum Permission

- Trigger pull_request dan push pada branch main dan develop memastikan setiap perubahan diperiksa sebelum merge dan setelah masuk ke branch utama.
- Trigger workflow_dispatch memungkinkan eksekusi manual dari tab Actions GitHub.
- Pengaturan permissions contents: read menerapkan prinsip hak akses minimum tanpa izin tulis.
- Pengaturan concurrency dengan cancel-in-progress: true membatalkan run lama pada branch yang sama saat commit baru masuk.

---

## Implementasi Workflow CI Flutter

Berkas workflow utama dibuat pada root repositori di .github/workflows/flutter-ci.yml (dan salinan referensinya disimpan di 13-week-13-ci-cd-automation/.github/workflows/flutter-ci.yml):

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test-and-build:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: 05-week-5-local-storage-offline-first

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - run: flutter build apk --release
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: |
            05-week-5-local-storage-offline-first/build/app/outputs/flutter-apk/app-release.apk
            05-week-5-local-storage-offline-first/build/app/outputs/bundle/release/app-release.aab
          if-no-files-found: error
          retention-days: 7
```

---

## Versioning, Secrets, dan Risiko Keamanan

### 1. Dokumentasi Versi Saat Ini dan Versi Berikutnya

- Versi aktif di 05-week-5-local-storage-offline-first/pubspec.yaml: 1.1.0+2 (naik dari 1.0.0+1 seiring penambahan fitur AI, optimasi performa, test suite, dan pipeline CI/CD).
- Rencana versi berikutnya:
  - 1.1.1+3 untuk perbaikan bug atau patch kompatibel.
  - 1.2.0+3 untuk penambahan fitur baru yang kompatibel ke belakang.
- Tag rilis yang direncanakan setelah merge ke main: v1.1.0.

### 2. Pemeriksaan yang Dijalankan di Pipeline

1. Resolusi dependensi melalui flutter pub get.
2. Pemeriksaan konsistensi format kode melalui dart format --output=none --set-exit-if-changed.
3. Analisis statis ketat melalui flutter analyze --fatal-infos sehingga warning maupun info menghentikan pipeline.
4. Pengujian unit dan widget melalui flutter test --coverage (55/55 tests lulus).
5. Build artefak Android rilis melalui flutter build apk --release dan flutter build appbundle --release.
6. Pengunggahan artefak APK dan AAB dengan validasi if-no-files-found: error dan retensi 7 hari.

### 3. Risiko Keamanan yang Masih Perlu Ditangani

| Risiko | Dampak | Rencana Mitigasi |
| :--- | :--- | :--- |
| Signing rilis masih memakai debug key | APK/AAB belum dapat diunggah langsung ke Google Play Store | Menyiapkan keystore produksi yang disimpan di GitHub Actions Secrets dan hanya diinjeksikan pada workflow rilis khusus tag |
| Penyalahgunaan --dart-define untuk secret | Nilai --dart-define dikompilasi ke binary dan mudah diekstrak | Tidak menyimpan API key privat atau credential pada --dart-define; tetap memakai flutter_secure_storage di sisi klien atau backend proxy |
| Akses secret pada pull request eksternal | Risiko eksfiltrasi credential jika workflow PR membaca secret | Mempertahankan permissions contents: read pada workflow CI PR dan memisahkan workflow rilis bertanda tangan |
| Pengujian manual perangkat tetap diperlukan | Build hijau belum menjamin bebas bug UI perangkat nyata atau izin OS | Menjalankan uji instalasi APK/AAB pada perangkat fisik sebelum distribusi publik |

---

## Hasil Verifikasi Lokal Sebelum Push

Pemeriksaan dijalankan secara lokal pada direktori 05-week-5-local-storage-offline-first:

### 1. Pemeriksaan Format (dart format)

```text
dart format --output=none --set-exit-if-changed lib test integration_test
Formatted 34 files (0 changed).
```

### 2. Static Analysis Ketat (flutter analyze --fatal-infos)

```text
Analyzing 05-week-5-local-storage-offline-first...
No issues found!
```

### 3. Automated Tests dan Coverage (flutter test --coverage)

```text
00:15 +55: All tests passed!
```

---

## Bukti Eksekusi Workflow GitHub Actions

Workflow Flutter CI dikonfigurasi untuk berjalan otomatis saat pull request diajukan ke branch develop maupun main. Bukti hasil eksekusi pipeline (tab Actions) dan artefak android-builds (app-release.apk dan app-release.aab) ditinjau langsung pada halaman GitHub Actions repositori setelah PR dibuka.

---

## Tugas

- [x] Menambahkan workflow CI Flutter (.github/workflows/flutter-ci.yml) dengan format, analisis statis (--fatal-infos), dan test (--coverage).
- [x] Menambahkan build APK dan AAB rilis serta mengunggah keduanya sebagai artefak android-builds melalui actions/upload-artifact@v4.
- [x] Memperbarui versi aplikasi di pubspec.yaml menjadi 1.1.0+2 dan mendokumentasikan rencana versi berikutnya.
- [x] Mendokumentasikan pemeriksaan yang dijalankan dan risiko keamanan yang masih perlu ditangani di README.md dan docs/ci-cd-pipeline.md.
- [x] Menjalankan verifikasi lokal hingga seluruh pemeriksaan lulus sebelum push ke branch feature/week13-ci-cd-automation.

---

## Refleksi

### 1. Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?

Jawaban: Pipeline CI secara otomatis menangkap tiga kategori masalah sebelum kode masuk ke branch utama. Pertama, ketidakkonsistenan gaya penulisan kode melalui dart format --output=none --set-exit-if-changed. Kedua, kesalahan tipe, import tidak terpakai, hingga lint info melalui flutter analyze --fatal-infos (seperti temuan anotasi override pada implementasi kontrak repository). Ketiga, regresi logika bisnis, kegagalan validasi UI, dan kegagalan kompilasi Gradle Android melalui flutter test --coverage serta build APK/AAB.

### 2. Informasi apa yang Anda butuhkan untuk menyelidiki build yang gagal?

Jawaban: Untuk menyelidiki kegagalan build di GitHub Actions, informasi utama yang dibutuhkan meliputi nama step yang gagal beserta exit code-nya, log stack trace lengkap pada step tersebut, commit SHA dan diff perubahan yang memicu run, serta versi environment runner (versi Flutter, Dart, dan JDK yang terpasang). Dengan informasi tersebut, kegagalan dapat direproduksi kembali secara lokal dengan perintah yang sama sebelum diperbaiki.

### 3. Bagian mana yang masih perlu persetujuan atau pemeriksaan manual sebelum rilis?

Jawaban: Meskipun seluruh step CI hijau dan artefak APK/AAB berhasil dibangun, tetap diperlukan pemeriksaan manual sebelum rilis publik. Pemeriksaan tersebut meliputi code review arsitektur dan keamanan pada pull request, verifikasi konfigurasi release signing dengan keystore produksi, pengecekan izin AndroidManifest serta applicationId, pengujian instalasi artefak APK/AAB pada perangkat fisik (termasuk kamera, penyimpanan lokal, dan jaringan nyata), serta persetujuan rilis versi dan catatan rilis untuk Google Play Console.

---

## Referensi

- Slide Minggu 13: CI/CD dan Otomatisasi: https://jti-polinema.github.io/flutter-codelab/00-slides/Week_13_CICD_Automation.html
- GitHub Actions documentation: https://docs.github.com/actions
- Continuous delivery with Flutter: https://docs.flutter.dev/deployment/cd
- Build and release an Android app: https://docs.flutter.dev/deployment/android
- Using secrets in GitHub Actions: https://docs.github.com/actions/security-guides/using-secrets-in-github-actions
- Semantic Versioning: https://semver.org/
