import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status of the pre-login or post-attempt security check
enum SecurityStatus {
  allowed,
  accountLocked,
  ipBlocked,
}

/// Represents the evaluated security outcome for an account and IP
class SecurityCheckResult {
  final SecurityStatus status;
  final int remainingAttempts;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final int remainingSeconds;
  final String? ip;
  final String? message;

  const SecurityCheckResult.allowed({
    this.remainingAttempts = 5,
    this.failedAttempts = 0,
    this.ip,
  })  : status = SecurityStatus.allowed,
        lockedUntil = null,
        remainingSeconds = 0,
        message = null;

  const SecurityCheckResult.accountLocked({
    required this.lockedUntil,
    required this.remainingSeconds,
    this.failedAttempts = 5,
    this.ip,
    this.message,
  })  : status = SecurityStatus.accountLocked,
        remainingAttempts = 0;

  const SecurityCheckResult.ipBlocked({
    required this.ip,
    this.failedAttempts = 1000,
    this.message,
  })  : status = SecurityStatus.ipBlocked,
        remainingAttempts = 0,
        lockedUntil = null,
        remainingSeconds = 0;

  bool get isAllowed => status == SecurityStatus.allowed;
  bool get isAccountLocked => status == SecurityStatus.accountLocked;
  bool get isIpBlocked => status == SecurityStatus.ipBlocked;

  /// Human-readable remaining cooldown string (e.g. "14m 32s" or "45s")
  String get formattedRemainingTime {
    if (remainingSeconds <= 0) return "0s";
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    if (minutes > 0) {
      return "${minutes}m ${seconds.toString().padLeft(2, '0')}s";
    }
    return "${seconds}s";
  }
}

/// Production-Grade Brute-Force Login Defense Service
/// Handles 5-attempt account lockouts with 15-minute cooldowns,
/// IP logging, and 1,000-attempt IP address blocking.
class LoginSecurityService {
  static const int maxFailedAttemptsPerAccount = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int maxFailedAttemptsPerIp = 1000;

  // SharedPreferences Keys
  static const String _prefPrefixEmailFailures = 'sec_email_failures_';
  static const String _prefPrefixEmailLockUntil = 'sec_email_lock_until_';
  static const String _prefPrefixIpFailures = 'sec_ip_failures_';
  static const String _prefPrefixIpBlocked = 'sec_ip_blocked_';

  // Firestore Collections
  static const String _accountSecurityCollection = 'account_security';
  static const String _ipSecurityCollection = 'ip_security';
  static const String _auditLogsCollection = 'security_audit_logs';

  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;
  final SharedPreferences? _injectedPrefs;
  final Future<String> Function()? _customIpResolver;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // Cached IP to prevent spamming external IP check endpoints
  static String? _cachedPublicIp;
  static DateTime? _lastIpLookup;

  LoginSecurityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SharedPreferences? prefs,
    Future<String> Function()? customIpResolver,
  })  : _customFirestore = firestore,
        _customAuth = auth,
        _injectedPrefs = prefs,
        _customIpResolver = customIpResolver;

  Future<SharedPreferences> _getPrefs() async {
    return _injectedPrefs ?? await SharedPreferences.getInstance();
  }


  /// Sanitizes an email into a Firestore-safe and SharedPreferences-safe document ID
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
  }

  /// Sanitizes an IP address into a Firestore-safe and SharedPreferences-safe document ID
  static String sanitizeIp(String ip) {
    return ip.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
  }

  /// Resolves the device's public WAN IP address with timeout and fallback
  Future<String> getClientIp() async {
    if (_customIpResolver != null) {
      return await _customIpResolver!();
    }

    if (kIsWeb) {
      return 'web_client';
    }

    // Return cached IP if obtained within the last 10 minutes
    if (_cachedPublicIp != null && _lastIpLookup != null &&
        DateTime.now().difference(_lastIpLookup!).inMinutes < 10) {
      return _cachedPublicIp!;
    }

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client
          .getUrl(Uri.parse('https://api.ipify.org'))
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final ip = body.trim();
        if (ip.isNotEmpty && ip.length <= 45) {
          _cachedPublicIp = ip;
          _lastIpLookup = DateTime.now();
          return ip;
        }
      }
    } catch (_) {
      // Secondary fallback endpoint
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
        final request = await client
            .getUrl(Uri.parse('https://icanhazip.com'))
            .timeout(const Duration(seconds: 2));
        final response = await request.close().timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final ip = body.trim();
          if (ip.isNotEmpty && ip.length <= 45) {
            _cachedPublicIp = ip;
            _lastIpLookup = DateTime.now();
            return ip;
          }
        }
      } catch (_) {}
    }

    return _cachedPublicIp ?? 'unknown_ip';
  }

  /// Validates security constraints before sending credentials to Firebase Auth
  Future<SecurityCheckResult> checkPreLoginSecurity(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    final sanitizedEmail = sanitizeEmail(email);
    final ip = await getClientIp();
    final sanitizedIp = sanitizeIp(ip);
    final prefs = await _getPrefs();

    // ── 1. CHECK LOCAL IP BLOCK ──
    final isLocalIpBlocked = prefs.getBool('$_prefPrefixIpBlocked$sanitizedIp') ?? false;
    if (isLocalIpBlocked) {
      return SecurityCheckResult.ipBlocked(
        ip: ip,
        message: "This IP address has been blocked due to excessive login attempts (1,000+ attempts).",
      );
    }

    // ── 2. CHECK LOCAL ACCOUNT LOCKOUT ──
    final localLockUntilEpoch = prefs.getInt('$_prefPrefixEmailLockUntil$sanitizedEmail');
    if (localLockUntilEpoch != null) {
      final lockedUntil = DateTime.fromMillisecondsSinceEpoch(localLockUntilEpoch);
      if (DateTime.now().isBefore(lockedUntil)) {
        final remainingSeconds = lockedUntil.difference(DateTime.now()).inSeconds;
        return SecurityCheckResult.accountLocked(
          lockedUntil: lockedUntil,
          remainingSeconds: remainingSeconds > 0 ? remainingSeconds : 1,
          ip: ip,
          message: "Account temporarily locked. Please verify your email or wait for cooldown.",
        );
      } else {
        // Cooldown period has elapsed: clear local lock
        await prefs.remove('$_prefPrefixEmailLockUntil$sanitizedEmail');
        await prefs.setInt('$_prefPrefixEmailFailures$sanitizedEmail', 0);
      }
    }

    // ── 3. SYNC WITH CLOUD FIRESTORE (WITH 2.5S TIMEOUT) ──
    final fs = _firestore;
    if (fs != null) {
      try {
        // Check Cloud IP Security
        final ipDocSnap = await fs
            .collection(_ipSecurityCollection)
            .doc(sanitizedIp)
            .get()
            .timeout(const Duration(milliseconds: 2500));

      if (ipDocSnap.exists) {
        final ipData = ipDocSnap.data() ?? {};
        final isCloudBlocked = ipData['isBlocked'] == true;
        final ipFailures = (ipData['failedAttempts'] as num?)?.toInt() ?? 0;

        if (isCloudBlocked || ipFailures >= maxFailedAttemptsPerIp) {
          await prefs.setBool('$_prefPrefixIpBlocked$sanitizedIp', true);
          return SecurityCheckResult.ipBlocked(
            ip: ip,
            failedAttempts: ipFailures,
            message: "This IP address has been blocked due to excessive login attempts (1,000+ attempts).",
          );
        }
      }

      // Check Cloud Account Security
      final accDocSnap = await fs
          .collection(_accountSecurityCollection)
          .doc(sanitizedEmail)
          .get()
          .timeout(const Duration(milliseconds: 2500));

      if (accDocSnap.exists) {
        final accData = accDocSnap.data() ?? {};
        final rawLockedUntil = accData['lockedUntil'];
        DateTime? cloudLockedUntil;

        if (rawLockedUntil is Timestamp) {
          cloudLockedUntil = rawLockedUntil.toDate();
        } else if (rawLockedUntil is String) {
          cloudLockedUntil = DateTime.tryParse(rawLockedUntil);
        }

        if (cloudLockedUntil != null) {
          if (DateTime.now().isBefore(cloudLockedUntil)) {
            // Save to local cache for instant enforcement
            await prefs.setInt(
              '$_prefPrefixEmailLockUntil$sanitizedEmail',
              cloudLockedUntil.millisecondsSinceEpoch,
            );
            final remainingSeconds = cloudLockedUntil.difference(DateTime.now()).inSeconds;
            return SecurityCheckResult.accountLocked(
              lockedUntil: cloudLockedUntil,
              remainingSeconds: remainingSeconds > 0 ? remainingSeconds : 1,
              failedAttempts: (accData['failedAttempts'] as num?)?.toInt() ?? 5,
              ip: ip,
              message: "Account temporarily locked. Please verify your email or wait for cooldown.",
            );
          } else {
            // Cloud lockout expired: reset cloud & local
            await unlockAccount(email);
          }
        }

          final cloudFailures = (accData['failedAttempts'] as num?)?.toInt() ?? 0;
          final remaining = (maxFailedAttemptsPerAccount - cloudFailures).clamp(0, maxFailedAttemptsPerAccount);
          return SecurityCheckResult.allowed(
            remainingAttempts: remaining,
            failedAttempts: cloudFailures,
            ip: ip,
          );
        }
      } catch (e) {
        debugPrint("Notice: Firestore pre-login security sync skipped/offline: $e");
      }
    }


    // Fallback: Local count if Firestore was unreachable
    final localFailures = prefs.getInt('$_prefPrefixEmailFailures$sanitizedEmail') ?? 0;
    final remaining = (maxFailedAttemptsPerAccount - localFailures).clamp(0, maxFailedAttemptsPerAccount);
    return SecurityCheckResult.allowed(
      remainingAttempts: remaining,
      failedAttempts: localFailures,
      ip: ip,
    );
  }

  /// Records a failed authentication attempt for both Account and IP
  Future<SecurityCheckResult> recordFailedAttempt(
    String rawEmail, {
    String? reason,
  }) async {
    final email = rawEmail.trim().toLowerCase();
    final sanitizedEmail = sanitizeEmail(email);
    final ip = await getClientIp();
    final sanitizedIp = sanitizeIp(ip);
    final prefs = await _getPrefs();

    // ── 1. INCREMENT LOCAL COUNTERS ──
    final currentEmailFailures = (prefs.getInt('$_prefPrefixEmailFailures$sanitizedEmail') ?? 0) + 1;
    await prefs.setInt('$_prefPrefixEmailFailures$sanitizedEmail', currentEmailFailures);

    final currentIpFailures = (prefs.getInt('$_prefPrefixIpFailures$sanitizedIp') ?? 0) + 1;
    await prefs.setInt('$_prefPrefixIpFailures$sanitizedIp', currentIpFailures);

    DateTime? newLockedUntil;
    bool isAccountNowLocked = false;
    bool isIpNowBlocked = false;

    // Check account lockout threshold (5 failed attempts)
    if (currentEmailFailures >= maxFailedAttemptsPerAccount) {
      newLockedUntil = DateTime.now().add(lockoutDuration);
      await prefs.setInt(
        '$_prefPrefixEmailLockUntil$sanitizedEmail',
        newLockedUntil.millisecondsSinceEpoch,
      );
      isAccountNowLocked = true;
    }

    // Check IP block threshold (1,000 failed attempts)
    if (currentIpFailures >= maxFailedAttemptsPerIp) {
      await prefs.setBool('$_prefPrefixIpBlocked$sanitizedIp', true);
      isIpNowBlocked = true;
    }

    // ── 2. ASYNC UPDATE CLOUD FIRESTORE ──
    final fs = _firestore;
    if (fs != null) {
      try {
        final batch = fs.batch();

        // Account Security Document
        final accDocRef = fs.collection(_accountSecurityCollection).doc(sanitizedEmail);
      final Map<String, dynamic> accUpdate = {
        'email': email,
        'failedAttempts': FieldValue.increment(1),
        'lastFailedAt': FieldValue.serverTimestamp(),
        'lastFailedIp': ip,
      };
      if (isAccountNowLocked && newLockedUntil != null) {
        accUpdate['lockedUntil'] = Timestamp.fromDate(newLockedUntil);
      }
      batch.set(accDocRef, accUpdate, SetOptions(merge: true));

        // IP Security Document
        final ipDocRef = fs.collection(_ipSecurityCollection).doc(sanitizedIp);
        batch.set(
          ipDocRef,
          {
            'ip': ip,
            'failedAttempts': FieldValue.increment(1),
            'lastFailedAt': FieldValue.serverTimestamp(),
            'isBlocked': isIpNowBlocked,
          },
          SetOptions(merge: true),
        );

        // Security Audit Log Document
        final auditDocRef = fs.collection(_auditLogsCollection).doc();
      batch.set(auditDocRef, {
        'email': email,
        'ip': ip,
        'reason': reason ?? 'invalid_credentials',
        'type': 'failed_login_attempt',
        'attemptNumber': currentEmailFailures,
        'ipAttemptNumber': currentIpFailures,
        'isLocked': isAccountNowLocked,
        'isBlocked': isIpNowBlocked,
        'timestamp': FieldValue.serverTimestamp(),
      });

        await batch.commit().timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint("Notice: Cloud security record failed attempt failed: $e");
      }
    }

    // Return the resulting state
    if (isIpNowBlocked) {
      return SecurityCheckResult.ipBlocked(
        ip: ip,
        failedAttempts: currentIpFailures,
        message: "This IP address has been blocked due to excessive login attempts (1,000+ attempts).",
      );
    }

    if (isAccountNowLocked && newLockedUntil != null) {
      return SecurityCheckResult.accountLocked(
        lockedUntil: newLockedUntil,
        remainingSeconds: lockoutDuration.inSeconds,
        failedAttempts: currentEmailFailures,
        ip: ip,
        message: "Account locked after 5 failed attempts. Please verify via email or wait 15 minutes.",
      );
    }

    final remaining = (maxFailedAttemptsPerAccount - currentEmailFailures).clamp(0, maxFailedAttemptsPerAccount);
    return SecurityCheckResult.allowed(
      remainingAttempts: remaining,
      failedAttempts: currentEmailFailures,
      ip: ip,
    );
  }

  /// Records a successful authentication, resetting failed attempts and lockouts
  Future<void> recordSuccessfulLogin(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    final sanitizedEmail = sanitizeEmail(email);
    final ip = await getClientIp();
    final prefs = await _getPrefs();

    // Reset local account tracking
    await prefs.setInt('$_prefPrefixEmailFailures$sanitizedEmail', 0);
    await prefs.remove('$_prefPrefixEmailLockUntil$sanitizedEmail');

    // Update Cloud Firestore
    final fs = _firestore;
    if (fs != null) {
      try {
        final accDocRef = fs.collection(_accountSecurityCollection).doc(sanitizedEmail);
        await accDocRef.set({
          'email': email,
          'failedAttempts': 0,
          'lockedUntil': null,
          'lastSuccessfulLogin': FieldValue.serverTimestamp(),
          'lastLoginIp': ip,
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));

        // Append Audit Log
        await fs.collection(_auditLogsCollection).add({
          'email': email,
          'ip': ip,
          'type': 'successful_login',
          'timestamp': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("Notice: Cloud successful login recording error: $e");
      }
    }
  }

  /// Dispatches an account unlock / password reset email to verify account ownership
  Future<void> sendUnlockEmail(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    final ip = await getClientIp();

    final auth = _auth;
    if (auth != null) {
      await auth.sendPasswordResetEmail(email: email);
    }

    final fs = _firestore;
    if (fs != null) {
      try {
        await fs.collection(_auditLogsCollection).add({
          'email': email,
          'ip': ip,
          'type': 'unlock_email_dispatched',
          'timestamp': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  /// Unlocks an account, resetting lockout timestamps and failure counters
  Future<void> unlockAccount(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    final sanitizedEmail = sanitizeEmail(email);
    final prefs = await _getPrefs();

    await prefs.setInt('$_prefPrefixEmailFailures$sanitizedEmail', 0);
    await prefs.remove('$_prefPrefixEmailLockUntil$sanitizedEmail');

    final fs = _firestore;
    if (fs != null) {
      try {
        final accDocRef = fs.collection(_accountSecurityCollection).doc(sanitizedEmail);
        await accDocRef.set({
          'failedAttempts': 0,
          'lockedUntil': null,
          'unlockedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }
}
