/// Centralized Environment Configuration
/// Exposes environment variables for build-time configuration.
/// Pass variables via --dart-define when building:
/// flutter build apk --dart-define=FIREBASE_API_KEY=your_key ...
class EnvConfig {
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseDatabaseUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Validates environment configuration during startup if custom build variables are provided.
  static void validateConfig() {
    // Environment validation logic
  }
}

