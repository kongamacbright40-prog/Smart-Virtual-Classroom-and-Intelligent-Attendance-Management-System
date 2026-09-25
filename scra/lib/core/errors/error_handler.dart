import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_exception.dart';

/// Converts arbitrary errors into [AppException]s and user-facing messages.
abstract final class ErrorHandler {
  static AppException normalize(Object error) {
    if (error is AppException) return error;
    if (error is http.ClientException) {
      return NetworkException(
        'Unable to reach the campus server. Check your connection and try again.',
        error,
      );
    }
    if (error is TimeoutException) return const TimeoutAppException();
    if (error is FormatException) {
      return ParsingException(error.message, error);
    }
    if (error is TypeError) {
      return ParsingException(
        'Received an unexpected response from the server.',
        error,
      );
    }
    return UnknownException('Something went wrong. Please try again.', error);
  }

  static String message(Object error) => normalize(error).message;

  /// Installs global handlers so uncaught errors are logged instead of
  /// crashing the application.
  static void installGlobalHandlers() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      log(details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      log(error, stack);
      return true;
    };
  }

  static void log(Object error, [StackTrace? stack]) {
    debugPrint('[SmartClass] ${normalize(error)}');
    if (stack != null && kDebugMode) debugPrint(stack.toString());
  }
}
