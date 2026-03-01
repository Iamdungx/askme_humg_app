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

/// UC-1.3 — OTP-specific exceptions thrown from OtpDatasource.
class OtpExpiredException extends AppException {
  const OtpExpiredException() : super('OTP has expired. Please request a new one.');
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
