import 'package:askme_humg/app/modules/auth/domain/i_auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repo);
  final IAuthRepository _repo;

  Future<void> call() => _repo.signInWithGoogle();
}

class SignOut {
  const SignOut(this._repo);
  final IAuthRepository _repo;

  Future<void> call() => _repo.signOut();
}
