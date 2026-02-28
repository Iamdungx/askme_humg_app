import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

abstract interface class IProfileRepository {
  Future<UserProfile> getUserProfile(String userId);
}
