import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // MANDATORY SECURITY FIX: Use AES-GCM authenticated encryption (No padding)
      // to eliminate CBC mode PKCS5/PKCS7 padding oracle vulnerabilities.
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Securely write sensitive data (Encrypted via Android Keystore / iOS Keychain)
  static Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Securely read sensitive data
  static Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  // Securely delete key
  static Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  // Securely write boolean flag (e.g. biometric lock preference)
  static Future<void> setBool(String key, bool value) async {
    await writeSecureData(key, value.toString());
  }

  // Securely read boolean flag
  static Future<bool?> getBool(String key) async {
    final val = await readSecureData(key);
    if (val == null) return null;
    return val == 'true';
  }

  // Clear all secure storage on sign out
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
