import '../models/app_user.dart';
import '../models/job_request.dart';
import '../models/review.dart';
import '../models/user_report.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Leaving a review, and reporting a user — the two "after the job" actions.
class ReviewViewModel extends BaseViewModel {
  ReviewViewModel(this._services);

  final Services _services;

  double _rating = 5;
  String _comment = '';

  double get rating => _rating;
  String get comment => _comment;
  bool get canSubmit => _rating > 0;

  void setRating(double value) {
    _rating = value;
    safeNotify();
  }

  void setComment(String value) => _comment = value;

  Future<bool> submit({required JobRequest job, required AppUser customer}) async {
    final bool? done = await guard<bool>(() async {
      await _services.data.addReview(
        Review(
          id: '',
          jobId: job.id,
          workerId: job.workerId,
          customerId: customer.id,
          customerName: customer.fullName,
          customerPhotoUrl: customer.photoUrl,
          rating: _rating,
          comment: _comment.trim(),
          createdAt: DateTime.now(),
        ),
      );
      return true;
    });
    return done ?? false;
  }

  Future<bool> report({
    required String reporterId,
    required String targetUserId,
    required String targetName,
    required ReportReason reason,
    String details = '',
    String? jobId,
    String? reviewId,
  }) async {
    final bool? done = await guard<bool>(() async {
      await _services.data.submitReport(
        UserReport(
          id: '',
          reporterId: reporterId,
          targetUserId: targetUserId,
          targetName: targetName,
          reason: reason,
          details: details.trim(),
          jobId: jobId,
          reviewId: reviewId,
          createdAt: DateTime.now(),
        ),
      );
      return true;
    });
    return done ?? false;
  }
}
