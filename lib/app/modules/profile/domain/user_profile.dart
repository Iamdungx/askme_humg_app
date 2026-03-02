import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String name,
    required String avatar,
    required String email,
    @Default(0) int answerCount,
    @Default(0) int totalLikes,
    @Default(false) bool isBlocked,
    @Default(false) bool isHumgVerified,
  }) = _UserProfile;
}
