import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Everything the whole app needs to know at once: who is signed in, what
/// language and theme they chose, and whether onboarding is behind them.
class SessionViewModel extends BaseViewModel {
  SessionViewModel(this._services) {
    _locale = _localeFromCode(_services.preferences.languageCode);
    _themeMode = _services.preferences.themeMode;
    _onboardingDone = _services.preferences.onboardingDone;
    _authSubscription =
        _services.auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final Services _services;

  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<WorkerProfile?>? _workerSubscription;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _onboardingDone = false;
  bool _bootstrapped = false;
  AppUser? _user;
  WorkerProfile? _workerProfile;
  int _unreadNotifications = 0;

  Services get services => _services;

  /// Null until the user has picked a language — that choice is the first
  /// screen of the app.
  Locale? get locale => _locale;
  bool get hasChosenLanguage => _locale != null;
  ThemeMode get themeMode => _themeMode;
  bool get onboardingDone => _onboardingDone;

  /// False until the first auth event has been processed, so the router can
  /// hold on the splash screen instead of flashing the login page.
  bool get bootstrapped => _bootstrapped;

  AppUser? get user => _user;
  WorkerProfile? get workerProfile => _workerProfile;
  bool get isSignedIn => _user != null;
  bool get isWorker => _user?.isWorker ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  int get unreadNotifications => _unreadNotifications;

  bool isFavorite(String workerId) =>
      _user?.favoriteWorkerIds.contains(workerId) ?? false;

  static Locale? _localeFromCode(String? code) =>
      code == null ? null : Locale(code);

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _services.preferences.setLanguageCode(locale.languageCode);
    final AppUser? current = _user;
    if (current != null && current.languageCode != locale.languageCode) {
      await _services.data
          .saveUser(current.copyWith(languageCode: locale.languageCode));
    }
    safeNotify();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _services.preferences.setThemeMode(mode);
    safeNotify();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _services.preferences.setOnboardingDone();
    safeNotify();
  }

  Future<void> _onAuthStateChanged(String? uid) async {
    await _userSubscription?.cancel();
    await _workerSubscription?.cancel();
    await _notificationSubscription?.cancel();
    _userSubscription = null;
    _workerSubscription = null;
    _notificationSubscription = null;

    if (uid == null) {
      _user = null;
      _workerProfile = null;
      _unreadNotifications = 0;
      _bootstrapped = true;
      safeNotify();
      return;
    }

    // One direct read first so the router can route on the very first frame,
    // then a live subscription for everything after that.
    _user = await _services.data.fetchUser(uid);
    _bootstrapped = true;
    safeNotify();

    _userSubscription = _services.data.watchUser(uid).listen((AppUser? user) {
      if (user != null) {
        _user = user;
        safeNotify();
      }
    });

    _notificationSubscription = _services.data
        .watchNotifications(uid)
        .listen((List<AppNotification> notifications) {
      _unreadNotifications = notifications
          .where((AppNotification notification) => !notification.read)
          .length;
      safeNotify();
    });

    if (_user?.isWorker ?? false) {
      _watchWorkerProfile(uid);
    }

    await _registerPushToken(uid);
  }

  void _watchWorkerProfile(String uid) {
    _workerSubscription?.cancel();
    _workerSubscription =
        _services.data.watchWorker(uid).listen((WorkerProfile? profile) {
      _workerProfile = profile;
      safeNotify();
    });
  }

  Future<void> _registerPushToken(String uid) async {
    final String? token = await _services.messaging.initialize();
    if (token != null) {
      await _services.data.registerFcmToken(uid, token);
    }
  }

  /// Called after sign-up, once a role has been chosen.
  Future<void> createProfile({
    required String uid,
    required String fullName,
    required UserRole role,
    String? email,
    String? phone,
    String? departmentId,
    String? city,
  }) async {
    final AppUser user = AppUser(
      id: uid,
      fullName: fullName,
      role: role,
      email: email,
      phone: phone,
      languageCode: _locale?.languageCode ?? 'ht',
      departmentId: departmentId,
      city: city,
      createdAt: DateTime.now(),
    );
    await _services.data.saveUser(user);
    _user = user;

    if (role == UserRole.worker) {
      final WorkerProfile profile = WorkerProfile(
        id: uid,
        fullName: fullName,
        categoryIds: const <String>[],
        departmentId: departmentId ?? 'ouest',
        city: city ?? 'Port-au-Prince',
        phone: phone,
        createdAt: DateTime.now(),
      );
      await _services.data.saveWorkerProfile(profile);
      _workerProfile = profile;
      _watchWorkerProfile(uid);
    }
    safeNotify();
  }

  Future<void> updateProfile(AppUser updated) async {
    await _services.data.saveUser(updated);
    _user = updated;
    safeNotify();
  }

  Future<void> toggleFavorite(String workerId) async {
    final AppUser? current = _user;
    if (current == null) {
      return;
    }
    final bool nowFavorite = !isFavorite(workerId);
    // Optimistic: the heart must not lag behind the tap on a slow connection.
    final List<String> favorites = List<String>.of(current.favoriteWorkerIds);
    if (nowFavorite) {
      favorites.add(workerId);
    } else {
      favorites.remove(workerId);
    }
    _user = current.copyWith(favoriteWorkerIds: favorites);
    safeNotify();
    try {
      await _services.data
          .setFavorite(current.id, workerId, value: nowFavorite);
    } catch (_) {
      _user = current;
      safeNotify();
    }
  }

  Future<void> markNotificationsRead() async {
    final AppUser? current = _user;
    if (current != null) {
      await _services.data.markNotificationsRead(current.id);
    }
  }

  Future<void> signOut() async {
    await _services.auth.signOut();
  }

  Future<bool> deleteAccount() async {
    final AppUser? current = _user;
    if (current == null) {
      return false;
    }
    final bool? result = await guard<bool>(() async {
      await _services.data.setAccountStatus(current.id, AccountStatus.deleted);
      await _services.auth.deleteAccount();
      return true;
    });
    return result ?? false;
  }

  /// Maps provider error codes onto catalog keys.
  static String errorKeyFor(Object error) {
    if (error is AuthException) {
      return switch (error.code) {
        'invalid-email' => 'invalidEmail',
        'weak-password' => 'passwordTooShort',
        'wrong-password' || 'user-not-found' || 'invalid-credential' =>
          'loginFailed',
        'email-already-in-use' => 'signupFailed',
        'invalid-verification-code' => 'invalidCode',
        'network-request-failed' => 'errorNetwork',
        _ => 'errorGeneric',
      };
    }
    return 'errorGeneric';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    _workerSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
