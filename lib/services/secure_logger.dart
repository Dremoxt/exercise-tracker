import 'package:flutter/foundation.dart';

/// Secure logging utility that only logs in debug mode.
/// In production, errors are silently handled without exposing details.
class SecureLogger {
  /// Log an error message (only visible in debug mode)
  static void error(String context, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$context] Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
    // In production: Consider sending to a secure crash reporting service
    // like Firebase Crashlytics (without sensitive user data)
  }

  /// Log a warning message (only visible in debug mode)
  static void warning(String context, String message) {
    if (kDebugMode) {
      debugPrint('[$context] Warning: $message');
    }
  }

  /// Log an info message (only visible in debug mode)
  static void info(String context, String message) {
    if (kDebugMode) {
      debugPrint('[$context] Info: $message');
    }
  }
}
