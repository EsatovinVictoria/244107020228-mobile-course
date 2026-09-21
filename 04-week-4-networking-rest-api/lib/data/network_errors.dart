import 'package:dio/dio.dart';

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat. Silakan coba lagi.';

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode == 404) {
          return 'Data yang diminta tidak ditemukan.';
        }

        if (statusCode == 401 || statusCode == 403) {
          return 'Anda tidak memiliki akses ke data ini.';
        }

        if (statusCode == 500) {
          return 'Terjadi masalah pada server. Silakan coba lagi.';
        }

        return 'Server mengalami masalah. Silakan coba lagi.';

      default:
        return 'Terjadi kesalahan jaringan. Silakan coba lagi.';
    }
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}