import 'dart:async';

import '../core/utils/validators.dart';
import '../models/app_user.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';
import 'session_view_model.dart';

enum AuthMode { login, signup }

/// Drives the login / sign-up / OTP screens. Validation returns catalog keys
/// so the same model serves all three languages.
class AuthViewModel extends BaseViewModel {
  AuthViewModel(this._services, this._session);

  final Services _services;
  final SessionViewModel _session;

  AuthMode _mode = AuthMode.login;
  UserRole _role = UserRole.customer;
  String? _verificationId;
  String? _pendingPhone;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  AuthMode get mode => _mode;
  UserRole get role => _role;
  String? get pendingPhone => _pendingPhone;
  bool get awaitingCode => _verificationId != null;
  int get resendSeconds => _resendSeconds;
  bool get canResend => _resendSeconds == 0;

  void setMode(AuthMode mode) {
    _mode = mode;
    clearError();
  }

  void setRole(UserRole role) {
    _role = role;
    safeNotify();
  }

  Future<String?> signInWithEmail(String email, String password) async {
    final String? invalid = Validators.email(email) ?? Validators.password(password);
    if (invalid != null) {
      setError(invalid);
      return null;
    }
    return _run(() => _services.auth.signInWithEmail(email, password));
  }

  /// Creates the account *and* its profile document, so the app never has a
  /// signed-in user without a row in `users/`.
  Future<String?> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
    String? departmentId,
    String? city,
  }) async {
    final String? invalid = Validators.name(fullName) ??
        Validators.email(email) ??
        Validators.password(password) ??
        Validators.match(password, confirmPassword);
    if (invalid != null) {
      setError(invalid);
      return null;
    }
    final String? uid =
        await _run(() => _services.auth.signUpWithEmail(email, password));
    if (uid == null) {
      return null;
    }
    await _session.createProfile(
      uid: uid,
      fullName: fullName.trim(),
      role: _role,
      email: email.trim(),
      phone: phone,
      departmentId: departmentId,
      city: city,
    );
    return uid;
  }

  Future<void> sendPasswordReset(String email) async {
    final String? invalid = Validators.email(email);
    if (invalid != null) {
      setError(invalid);
      return;
    }
    await _run(() async {
      await _services.auth.sendPasswordReset(email);
      return '';
    });
  }

  Future<String?> signInWithGoogle() =>
      _runFederated(_services.auth.signInWithGoogle);

  Future<String?> signInWithApple() =>
      _runFederated(_services.auth.signInWithApple);

  /// Federated sign-in may be a first visit: create the profile when the
  /// account has no `users/` row yet.
  Future<String?> _runFederated(Future<String> Function() action) async {
    final String? uid = await _run(action);
    if (uid == null) {
      return null;
    }
    final AppUser? existing = await _services.data.fetchUser(uid);
    if (existing == null || existing.fullName.isEmpty) {
      await _session.createProfile(
        uid: uid,
        fullName: existing?.fullName ?? '',
        role: _role,
      );
    }
    return uid;
  }

  Future<bool> startPhoneVerification(String phone) async {
    final String? invalid = Validators.haitianPhone(phone);
    if (invalid != null) {
      setError(invalid);
      return false;
    }
    final String normalized = Validators.normalizeHaitianPhone(phone);
    final String? id = await _run(
      () => _services.auth.startPhoneVerification(normalized),
    );
    if (id == null) {
      return false;
    }
    _verificationId = id;
    _pendingPhone = normalized;
    _startResendCountdown();
    safeNotify();
    return true;
  }

  Future<String?> confirmCode(String code) async {
    final String? id = _verificationId;
    if (id == null) {
      setError('errorGeneric');
      return null;
    }
    if (code.trim().length < 6) {
      setError('invalidCode');
      return null;
    }
    final String? uid =
        await _run(() => _services.auth.confirmPhoneCode(id, code.trim()));
    if (uid == null) {
      return null;
    }
    final AppUser? existing = await _services.data.fetchUser(uid);
    if (existing != null) {
      await _session.updateProfile(
        existing.copyWith(phone: _pendingPhone, phoneVerified: true),
      );
    }
    _verificationId = null;
    return uid;
  }

  Future<void> resendCode() async {
    final String? phone = _pendingPhone;
    if (phone == null || !canResend) {
      return;
    }
    await startPhoneVerification(phone);
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _resendSeconds--;
      if (_resendSeconds <= 0) {
        timer.cancel();
      }
      safeNotify();
    });
  }

  void cancelPhoneVerification() {
    _verificationId = null;
    _pendingPhone = null;
    _resendTimer?.cancel();
    _resendSeconds = 0;
    safeNotify();
  }

  Future<String?> _run(Future<String> Function() action) async {
    setBusy(true);
    setError(null);
    try {
      return await action();
    } catch (error) {
      setError(SessionViewModel.errorKeyFor(error));
      return null;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
