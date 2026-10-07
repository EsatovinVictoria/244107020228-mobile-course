import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  if (error.response?.statusCode == 401) {
    return 'Sesi login tidak valid atau sudah berakhir. '
        'Silakan login kembali.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Permintaan terlalu lama. Silakan coba lagi.';

    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. '
          'Periksa koneksi internet lalu coba lagi.';

    case DioExceptionType.badCertificate:
      return 'Koneksi aman ke server gagal. Silakan coba nanti.';

    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';

    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;

      if (status == 403) {
        return 'Kamu tidak memiliki izin untuk melakukan tindakan ini.';
      }

      if (status != null && status >= 500) {
        return 'Server sedang bermasalah. Silakan coba nanti.';
      }

      return 'Permintaan tidak dapat diproses. Periksa data yang dikirim.';

    case DioExceptionType.unknown:
      return 'Terjadi gangguan saat menghubungi server. '
          'Silakan coba lagi.';
  }
}
