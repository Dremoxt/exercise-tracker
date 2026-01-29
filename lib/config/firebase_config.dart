import 'package:firebase_core/firebase_core.dart';
import 'environment.dart';

/// Firebase configuration using compile-time environment variables.
///
/// Production build:
/// flutter build web --dart-define=ENV=production \
///                   --dart-define=FIREBASE_API_KEY=your_prod_key \
///                   ... (other prod credentials)
///
/// QA build:
/// flutter build web --dart-define=ENV=qa \
///                   --dart-define=FIREBASE_API_KEY=your_qa_key \
///                   ... (other QA credentials)
class FirebaseConfig {
  // Read from compile-time environment variables
  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const String _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Check if Firebase is properly configured
  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _authDomain.isNotEmpty &&
      _projectId.isNotEmpty &&
      _appId.isNotEmpty;

  /// Get the current environment's Firebase options
  static FirebaseOptions get webOptions {
    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured for ${EnvironmentConfig.environmentName}.\n'
        'Please provide environment variables:\n'
        'FIREBASE_API_KEY, FIREBASE_AUTH_DOMAIN, FIREBASE_PROJECT_ID, '
        'FIREBASE_STORAGE_BUCKET, FIREBASE_MESSAGING_SENDER_ID, FIREBASE_APP_ID',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      authDomain: _authDomain,
      projectId: _projectId,
      storageBucket: _storageBucket,
      messagingSenderId: _messagingSenderId,
      appId: _appId,
    );
  }

  /// Get project ID for display/debugging
  static String get projectId => _projectId;
}
