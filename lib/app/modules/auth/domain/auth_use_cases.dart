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

/// UC-1.3 — Sends OTP to the given HUMG email address.
class GenerateOtp {
  const GenerateOtp(this._repo);
  final IAuthRepository _repo;

  Future<void> call({
    required String email,
    required String uid,
    String? recipientName,
  }) => _repo.generateOtp(email: email, uid: uid, recipientName: recipientName);
}

/// UC-1.3 — Verifies OTP entered by the user.
class VerifyOtp {
  const VerifyOtp(this._repo);
  final IAuthRepository _repo;

  Future<void> call({required String otp, required String uid}) =>
      _repo.verifyOtp(otp: otp, uid: uid);
}
