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
}
