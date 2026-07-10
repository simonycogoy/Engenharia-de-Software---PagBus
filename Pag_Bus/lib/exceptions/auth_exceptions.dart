abstract class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class EmailAlreadyExistsException extends AuthException {
  const EmailAlreadyExistsException(super.message);
}

class ValidationException extends AuthException {
  const ValidationException(super.message);
}

class ServerException extends AuthException {
  const ServerException(super.message);
}

class ApiTimeoutException extends AuthException {
  const ApiTimeoutException(super.message);
}

class NetworkException extends AuthException {
  const NetworkException(super.message);
}
