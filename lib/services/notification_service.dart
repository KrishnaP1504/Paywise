import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/utils/currency_formatter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'emi_channel';
  static const String channelName = 'EMI Reminders';
  static const String channelDescription =
      'Smart notifications for loan EMI payment dues';

  /// Initializes timezone database, local location, notification channels & permissions
  Future<void> init() async {
    _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: payload=${details.payload}");
      },
    );

    // CRITICAL: Explicitly create high-importance notification channel for Android (required for API 26+)
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidImplementation.createNotificationChannel(channel);
    }

    // Prompt native runtime permissions post-frame so initial UI renders immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestNotificationPermissions();
    });
  }

  bool _timeZoneInitialized = false;

  /// Ensures timezone database and local location are initialized
  void _ensureTimeZoneConfigured() {
    if (_timeZoneInitialized) return;
    _configureLocalTimeZone();
    _timeZoneInitialized = true;
  }

  /// Sets up local device timezone so scheduled notifications match the user's exact clock
  void _configureLocalTimeZone() {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }

      // Match timezone by current device UTC offset in milliseconds
      final int currentOffsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == currentOffsetMs) {
          tz.setLocalLocation(loc);
          return;
        }
      }

      // Fallback: set UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      debugPrint("Notice: Local timezone setup fallback: $e");
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  /// Prompts native Android OS & iOS runtime permissions for notifications & exact alarms
  Future<bool> requestNotificationPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (_) {}
      return granted ?? false;
    }

    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.private,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Schedules a notification safely using exact alarms, with graceful fallback to inexact
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    String? payload,
  }) async {
    _ensureTimeZoneConfigured();
    final nowTz = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(nowTz)) {
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Notice: exact alarm failed ($e), falling back to inexactAllowWhileIdle");
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (err) {
        debugPrint("Error scheduling notification $id: $err");
      }
    }
  }

  /// Schedules 5 smart notification reminders across 2 consecutive billing cycles:
  /// 1. 🗓️ 7 Days Before (9:30 AM)
  /// 2. 📅 3 Days Before (10:00 AM)
  /// 3. ⏰ 1 Day Before / Due Tomorrow (7:00 PM)
  /// 4. 🚨 Due Today (8:00 AM) — with instant catch-up banner if opened on due date!
  /// 5. ⚠️ Overdue Follow-Up (1 Day After at 11:00 AM)
  Future<void> scheduleAll5EmiReminders({
    required String loanId,
    required String loanTitle,
    required double emiAmount,
    required int dueDayOfMonth,
  }) async {
    _ensureTimeZoneConfigured();
    final prefs = await SharedPreferences.getInstance();
    final bool masterEnabled = prefs.getBool('notificationsEnabled') ?? true;
    if (!masterEnabled) return;

    final bool notifyAdvance = prefs.getBool('notifyAdvance') ?? true;
    final bool notifyDueTomorrow = prefs.getBool('notifyDueTomorrow') ?? true;
    final bool notifyDueToday = prefs.getBool('notifyDueToday') ?? true;
    final bool notifyOverdue = prefs.getBool('notifyOverdue') ?? true;

    final now = DateTime.now();
    final currency = AppCurrency.format(emiAmount);
    final baseHash = loanId.hashCode;

    // Schedule across 2 consecutive billing cycles (current & next month)
    // so reminders never lapse even if the app remains unopened for weeks
    for (int cycle = 0; cycle < 2; cycle++) {
      int targetYear = now.year;
      int targetMonth = now.month + cycle;
      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear += 1;
      }

      final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final safeDueDay = min(dueDayOfMonth, daysInTargetMonth);
      final targetDueDate = DateTime(targetYear, targetMonth, safeDueDay, 9, 0);

      final int cycleOffset = cycle * 10;
      final dueDateStr = DateFormat('MMM dd, yyyy').format(targetDueDate);
      final shortDueDateStr = DateFormat('MMM dd').format(targetDueDate);

      // ── 1. 7 DAYS BEFORE REMINDER (9:30 AM) ──
      final date7DaysBefore = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day - 7, 9, 30);
      if (notifyAdvance && date7DaysBefore.isAfter(now)) {
        final weekdayName = DateFormat('EEEE').format(targetDueDate);
        await _safeZonedSchedule(
          id: (baseHash * 31 + cycleOffset + 4) & 0x7FFFFFFF,
          title: '🗓️ Upcoming EMI in 7 Days: $loanTitle',
          body: 'Your EMI of $currency is due next $weekdayName ($shortDueDateStr). Plan your account balance ahead!',
          scheduledDate: tz.TZDateTime.from(date7DaysBefore, tz.local),
          details: _notificationDetails(),
          payload: loanId,
        );
      }

      // ── 2. 3 DAYS BEFORE REMINDER (10:00 AM) ──
      final date3DaysBefore = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day - 3, 10, 0);
      if (notifyAdvance && date3DaysBefore.isAfter(now)) {
        await _safeZonedSchedule(
          id: (baseHash * 31 + cycleOffset + 1) & 0x7FFFFFFF,
          title: '📅 EMI Payment Due in 3 Days',
          body: 'Your EMI of $currency for $loanTitle is due on $dueDateStr. Keep funds ready!',
          scheduledDate: tz.TZDateTime.from(date3DaysBefore, tz.local),
          details: _notificationDetails(),
          payload: loanId,
        );
      }

      // ── 3. 1 DAY BEFORE REMINDER (7:00 PM) ──
      final date1DayBefore = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day - 1, 19, 0);
      if (notifyDueTomorrow && date1DayBefore.isAfter(now)) {
        await _safeZonedSchedule(
          id: (baseHash * 31 + cycleOffset + 2) & 0x7FFFFFFF,
          title: '⏰ Tomorrow is EMI Payment Day!',
          body: 'Tomorrow ($shortDueDateStr) is your EMI payment day for $loanTitle ($currency).',
          scheduledDate: tz.TZDateTime.from(date1DayBefore, tz.local),
          details: _notificationDetails(),
          payload: loanId,
        );
      }

      // ── 4. DUE TODAY REMINDER (8:00 AM) ──
      final dateDueToday = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day, 8, 0);
      if (notifyDueToday) {
        if (dateDueToday.isAfter(now)) {
          // Future due date: schedule it
          await _safeZonedSchedule(
            id: (baseHash * 31 + cycleOffset + 3) & 0x7FFFFFFF,
            title: '🚨 EMI Payment Due Today!',
            body: 'Your EMI of $currency for $loanTitle is due today ($shortDueDateStr). Record payment once paid!',
            scheduledDate: tz.TZDateTime.from(dateDueToday, tz.local),
            details: _notificationDetails(),
            payload: loanId,
          );
        } else if (now.year == targetDueDate.year && now.month == targetDueDate.month && now.day == targetDueDate.day) {
          // Today IS the exact due date!
          // If scheduled time has already passed today, deliver catch-up banner once
          final dueTodayKey = 'has_notified_due_today_${loanId}_${targetYear}_${targetMonth}_$safeDueDay';
          final alreadyNotified = prefs.getBool(dueTodayKey) ?? false;
          if (!alreadyNotified) {
            await flutterLocalNotificationsPlugin.show(
              (baseHash * 31 + cycleOffset + 3) & 0x7FFFFFFF,
              '🚨 EMI Payment Due Today!',
              'Your EMI of $currency for $loanTitle is due today ($shortDueDateStr). Tap to review and record payment!',
              _notificationDetails(),
              payload: loanId,
            );
            await prefs.setBool(dueTodayKey, true);
          }
        }
      }

      // ── 5. OVERDUE / MISSED PAYMENT ALERT (1 Day After at 11:00 AM) ──
      final dateOverdue = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day + 1, 11, 0);
      if (notifyOverdue && dateOverdue.isAfter(now)) {
        await _safeZonedSchedule(
          id: (baseHash * 31 + cycleOffset + 5) & 0x7FFFFFFF,
          title: '⚠️ Follow-Up Alert: EMI Due Date Passed',
          body: 'Your EMI of $currency for $loanTitle was due yesterday. Record your payment now if already paid!',
          scheduledDate: tz.TZDateTime.from(dateOverdue, tz.local),
          details: _notificationDetails(),
          payload: loanId,
        );
      }
    }
  }

  /// Cancels all scheduled reminder notifications for a loan
  Future<void> cancelReminder(String loanId) async {
    try {
      final baseHash = loanId.hashCode;
      for (int cycle = 0; cycle < 2; cycle++) {
        final offset = cycle * 10;
        for (int r = 1; r <= 5; r++) {
          await flutterLocalNotificationsPlugin.cancel((baseHash * 31 + offset + r) & 0x7FFFFFFF);
        }
      }
      await flutterLocalNotificationsPlugin.cancel(baseHash);
    } catch (e) {
      debugPrint("Notice: cancelReminder error: $e");
    }
  }

  /// Cancels all notifications across all loans
  Future<void> cancelAllReminders() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint("Notice: cancelAllReminders error: $e");
    }
  }

  /// Synchronizes active loan reminders with Android AlarmManager & iOS NotificationCenter
  Future<void> syncAllLoanReminders(List<LoanModel> loans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool masterEnabled = prefs.getBool('notificationsEnabled') ?? true;

      if (!masterEnabled) {
        for (final loan in loans) {
          await cancelReminder(loan.id);
        }
        return;
      }

      for (final loan in loans) {
        if (loan.isPaidOff) {
          await cancelReminder(loan.id);
        } else {
          await scheduleAll5EmiReminders(
            loanId: loan.id,
            loanTitle: loan.lenderName.isNotEmpty ? loan.lenderName : loan.category,
            emiAmount: loan.emiAmount,
            dueDayOfMonth: loan.emiDueDate,
          );
        }
      }
    } catch (e) {
      debugPrint("Notice: syncAllLoanReminders error: $e");
    }
  }

  /// Triggers an immediate test notification AND schedules a 5-second test alarm to verify AlarmManager
  Future<int> showTestNotification() async {
    try {
      // 1. Immediate banner
      await flutterLocalNotificationsPlugin.show(
        99999,
        '🔔 PayWise Test Notification',
        'Test successful! Immediate notification delivery is active and working on your device.',
        _notificationDetails(),
      );

      _ensureTimeZoneConfigured();
      // 2. Scheduled test alarm 5 seconds from now to verify AlarmManager & ScheduledNotificationReceiver
      final testDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      await _safeZonedSchedule(
        id: 99998,
        title: '⏰ PayWise Background Alarm Test (5s)',
        body: 'Verified! Android Background AlarmManager delivered your scheduled reminder successfully.',
        scheduledDate: testDate,
        details: _notificationDetails(),
      );

      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint("Notice: showTestNotification error: $e");
      return 0;
    }
  }

  /// Returns total count of scheduled reminders waiting in system AlarmManager
  Future<int> getPendingNotificationCount() async {
    try {
      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }
}

