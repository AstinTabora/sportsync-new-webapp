import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sportsync/features/profile/data/user_profile_repository.dart';

/// Thrown by [AuthRepository] with a message safe to show the user.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Email/password auth that upgrades the anonymous session in place.
///
/// Everyone is signed in anonymously at boot, so booking/paying always works.
/// Signing up *links* the email credential to that anonymous user
/// ([User.linkWithCredential]) so existing data keyed by the anon uid carries
/// over. Signing out drops back to a fresh anonymous session so payments keep
/// working.
class AuthRepository {
  AuthRepository(this._auth, this._profiles);

  final FirebaseAuth _auth;
  final UserProfileRepository _profiles;

  /// Create an account, preferring to link onto the current anonymous user.
  /// Falls back to a plain sign-in when the email already exists.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    final current = _auth.currentUser;
    try {
      if (current != null && current.isAnonymous) {
        await current.linkWithCredential(cred);
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        // Account exists — sign into it instead of creating a duplicate.
        await _signIn(email, password);
        await _persistProfile(name: name, email: email);
        return;
      }
      throw AuthException(_friendly(e));
    }
    await _persistProfile(name: name, email: email);
  }

  /// Sign in to an existing account.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _signIn(email, password);
    await _persistProfile(email: email);
  }

  /// Sign in with Google, preferring to link onto the current anonymous user.
  /// Returns false if the user cancelled the Google chooser.
  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return false; // cancelled
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _linkOrSignIn(cred, name: googleUser.displayName, email: googleUser.email);
    return true;
  }

  /// Sign in with Apple, preferring to link onto the current anonymous user.
  /// Returns false if the user cancelled the Apple sheet. Apple only returns
  /// the name on the *first* authorization.
  Future<bool> signInWithApple() async {
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final name = [apple.givenName, apple.familyName]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      await _linkOrSignIn(oauth, name: name.isEmpty ? null : name, email: apple.email);
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      throw AuthException('Apple sign-in failed. Please try again.');
    }
  }

  /// Link an OAuth credential onto the anonymous user (or sign in with it).
  /// Falls back to a plain credential sign-in when it already belongs to an
  /// existing account.
  Future<void> _linkOrSignIn(
    AuthCredential cred, {
    String? name,
    String? email,
  }) async {
    final current = _auth.currentUser;
    try {
      if (current != null && current.isAnonymous) {
        await current.linkWithCredential(cred);
      } else {
        await _auth.signInWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        await _auth.signInWithCredential(cred);
      } else {
        throw AuthException(_friendly(e));
      }
    }
    await _persistProfile(
      name: name,
      email: _auth.currentUser?.email ?? email ?? '',
    );
  }

  /// Sign out, then re-establish an anonymous session so the user can still
  /// browse and pay without an account. Hardened so the re-anon always runs —
  /// leaving `currentUser == null` breaks the payment sheet.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore — we still want to ensure an anonymous session below.
    }
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Send a password-reset email for an existing account.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  /// Re-authenticate the current email user — required before sensitive ops
  /// (change password, delete account) when the last sign-in is stale.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw AuthException('Please sign in again to continue.');
    }
    final cred = EmailAuthProvider.credential(email: email, password: password);
    try {
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  /// Change the signed-in user's password (re-auth first).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await reauthenticate(currentPassword);
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  /// Permanently delete the account + profile doc, then drop back to a fresh
  /// anonymous session so browsing/paying keeps working.
  Future<void> deleteAccount(String password) async {
    await reauthenticate(password);
    final user = _auth.currentUser!;
    try {
      await _profiles.delete(user.uid);
    } catch (_) {
      // Non-fatal — proceed with account deletion regardless.
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  /// Send a verification email to the current (unverified) user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  /// Refresh the cached user — e.g. to pick up `emailVerified` after the user
  /// taps the link in their inbox.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> _signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  Future<void> _persistProfile({String? name, required String email}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _profiles.merge(uid, displayName: name, email: email);
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please re-enter your password to continue.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.watch(userProfileRepositoryProvider),
  );
});
