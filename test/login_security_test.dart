import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywise/services/login_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginSecurityService & Brute-Force Defense Tests', () {
    late SharedPreferences prefs;
    late LoginSecurityService securityService;
    const testEmail = 'victim_user@gmail.com';
    const testIp = '192.168.1.100';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      securityService = LoginSecurityService(
        prefs: prefs,
        customIpResolver: () async => testIp,
      );
    });

    test('Sanitization produces clean, valid Firestore doc IDs and keys', () {
      expect(
        LoginSecurityService.sanitizeEmail('User.Name+Tag@Gmail.com'),
        'user.name_tag_gmail.com',
      );
      expect(
        LoginSecurityService.sanitizeIp('2001:0db8:85a3:0000:0000:8a2e:0370:7334'),
        '2001_0db8_85a3_0000_0000_8a2e_0370_7334',
      );
      expect(
        LoginSecurityService.sanitizeIp('192.168.1.1'),
        '192.168.1.1',
      );
    });

    test('Initial pre-login check allows login with full 5 attempts remaining', () async {
      final result = await securityService.checkPreLoginSecurity(testEmail);
      expect(result.status, SecurityStatus.allowed);
      expect(result.isAllowed, isTrue);
      expect(result.remainingAttempts, 5);
      expect(result.failedAttempts, 0);
      expect(result.ip, testIp);
    });

    test('Failed attempts decrement remaining attempts proportionally (1 to 4)', () async {
      // 1st failed attempt
      var res = await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      expect(res.status, SecurityStatus.allowed);
      expect(res.remainingAttempts, 4);
      expect(res.failedAttempts, 1);

      // 2nd failed attempt
      res = await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      expect(res.status, SecurityStatus.allowed);
      expect(res.remainingAttempts, 3);
      expect(res.failedAttempts, 2);

      // 3rd failed attempt
      res = await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      expect(res.status, SecurityStatus.allowed);
      expect(res.remainingAttempts, 2);
      expect(res.failedAttempts, 3);

      // 4th failed attempt
      res = await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      expect(res.status, SecurityStatus.allowed);
      expect(res.remainingAttempts, 1);
      expect(res.failedAttempts, 4);
    });

    test('5th failed attempt triggers Account Lockout with 15-minute cooldown', () async {
      // Record 4 failed attempts
      for (int i = 0; i < 4; i++) {
        await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      }

      // 5th attempt
      final res = await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      expect(res.status, SecurityStatus.accountLocked);
      expect(res.isAccountLocked, isTrue);
      expect(res.remainingAttempts, 0);
      expect(res.failedAttempts, 5);
      expect(res.lockedUntil, isNotNull);
      expect(res.remainingSeconds, greaterThan(800)); // around 900 seconds (15 mins)
      expect(res.formattedRemainingTime, contains('m'));

      // Subsequent pre-login check should immediately return accountLocked
      final preCheck = await securityService.checkPreLoginSecurity(testEmail);
      expect(preCheck.status, SecurityStatus.accountLocked);
      expect(preCheck.isAccountLocked, isTrue);
      expect(preCheck.remainingSeconds, greaterThan(0));
    });

    test('Successful login clears failed attempts counter', () async {
      // Fail 3 times
      for (int i = 0; i < 3; i++) {
        await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      }

      var check = await securityService.checkPreLoginSecurity(testEmail);
      expect(check.remainingAttempts, 2);

      // Successful login occurs
      await securityService.recordSuccessfulLogin(testEmail);

      check = await securityService.checkPreLoginSecurity(testEmail);
      expect(check.status, SecurityStatus.allowed);
      expect(check.remainingAttempts, 5);
      expect(check.failedAttempts, 0);
    });

    test('UnlockAccount explicitly unlocks a locked account and resets counter', () async {
      // Trigger lockout
      for (int i = 0; i < 5; i++) {
        await securityService.recordFailedAttempt(testEmail, reason: 'wrong-password');
      }

      var check = await securityService.checkPreLoginSecurity(testEmail);
      expect(check.isAccountLocked, isTrue);

      // User unlocks account
      await securityService.unlockAccount(testEmail);

      check = await securityService.checkPreLoginSecurity(testEmail);
      expect(check.status, SecurityStatus.allowed);
      expect(check.remainingAttempts, 5);
      expect(check.failedAttempts, 0);
    });

    test('Expired lockout automatically resets and allows login', () async {
      final sanitized = LoginSecurityService.sanitizeEmail(testEmail);
      // Simulate lockout that expired 1 minute ago
      final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
      await prefs.setInt('sec_email_lock_until_$sanitized', pastTime.millisecondsSinceEpoch);
      await prefs.setInt('sec_email_failures_$sanitized', 5);

      final check = await securityService.checkPreLoginSecurity(testEmail);
      expect(check.status, SecurityStatus.allowed);
      expect(check.isAllowed, isTrue);
      expect(check.remainingAttempts, 5);
    });

    test('Excessive IP attempts (1,000 tries) permanently blocks the IP', () async {
      final sanitizedIp = LoginSecurityService.sanitizeIp(testIp);
      // Simulate 999 attempts
      await prefs.setInt('sec_ip_failures_$sanitizedIp', 999);

      // 1,000th attempt
      final res = await securityService.recordFailedAttempt('another_user@gmail.com');
      expect(res.status, SecurityStatus.ipBlocked);
      expect(res.isIpBlocked, isTrue);
      expect(res.failedAttempts, 1000);

      // Any email from this IP is now rejected during pre-login check
      final preCheck = await securityService.checkPreLoginSecurity('innocent@gmail.com');
      expect(preCheck.status, SecurityStatus.ipBlocked);
      expect(preCheck.isIpBlocked, isTrue);
      expect(preCheck.message, contains('blocked'));
    });
  });
}
