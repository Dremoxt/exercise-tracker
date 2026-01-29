/// Application environment configuration
enum Environment {
  production,
  qa,
}

class EnvironmentConfig {
  /// Current environment - set via --dart-define=ENV=qa or ENV=production
  static const String _envString = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  static Environment get current {
    switch (_envString.toLowerCase()) {
      case 'qa':
      case 'staging':
      case 'test':
        return Environment.qa;
      default:
        return Environment.production;
    }
  }

  static bool get isQA => current == Environment.qa;
  static bool get isProduction => current == Environment.production;

  /// Whether to skip Firebase initialization (for UI-only testing)
  static bool get skipFirebase => isQA;

  /// App name with environment suffix
  static String get appName {
    switch (current) {
      case Environment.qa:
        return 'Move Now (QA)';
      case Environment.production:
        return 'Move Now';
    }
  }

  /// Get environment display name
  static String get environmentName {
    switch (current) {
      case Environment.qa:
        return 'QA - Local Only';
      case Environment.production:
        return 'Production';
    }
  }
}
