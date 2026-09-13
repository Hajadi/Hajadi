import 'dart:async';

import 'auth_service.dart';
import 'preferences_service.dart';

/// Offline stand-in for Firebase Auth used by demo mode.
///
/// Any password of four characters or more is accepted for the seeded demo
/// accounts, and the OTP is always `123456` — documented in the README so a
/// reviewer can walk the whole app without provisioning a backend.
class DemoAuthService implements AuthService {
  DemoAuthService(this._prefs) {
    _uid = _prefs.demoUid;
    // Replay the restored session to whoever listens first.
    scheduleMicrotask(() => _controller.add(_uid));
  }

  final PreferencesService _prefs;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  String? _uid;

  static const String demoOtp = '123456';

  static const Map<String, String> knownAccounts = <String, String>{
    'customer@demo.ht': 'demo_customer',
    'worker@demo.ht': 'demo_worker',
    'admin@demo.ht': 'demo_admin',
  };

  @override
  Stream<String?> authStateChanges() async* {
    yield _uid;
    yield* _controller.stream;
  }

  @override
  String? get currentUid => _uid;

  Future<String> _signIn(String uid) async {
    _uid = uid;
    await _prefs.setDemoUid(uid);
    _controller.add(uid);
    return uid;
  }

  @override
  Future<String> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (password.length < 4) {
      throw const AuthException('wrong-password');
    }
    final String key = email.trim().toLowerCase();
    return _signIn(knownAccounts[key] ?? 'demo_customer');
  }

  @override
  Future<String> signUpWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (password.length < 8) {
      throw const AuthException('weak-password');
    }
    final String key = email.trim().toLowerCase();
    return _signIn(
      knownAccounts[key] ??
          'demo_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<String> signInWithGoogle() async =>
      _signIn(knownAccounts['customer@demo.ht']!);

  @override
  Future<String> signInWithApple() async =>
      _signIn(knownAccounts['customer@demo.ht']!);

  @override
  Future<String> startPhoneVerification(String phoneNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'demo-verification-id';
  }

  @override
  Future<String> confirmPhoneCode(String verificationId, String smsCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (smsCode.trim() != demoOtp) {
      throw const AuthException('invalid-verification-code');
    }
    return _signIn(_uid ?? 'demo_customer');
  }

  @override
  Future<String?> idToken() async =>
      _uid == null ? null : 'demo-id-token-$_uid';

  @override
  Future<void> signOut() async {
    _uid = null;
    await _prefs.setDemoUid(null);
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() => signOut();
}
