import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session, this.failure});

  final AuthSession? session;
  final Failure? failure;

  int calls = 0;
  String? receivedEmail;
  String? receivedPassword;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    calls++;
    receivedEmail = email;
    receivedPassword = password;

    return (session: session, failure: failure);
  }

  @override
  Future<({bool loggedIn, Failure? failure})> checkSession() {
    throw UnimplementedError();
  }

  @override
  Future<({String? access, Failure? failure})> refresh(String refreshToken) {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> logout() {
    throw UnimplementedError();
  }
}

void main() {
  group('Login', () {
    for (final email in [
      '',
      '   ',
      '@',
      'mahasiswa',
      'mahasiswa@',
      '@kampus.ac.id',
      'mahasiswa@@kampus.ac.id',
      'maha siswa@kampus.ac.id',
      'mahasiswa@kampus .ac.id',
      'mahasiswa@kampus',
    ]) {
      test('menolak email "$email" tanpa memanggil repository', () async {
        final repo = FakeAuthRepository();

        final result = await Login(repo).call(email: email, password: '123456');

        expect(result.session, isNull);
        expect(result.failure, isA<AuthFailure>());
        expect(repo.calls, 0);
      });
    }

    for (final password in ['', '12345']) {
      test('menolak password sepanjang ${password.length} karakter', () async {
        final repo = FakeAuthRepository();

        final result = await Login(repo)
            .call(email: 'mahasiswa@kampus.ac.id', password: password);

        expect(result.session, isNull);
        expect(result.failure, isA<AuthFailure>());
        expect(repo.calls, 0);
      });
    }

    test('meneruskan email valid dan password enam karakter', () async {
      const session = AuthSession(
        access: 'fake-access',
        refresh: 'fake-refresh',
      );
      final repo = FakeAuthRepository(session: session);

      final result = await Login(repo)
          .call(email: 'mahasiswa@kampus.ac.id', password: '123456');

      expect(result.failure, isNull);
      expect(result.session, same(session));
      expect(repo.receivedEmail, 'mahasiswa@kampus.ac.id');
      expect(repo.receivedPassword, '123456');
      expect(repo.calls, 1);
    });

    test('meneruskan password lebih dari enam karakter', () async {
      const session = AuthSession(
        access: 'fake-access',
        refresh: 'fake-refresh',
      );
      final repo = FakeAuthRepository(session: session);

      final result = await Login(repo)
          .call(email: 'mahasiswa@kampus.ac.id', password: '1234567');

      expect(result.failure, isNull);
      expect(result.session, same(session));
      expect(repo.receivedEmail, 'mahasiswa@kampus.ac.id');
      expect(repo.receivedPassword, '1234567');
      expect(repo.calls, 1);
    });

    for (final email in [
      'mahasiswa.baru@kampus.ac.id',
      'user+tag@domain.com',
      'admin@sub.domain.org',
    ]) {
      test('meneruskan variasi email valid "$email"', () async {
        const session = AuthSession(
          access: 'fake-access',
          refresh: 'fake-refresh',
        );
        final repo = FakeAuthRepository(session: session);

        final result = await Login(repo)
            .call(email: email, password: 'password123');

        expect(result.failure, isNull);
        expect(result.session, same(session));
        expect(repo.receivedEmail, email);
        expect(repo.calls, 1);
      });
    }

    test('meneruskan failure dari repository', () async {
      const failure = AuthFailure('Login ditolak.');
      final repo = FakeAuthRepository(failure: failure);

      final result = await Login(repo)
          .call(email: 'mahasiswa@kampus.ac.id', password: '123456');

      expect(result.session, isNull);
      expect(result.failure, same(failure));
      expect(repo.calls, 1);
    });
  });
}
