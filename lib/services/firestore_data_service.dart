import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Firestore-backed implementation.
///
/// Offline behaviour comes from the SDK's own persistence (enabled in
/// `main.dart`): every `snapshots()` stream below replays from the local cache
/// before the network responds, which is what keeps the app usable on a weak
/// connection.
class FirestoreDataService implements DataService {
  FirestoreDataService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _workers =>
      _db.collection('workers');
  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _invoices =>
      _db.collection('invoices');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');
  CollectionReference<Map<String, dynamic>> get _verifications =>
      _db.collection('verificationRequests');

  // ---------------------------------------------------------------- users
  @override
  Future<AppUser?> fetchUser(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _users.doc(uid).get();
    final Map<String, dynamic>? data = doc.data();
    return data == null ? null : AppUser.fromMap(doc.id, data);
  }

  @override
  Stream<AppUser?> watchUser(String uid) => _users.doc(uid).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic>? data = doc.data();
          return data == null ? null : AppUser.fromMap(doc.id, data);
        },
      );

  @override
  Future<void> saveUser(AppUser user) async {
    final Map<String, dynamic> data = user.toMap();
    data['createdAt'] = user.createdAt ?? FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> setFavorite(
    String uid,
    String workerId, {
    required bool value,
  }) =>
      _users.doc(uid).update(<String, dynamic>{
        'favoriteWorkerIds': value
            ? FieldValue.arrayUnion(<String>[workerId])
            : FieldValue.arrayRemove(<String>[workerId]),
      });

  @override
  Future<void> registerFcmToken(String uid, String token) =>
      _users.doc(uid).set(
        <String, dynamic>{
          'fcmTokens': FieldValue.arrayUnion(<String>[token]),
        },
        SetOptions(merge: true),
      );

  @override
  Future<void> setAccountStatus(String uid, AccountStatus status) async {
    await _users.doc(uid).update(<String, dynamic>{'status': status.id});
    final DocumentSnapshot<Map<String, dynamic>> worker =
        await _workers.doc(uid).get();
    if (worker.exists) {
      await _workers.doc(uid).update(<String, dynamic>{
        'suspended': status == AccountStatus.suspended,
      });
    }
  }

  // -------------------------------------------------------------- workers
  @override
  Future<List<WorkerProfile>> searchWorkers(
    SearchFilters filters, {
    double? originLatitude,
    double? originLongitude,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query =
        _workers.where('suspended', isEqualTo: false);

    // One array-contains per query is all Firestore allows, so the category
    // gets it; department and city are narrowed client-side below.
    if (filters.categoryId != null) {
      query = query.where('categoryIds', arrayContains: filters.categoryId);
    }
    if (filters.verifiedOnly) {
      query = query.where('verification', isEqualTo: 'approved');
    }
    if (filters.availableNow) {
      query = query.where('availableNow', isEqualTo: true);
    }
    query = query.orderBy('rating', descending: true).limit(limit * 3);

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    final List<WorkerProfile> workers = snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              WorkerProfile.fromMap(doc.id, doc.data()),
        )
        .toList();

    final List<WorkerProfile> filtered = WorkerQuery.apply(
      workers,
      filters,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
    );
    return filtered.length > limit ? filtered.sublist(0, limit) : filtered;
  }

  @override
  Future<WorkerProfile?> fetchWorker(String workerId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _workers.doc(workerId).get();
    final Map<String, dynamic>? data = doc.data();
    return data == null ? null : WorkerProfile.fromMap(doc.id, data);
  }

  @override
  Stream<WorkerProfile?> watchWorker(String workerId) =>
      _workers.doc(workerId).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic>? data = doc.data();
          return data == null ? null : WorkerProfile.fromMap(doc.id, data);
        },
      );

  @override
  Future<List<WorkerProfile>> fetchWorkersByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const <WorkerProfile>[];
    }
    final List<WorkerProfile> result = <WorkerProfile>[];
    // `whereIn` caps at 30 values per query.
    for (int i = 0; i < ids.length; i += 30) {
      final List<String> chunk =
          ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _workers
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      result.addAll(
        snapshot.docs.map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              WorkerProfile.fromMap(doc.id, doc.data()),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> saveWorkerProfile(WorkerProfile profile) async {
    final Map<String, dynamic> data = profile.toMap();
    data['createdAt'] = profile.createdAt ?? FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _workers.doc(profile.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> setWorkerAvailability(
    String workerId, {
    required bool available,
  }) =>
      _workers.doc(workerId).update(<String, dynamic>{'availableNow': available});

  // ----------------------------------------------------------------- jobs
  @override
  Future<JobRequest> createJob(JobRequest job) async {
    final DocumentReference<Map<String, dynamic>> ref = _jobs.doc();
    final Map<String, dynamic> data = job.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return JobRequest.fromMap(
      ref.id,
      job.toMap()..['createdAt'] = DateTime.now().toIso8601String(),
    );
  }

  @override
  Stream<List<JobRequest>> watchJobsForCustomer(String customerId) => _jobs
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_jobsFrom);

  @override
  Stream<List<JobRequest>> watchJobsForWorker(String workerId) => _jobs
      .where('workerId', isEqualTo: workerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_jobsFrom);

  List<JobRequest> _jobsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                JobRequest.fromMap(doc.id, doc.data()),
          )
          .toList();

  @override
  Future<JobRequest?> fetchJob(String jobId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _jobs.doc(jobId).get();
    final Map<String, dynamic>? data = doc.data();
    return data == null ? null : JobRequest.fromMap(doc.id, data);
  }

  @override
  Future<void> updateJobStatus(
    String jobId,
    JobStatus status, {
    double? agreedPrice,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'status': status.id,
      'updatedAt': FieldValue.serverTimestamp(),
      if (agreedPrice != null) 'agreedPrice': agreedPrice,
      if (status == JobStatus.completed)
        'completedAt': FieldValue.serverTimestamp(),
    };
    await _jobs.doc(jobId).update(data);
  }

  // -------------------------------------------------------------- reviews
  @override
  Stream<List<Review>> watchReviewsForWorker(String workerId) => _reviews
      .where('workerId', isEqualTo: workerId)
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_reviewsFrom);

  List<Review> _reviewsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Review.fromMap(doc.id, doc.data()),
          )
          .toList();

  @override
  Future<void> addReview(Review review) async {
    final DocumentReference<Map<String, dynamic>> ref = _reviews.doc();
    await ref.set(
      review.toMap()..['createdAt'] = FieldValue.serverTimestamp(),
    );
    await _jobs.doc(review.jobId).update(<String, dynamic>{'reviewId': ref.id});
    // The worker's rating aggregate is recomputed by the
    // `onReviewWritten` Cloud Function so the number can't be forged here.
  }

  @override
  Future<void> setReviewStatus(String reviewId, ReviewStatus status) =>
      _reviews.doc(reviewId).update(<String, dynamic>{'status': status.id});

  @override
  Future<void> deleteReview(String reviewId) => _reviews.doc(reviewId).delete();

  // ----------------------------------------------------------------- chat
  @override
  Stream<List<Conversation>> watchConversations(String uid) => _conversations
      .where('participantIds', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  Conversation.fromMap(doc.id, doc.data()),
            )
            .toList(),
      );

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _conversations
          .doc(conversationId)
          .collection('messages')
          .orderBy('sentAt')
          .snapshots()
          .map(
            (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      ChatMessage.fromMap(doc.id, doc.data()),
                )
                .toList(),
          );

  @override
  Future<Conversation> ensureConversation({
    required AppUser me,
    required String otherId,
    required String otherName,
    String? otherPhotoUrl,
    String? jobId,
  }) async {
    final String id = Conversation.idFor(me.id, otherId);
    final DocumentReference<Map<String, dynamic>> ref = _conversations.doc(id);
    final Conversation conversation = Conversation(
      id: id,
      participantIds: <String>[me.id, otherId],
      titles: <String, String>{me.id: me.fullName, otherId: otherName},
      photoUrls: <String, String>{
        if (me.photoUrl != null) me.id: me.photoUrl!,
        if (otherPhotoUrl != null) otherId: otherPhotoUrl,
      },
      jobId: jobId,
    );
    await ref.set(
      conversation.toMap()
        ..remove('lastMessageAt')
        ..remove('unreadCounts'),
      SetOptions(merge: true),
    );
    return conversation;
  }

  @override
  Future<void> sendMessage(
    String conversationId,
    ChatMessage message,
    String recipientId,
  ) async {
    final DocumentReference<Map<String, dynamic>> conversation =
        _conversations.doc(conversationId);
    final WriteBatch batch = _db.batch();
    batch.set(
      conversation.collection('messages').doc(),
      message.toMap()..['sentAt'] = FieldValue.serverTimestamp(),
    );
    batch.set(
      conversation,
      <String, dynamic>{
        'lastMessage': message.imageUrl != null && message.text.isEmpty
            ? '📷'
            : message.text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': <String, dynamic>{
          recipientId: FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Future<void> markConversationRead(String conversationId, String uid) =>
      _conversations.doc(conversationId).set(
        <String, dynamic>{
          'unreadCounts': <String, dynamic>{uid: 0},
        },
        SetOptions(merge: true),
      );

  // -------------------------------------------------------- notifications
  @override
  Stream<List<AppNotification>> watchNotifications(String uid) => _users
      .doc(uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AppNotification.fromMap(doc.id, doc.data()),
            )
            .toList(),
      );

  @override
  Future<void> pushNotification(
    String uid,
    AppNotification notification,
  ) =>
      _users.doc(uid).collection('notifications').add(
            notification.toMap()..['createdAt'] = FieldValue.serverTimestamp(),
          );

  @override
  Future<void> markNotificationsRead(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> unread = await _users
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) {
      return;
    }
    final WriteBatch batch = _db.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in unread.docs) {
      batch.update(doc.reference, <String, dynamic>{'read': true});
    }
    await batch.commit();
  }

  // ------------------------------------------------------------- payments
  @override
  Future<Invoice> createInvoice(Invoice invoice) async {
    final DocumentReference<Map<String, dynamic>> ref = _invoices.doc();
    await ref.set(invoice.toMap()..['issuedAt'] = FieldValue.serverTimestamp());
    await _jobs.doc(invoice.jobId).update(<String, dynamic>{'invoiceId': ref.id});
    return Invoice.fromMap(ref.id, invoice.toMap());
  }

  @override
  Stream<List<Invoice>> watchInvoicesForCustomer(String customerId) => _invoices
      .where('customerId', isEqualTo: customerId)
      .orderBy('issuedAt', descending: true)
      .snapshots()
      .map(_invoicesFrom);

  @override
  Stream<List<Invoice>> watchInvoicesForWorker(String workerId) => _invoices
      .where('workerId', isEqualTo: workerId)
      .orderBy('issuedAt', descending: true)
      .snapshots()
      .map(_invoicesFrom);

  List<Invoice> _invoicesFrom(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Invoice.fromMap(doc.id, doc.data()),
          )
          .toList();

  @override
  Future<void> updateInvoiceStatus(
    String invoiceId,
    PaymentStatus status, {
    PaymentMethod? method,
    String? transactionRef,
    String? cardBrand,
    String? cardLast4,
  }) =>
      _invoices.doc(invoiceId).update(<String, dynamic>{
        'status': status.id,
        if (method != null) 'method': method.id,
        if (transactionRef != null) 'transactionRef': transactionRef,
        if (cardBrand != null) 'cardBrand': cardBrand,
        if (cardLast4 != null) 'cardLast4': cardLast4,
        if (status == PaymentStatus.paid) 'paidAt': FieldValue.serverTimestamp(),
      });

  // --------------------------------------------------- trust & moderation
  @override
  Future<void> submitReport(UserReport report) => _reports.add(
        report.toMap()..['createdAt'] = FieldValue.serverTimestamp(),
      );

  @override
  Stream<List<UserReport>> watchReports({ReportStatus? status}) {
    Query<Map<String, dynamic>> query = _reports;
    if (status != null) {
      query = query.where('status', isEqualTo: status.id);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    UserReport.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  @override
  Future<void> resolveReport(
    String reportId,
    ReportStatus status, {
    String? note,
  }) =>
      _reports.doc(reportId).update(<String, dynamic>{
        'status': status.id,
        'resolutionNote': note,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> submitVerification(VerificationRequest request) async {
    await _verifications.doc(request.workerId).set(
          request.toMap()
            ..['status'] = 'pending'
            ..['submittedAt'] = FieldValue.serverTimestamp(),
        );
    await _workers.doc(request.workerId).set(
      <String, dynamic>{'verification': 'pending'},
      SetOptions(merge: true),
    );
  }

  @override
  Stream<List<VerificationRequest>> watchVerificationRequests({
    String status = 'pending',
  }) =>
      _verifications
          .where('status', isEqualTo: status)
          .orderBy('submittedAt')
          .snapshots()
          .map(
            (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      VerificationRequest.fromMap(doc.id, doc.data()),
                )
                .toList(),
          );

  @override
  Future<void> decideVerification(
    String workerId, {
    required bool approved,
    required String adminId,
    String? note,
  }) async {
    final WriteBatch batch = _db.batch();
    batch.update(_verifications.doc(workerId), <String, dynamic>{
      'status': approved ? 'approved' : 'rejected',
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
      'note': note,
    });
    batch.set(
      _workers.doc(workerId),
      <String, dynamic>{'verification': approved ? 'approved' : 'rejected'},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // ---------------------------------------------------------------- admin
  @override
  Stream<List<AppUser>> watchUsers({UserRole? role, int limit = 100}) {
    Query<Map<String, dynamic>> query = _users;
    if (role != null) {
      query = query.where('role', isEqualTo: role.id);
    }
    return query.limit(limit).snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    AppUser.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  @override
  Stream<List<Review>> watchReviewsForModeration() => _reviews
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(_reviewsFrom);

  @override
  Future<PlatformStats> fetchStats() async {
    // `stats/platform` is maintained incrementally by Cloud Functions; the
    // live counts below cover the two admin queues, which must never be stale.
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('stats').doc('platform').get();
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    final AggregateQuerySnapshot pending = await _verifications
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    final AggregateQuerySnapshot reports =
        await _reports.where('status', isEqualTo: 'open').count().get();

    Map<String, int> counts(Object? value) {
      if (value is! Map) {
        return const <String, int>{};
      }
      return value.map(
        (Object? key, Object? v) =>
            MapEntry<String, int>('$key', v is num ? v.toInt() : 0),
      );
    }

    return PlatformStats(
      totalUsers: (data['totalUsers'] as num?)?.toInt() ?? 0,
      totalWorkers: (data['totalWorkers'] as num?)?.toInt() ?? 0,
      totalCustomers: (data['totalCustomers'] as num?)?.toInt() ?? 0,
      activeWorkers: (data['activeWorkers'] as num?)?.toInt() ?? 0,
      totalJobs: (data['totalJobs'] as num?)?.toInt() ?? 0,
      completedJobs: (data['completedJobs'] as num?)?.toInt() ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0,
      jobsByCategory: counts(data['jobsByCategory']),
      jobsByDepartment: counts(data['jobsByDepartment']),
      pendingVerifications: pending.count ?? 0,
      openReports: reports.count ?? 0,
    );
  }
}
