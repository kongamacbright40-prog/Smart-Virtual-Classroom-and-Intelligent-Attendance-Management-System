import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_exception.dart';

/// Converts arbitrary errors into [AppException]s and user-facing messages.
abstract final class ErrorHandler {
  static AppException normalize(Object error) {
    if (error is AppException) return error;
    // Several requests loaded at once (`(a, b).wait`): report the first
    // failure itself, e.g. "Unable to reach the campus server".
    if (error is ParallelWaitError) {
      final first = _firstError(error.errors);
      if (first != null) return normalize(first);
    }
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

  /// The first error inside a [ParallelWaitError.errors] record / list.
  static Object? _firstError(Object? errors) {
    final values = switch (errors) {
      (final a, final b) => [a, b],
      (final a, final b, final c) => [a, b, c],
      (final a, final b, final c, final d) => [a, b, c, d],
      (final a, final b, final c, final d, final e) => [a, b, c, d, e],
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    for (final value in values) {
      if (value is AsyncError) return value.error;
      if (value != null) return value;
    }
    return null;
  }

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
