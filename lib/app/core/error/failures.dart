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

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}

/// UC-1.3 — OTP-specific failures surfaced to presentation layer.
final class OtpExpiredFailure extends Failure {
  const OtpExpiredFailure() : super('OTP has expired. Please request a new one.');
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
