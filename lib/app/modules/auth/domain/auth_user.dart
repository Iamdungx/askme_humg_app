import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default(false) bool isHumgVerified,
    String? humgEmail,
    @Default(false) bool isBlocked,
  }) = _AuthUser;
}
