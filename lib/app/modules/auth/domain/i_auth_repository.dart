import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';

abstract interface class IAuthRepository {
  /// Stream of the current authenticated user. Emits null when signed out.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the currently signed-in user, or null.
  AuthUser? get currentUser;

  /// Signs in with Google OAuth → upserts users/{uid} in Firestore.
  Future<void> signInWithGoogle();

  /// Signs out from Firebase Auth and Google Sign-In.
  Future<void> signOut();

  /// Generates a 6-digit OTP, stores SHA-256 hash in Firestore, and sends it
  /// to [email] via Resend API. [recipientName] is shown in the email body. (UC-1.3)
  Future<void> generateOtp({
    required String email,
    required String uid,
    String? recipientName,
  });

  /// Verifies [otp] against the stored hash for [uid]. On success updates
  /// users/{uid}.isHumgVerified = true and deletes the otpRequests doc. (UC-1.3)
  Future<void> verifyOtp({required String otp, required String uid});
}
