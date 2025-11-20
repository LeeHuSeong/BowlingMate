class AppException implements Exception {
  final String message;
  final int? code;

  AppException(this.message, {this.code});

  @override
  String toString() => "AppException($code): $message";
}

class NetworkException extends AppException {
  NetworkException(String message, {int? code}) : super(message, code: code);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(String message) : super(message);
}
