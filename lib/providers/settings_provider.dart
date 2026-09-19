import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paywise/services/secure_storage_service.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _biometricEnabled = false;
  bool _swipeActionsEnabled = true; // swipe left = delete, right = pay
  bool _notificationsEnabled = true;
  bool _notifyDueToday = true;
  bool _notifyDueTomorrow = true;
  bool _notifyAdvance = true;
  bool _notifyOverdue = true;

  final LocalAuthentication auth = LocalAuthentication();

  ThemeMode get themeMode => _themeMode;
  bool get biometricEnabled => _biometricEnabled;
  bool get swipeActionsEnabled => _swipeActionsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get notifyDueToday => _notifyDueToday;
  bool get notifyDueTomorrow => _notifyDueTomorrow;
  bool get notifyAdvance => _notifyAdvance;
  bool get notifyOverdue => _notifyOverdue;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('isDarkMode')) {
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    _swipeActionsEnabled = prefs.getBool('swipeActionsEnabled') ?? true;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _notifyDueToday = prefs.getBool('notifyDueToday') ?? true;
    _notifyDueTomorrow = prefs.getBool('notifyDueTomorrow') ?? true;
    _notifyAdvance = prefs.getBool('notifyAdvance') ?? true;
    _notifyOverdue = prefs.getBool('notifyOverdue') ?? true;

    // Load biometric preference from encrypted SecureStorage (Keystore/Keychain)
    final secureBiometric = await SecureStorageService.getBool('biometricEnabled');
    if (secureBiometric != null) {
      _biometricEnabled = secureBiometric;
    } else {
      // Seamlessly migrate legacy cleartext SharedPreferences setting if present
      final legacyBiometric = prefs.getBool('biometricEnabled') ?? false;
      _biometricEnabled = legacyBiometric;
      await SecureStorageService.setBool('biometricEnabled', legacyBiometric);
      await prefs.remove('biometricEnabled');
    }

    notifyListeners();
  }

  Future<void> toggleAllNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
    notifyListeners();
  }

  Future<void> toggleNotifyDueToday(bool enabled) async {
    _notifyDueToday = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyDueToday', enabled);
    notifyListeners();
  }

  Future<void> toggleNotifyDueTomorrow(bool enabled) async {
    _notifyDueTomorrow = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyDueTomorrow', enabled);
    notifyListeners();
  }

  Future<void> toggleNotifyAdvance(bool enabled) async {
    _notifyAdvance = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyAdvance', enabled);
    notifyListeners();
  }

  Future<void> toggleNotifyOverdue(bool enabled) async {
    _notifyOverdue = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifyOverdue', enabled);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> toggleSwipeActions(bool enabled) async {
    _swipeActionsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swipeActionsEnabled', enabled);
    notifyListeners();
  }
  
  Future<bool> toggleBiometric(bool isEnabled) async {
    if (isEnabled) {
      // Check if hardware is available before enabling
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      // Ask for scan to confirm ownership before enabling
      bool didAuthenticate = await authenticate();
      if (!didAuthenticate) return false; 
    }

    _biometricEnabled = isEnabled;
    // Persist securely in hardware-backed Keystore / Keychain
    await SecureStorageService.setBool('biometricEnabled', isEnabled);

    // Clean up any remaining legacy cleartext entry from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometricEnabled');

    notifyListeners();
    return true;
  }

  // --- THIS WAS MISSING ---
  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access PayWise',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint("Biometric Error: $e");
      return false;
    }
  }
}
