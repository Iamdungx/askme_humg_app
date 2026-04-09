import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/profile/data/firebase_profile_datasource.dart';
import 'package:askme_humg/app/modules/profile/domain/i_profile_repository.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  const ProfileRepositoryImpl(this._datasource);

  final FirebaseProfileDatasource _datasource;

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      return await _datasource.getUserProfile(userId);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e, st) {
      logger.e('getUserProfile unexpected error', error: e, stackTrace: st);
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? avatarLocalPath,
  }) async {
    try {
      await _datasource.updateProfile(
        userId: userId,
        name: name,
        avatarLocalPath: avatarLocalPath,
      );
    } on AvatarCooldownException catch (e) {
      throw AvatarCooldownFailure(e.nextAllowedAt);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e, st) {
      logger.e('updateProfile unexpected error', error: e, stackTrace: st);
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<DateTime?> getAvatarUpdatedAt(String userId) async {
    try {
      return await _datasource.getAvatarUpdatedAt(userId);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } catch (e, st) {
      logger.e('getAvatarUpdatedAt unexpected error', error: e, stackTrace: st);
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> updateNotificationPrefs({
    required String userId,
    required bool notifNewQuestion,
    required bool notifNewComment,
  }) async {
    try {
      await _datasource.updateNotificationPrefs(
        userId: userId,
        notifNewQuestion: notifNewQuestion,
        notifNewComment: notifNewComment,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } catch (e, st) {
      logger.e(
        'updateNotificationPrefs unexpected error',
        error: e,
        stackTrace: st,
      );
      throw UnknownFailure(e.toString());
    }
  }
}
