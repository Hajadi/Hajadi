import 'dart:async';

/// What the app needs from an identity provider. Two implementations exist:
/// [FirebaseAuthService] for real builds and `DemoAuthService` for the bundled
/// sample-data mode, so the UI never branches on which backend is live.
abstract class AuthService {
  /// Emits the signed-in uid, or null after sign-out.
  Stream<String?> authStateChanges();

  String? get currentUid;

  Future<String> signInWithEmail(String email, String password);

  Future<String> signUpWithEmail(String email, String password);

  Future<void> sendPasswordReset(String email);

  Future<String> signInWithGoogle();

  Future<String> signInWithApple();

  /// Starts phone verification and returns the verification id used by
  /// [confirmPhoneCode]. On Android the SMS may be auto-resolved; callers
  /// should therefore also watch [authStateChanges].
  Future<String> startPhoneVerification(String phoneNumber);

  Future<String> confirmPhoneCode(String verificationId, String smsCode);

  /// Fresh ID token for authenticating calls to our own Cloud Functions.
  /// Null when nobody is signed in.
  Future<String?> idToken();

  Future<void> signOut();

  Future<void> deleteAccount();
}

/// Thrown for every auth failure so view-models can show one localized message
/// instead of leaking provider-specific codes.
class AuthException implements Exception {
  const AuthException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'AuthException($code, $message)';
}
