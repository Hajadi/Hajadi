import '../core/utils/json_utils.dart';

enum ReportReason {
  spam('spam'),
  fraud('fraud'),
  abuse('abuse'),
  fake('fake'),
  other('other');

  const ReportReason(this.id);

  final String id;

  static ReportReason fromId(String? id) => switch (id) {
        'fraud' => ReportReason.fraud,
        'abuse' => ReportReason.abuse,
        'fake' => ReportReason.fake,
        'other' => ReportReason.other,
        _ => ReportReason.spam,
      };
}

enum ReportStatus {
  open('open'),
  resolved('resolved'),
  dismissed('dismissed');

  const ReportStatus(this.id);

  final String id;

  static ReportStatus fromId(String? id) => switch (id) {
        'resolved' => ReportStatus.resolved,
        'dismissed' => ReportStatus.dismissed,
        _ => ReportStatus.open,
      };
}

/// A row in `reports/{reportId}`. Only admins can read the collection.
class UserReport {
  const UserReport({
    required this.id,
    required this.reporterId,
    required this.targetUserId,
    required this.reason,
    this.targetName = '',
    this.details = '',
    this.reviewId,
    this.jobId,
    this.status = ReportStatus.open,
    this.createdAt,
    this.resolvedAt,
    this.resolutionNote,
  });

  final String id;
  final String reporterId;
  final String targetUserId;
  final String targetName;
  final ReportReason reason;
  final String details;
  final String? reviewId;
  final String? jobId;
  final ReportStatus status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;

  factory UserReport.fromMap(String id, Map<String, dynamic> map) => UserReport(
        id: id,
        reporterId: Json.asString(map['reporterId']),
        targetUserId: Json.asString(map['targetUserId']),
        targetName: Json.asString(map['targetName']),
        reason: ReportReason.fromId(Json.asStringOrNull(map['reason'])),
        details: Json.asString(map['details']),
        reviewId: Json.asStringOrNull(map['reviewId']),
        jobId: Json.asStringOrNull(map['jobId']),
        status: ReportStatus.fromId(Json.asStringOrNull(map['status'])),
        createdAt: Json.asDateOrNull(map['createdAt']),
        resolvedAt: Json.asDateOrNull(map['resolvedAt']),
        resolutionNote: Json.asStringOrNull(map['resolutionNote']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'reporterId': reporterId,
        'targetUserId': targetUserId,
        'targetName': targetName,
        'reason': reason.id,
        'details': details,
        'reviewId': reviewId,
        'jobId': jobId,
        'status': status.id,
        'createdAt': createdAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'resolutionNote': resolutionNote,
      };

  UserReport copyWith({
    ReportStatus? status,
    DateTime? resolvedAt,
    String? resolutionNote,
  }) =>
      UserReport(
        id: id,
        reporterId: reporterId,
        targetUserId: targetUserId,
        targetName: targetName,
        reason: reason,
        details: details,
        reviewId: reviewId,
        jobId: jobId,
        status: status ?? this.status,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        resolutionNote: resolutionNote ?? this.resolutionNote,
      );
}

/// A row in `verificationRequests/{uid}` — the admin work queue for identity
/// checks. ID images live in a Storage path only admins can read.
class VerificationRequest {
  const VerificationRequest({
    required this.workerId,
    required this.workerName,
    required this.idDocumentUrl,
    this.idType = 'cin',
    this.certificateUrls = const <String>[],
    this.status = 'pending',
    this.note,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String workerId;
  final String workerName;
  final String idDocumentUrl;
  final String idType;
  final List<String> certificateUrls;
  final String status;
  final String? note;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  factory VerificationRequest.fromMap(String id, Map<String, dynamic> map) =>
      VerificationRequest(
        workerId: id,
        workerName: Json.asString(map['workerName']),
        idDocumentUrl: Json.asString(map['idDocumentUrl']),
        idType: Json.asString(map['idType'], fallback: 'cin'),
        certificateUrls: Json.asStringList(map['certificateUrls']),
        status: Json.asString(map['status'], fallback: 'pending'),
        note: Json.asStringOrNull(map['note']),
        submittedAt: Json.asDateOrNull(map['submittedAt']),
        reviewedAt: Json.asDateOrNull(map['reviewedAt']),
        reviewedBy: Json.asStringOrNull(map['reviewedBy']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'workerName': workerName,
        'idDocumentUrl': idDocumentUrl,
        'idType': idType,
        'certificateUrls': certificateUrls,
        'status': status,
        'note': note,
        'submittedAt': submittedAt?.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewedBy': reviewedBy,
      };
}
