import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<({bool loggedIn, Failure? failure})> checkSession() async {
    try {
      final access = await _tokenStore.readAccess();

      // Mempertahankan pemeriksaan sesi pada aplikasi lama.
      return (loggedIn: access != null, failure: null);
    } catch (_) {
      return (
        loggedIn: false,
        failure: const LocalFailure('Gagal membaca sesi login.'),
      );
    }
  }

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    // Simulasi autentikasi seperti implementasi Week 6.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final session = AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );

    try {
      await _tokenStore.save(access: session.access, refresh: session.refresh);

      return (session: session, failure: null);
    } catch (_) {
      return (
        session: null,
        failure: const LocalFailure('Gagal menyimpan sesi login.'),
      );
    }
  }

  @override
  Future<({String? access, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    if (refreshToken.isEmpty) {
      return (
        access: null,
        failure: const AuthFailure('Refresh token tidak tersedia.'),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final access =
        'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _tokenStore.save(access: access, refresh: refreshToken);

      return (access: access, failure: null);
    } catch (_) {
      return (
        access: null,
        failure: const LocalFailure('Gagal menyimpan sesi yang diperbarui.'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> logout() async {
    try {
      await _tokenStore.clear();

      return (success: true, failure: null);
    } catch (_) {
      return (
        success: false,
        failure: const LocalFailure('Gagal menghapus sesi login.'),
      );
    }
  }
}
