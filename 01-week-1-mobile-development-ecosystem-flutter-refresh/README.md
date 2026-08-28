# 01-week-1-mobile-development-ecosystem-flutter-refresh

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

=====================================

# Week 1: Mobile Development Ecosystem & Flutter Refresh

# Tujuan:
## 1. menjelaskan evolusi pengembangan mobile serta perbedaan native, hybrid, dan cross-platform;
## 2. menjelaskan arsitektur Flutter, peran Dart, struktur proyek, dan widget tree;
## 3. mengulang dasar Dart: variabel, tipe data, fungsi, class, dan null safety;
## 4. menyiapkan Flutter, Android SDK, emulator atau perangkat fisik, lalu menjalankan aplikasi pertama;
## 5. mengubah UI awal Flutter dan menyimpan hasilnya pada repository Git pribadi.

# Fitur Utama
## UI Profil Mahasiswa

# Stack Teknologi
## Flutter
## Dart
## Github
## Android SDK

# Cara Menjalankan
## 1. Menginstall semua environment yang diperlukan sesuai dengan ketentuan.
## 2. Menjalankan perintah flutter --version untuk mengecek flutter apakh sudah terinstall
## 3. Menjalankan perintah flutter doctor untuk mengecek isu dan konflik apabila ada
## 4. Menjalankan perintah flutter --android-licenses untuk mendapatkan license android
## 5. Menjalankan virtual device (Pixel 7 pada praktikum saya) pada Android Studio
## 6. Menjalankan perintah flutter run untuk menjalankan aplikasi pada virtual device
## 7. Memperbarui kode pada folder lib/main.dart kemudian dilakukan hot reload untuk mengecek perubahan pada tampilan virtual device

# Hasil dicapai
## 1. Konfigurasi environment berjalan
## 2. Aplikasi dapat berjalan
## 3. Terdapat dokumentasi pada Git


# Kendala Setup
## Saya mengalami kendala setup ketika menginstall FLutter pertama kali dikarenakan saya menempatkan folder flutter nya di OneDrive, yang dimana direktori/path nya memiliki karakter jepang yang tidak bisa dibaca oleh sistem, sehingga saya panik.


# Refleksi
## 1. Kapan native lebih tepat dipilih daripada cross-platform?
## ==> Native lebih tepat dipilih daripada cross-platform apabila pengembang aplikasi berencana untuk membuat aplikasi yang ditujukan pada satu tipe device saja, yakni Android maupun iOS. Hal ini dikarekanan native memiliki kode dan UI khusus untuk setipa platform dan akses API yang langsung. 
## 2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?
## ==> Ketika terjadi perubahan state di dalam aplikasi Flutter akan menandai widget yang bersangkutan dan memicu pengerjaan ulang metode build(). Proses ini menghasilkan pembentukan Widget Tree baru, yang selanjutnya akan dibandingkan untuk mendeteksi perubahan konfigurasi secara presisi. Hal ini membuat proses pembuatan ulang UI tetap berjalan responsif.
## 3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?
## ==> Commit kecil dengan pesan jelas bermanfaat bagi tim karena tim dapat memahami konteks/perubahan kode yang dimaksud oleh individu, yang nantinya dapat ditindaklanjuti oleh rekan tim sehingga menghindari miskomunikasi dan kesalahpahaman.