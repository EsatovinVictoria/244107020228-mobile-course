# Dokumentasi Pipeline CI/CD, Versioning, dan Keamanan (Minggu 13)

## 1. Arsitektur Alur CI/CD

Pipeline CI/CD dikonfigurasi pada berkas .github/workflows/flutter-ci.yml dan menargetkan proyek Flutter utama pada direktori 05-week-5-local-storage-offline-first.

Alur eksekusi otomatis:
1. Trigger Event: Berjalan otomatis pada setiap pull_request dan push ke branch main atau develop, serta dapat dipicu manual via workflow_dispatch.
2. Concurrency Control: Membatalkan eksekusi lama pada branch yang sama (cancel-in-progress: true) agar runner tidak membuang kuota menit build.
3. Minimum Permission: Menggunakan permissions contents: read tanpa izin tulis ke repositori.
4. Persiapan Environment: Checkout source code (actions/checkout@v4), setup JDK 17 Temurin (actions/setup-java@v4), dan setup Flutter stable (subosito/flutter-action@v2).
5. Pemeriksaan Kualitas (Quality Gate):
   - flutter pub get
   - dart format --output=none --set-exit-if-changed .
   - flutter analyze --fatal-infos
   - flutter test --coverage
6. Build Rilis Android dan Artefak:
   - flutter build apk --release (untuk uji internal dan instalasi langsung)
   - flutter build appbundle --release (untuk distribusi Google Play)
   - actions/upload-artifact@v4 menyimpan app-release.apk dan app-release.aab ke artefak android-builds dengan masa simpan 7 hari dan if-no-files-found: error.

---

## 2. Strategi Versioning (Semantic Versioning)

- Versi saat ini pada 05-week-5-local-storage-offline-first/pubspec.yaml: 1.1.0+2
  - 1.1.0 (major.minor.patch): Minor naik dari 1.0.0 karena penambahan fitur AI (Minggu 10), optimasi performa (Minggu 11), validasi & test suite (Minggu 12), dan otomatisasi CI/CD (Minggu 13) yang kompatibel ke belakang.
  - +2 (build number): Dinaikkan dari +1 untuk membedakan artefak build baru.
- Rencana versi berikutnya:
  - 1.1.1+3 apabila rilis selanjutnya hanya berisi perbaikan bug atau patch minor.
  - 1.2.0+3 apabila rilis selanjutnya menambahkan fitur baru yang kompatibel (misalnya release signing otomatis atau integrasi sinkronisasi cloud nyata).
  - Tag rilis Git: v1.1.0 ditautkan pada commit main yang telah lulus seluruh langkah pipeline CI.

---

## 3. Analisis Risiko Keamanan yang Masih Perlu Ditangani

| Risiko Keamanan | Kondisi Saat Ini | Mitigasi yang Diperlukan Sebelum Rilis Produksi |
| :--- | :--- | :--- |
| Release Signing Menggunakan Debug Key | build.gradle.kts masih memakai signingConfigs.getByName("debug") untuk buildType release | Buat keystore produksi (.jks), encode ke base64, simpan pada GitHub Actions Secrets bersama storePassword, keyPassword, dan keyAlias, serta injeksikan hanya pada workflow rilis khusus tag |
| Kebocoran Secret pada Pull Request Fork | Workflow PR memakai permissions contents: read dan tidak membaca secret | Tetap pisahkan workflow CI PR dari workflow CD rilis agar PR eksternal tidak pernah memiliki akses ke keystore atau token Play Console |
| Eksposur Konfigurasi via --dart-define | Nilai --dart-define dikompilasi ke binary klien dan dapat diekstrak | Jangan pernah menempatkan API key privat atau credential server ke --dart-define; gunakan flutter_secure_storage di sisi pengguna atau proxy backend |
| Dependensi Pihak Ketiga Kadaluarsa | Beberapa paket di pubspec.lock memiliki versi lebih baru | Jalankan audit berkala dengan flutter pub outdated dan tinjau changelog keamanan sebelum menaikkan versi |
