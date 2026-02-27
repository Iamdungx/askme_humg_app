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
}
