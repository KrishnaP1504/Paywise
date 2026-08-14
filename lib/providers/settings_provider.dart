import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _biometricEnabled = false;
  bool _swipeActionsEnabled = true; // swipe left = delete, right = pay
  final LocalAuthentication auth = LocalAuthentication();

  ThemeMode get themeMode => _themeMode;
  bool get biometricEnabled => _biometricEnabled;
  bool get swipeActionsEnabled => _swipeActionsEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _biometricEnabled = prefs.getBool('biometricEnabled') ?? false;
    _swipeActionsEnabled = prefs.getBool('swipeActionsEnabled') ?? true;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', isEnabled);
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
