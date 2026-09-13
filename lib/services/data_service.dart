import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/invoice.dart';
import '../models/job_request.dart';
import '../models/review.dart';
import '../models/search_filters.dart';
import '../models/user_report.dart';
import '../models/worker_profile.dart';

/// Aggregate analytics shown on the admin dashboard.
class PlatformStats {
  const PlatformStats({
    this.totalUsers = 0,
    this.totalWorkers = 0,
    this.totalCustomers = 0,
    this.activeWorkers = 0,
    this.totalJobs = 0,
    this.completedJobs = 0,
    this.pendingVerifications = 0,
    this.openReports = 0,
    this.totalRevenue = 0,
    this.jobsByCategory = const <String, int>{},
    this.jobsByDepartment = const <String, int>{},
  });

  final int totalUsers;
  final int totalWorkers;
  final int totalCustomers;
  final int activeWorkers;
  final int totalJobs;
  final int completedJobs;
  final int pendingVerifications;
  final int openReports;
  final double totalRevenue;
  final Map<String, int> jobsByCategory;
  final Map<String, int> jobsByDepartment;
}

/// Every read and write the app performs, in one interface.
///
/// `FirestoreDataService` talks to Firebase; `DemoDataService` serves the
/// bundled sample data. Keeping them behind one contract is what lets the app
/// boot and be demoed with no backend provisioned.
abstract class DataService {
  // ---------------------------------------------------------------- users
  Future<AppUser?> fetchUser(String uid);

  Stream<AppUser?> watchUser(String uid);

  Future<void> saveUser(AppUser user);

  Future<void> setFavorite(String uid, String workerId, {required bool value});

  Future<void> registerFcmToken(String uid, String token);

  Future<void> setAccountStatus(String uid, AccountStatus status);

  // -------------------------------------------------------------- workers
  /// Applies the category / department / city / rating / verified / available
  /// predicates server-side where Firestore allows it, then the free-text,
  /// price and distance predicates client-side.
  Future<List<WorkerProfile>> searchWorkers(
    SearchFilters filters, {
    double? originLatitude,
    double? originLongitude,
    int limit = 50,
  });

  Future<WorkerProfile?> fetchWorker(String workerId);

  Stream<WorkerProfile?> watchWorker(String workerId);

  Future<List<WorkerProfile>> fetchWorkersByIds(List<String> ids);

  Future<void> saveWorkerProfile(WorkerProfile profile);

  Future<void> setWorkerAvailability(String workerId, {required bool available});

  // ----------------------------------------------------------------- jobs
  Future<JobRequest> createJob(JobRequest job);

  Stream<List<JobRequest>> watchJobsForCustomer(String customerId);

  Stream<List<JobRequest>> watchJobsForWorker(String workerId);

  Future<JobRequest?> fetchJob(String jobId);

  Future<void> updateJobStatus(
    String jobId,
    JobStatus status, {
    double? agreedPrice,
  });

  // -------------------------------------------------------------- reviews
  Stream<List<Review>> watchReviewsForWorker(String workerId);

  Future<void> addReview(Review review);

  Future<void> setReviewStatus(String reviewId, ReviewStatus status);

  Future<void> deleteReview(String reviewId);

  // ----------------------------------------------------------------- chat
  Stream<List<Conversation>> watchConversations(String uid);

  Stream<List<ChatMessage>> watchMessages(String conversationId);

  Future<Conversation> ensureConversation({
    required AppUser me,
    required String otherId,
    required String otherName,
    String? otherPhotoUrl,
    String? jobId,
  });

  Future<void> sendMessage(
    String conversationId,
    ChatMessage message,
    String recipientId,
  );

  Future<void> markConversationRead(String conversationId, String uid);

  // -------------------------------------------------------- notifications
  Stream<List<AppNotification>> watchNotifications(String uid);

  Future<void> pushNotification(String uid, AppNotification notification);

  Future<void> markNotificationsRead(String uid);

  // ------------------------------------------------------------- payments
  Future<Invoice> createInvoice(Invoice invoice);

  Stream<List<Invoice>> watchInvoicesForCustomer(String customerId);

  Stream<List<Invoice>> watchInvoicesForWorker(String workerId);

  Future<void> updateInvoiceStatus(
    String invoiceId,
    PaymentStatus status, {
    String? transactionRef,
  });

  // --------------------------------------------------- trust & moderation
  Future<void> submitReport(UserReport report);

  Stream<List<UserReport>> watchReports({ReportStatus? status});

  Future<void> resolveReport(
    String reportId,
    ReportStatus status, {
    String? note,
  });

  Future<void> submitVerification(VerificationRequest request);

  Stream<List<VerificationRequest>> watchVerificationRequests({
    String status = 'pending',
  });

  Future<void> decideVerification(
    String workerId, {
    required bool approved,
    required String adminId,
    String? note,
  });

  // ---------------------------------------------------------------- admin
  Stream<List<AppUser>> watchUsers({UserRole? role, int limit = 100});

  Stream<List<Review>> watchReviewsForModeration();

  Future<PlatformStats> fetchStats();
}
