import 'package:askme_humg/app/modules/profile/domain/i_profile_repository.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

class GetUserProfile {
  const GetUserProfile(this._repository);

  final IProfileRepository _repository;

  Future<UserProfile> call(String userId) => _repository.getUserProfile(userId);
}

class GenerateDeepLink {
  const GenerateDeepLink();

  String call(String userId) => 'https://askme.humg.edu.vn/u/$userId';
}
