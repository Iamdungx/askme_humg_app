import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

abstract interface class IProfileRepository {
  Future<UserProfile> getUserProfile(String userId);

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? avatarLocalPath,
  });

  /// Returns the last time the user changed their avatar, or null if never.
  Future<DateTime?> getAvatarUpdatedAt(String userId);
}
