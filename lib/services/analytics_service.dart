import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, privacy-first analytics service designed specifically for PayWise mobile (Android & iOS).
/// Respects user privacy preferences, operates with zero third-party data tracking,
/// and stores essential app lifecycle events with local diagnostics.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _prefAnalyticsKey = 'analytics_tracking_enabled';
  bool _isEnabled = true;
  final List<Map<String, dynamic>> _inMemoryEvents = [];
  static const int _maxInMemoryEvents = 100;

  /// Initializes analytics preferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefAnalyticsKey) ?? true;
    } catch (e) {
      debugPrint("AnalyticsService init notice: $e");
    }
  }

  /// Checks if analytics event tracking is currently active
  bool get isEnabled => _isEnabled;

  /// Toggles analytics preference
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAnalyticsKey, enabled);
    } catch (e) {
      debugPrint("AnalyticsService setEnabled notice: $e");
    }
  }

  /// Dispatches a structured event safely
  Future<void> logEvent(String eventName, [Map<String, dynamic>? parameters]) async {
    if (!_isEnabled) return;

    try {
      final eventData = {
        'name': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'parameters': parameters ?? {},
      };

      if (_inMemoryEvents.length >= _maxInMemoryEvents) {
        _inMemoryEvents.removeAt(0);
      }
      _inMemoryEvents.add(eventData);

      debugPrint("📊 [Analytics] $eventName: ${parameters ?? {}}");
    } catch (e) {
      debugPrint("AnalyticsService logEvent notice: $e");
    }
  }

  /// Logs when the user visits a specific mobile screen
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }

  /// Logs when a new loan is successfully added
  Future<void> logLoanAdded({
    required String category,
    required double principalAmount,
  }) async {
    await logEvent('loan_added', {
      'category': category,
      'principal_amount': principalAmount,
    });
  }

  /// Logs when an EMI payment is recorded
  Future<void> logPaymentRecorded({
    required double amount,
    required bool isPaidOff,
  }) async {
    await logEvent('payment_recorded', {
      'amount': amount,
      'is_paid_off': isPaidOff,
    });
  }

  /// Logs when a prepayment simulation is run
  Future<void> logSimulationRun({required String type}) async {
    await logEvent('simulation_calculated', {'simulation_type': type});
  }

  /// Logs security-relevant actions (e.g. biometric unlocked, lockout triggered)
  Future<void> logSecurityEvent({
    required String eventType,
    String? details,
  }) async {
    await logEvent('security_event', {
      'event_type': eventType,
      'details': details ?? '',
    });
  }

  /// Retrieves recent in-memory events for diagnostics or debugging
  List<Map<String, dynamic>> getRecentEvents() => List.unmodifiable(_inMemoryEvents);

  /// Clears in-memory diagnostics log
  void clearEvents() {
    _inMemoryEvents.clear();
  }
}
