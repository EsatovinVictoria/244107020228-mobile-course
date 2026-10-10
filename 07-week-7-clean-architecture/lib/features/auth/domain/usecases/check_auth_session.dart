import '../../../../core/failures.dart';
import '../repositories/auth_repository.dart';

class CheckAuthSession {
  const CheckAuthSession(this._repository);

  final AuthRepository _repository;

  Future<({bool loggedIn, Failure? failure})> call() {
    return _repository.checkSession();
  }
}
