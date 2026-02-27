import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String userId,
    @Default('') String name,
    @Default('') String avatar,
    @Default('') String email,
    @Default(false) bool isBlocked,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}

extension UserProfileModelX on UserProfileModel {
  UserProfile toDomain({int answerCount = 0, int totalLikes = 0}) =>
      UserProfile(
        userId: userId,
        name: name,
        avatar: avatar,
        email: email,
        answerCount: answerCount,
        totalLikes: totalLikes,
        isBlocked: isBlocked,
      );
}
