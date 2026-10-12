import 'package:dio/dio.dart';

Dio buildApiClient({
  required String baseUrl,
  required Future<String?> Function() readAccess,
  required Future<String?> Function() readRefresh,
  required Future<String?> Function(String token) refreshAccess,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // Request yang bersamaan menunggu satu proses refresh.
  Future<String?>? refreshing;

  Future<String?> refreshOnce(String token) {
    final current = refreshing;

    if (current != null) {
      return current;
    }

    final operation = Future<String?>.sync(() => refreshAccess(token))
        .whenComplete(() {
          refreshing = null;
        });

    refreshing = operation;
    return operation;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final access = await readAccess();

          if (access != null) {
            options.headers['Authorization'] = 'Bearer $access';
          } else {
            options.headers.remove('Authorization');
          }

          handler.next(options);
        } catch (_) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Gagal membaca sesi autentikasi.',
            ),
          );
        }
      },
      onError: (error, handler) async {
        final options = error.requestOptions;

        if (error.response?.statusCode != 401 ||
            options.extra['authRetried'] == true) {
          handler.next(error);
          return;
        }

        try {
          final refresh = await readRefresh();

          if (refresh == null || refresh.isEmpty) {
            handler.next(error);
            return;
          }

          final access = await refreshOnce(refresh);

          if (access == null) {
            handler.next(error);
            return;
          }

          options.extra['authRetried'] = true;
          options.headers['Authorization'] = 'Bearer $access';

          final response = await dio.fetch<dynamic>(options);
          handler.resolve(response);
        } on DioException catch (retryError) {
          handler.next(retryError);
        } catch (_) {
          handler.next(error);
        }
      },
    ),
  );

  return dio;
}
