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
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

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
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

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
    // Chạy tuần tự và xử lý lỗi riêng để đảm bảo cả hai session đều được clear,
    // ngay cả khi một trong hai thất bại.
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e, s) {
      logger.e('FirebaseAuth sign-out failed', error: e, stackTrace: s);
      throw AuthException(e.message ?? 'Sign-out failed');
    }

    try {
      await _googleSignIn.signOut();
    } catch (e, s) {
      logger.w('Google sign-out failed (non-fatal)', error: e, stackTrace: s);
    }
  }

  Future<void> _upsertUserDoc(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        // Chỉ cập nhật name/email/avatar — không ghi đè isBlocked/isHumgVerified/role/createdAt
        await docRef.update(AuthUserModel.toFirestoreUpsert(user));
      } else {
        // Tạo document mới với đầy đủ fields mặc định
        await docRef.set(AuthUserModel.toFirestoreCreate(user));
      }
    } on FirebaseException catch (e, s) {
      logger.e('Failed to upsert users doc', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore write failed');
    }
  }
}
