import 'dart:async';

import '../models/app_user.dart';
import '../models/review.dart';
import '../models/user_report.dart';
import '../services/data_service.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Backs the admin console: verification queue, moderation, user management
/// and the analytics tiles.
class AdminViewModel extends BaseViewModel {
  AdminViewModel(this._services, this.adminId) {
    _verificationSubscription = _services.data
        .watchVerificationRequests()
        .listen((List<VerificationRequest> requests) {
      _verifications = requests;
      safeNotify();
    });
    _reportSubscription = _services.data
        .watchReports(status: ReportStatus.open)
        .listen((List<UserReport> reports) {
      _reports = reports;
      safeNotify();
    });
    _reviewSubscription = _services.data
        .watchReviewsForModeration()
        .listen((List<Review> reviews) {
      _reviews = reviews;
      safeNotify();
    });
    _userSubscription = _services.data.watchUsers().listen((List<AppUser> users) {
      _users = users;
      safeNotify();
    });
    refreshStats();
  }

  final Services _services;
  final String adminId;

  StreamSubscription<List<VerificationRequest>>? _verificationSubscription;
  StreamSubscription<List<UserReport>>? _reportSubscription;
  StreamSubscription<List<Review>>? _reviewSubscription;
  StreamSubscription<List<AppUser>>? _userSubscription;

  List<VerificationRequest> _verifications = const <VerificationRequest>[];
  List<UserReport> _reports = const <UserReport>[];
  List<Review> _reviews = const <Review>[];
  List<AppUser> _users = const <AppUser>[];
  PlatformStats _stats = const PlatformStats();

  List<VerificationRequest> get verifications => _verifications;
  List<UserReport> get reports => _reports;
  List<Review> get reviews => _reviews;
  List<AppUser> get users => _users;
  PlatformStats get stats => _stats;

  List<AppUser> usersOfRole(UserRole role) =>
      _users.where((AppUser user) => user.role == role).toList();

  Future<void> refreshStats() async {
    final PlatformStats? stats =
        await guard<PlatformStats>(() => _services.data.fetchStats());
    if (stats != null) {
      _stats = stats;
      safeNotify();
    }
  }

  Future<void> decideVerification(
    String workerId, {
    required bool approved,
    String? note,
  }) async {
    await guard(() async {
      await _services.data.decideVerification(
        workerId,
        approved: approved,
        adminId: adminId,
        note: note,
      );
      return true;
    });
    await refreshStats();
  }

  Future<void> resolveReport(
    String reportId, {
    required bool dismissed,
    String? note,
  }) async {
    await guard(() async {
      await _services.data.resolveReport(
        reportId,
        dismissed ? ReportStatus.dismissed : ReportStatus.resolved,
        note: note,
      );
      return true;
    });
  }

  Future<void> hideReview(String reviewId) async {
    await guard(() async {
      await _services.data.setReviewStatus(reviewId, ReviewStatus.hidden);
      return true;
    });
  }

  Future<void> publishReview(String reviewId) async {
    await guard(() async {
      await _services.data.setReviewStatus(reviewId, ReviewStatus.published);
      return true;
    });
  }

  Future<void> deleteReview(String reviewId) async {
    await guard(() async {
      await _services.data.deleteReview(reviewId);
      return true;
    });
  }

  Future<void> setUserSuspended(AppUser user, {required bool suspended}) async {
    await guard(() async {
      await _services.data.setAccountStatus(
        user.id,
        suspended ? AccountStatus.suspended : AccountStatus.active,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    _reportSubscription?.cancel();
    _reviewSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
