import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    // Validasi format dasar email: [local-part]@[domain].[tld]
    final isEmailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!isEmailValid || password.length < 6) {
      return (
        session: null,
        failure: const AuthFailure('Email atau kata sandi tidak valid'),
      );
    }

    return _repository.login(email: email, password: password);
  }
}
