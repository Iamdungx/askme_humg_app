import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String email,
    @Default(false) bool isHumgVerified,
    @Default(false) bool isBlocked,
    @Default(false) bool isAdmin,
    String? displayName,
    String? photoUrl,
    String? humgEmail,
  }) = _AuthUser;
}
