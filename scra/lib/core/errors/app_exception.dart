/// Base type for every error surfaced to the UI.
///
/// Repositories and services translate low-level failures (socket errors,
/// HTTP status codes, JSON issues) into one of these subtypes so screens only
/// need to deal with a small, predictable set of errors.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connectivity / host unreachable.
final class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Unable to reach the campus server. Check your connection and try again.',
    Object? cause,
  ]) : super(cause: cause);
}

/// Request exceeded the configured timeout.
final class TimeoutAppException extends AppException {
  const TimeoutAppException([
    super.message = 'The request timed out. Please try again.',
  ]);
}

/// Invalid credentials or expired session (HTTP 401).
final class AuthException extends AppException {
  const AuthException([
    super.message = 'Invalid credentials. Please check and try again.',
  ]);
}

/// Authenticated but not allowed (HTTP 403 or role guard).
final class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

/// Resource not found (HTTP 404).
final class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'The requested item was not found.',
  ]);
}

/// Server-side validation failure (HTTP 400/409/422).
final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
}

/// Unexpected server failure (HTTP 5xx).
final class ServerException extends AppException {
  const ServerException([
    super.message = 'The server encountered an error. Please try again later.',
    this.statusCode,
  ]);

  final int? statusCode;
}

/// Malformed or unexpected response payload.
final class ParsingException extends AppException {
  const ParsingException([
    super.message = 'Received an unexpected response from the server.',
    Object? cause,
  ]) : super(cause: cause);
}

/// Anything else.
final class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Something went wrong. Please try again.',
    Object? cause,
  ]) : super(cause: cause);
}
