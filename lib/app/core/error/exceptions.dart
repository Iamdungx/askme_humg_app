/// Raw exceptions thrown from the data layer.
/// These are caught at repository boundaries and mapped to [Failure] subtypes.
library;

class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class AuthCanceledException extends AuthException {
  const AuthCanceledException() : super('Sign-in canceled by user');
}

class InvalidDomainException extends AuthException {
  const InvalidDomainException()
    : super('Only @humg.edu.vn emails are accepted');
}

class UserBlockedException extends AuthException {
  const UserBlockedException() : super('Your account has been blocked');
}

class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

/// UC-5.1 — user already has a report doc for this target (no duplicate reports).
class DuplicateReportException extends AppException {
  const DuplicateReportException() : super('duplicate_report');
}

class StorageException extends AppException {
  const StorageException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class RateLimitException extends AppException {
  const RateLimitException()
    : super('Too many requests. Please try again later.');
}

class AppCheckException extends AppException {
  const AppCheckException() : super('App verification failed.');
}

class InvalidTrackingCodeException extends AppException {
  const InvalidTrackingCodeException() : super('Invalid tracking code.');
}

class TrackingNotFoundException extends AppException {
  const TrackingNotFoundException() : super('Tracking code not found.');
}

/// UC-1.3 — OTP-specific exceptions thrown from OtpDatasource.
class OtpExpiredException extends AppException {
  const OtpExpiredException()
    : super('OTP has expired. Please request a new one.');
}

class OtpInvalidException extends AppException {
  const OtpInvalidException() : super('Invalid OTP. Please try again.');
}

class OtpMaxAttemptsException extends AppException {
  const OtpMaxAttemptsException()
    : super('Too many failed attempts. Please request a new OTP.');
}

class OtpSendException extends AppException {
  const OtpSendException(super.message);
}

/// Thrown when the user tries to change their avatar within the 7-day cooldown window.
class AvatarCooldownException extends AppException {
  const AvatarCooldownException(this.nextAllowedAt)
    : super('Avatar can only be changed once every 7 days');

  /// The earliest DateTime the user may change their avatar again.
  final DateTime nextAllowedAt;
}
