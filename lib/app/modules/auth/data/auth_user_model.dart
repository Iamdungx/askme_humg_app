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

  static AuthUser fromFirestore(
    User firebaseUser,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isHumgVerified: data?['isHumgVerified'] as bool? ?? false,
      humgEmail: data?['humgEmail'] as String?,
      isBlocked: data?['isBlocked'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> toFirestoreUpsert(User user) => {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'avatar': user.photoURL ?? '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'isBlocked': false,
        'isHumgVerified': false,
        'humgEmail': null,
      };
}
