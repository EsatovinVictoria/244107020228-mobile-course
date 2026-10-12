import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/token_store.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/check_auth_session.dart';
import '../domain/usecases/login.dart';
import '../domain/usecases/logout.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);

  return AuthRepositoryImpl(tokenStore);
});

final checkAuthSessionProvider = Provider<CheckAuthSession>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return CheckAuthSession(repository);
});

final loginUseCaseProvider = Provider<Login>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return Login(repository);
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return Logout(repository);
});
