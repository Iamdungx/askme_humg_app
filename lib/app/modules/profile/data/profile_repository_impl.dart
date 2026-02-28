import 'package:askme_humg/app/modules/profile/data/firebase_profile_datasource.dart';
import 'package:askme_humg/app/modules/profile/domain/i_profile_repository.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  const ProfileRepositoryImpl(this._datasource);

  final FirebaseProfileDatasource _datasource;

  @override
  Future<UserProfile> getUserProfile(String userId) =>
      _datasource.getUserProfile(userId);
}
