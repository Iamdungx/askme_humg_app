import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/auth/data/auth_user_model.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';

class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _auth = firebaseAuth,
       _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // google_sign_in v7 uses a singleton — no need to inject
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (!doc.exists) return AuthUserModel.fromFirebaseUser(user);
          return AuthUserModel.fromFirestore(user, doc);
        } catch (e) {
          logger.w('Failed to fetch user doc, falling back to Firebase user');
          return AuthUserModel.fromFirebaseUser(user);
        }
      });

  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }

  Future<void> signInWithGoogle() async {
    try {
      // v7: signIn() → authenticate(); accessToken removed, idToken only
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw const AuthException('Sign-in returned null user');

      await _upsertUserDoc(user);
    } on FirebaseAuthException catch (e, s) {
      logger.e('FirebaseAuth sign-in failed', error: e, stackTrace: s);
      throw AuthException(e.message ?? 'Sign-in failed');
    } catch (e, s) {
      if (e is AuthException) rethrow;
      logger.e('Unexpected sign-in error', error: e, stackTrace: s);
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e, s) {
      logger.e('FirebaseAuth sign-out failed', error: e, stackTrace: s);
      throw AuthException(e.message ?? 'Sign-out failed');
    }

    try {
      // v7: signOut() still exists but disconnect() revokes token entirely
      await _googleSignIn.disconnect();
    } catch (e, s) {
      logger.w('Google disconnect failed (non-fatal)', error: e, stackTrace: s);
    }
  }

  Future<void> _upsertUserDoc(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update(AuthUserModel.toFirestoreUpsert(user));
      } else {
        await docRef.set(AuthUserModel.toFirestoreCreate(user));
      }
    } on FirebaseException catch (e, s) {
      logger.e('Failed to upsert users doc', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore write failed');
    }
  }
}
