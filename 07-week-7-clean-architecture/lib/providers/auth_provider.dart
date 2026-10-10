import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final apiClientProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final auth = ref.watch(authRepositoryProvider);

  return buildApiClient(store, auth);
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();

    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);

      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();

    ref.invalidateSelf();
  }
}
