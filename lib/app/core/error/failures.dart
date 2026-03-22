sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class AuthCanceledFailure extends AuthFailure {
  const AuthCanceledFailure() : super('Sign-in canceled by user');
}

final class InvalidDomainFailure extends AuthFailure {
  const InvalidDomainFailure() : super('Only @humg.edu.vn emails are accepted');
}

final class UserBlockedFailure extends AuthFailure {
  const UserBlockedFailure() : super('Your account has been blocked');
}

final class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

/// UC-5.1 — user already reported this target; show [reportAlreadyReported] snackbar.
final class DuplicateReportFailure extends Failure {
  const DuplicateReportFailure()
    : super('You have already reported this content.');
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure()
    : super('Too many requests. Please try again later.');
}

final class InvalidTrackingCodeFailure extends Failure {
  const InvalidTrackingCodeFailure() : super('Invalid tracking code.');
}

final class TrackingNotFoundFailure extends Failure {
  const TrackingNotFoundFailure() : super('Tracking code not found.');
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}

/// UC-1.3 — OTP-specific failures surfaced to presentation layer.
final class OtpExpiredFailure extends Failure {
  const OtpExpiredFailure()
    : super('OTP has expired. Please request a new one.');
}

final class OtpInvalidFailure extends Failure {
  const OtpInvalidFailure() : super('Invalid OTP. Please try again.');
}

final class OtpMaxAttemptsFailure extends Failure {
  const OtpMaxAttemptsFailure()
    : super('Too many failed attempts. Please request a new OTP.');
}

final class OtpSendFailure extends Failure {
  const OtpSendFailure(super.message);
}

/// Surfaced to the presentation layer when the avatar 7-day cooldown is active.
final class AvatarCooldownFailure extends Failure {
  const AvatarCooldownFailure(this.nextAllowedAt)
    : super('Avatar can only be changed once every 7 days');

  /// The earliest DateTime the user may change their avatar again.
  final DateTime nextAllowedAt;
}
