import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paywise/config/env_config.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    // 2. Delete all loans and sub-collection transactions
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

    // 4. Delete Firebase Auth account
    if (user != null && user.uid == userId) {
      await user.delete();
    }
  }
}
