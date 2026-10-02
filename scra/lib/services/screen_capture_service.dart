import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android only: the foreground service screen capture needs.
///
/// Android 10+ only allows screen capture (MediaProjection) while a
/// foreground service of type `mediaProjection` runs; Android 14+ also
/// requires the user's capture consent *before* that service starts. The
/// service lives in `android/app/src/main/kotlin/.../ScreenCaptureService.kt`.
abstract final class ScreenCaptureService {
  static const MethodChannel _channel = MethodChannel(
    'smart_class/screen_capture',
  );

  static bool get isRequired =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts the service; completes once it is in the foreground.
  static Future<void> start() async {
    final running = await _channel.invokeMethod<bool>('start');
    if (running != true) {
      throw StateError('Screen sharing service did not start');
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on Object {
      // Not running: nothing to stop.
    }
  }
}
