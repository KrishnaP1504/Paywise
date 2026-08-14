/// Centralized Environment Configuration
/// Exposes environment variables with optional defaults for local development.
/// Build with --dart-define keys to override in production:
/// flutter build apk --dart-define=FIREBASE_API_KEY=your_key ...
class EnvConfig {
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyCEwbenQ-B8cLVB6WtRPTRpGbBU7FWEkN4',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:416506927819:android:15f14c3f910558bd80594e',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '416506927819',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'paywise-kp1504',
  );

  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: 'https://paywise-kp1504-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'paywise-kp1504.firebasestorage.app',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '416506927819-up69penonpa55f2or8epqpe4nagtmjtc.apps.googleusercontent.com',
  );

  /// Validates environment configuration during startup.
  /// Throws a StateError if a critical variable is missing or empty.
  static void validateConfig() {
    if (firebaseApiKey.isEmpty) {
      throw StateError("CRITICAL CONFIG ERROR: FIREBASE_API_KEY is missing or empty.");
    }
    if (firebaseAppId.isEmpty) {
      throw StateError("CRITICAL CONFIG ERROR: FIREBASE_APP_ID is missing or empty.");
    }
    if (firebaseProjectId.isEmpty) {
      throw StateError("CRITICAL CONFIG ERROR: FIREBASE_PROJECT_ID is missing or empty.");
    }
    if (googleServerClientId.isEmpty) {
      throw StateError("CRITICAL CONFIG ERROR: GOOGLE_SERVER_CLIENT_ID is missing or empty.");
    }
  }
}
