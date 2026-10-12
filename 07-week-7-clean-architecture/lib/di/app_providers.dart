import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/auth/di/auth_providers.dart';
import '../messaging/push_service.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example-campus-api.test',
);

final apiClientProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final auth = ref.watch(authRepositoryProvider);

  final dio = buildApiClient(
    baseUrl: _apiBaseUrl,
    readAccess: store.readAccess,
    readRefresh: store.readRefresh,
    refreshAccess: (token) async {
      final result = await auth.refresh(token);

      if (result.failure != null) {
        return null;
      }

      return result.access;
    },
  );

  ref.onDispose(() {
    dio.close(force: true);
  });

  return dio;
});

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(api: ref.watch(apiClientProvider));

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});
