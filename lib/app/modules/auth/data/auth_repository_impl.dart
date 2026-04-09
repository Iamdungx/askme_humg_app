import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/auth/data/firebase_auth_datasource.dart';
import 'package:askme_humg/app/modules/auth/data/otp_datasource.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/domain/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._datasource, this._otpDatasource);
  final FirebaseAuthDatasource _datasource;
  final OtpDatasource _otpDatasource;

  @override
  Stream<AuthUser?> get authStateChanges => _datasource.authStateChanges;

  @override
  AuthUser? get currentUser => _datasource.currentUser;

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _datasource.signInWithGoogle();
    } on AuthCanceledException {
      throw const AuthCanceledFailure();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } catch (e, s) {
      logger.e(
        'AuthRepository.signInWithGoogle unexpected error',
        error: e,
        stackTrace: s,
      );
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _datasource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e, s) {
      logger.e(
        'AuthRepository.signOut unexpected error',
        error: e,
        stackTrace: s,
      );
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> generateOtp({
    required String email,
    required String uid,
    String? recipientName,
  }) async {
    try {
      await _otpDatasource.generateOtp(
        email: email,
        uid: uid,
        recipientName: recipientName,
      );
    } on OtpSendException catch (e) {
      throw OtpSendFailure(e.message);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } catch (e, s) {
      logger.e(
        'AuthRepository.generateOtp unexpected error',
        error: e,
        stackTrace: s,
      );
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> verifyOtp({required String otp, required String uid}) async {
    try {
      await _otpDatasource.verifyOtp(otp: otp, uid: uid);
    } on OtpExpiredException {
      throw const OtpExpiredFailure();
    } on OtpInvalidException {
      throw const OtpInvalidFailure();
    } on OtpMaxAttemptsException {
      throw const OtpMaxAttemptsFailure();
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } catch (e, s) {
      logger.e(
        'AuthRepository.verifyOtp unexpected error',
        error: e,
        stackTrace: s,
      );
      throw UnknownFailure(e.toString());
    }
  }
}
