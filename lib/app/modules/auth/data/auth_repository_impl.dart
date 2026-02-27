import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/auth/data/firebase_auth_datasource.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/domain/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._datasource);
  final FirebaseAuthDatasource _datasource;

  @override
  Stream<AuthUser?> get authStateChanges => _datasource.authStateChanges;

  @override
  AuthUser? get currentUser => _datasource.currentUser;

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _datasource.signInWithGoogle();
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
}
