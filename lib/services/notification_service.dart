import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Automatically prompt native system runtime permission dialog on startup
    await requestNotificationPermissions();
  }

  /// Prompts the native Android OS & iOS system runtime permission dialog
  Future<bool> requestNotificationPermissions() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
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

  /// Triggers an immediate test notification to verify notification permissions & system delivery
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'emi_channel',
      'EMI Reminders',
      channelDescription: 'Smart notifications for loan EMI payment dues',
      importance: Importance.max,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      99999,
      '🔔 PayWise Test Notification',
      'Test successful! Smart EMI payment reminders are active and working on your device.',
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'emi_channel',
        'EMI Reminders',
        channelDescription: 'Smart notifications for loan EMI payment dues',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Schedules 5 smart notification reminders for an EMI payment:
  /// 1. 📅 Upcoming Date Specific Reminder (3 Days Before at 10:00 AM)
  /// 2. ⏰ "Due Tomorrow / Last Date" Reminder (1 Day Before at 7:00 PM)
  /// 3. 🚨 "Due Today" Reminder (Exact Due Date at 8:00 AM)
  /// 4. 🗓️ "Due This Monday" Reminder (Preceding Monday at 9:30 AM)
  /// 5. ⚠️ Overdue / Follow-Up Alert (1 Day After Due Date at 11:00 AM)
  Future<void> scheduleAll5EmiReminders({
    required String loanId,
    required String loanTitle,
    required double emiAmount,
    required int dueDayOfMonth,
  }) async {
    final now = DateTime.now();
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0).format(emiAmount);
    final baseHash = loanId.hashCode;

    // Determine target EMI Due Date for current or next month
    int targetYear = now.year;
    int targetMonth = now.month;

    int lastDayOfCurrMonth = DateTime(now.year, now.month + 1, 0).day;
    int safeDueDay = min(dueDayOfMonth, lastDayOfCurrMonth);

    DateTime targetDueDate = DateTime(targetYear, targetMonth, safeDueDay, 9, 0);
    if (targetDueDate.isBefore(now)) {
      // Advance to next month if target date for this month has already passed
      targetMonth += 1;
      if (targetMonth > 12) {
        targetMonth = 1;
        targetYear += 1;
      }
      int lastDayOfNextMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      safeDueDay = min(dueDayOfMonth, lastDayOfNextMonth);
      targetDueDate = DateTime(targetYear, targetMonth, safeDueDay, 9, 0);
    }

    final dueDateStr = DateFormat('MMM dd, yyyy').format(targetDueDate);

    // ── 1. UPCOMING DATE SPECIFIC REMINDER (3 Days Before at 10:00 AM) ──
    DateTime date1 = targetDueDate.subtract(const Duration(days: 3));
    if (date1.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        (baseHash * 31 + 1) & 0x7FFFFFFF,
        '📅 Payment Due Reminder: $dueDateStr',
        'Your EMI of $currency for $loanTitle is due on $dueDateStr (Day $dueDayOfMonth). Keep funds ready!',
        tz.TZDateTime.from(date1, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // ── 2. DUE TOMORROW / LAST DATE REMINDER (1 Day Before at 7:00 PM) ──
    DateTime date2 = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day - 1, 19, 0);
    if (date2.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        (baseHash * 31 + 2) & 0x7FFFFFFF,
        '⏰ Tomorrow is the Last Date for Payment!',
        'Tomorrow (${DateFormat('MMM dd').format(targetDueDate)}) is your EMI payment day for $loanTitle ($currency).',
        tz.TZDateTime.from(date2, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // ── 3. DUE TODAY REMINDER (Exact Due Day at 8:00 AM) ──
    DateTime date3 = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day, 8, 0);
    if (date3.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        (baseHash * 31 + 3) & 0x7FFFFFFF,
        '🚨 EMI Payment Due Today!',
        'Your EMI of $currency for $loanTitle is due today ($dueDateStr). Tap to record once paid!',
        tz.TZDateTime.from(date3, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // ── 4. 1-WEEK AHEAD WEEKDAY REMINDER (Exactly 7 Days Before at 9:30 AM) ──
    final weekdayName = DateFormat('EEEE').format(targetDueDate);
    DateTime date4 = targetDueDate.subtract(const Duration(days: 7));
    if (date4.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        (baseHash * 31 + 4) & 0x7FFFFFFF,
        '🗓️ Upcoming Payment Next $weekdayName!',
        'Your EMI of $currency for $loanTitle is due next $weekdayName ($dueDateStr). Plan your budget ahead!',
        tz.TZDateTime.from(date4, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // ── 5. OVERDUE / MISSED PAYMENT ALERT (1 Day After Due Date at 11:00 AM) ──
    DateTime date5 = DateTime(targetDueDate.year, targetDueDate.month, targetDueDate.day + 1, 11, 0);
    if (date5.isAfter(now)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        (baseHash * 31 + 5) & 0x7FFFFFFF,
        '⚠️ Missed Payment Alert: Day $dueDayOfMonth',
        'Your EMI of $currency for $loanTitle was due yesterday. Record your payment now if already paid!',
        tz.TZDateTime.from(date5, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Backward-compatible single reminder schedule method
  Future<void> scheduleEmiReminder(String loanId, String loanTitle, int dayOfMonth) async {
    await scheduleAll5EmiReminders(
      loanId: loanId,
      loanTitle: loanTitle,
      emiAmount: 0,
      dueDayOfMonth: dayOfMonth,
    );
  }

  /// Cancels all 5 notification reminders associated with a loan
  Future<void> cancelReminder(String loanId) async {
    final baseHash = loanId.hashCode;
    await flutterLocalNotificationsPlugin.cancel((baseHash * 31 + 1) & 0x7FFFFFFF);
    await flutterLocalNotificationsPlugin.cancel((baseHash * 31 + 2) & 0x7FFFFFFF);
    await flutterLocalNotificationsPlugin.cancel((baseHash * 31 + 3) & 0x7FFFFFFF);
    await flutterLocalNotificationsPlugin.cancel((baseHash * 31 + 4) & 0x7FFFFFFF);
    await flutterLocalNotificationsPlugin.cancel((baseHash * 31 + 5) & 0x7FFFFFFF);
    await flutterLocalNotificationsPlugin.cancel(baseHash);
  }
}
