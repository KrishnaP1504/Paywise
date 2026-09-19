import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:paywise/config/env_config.dart';

class AuthService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Login with Email Only
  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(), 
      password: password
    );
    return credential.user;
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: EnvConfig.googleServerClientId.isNotEmpty ? EnvConfig.googleServerClientId : null,
    );
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // User canceled the sign-in prompt
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign out of previous Firebase Auth session to prevent any session bleeding
    await _auth.signOut();

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? googleUser.displayName ?? 'Google User',
        'email': user.email ?? googleUser.email,
        'photoUrl': user.photoURL ?? googleUser.photoUrl,
        'lastLogin': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    return user;
  }

  // Register with Name, Email & Password
  Future<User?> register(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), 
      password: password
    );
    
    // Save basic user data & update display name
    if (credential.user != null) {
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await credential.user!.updateDisplayName(trimmedName);
      }
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': trimmedName,
        'email': email.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    return credential.user;
  }

  // Update Display Name
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      final trimmedName = newName.trim();
      await user.updateDisplayName(trimmedName);
      await _firestore.collection('users').doc(user.uid).set({
        'name': trimmedName,
      }, SetOptions(merge: true));
    }
  }

  /// Fetch stored profile data (firstName, lastName, username, birthdate, etc.)
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
    return {};
  }

  /// Update user full profile details
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    DateTime? birthdate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final fullName = [trimmedFirst, trimmedLast].where((s) => s.isNotEmpty).join(' ');
    final cleanUsername = username.trim().replaceAll('@', '');

    // 1. Update display name in Firebase Auth
    if (fullName.isNotEmpty) {
      await user.updateDisplayName(fullName);
    }

    // 2. Update email in Firebase Auth if changed
    final trimmedEmail = email.trim();
    bool emailVerificationSent = false;
    if (trimmedEmail.isNotEmpty && trimmedEmail.toLowerCase() != (user.email ?? '').toLowerCase()) {
      try {
        await user.verifyBeforeUpdateEmail(trimmedEmail);
        emailVerificationSent = true;
      } catch (e) {
        debugPrint("verifyBeforeUpdateEmail error: $e");
      }
    }

    // 3. Save to Firestore (preserve verified email in Firestore until verified)
    final data = <String, dynamic>{
      'name': fullName,
      'firstName': trimmedFirst,
      'lastName': trimmedLast,
      'username': cleanUsername,
      'email': emailVerificationSent ? (user.email ?? trimmedEmail) : trimmedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (emailVerificationSent) {
      data['pendingEmail'] = trimmedEmail;
    }
    if (birthdate != null) {
      data['birthdate'] = birthdate.toIso8601String();
    }

    await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
  }

  // ── ACCOUNT DELETION & 7-DAY RECOVERY SYSTEM ──

  /// Schedule deletion in 7 days
  Future<void> scheduleAccountDeletion(String userId) async {
    final scheduledDate = DateTime.now().add(const Duration(days: 7));
    await _firestore.collection('users').doc(userId).set({
      'deletionScheduled': true,
      'deletionScheduledAt': FieldValue.serverTimestamp(),
      'scheduledDeletionDate': Timestamp.fromDate(scheduledDate),
    }, SetOptions(merge: true));
  }

  /// Cancel scheduled deletion
  Future<void> cancelAccountDeletion(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'deletionScheduled': false,
      'deletionScheduledAt': FieldValue.delete(),
      'scheduledDeletionDate': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Check deletion status
  Future<Map<String, dynamic>> checkDeletionStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return {'deletionScheduled': false};

      final data = doc.data() ?? {};
      final isScheduled = data['deletionScheduled'] == true;
      final Timestamp? scheduledTs = data['scheduledDeletionDate'] as Timestamp?;

      if (isScheduled && scheduledTs != null) {
        final scheduledDate = scheduledTs.toDate();
        final isExpired = DateTime.now().isAfter(scheduledDate);
        return {
          'deletionScheduled': true,
          'scheduledDate': scheduledDate,
          'isExpired': isExpired,
        };
      }
    } catch (_) {}
    return {'deletionScheduled': false};
  }

  /// Re-authenticate user with password
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Re-authenticate user with Google Sign-In
  Future<void> reauthenticateWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: EnvConfig.googleServerClientId.isNotEmpty ? EnvConfig.googleServerClientId : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception("Google authentication was cancelled.");
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final user = _auth.currentUser;
    if (user != null) {
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Purge all user data and delete Firebase Auth user account permanently
  Future<void> purgeUserDataAndAccount(String userId, {String? password}) async {
    final user = _auth.currentUser;

    // 1. Re-authenticate if password is provided (required by Firebase Auth for account deletion)
    if (password != null && password.isNotEmpty) {
      await reauthenticateWithPassword(password);
    }

    // 2. Delete all loans and sub-collection transactions in Firestore
    try {
      final loansSnap = await _firestore
          .collection('loans')
          .where('userId', isEqualTo: userId)
          .get();

      for (final loanDoc in loansSnap.docs) {
        final txSnap = await loanDoc.reference.collection('transactions').get();
        for (final txDoc in txSnap.docs) {
          await txDoc.reference.delete();
        }
        await loanDoc.reference.delete();
      }

      // 3. Delete user doc
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint("Error purging user data from Firestore: $e");
      rethrow;
    }

    // 4. Delete Firebase Auth account
    if (user != null && user.uid == userId) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        debugPrint("Firebase Auth account deletion notice: ${e.code}");
        if (e.code == 'requires-recent-login') {
          // Stale session token: ensure user is logged out immediately since data was erased
          await _auth.signOut();
        } else {
          rethrow;
        }
      } catch (e) {
        debugPrint("Error deleting Auth user: $e");
        await _auth.signOut();
      }
    }
  }

  /// Centralized sign-out from both Google Sign-In and Firebase Auth
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: EnvConfig.googleServerClientId.isNotEmpty ? EnvConfig.googleServerClientId : null,
      );
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint("Google signOut notice: $e");
    }
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("FirebaseAuth signOut notice: $e");
    }
  }
}
