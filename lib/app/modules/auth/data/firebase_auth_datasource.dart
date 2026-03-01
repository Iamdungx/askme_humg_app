import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(null);
        return _userDocStream(user);
      });

  Stream<AuthUser?> _userDocStream(User user) async* {
    final snapshots = _firestore.collection('users').doc(user.uid).snapshots();
    await for (final doc in snapshots) {
      if (!doc.exists) {
        yield await AuthUserModel.fromFirebaseUserWithClaims(user);
      } else {
        try {
          yield await AuthUserModel.fromFirestore(user, doc);
        } catch (e) {
          logger.w('Failed to parse user doc snapshot', error: e);
          yield AuthUserModel.fromFirebaseUser(user);
        }
      }
    }
  }

  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }

  Future<void> signInWithGoogle() async {
    try {
      // v7: authenticate() throws on user cancellation (never returns null).
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;

      // idToken is String? in google_sign_in v7; null means the platform did
      // not return a token (should not happen on a successful flow, but guard
      // defensively rather than letting Firebase reject an invalid credential).
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException('Google Sign-In did not return an ID token');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw const AuthException('Sign-in returned null user');

      try {
        await _upsertUserDoc(user);
      } on FirestoreException catch (e, s) {
        logger.w(
          'Firestore upsert failed (non-fatal, will retry on reconnect)',
          error: e,
          stackTrace: s,
        );
      }
    } on FirebaseAuthException catch (e, s) {
      logger.e('FirebaseAuth sign-in failed', error: e, stackTrace: s);
      throw AuthException(e.message ?? 'Sign-in failed');
    } on PlatformException catch (e, s) {
      if (e.code == 'canceled' || e.code == 'sign_in_canceled') {
        logger.i('Google Sign-In canceled by user');
        throw const AuthCanceledException();
      }
      logger.e('Google Sign-In platform error', error: e, stackTrace: s);
      throw AuthException(e.message ?? 'Sign-in failed');
    } catch (e, s) {
      if (e is AuthException) rethrow;
      final msg = e.toString();
      if (msg.contains('canceled') || msg.contains('cancelled')) {
        logger.i('Google Sign-In canceled by user');
        throw const AuthCanceledException();
      }
      logger.e('Unexpected sign-in error', error: e, stackTrace: s);
      throw AuthException(msg);
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
