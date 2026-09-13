import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/utils/json_utils.dart';
import '../core/utils/worker_query.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/invoice.dart';
import '../models/job_request.dart';
import '../models/review.dart';
import '../models/search_filters.dart';
import '../models/user_report.dart';
import '../models/worker_profile.dart';
import 'data_service.dart';

/// In-memory implementation backed by `assets/sample_data/`.
///
/// Writes are kept for the lifetime of the process so the whole product loop —
/// request a job, accept it, complete it, invoice it, review it — can be walked
/// end to end without a Firebase project. Restarting the app resets the data.
class DemoDataService implements DataService {
  DemoDataService() {
    _ready = _load();
  }

  late final Future<void> _ready;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  final Map<String, AppUser> _users = <String, AppUser>{};
  final Map<String, WorkerProfile> _workers = <String, WorkerProfile>{};
  final List<JobRequest> _jobs = <JobRequest>[];
  final List<Review> _reviews = <Review>[];
  final Map<String, Conversation> _conversations = <String, Conversation>{};
  final Map<String, List<ChatMessage>> _messages =
      <String, List<ChatMessage>>{};
  final Map<String, List<AppNotification>> _notifications =
      <String, List<AppNotification>>{};
  final List<Invoice> _invoices = <Invoice>[];
  final List<UserReport> _reports = <UserReport>[];
  final Map<String, VerificationRequest> _verifications =
      <String, VerificationRequest>{};

  int _sequence = 0;

  String _nextId(String prefix) => '${prefix}_${++_sequence}_'
      '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  Future<List<Map<String, dynamic>>> _loadList(String name) async {
    final String raw = await rootBundle.loadString('assets/sample_data/$name');
    final dynamic decoded = json.decode(raw);
    return (decoded as List<dynamic>).map(Json.asMap).toList();
  }

  Future<void> _load() async {
    for (final Map<String, dynamic> map in await _loadList('users.json')) {
      final String id = Json.asString(map['id']);
      _users[id] = AppUser.fromMap(id, map);
    }
    for (final Map<String, dynamic> map in await _loadList('workers.json')) {
      final String id = Json.asString(map['id']);
      _workers[id] = WorkerProfile.fromMap(id, map);
    }
    for (final Map<String, dynamic> map in await _loadList('jobs.json')) {
      _jobs.add(JobRequest.fromMap(Json.asString(map['id']), map));
    }
    for (final Map<String, dynamic> map in await _loadList('reviews.json')) {
      _reviews.add(Review.fromMap(Json.asString(map['id']), map));
    }
    for (final Map<String, dynamic> map
        in await _loadList('conversations.json')) {
      final String id = Json.asString(map['id']);
      _conversations[id] = Conversation.fromMap(id, map);
      _messages[id] = Json.asMapList(map['messages'])
          .map(
            (Map<String, dynamic> m) =>
                ChatMessage.fromMap(Json.asString(m['id']), m),
          )
          .toList();
    }
    for (final Map<String, dynamic> map in await _loadList('invoices.json')) {
      _invoices.add(Invoice.fromMap(Json.asString(map['id']), map));
    }
    for (final Map<String, dynamic> map in await _loadList('reports.json')) {
      _reports.add(UserReport.fromMap(Json.asString(map['id']), map));
    }
    for (final Map<String, dynamic> map
        in await _loadList('verification_requests.json')) {
      final String id = Json.asString(map['id']);
      _verifications[id] = VerificationRequest.fromMap(id, map);
    }

    final String rawNotifications =
        await rootBundle.loadString('assets/sample_data/notifications.json');
    final Map<String, dynamic> byUser =
        Json.asMap(json.decode(rawNotifications));
    byUser.forEach((String uid, dynamic value) {
      _notifications[uid] = Json.asMapList(value)
          .map(
            (Map<String, dynamic> m) =>
                AppNotification.fromMap(Json.asString(m['id']), m),
          )
          .toList();
    });
  }

  void _emit() => _changes.add(null);

  /// Emits once the data is loaded, then again after every local write.
  Stream<T> _watch<T>(T Function() compute) async* {
    await _ready;
    yield compute();
    yield* _changes.stream.map((void _) => compute());
  }

  int _byDateDesc(DateTime? a, DateTime? b) =>
      (b ?? DateTime(0)).compareTo(a ?? DateTime(0));

  // ---------------------------------------------------------------- users
  @override
  Future<AppUser?> fetchUser(String uid) async {
    await _ready;
    return _users[uid] ??
        // A brand-new demo sign-up has no seeded row; give it a blank profile
        // so onboarding can fill it in.
        (uid.startsWith('demo_')
            ? AppUser(
                id: uid,
                fullName: '',
                role: UserRole.customer,
                createdAt: DateTime.now(),
              )
            : null);
  }

  @override
  Stream<AppUser?> watchUser(String uid) => _watch(() => _users[uid]);

  @override
  Future<void> saveUser(AppUser user) async {
    await _ready;
    _users[user.id] = user;
    _emit();
  }

  @override
  Future<void> setFavorite(
    String uid,
    String workerId, {
    required bool value,
  }) async {
    await _ready;
    final AppUser? user = _users[uid];
    if (user == null) {
      return;
    }
    final List<String> favorites = List<String>.of(user.favoriteWorkerIds);
    if (value) {
      if (!favorites.contains(workerId)) {
        favorites.add(workerId);
      }
    } else {
      favorites.remove(workerId);
    }
    _users[uid] = user.copyWith(favoriteWorkerIds: favorites);
    _emit();
  }

  @override
  Future<void> registerFcmToken(String uid, String token) async {}

  @override
  Future<void> setAccountStatus(String uid, AccountStatus status) async {
    await _ready;
    final AppUser? user = _users[uid];
    if (user != null) {
      _users[uid] = user.copyWith(status: status);
    }
    final WorkerProfile? worker = _workers[uid];
    if (worker != null) {
      _workers[uid] =
          worker.copyWith(suspended: status == AccountStatus.suspended);
    }
    _emit();
  }

  // -------------------------------------------------------------- workers
  @override
  Future<List<WorkerProfile>> searchWorkers(
    SearchFilters filters, {
    double? originLatitude,
    double? originLongitude,
    int limit = 50,
  }) async {
    await _ready;
    final List<WorkerProfile> result = WorkerQuery.apply(
      _workers.values.toList(),
      filters,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
    );
    return result.length > limit ? result.sublist(0, limit) : result;
  }

  @override
  Future<WorkerProfile?> fetchWorker(String workerId) async {
    await _ready;
    return _workers[workerId];
  }

  @override
  Stream<WorkerProfile?> watchWorker(String workerId) =>
      _watch(() => _workers[workerId]);

  @override
  Future<List<WorkerProfile>> fetchWorkersByIds(List<String> ids) async {
    await _ready;
    return <WorkerProfile>[
      for (final String id in ids)
        if (_workers[id] != null) _workers[id]!,
    ];
  }

  @override
  Future<void> saveWorkerProfile(WorkerProfile profile) async {
    await _ready;
    _workers[profile.id] = profile;
    _emit();
  }

  @override
  Future<void> setWorkerAvailability(
    String workerId, {
    required bool available,
  }) async {
    await _ready;
    final WorkerProfile? worker = _workers[workerId];
    if (worker != null) {
      _workers[workerId] = worker.copyWith(availableNow: available);
      _emit();
    }
  }

  // ----------------------------------------------------------------- jobs
  @override
  Future<JobRequest> createJob(JobRequest job) async {
    await _ready;
    final JobRequest created = JobRequest.fromMap(
      _nextId('job'),
      job.toMap()
        ..['createdAt'] = DateTime.now().toIso8601String()
        ..['updatedAt'] = DateTime.now().toIso8601String(),
    );
    _jobs.insert(0, created);
    await pushNotification(
      created.workerId,
      AppNotification(
        id: _nextId('notif'),
        type: NotificationType.jobRequest,
        messageKey: 'notifNewRequest',
        args: <String, String>{'name': created.customerName},
        jobId: created.id,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
    return created;
  }

  @override
  Stream<List<JobRequest>> watchJobsForCustomer(String customerId) => _watch(
        () => _jobs
            .where((JobRequest job) => job.customerId == customerId)
            .toList()
          ..sort(
            (JobRequest a, JobRequest b) => _byDateDesc(a.createdAt, b.createdAt),
          ),
      );

  @override
  Stream<List<JobRequest>> watchJobsForWorker(String workerId) => _watch(
        () => _jobs.where((JobRequest job) => job.workerId == workerId).toList()
          ..sort(
            (JobRequest a, JobRequest b) => _byDateDesc(a.createdAt, b.createdAt),
          ),
      );

  @override
  Future<JobRequest?> fetchJob(String jobId) async {
    await _ready;
    for (final JobRequest job in _jobs) {
      if (job.id == jobId) {
        return job;
      }
    }
    return null;
  }

  @override
  Future<void> updateJobStatus(
    String jobId,
    JobStatus status, {
    double? agreedPrice,
  }) async {
    await _ready;
    final int index = _jobs.indexWhere((JobRequest job) => job.id == jobId);
    if (index < 0) {
      return;
    }
    final JobRequest job = _jobs[index];
    _jobs[index] = job.copyWith(
      status: status,
      agreedPrice: agreedPrice,
      updatedAt: DateTime.now(),
      completedAt: status == JobStatus.completed ? DateTime.now() : null,
    );
    if (status == JobStatus.accepted || status == JobStatus.rejected) {
      await pushNotification(
        job.customerId,
        AppNotification(
          id: _nextId('notif'),
          type: status == JobStatus.accepted
              ? NotificationType.jobAccepted
              : NotificationType.jobRejected,
          messageKey:
              status == JobStatus.accepted ? 'notifAccepted' : 'notifRejected',
          args: <String, String>{'name': job.workerName},
          jobId: job.id,
          createdAt: DateTime.now(),
        ),
      );
    }
    _emit();
  }

  // -------------------------------------------------------------- reviews
  @override
  Stream<List<Review>> watchReviewsForWorker(String workerId) => _watch(
        () => _reviews
            .where(
              (Review review) =>
                  review.workerId == workerId &&
                  review.status == ReviewStatus.published,
            )
            .toList()
          ..sort((Review a, Review b) => _byDateDesc(a.createdAt, b.createdAt)),
      );

  @override
  Future<void> addReview(Review review) async {
    await _ready;
    final Review created = Review.fromMap(
      _nextId('review'),
      review.toMap()..['createdAt'] = DateTime.now().toIso8601String(),
    );
    _reviews.insert(0, created);

    // Recompute the worker aggregate — in production this is the
    // `onReviewWritten` Cloud Function's job.
    final WorkerProfile? worker = _workers[created.workerId];
    if (worker != null) {
      final List<Review> published = _reviews
          .where(
            (Review r) =>
                r.workerId == worker.id && r.status == ReviewStatus.published,
          )
          .toList();
      final double sum = published.fold<double>(
        0,
        (double total, Review r) => total + r.rating,
      );
      _workers[worker.id] = worker.copyWith(
        rating: published.isEmpty
            ? 0
            : double.parse((sum / published.length).toStringAsFixed(2)),
        reviewCount: published.length,
      );
    }

    final int index =
        _jobs.indexWhere((JobRequest job) => job.id == created.jobId);
    if (index >= 0) {
      _jobs[index] = _jobs[index].copyWith(reviewId: created.id);
    }
    await pushNotification(
      created.workerId,
      AppNotification(
        id: _nextId('notif'),
        type: NotificationType.review,
        messageKey: 'notifReviewReceived',
        args: <String, String>{'name': created.customerName},
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  @override
  Future<void> setReviewStatus(String reviewId, ReviewStatus status) async {
    await _ready;
    final int index = _reviews.indexWhere((Review r) => r.id == reviewId);
    if (index >= 0) {
      _reviews[index] = _reviews[index].copyWith(status: status);
      _emit();
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _ready;
    _reviews.removeWhere((Review review) => review.id == reviewId);
    _emit();
  }

  // ----------------------------------------------------------------- chat
  @override
  Stream<List<Conversation>> watchConversations(String uid) => _watch(
        () => _conversations.values
            .where(
              (Conversation conversation) =>
                  conversation.participantIds.contains(uid),
            )
            .toList()
          ..sort(
            (Conversation a, Conversation b) =>
                _byDateDesc(a.lastMessageAt, b.lastMessageAt),
          ),
      );

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) => _watch(
        () => List<ChatMessage>.of(
          _messages[conversationId] ?? const <ChatMessage>[],
        ),
      );

  @override
  Future<Conversation> ensureConversation({
    required AppUser me,
    required String otherId,
    required String otherName,
    String? otherPhotoUrl,
    String? jobId,
  }) async {
    await _ready;
    final String id = Conversation.idFor(me.id, otherId);
    final Conversation existing = _conversations[id] ??
        Conversation(
          id: id,
          participantIds: <String>[me.id, otherId],
          titles: <String, String>{me.id: me.fullName, otherId: otherName},
          photoUrls: <String, String>{
            if (me.photoUrl != null) me.id: me.photoUrl!,
            if (otherPhotoUrl != null) otherId: otherPhotoUrl,
          },
          jobId: jobId,
          lastMessageAt: DateTime.now(),
        );
    _conversations[id] = existing;
    _messages.putIfAbsent(id, () => <ChatMessage>[]);
    _emit();
    return existing;
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    ChatMessage message,
    String recipientId,
  ) async {
    await _ready;
    final ChatMessage sent = ChatMessage(
      id: _nextId('msg'),
      senderId: message.senderId,
      text: message.text,
      imageUrl: message.imageUrl,
      sentAt: DateTime.now(),
      readBy: <String>[message.senderId],
    );
    _messages.putIfAbsent(conversationId, () => <ChatMessage>[]).add(sent);

    final Conversation? conversation = _conversations[conversationId];
    if (conversation != null) {
      final Map<String, int> unread =
          Map<String, int>.of(conversation.unreadCounts);
      unread[recipientId] = (unread[recipientId] ?? 0) + 1;
      _conversations[conversationId] = Conversation(
        id: conversation.id,
        participantIds: conversation.participantIds,
        titles: conversation.titles,
        photoUrls: conversation.photoUrls,
        jobId: conversation.jobId,
        lastMessage: sent.text.isEmpty && sent.imageUrl != null ? '📷' : sent.text,
        lastMessageAt: sent.sentAt,
        unreadCounts: unread,
      );
    }
    _emit();
  }

  @override
  Future<void> markConversationRead(String conversationId, String uid) async {
    await _ready;
    final Conversation? conversation = _conversations[conversationId];
    if (conversation == null) {
      return;
    }
    final Map<String, int> unread =
        Map<String, int>.of(conversation.unreadCounts)..[uid] = 0;
    _conversations[conversationId] = Conversation(
      id: conversation.id,
      participantIds: conversation.participantIds,
      titles: conversation.titles,
      photoUrls: conversation.photoUrls,
      jobId: conversation.jobId,
      lastMessage: conversation.lastMessage,
      lastMessageAt: conversation.lastMessageAt,
      unreadCounts: unread,
    );
    _emit();
  }

  // -------------------------------------------------------- notifications
  @override
  Stream<List<AppNotification>> watchNotifications(String uid) => _watch(
        () => List<AppNotification>.of(
          _notifications[uid] ?? const <AppNotification>[],
        )..sort(
            (AppNotification a, AppNotification b) =>
                _byDateDesc(a.createdAt, b.createdAt),
          ),
      );

  @override
  Future<void> pushNotification(
    String uid,
    AppNotification notification,
  ) async {
    await _ready;
    _notifications.putIfAbsent(uid, () => <AppNotification>[]).insert(
          0,
          notification,
        );
    _emit();
  }

  @override
  Future<void> markNotificationsRead(String uid) async {
    await _ready;
    final List<AppNotification>? list = _notifications[uid];
    if (list == null) {
      return;
    }
    _notifications[uid] = list
        .map((AppNotification notification) => notification.copyWith(read: true))
        .toList();
    _emit();
  }

  // ------------------------------------------------------------- payments
  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    await _ready;
    final Invoice created = Invoice.fromMap(
      _nextId('invoice'),
      invoice.toMap()..['issuedAt'] = DateTime.now().toIso8601String(),
    );
    _invoices.insert(0, created);
    final int index =
        _jobs.indexWhere((JobRequest job) => job.id == created.jobId);
    if (index >= 0) {
      _jobs[index] = _jobs[index].copyWith(invoiceId: created.id);
    }
    _emit();
    return created;
  }

  @override
  Stream<List<Invoice>> watchInvoicesForCustomer(String customerId) => _watch(
        () => _invoices
            .where((Invoice invoice) => invoice.customerId == customerId)
            .toList()
          ..sort(
            (Invoice a, Invoice b) => _byDateDesc(a.issuedAt, b.issuedAt),
          ),
      );

  @override
  Stream<List<Invoice>> watchInvoicesForWorker(String workerId) => _watch(
        () => _invoices
            .where((Invoice invoice) => invoice.workerId == workerId)
            .toList()
          ..sort(
            (Invoice a, Invoice b) => _byDateDesc(a.issuedAt, b.issuedAt),
          ),
      );

  @override
  Future<void> updateInvoiceStatus(
    String invoiceId,
    PaymentStatus status, {
    PaymentMethod? method,
    String? transactionRef,
    String? cardBrand,
    String? cardLast4,
  }) async {
    await _ready;
    final int index =
        _invoices.indexWhere((Invoice invoice) => invoice.id == invoiceId);
    if (index >= 0) {
      _invoices[index] = _invoices[index].copyWith(
        status: status,
        method: method,
        transactionRef: transactionRef,
        cardBrand: cardBrand,
        cardLast4: cardLast4,
        paidAt: status == PaymentStatus.paid ? DateTime.now() : null,
      );
      _emit();
    }
  }

  // --------------------------------------------------- trust & moderation
  @override
  Future<void> submitReport(UserReport report) async {
    await _ready;
    _reports.insert(
      0,
      UserReport.fromMap(
        _nextId('report'),
        report.toMap()..['createdAt'] = DateTime.now().toIso8601String(),
      ),
    );
    _emit();
  }

  @override
  Stream<List<UserReport>> watchReports({ReportStatus? status}) => _watch(
        () => _reports
            .where(
              (UserReport report) => status == null || report.status == status,
            )
            .toList()
          ..sort(
            (UserReport a, UserReport b) =>
                _byDateDesc(a.createdAt, b.createdAt),
          ),
      );

  @override
  Future<void> resolveReport(
    String reportId,
    ReportStatus status, {
    String? note,
  }) async {
    await _ready;
    final int index =
        _reports.indexWhere((UserReport report) => report.id == reportId);
    if (index >= 0) {
      _reports[index] = _reports[index].copyWith(
        status: status,
        resolvedAt: DateTime.now(),
        resolutionNote: note,
      );
      _emit();
    }
  }

  @override
  Future<void> submitVerification(VerificationRequest request) async {
    await _ready;
    _verifications[request.workerId] = request;
    final WorkerProfile? worker = _workers[request.workerId];
    if (worker != null) {
      _workers[request.workerId] =
          worker.copyWith(verification: VerificationStatus.pending);
    }
    _emit();
  }

  @override
  Stream<List<VerificationRequest>> watchVerificationRequests({
    String status = 'pending',
  }) =>
      _watch(
        () => _verifications.values
            .where((VerificationRequest request) => request.status == status)
            .toList(),
      );

  @override
  Future<void> decideVerification(
    String workerId, {
    required bool approved,
    required String adminId,
    String? note,
  }) async {
    await _ready;
    final VerificationRequest? request = _verifications[workerId];
    if (request != null) {
      _verifications[workerId] = VerificationRequest(
        workerId: request.workerId,
        workerName: request.workerName,
        idDocumentUrl: request.idDocumentUrl,
        idType: request.idType,
        certificateUrls: request.certificateUrls,
        status: approved ? 'approved' : 'rejected',
        note: note,
        submittedAt: request.submittedAt,
        reviewedAt: DateTime.now(),
        reviewedBy: adminId,
      );
    }
    final WorkerProfile? worker = _workers[workerId];
    if (worker != null) {
      _workers[workerId] = worker.copyWith(
        verification: approved
            ? VerificationStatus.approved
            : VerificationStatus.rejected,
      );
    }
    if (approved) {
      await pushNotification(
        workerId,
        AppNotification(
          id: _nextId('notif'),
          type: NotificationType.verification,
          messageKey: 'notifVerified',
          createdAt: DateTime.now(),
        ),
      );
    }
    _emit();
  }

  // ---------------------------------------------------------------- admin
  @override
  Stream<List<AppUser>> watchUsers({UserRole? role, int limit = 100}) => _watch(
        () {
          final List<AppUser> users = _users.values
              .where((AppUser user) => role == null || user.role == role)
              .toList()
            ..sort((AppUser a, AppUser b) => a.fullName.compareTo(b.fullName));
          return users.length > limit ? users.sublist(0, limit) : users;
        },
      );

  @override
  Stream<List<Review>> watchReviewsForModeration() => _watch(
        () => List<Review>.of(_reviews)
          ..sort((Review a, Review b) => _byDateDesc(a.createdAt, b.createdAt)),
      );

  @override
  Future<PlatformStats> fetchStats() async {
    await _ready;
    final Map<String, int> byCategory = <String, int>{};
    final Map<String, int> byDepartment = <String, int>{};
    for (final JobRequest job in _jobs) {
      byCategory[job.categoryId] = (byCategory[job.categoryId] ?? 0) + 1;
      final String department = job.departmentId ?? 'unknown';
      byDepartment[department] = (byDepartment[department] ?? 0) + 1;
    }
    return PlatformStats(
      totalUsers: _users.length,
      totalWorkers: _workers.length,
      totalCustomers: _users.values
          .where((AppUser user) => user.role == UserRole.customer)
          .length,
      activeWorkers: _workers.values
          .where((WorkerProfile worker) => worker.availableNow)
          .length,
      totalJobs: _jobs.length,
      completedJobs: _jobs
          .where((JobRequest job) => job.status == JobStatus.completed)
          .length,
      pendingVerifications: _verifications.values
          .where((VerificationRequest request) => request.status == 'pending')
          .length,
      openReports: _reports
          .where((UserReport report) => report.status == ReportStatus.open)
          .length,
      totalRevenue: _invoices
          .where((Invoice invoice) => invoice.status == PaymentStatus.paid)
          .fold<double>(0, (double sum, Invoice invoice) => sum + invoice.total),
      jobsByCategory: byCategory,
      jobsByDepartment: byDepartment,
    );
  }
}
