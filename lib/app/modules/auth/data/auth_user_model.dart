import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';

class AuthUserModel {
  static AuthUser fromFirebaseUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );

  static Future<AuthUser> fromFirebaseUserWithClaims(User user) async {
    final tokenResult = await user.getIdTokenResult();
    final isAdmin = tokenResult.claims?['admin'] == true;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAdmin: isAdmin,
    );
  }

  static Future<AuthUser> fromFirestore(
    User firebaseUser,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final tokenResult = await firebaseUser.getIdTokenResult();
    final isAdmin = tokenResult.claims?['admin'] == true;
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isHumgVerified: data?['isHumgVerified'] as bool? ?? false,
      humgEmail: data?['humgEmail'] as String?,
      isBlocked: data?['isBlocked'] as bool? ?? false,
      isAdmin: isAdmin,
    );
  }

  /// Fields updated on every login — intentionally excludes sensitive/immutable fields:
  /// - `createdAt`: set only once at account creation via [toFirestoreCreate]
  /// - `isBlocked`, `isHumgVerified`, `humgEmail`, `role`: managed server-side only
  static Map<String, dynamic> toFirestoreUpsert(User user) => {
    'name': user.displayName ?? '',
    'email': user.email ?? '',
    'avatar': user.photoURL ?? '',
  };

  /// Fields written only when creating a brand-new user document.
  static Map<String, dynamic> toFirestoreCreate(User user) => {
    ...toFirestoreUpsert(user),
    'role': 'user',
    'createdAt': FieldValue.serverTimestamp(),
    'isBlocked': false,
    'isHumgVerified': false,
    'humgEmail': null,
  };
}
