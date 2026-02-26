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
