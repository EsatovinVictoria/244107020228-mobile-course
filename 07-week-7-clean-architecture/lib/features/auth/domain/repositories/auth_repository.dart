import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<({bool loggedIn, Failure? failure})> checkSession();

  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? access, Failure? failure})> refresh(String refreshToken);

  Future<({bool success, Failure? failure})> logout();
}
