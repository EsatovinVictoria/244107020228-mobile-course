import 'package:dio/dio.dart';

import '../failures.dart';

Failure apiFailure(Object error) {
  if (error is Failure) {
    return error;
  }

  if (error is! DioException) {
    return const LocalFailure('Terjadi kesalahan. Silakan coba lagi.');
  }

  if (error.response?.statusCode == 401) {
    return const AuthFailure(
      'Sesi login tidak valid atau sudah berakhir. '
      'Silakan login kembali.',
    );
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const NetworkFailure(
        'Permintaan terlalu lama. Silakan coba lagi.',
      );

    case DioExceptionType.connectionError:
      return const NetworkFailure(
        'Tidak dapat terhubung ke server. '
        'Periksa koneksi internet lalu coba lagi.',
      );

    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'Koneksi aman ke server gagal. Silakan coba nanti.',
      );

    case DioExceptionType.cancel:
      return const NetworkFailure('Permintaan dibatalkan.');

    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;

      if (status == 403) {
        return const AuthFailure(
          'Kamu tidak memiliki izin untuk melakukan tindakan ini.',
        );
      }

      if (status != null && status >= 500) {
        return const NetworkFailure(
          'Server sedang bermasalah. Silakan coba nanti.',
        );
      }

      return const NetworkFailure(
        'Permintaan tidak dapat diproses. '
        'Periksa data yang dikirim.',
      );

    case DioExceptionType.unknown:
      return const NetworkFailure(
        'Terjadi gangguan saat menghubungi server. '
        'Silakan coba lagi.',
      );
  }
}

String apiErrorMessage(Object error) {
  return apiFailure(error).message;
}
