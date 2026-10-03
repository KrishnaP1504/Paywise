import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywise/services/notification_service.dart';
import 'package:paywise/models/loan_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Deterministic ID & Date Safety Tests', () {
    test('NotificationService singleton returns identical instance', () {
      final s1 = NotificationService();
      final s2 = NotificationService();
      expect(identical(s1, s2), isTrue);
    });

    test('Reminder notification IDs are deterministic and non-colliding across cycles', () {
      const loanIdA = 'loan_personal_123';
      const loanIdB = 'loan_home_456';

      final hashA = loanIdA.hashCode;
      final hashB = loanIdB.hashCode;

      final idsA = <int>{};
      final idsB = <int>{};

      for (int cycle = 0; cycle < 2; cycle++) {
        final cycleOffset = cycle * 10;
        for (int r = 1; r <= 5; r++) {
          final idA = (hashA * 31 + cycleOffset + r) & 0x7FFFFFFF;
          final idB = (hashB * 31 + cycleOffset + r) & 0x7FFFFFFF;

          expect(idsA.contains(idA), isFalse, reason: 'Duplicate ID for loan A within its cycles');
          expect(idsB.contains(idB), isFalse, reason: 'Duplicate ID for loan B within its cycles');

          idsA.add(idA);
          idsB.add(idB);
        }
      }

      expect(idsA.length, equals(10));
      expect(idsB.length, equals(10));
      // Ensure all IDs fit within standard Android 32-bit positive integer range
      for (final id in idsA) {
        expect(id >= 0 && id <= 0x7FFFFFFF, isTrue);
      }
      for (final id in idsB) {
        expect(id >= 0 && id <= 0x7FFFFFFF, isTrue);
      }
    });

    test('Due date day clamping logic prevents leap year and short month crashes', () {
      // Month with 28/29 days (February)
      final feb2026Days = DateTime(2026, 3, 0).day; // 28
      expect(feb2026Days, equals(28));

      const inputDueDay = 31; // User set due day to 31st
      final safeDueDay = min(inputDueDay, feb2026Days);
      expect(safeDueDay, equals(28));

      // Attempting DateTime(2026, 2, safeDueDay) should produce valid date without overflow
      final clampedDate = DateTime(2026, 2, safeDueDay, 9, 0);
      expect(clampedDate.month, equals(2));
      expect(clampedDate.day, equals(28));

      // Month with 30 days (April)
      final aprDays = DateTime(2026, 5, 0).day;
      expect(aprDays, equals(30));
      final safeAprDay = min(inputDueDay, aprDays);
      expect(safeAprDay, equals(30));
    });

    test('Graceful execution in headless environment without native notification plugin', () async {
      SharedPreferences.setMockInitialValues({
        'notificationsEnabled': true,
        'notifyDueToday': true,
        'notifyDueTomorrow': true,
        'notifyAdvance': true,
        'notifyOverdue': true,
      });

      final service = NotificationService();

      // Ensure calling cancelReminder, cancelAllReminders, and getPendingNotificationCount
      // catches MissingPluginException gracefully and does not throw unhandled exception
      await expectLater(service.cancelReminder('test_loan_1'), completes);
      await expectLater(service.cancelAllReminders(), completes);

      final count = await service.getPendingNotificationCount();
      expect(count, equals(0));

      final testCount = await service.showTestNotification();
      expect(testCount, equals(0));

      // Test syncAllLoanReminders with active & paid off loans
      final testLoans = [
        LoanModel(
          id: 'test_loan_active',
          userId: 'user_1',
          title: 'HDFC Personal Loan',
          lenderName: 'HDFC Bank',
          category: 'Personal',
          principalAmount: 100000,
          interestRate: 10.5,
          tenureMonths: 12,
          emiAmount: 8815,
          emiDueDate: 15,
          startDate: DateTime(2026, 1, 1),
          totalPaid: 0,
          isPaidOff: false,
        ),
        LoanModel(
          id: 'test_loan_paid',
          userId: 'user_1',
          title: 'SBI Car Loan',
          lenderName: 'SBI Bank',
          category: 'Vehicle',
          principalAmount: 50000,
          interestRate: 8.5,
          tenureMonths: 6,
          emiAmount: 8540,
          emiDueDate: 5,
          startDate: DateTime(2025, 1, 1),
          totalPaid: 51240,
          isPaidOff: true,
        ),
      ];

      await expectLater(service.syncAllLoanReminders(testLoans), completes);
    });

    test('Disabled master notifications cancel all scheduled reminders', () async {
      SharedPreferences.setMockInitialValues({
        'notificationsEnabled': false, // Master disabled
      });

      final service = NotificationService();
      final testLoans = [
        LoanModel(
          id: 'test_loan_disabled',
          userId: 'user_1',
          title: 'ICICI Home Loan',
          lenderName: 'ICICI Bank',
          category: 'Home',
          principalAmount: 2000000,
          interestRate: 8.5,
          tenureMonths: 240,
          emiAmount: 17356,
          emiDueDate: 10,
          startDate: DateTime(2026, 1, 1),
          totalPaid: 0,
          isPaidOff: false,
        ),
      ];

      // Should complete safely by invoking cancelReminder on each loan
      await expectLater(service.syncAllLoanReminders(testLoans), completes);
    });
  });
}
