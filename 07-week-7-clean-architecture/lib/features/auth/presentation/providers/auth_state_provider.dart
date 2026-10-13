import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../../di/auth_providers.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final checkSession = ref.watch(checkAuthSessionProvider);
    final result = await checkSession();

    final failure = result.failure;

    if (failure != null) {
      throw failure;
    }

    return result.loggedIn;
  }

  Future<void> login(String email, String password) async {
    // Abaikan pemanggilan berulang ketika operasi masih berlangsung.
    if (state.isLoading) return;

    final loginUseCase = ref.read(loginUseCaseProvider);

    state = const AsyncLoading();

    final result = await loginUseCase(email: email, password: password);

    if (!ref.mounted) return;

    final failure = result.failure;

    if (failure != null) {
      state = AsyncError(failure, StackTrace.current);
      return;
    }

    if (result.session == null) {
      state = AsyncError(
        const AuthFailure('Sesi login tidak tersedia. Silakan coba lagi.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncData(true);
  }

  Future<void> logout() async {
    if (state.isLoading) return;

    final logoutUseCase = ref.read(logoutUseCaseProvider);

    state = const AsyncLoading();

    final result = await logoutUseCase();

    if (!ref.mounted) return;

    final failure = result.failure;

    if (failure != null) {
      state = AsyncError(failure, StackTrace.current);
      return;
    }

    if (!result.success) {
      state = AsyncError(
        const AuthFailure('Logout belum berhasil. Silakan coba lagi.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncData(false);
  }
}
