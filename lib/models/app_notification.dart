import '../core/utils/json_utils.dart';

enum NotificationType {
  jobRequest('job_request'),
  jobAccepted('job_accepted'),
  jobRejected('job_rejected'),
  message('message'),
  review('review'),
  verification('verification'),
  payment('payment');

  const NotificationType(this.id);

  final String id;

  static NotificationType fromId(String? id) => switch (id) {
        'job_accepted' => NotificationType.jobAccepted,
        'job_rejected' => NotificationType.jobRejected,
        'message' => NotificationType.message,
        'review' => NotificationType.review,
        'verification' => NotificationType.verification,
        'payment' => NotificationType.payment,
        _ => NotificationType.jobRequest,
      };
}

/// A row in `users/{uid}/notifications/{id}`.
///
/// The body is stored as a catalog key plus arguments rather than rendered
/// text, so a notification written while the user read French still renders in
/// Kreyòl once they switch language.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.messageKey,
    this.args = const <String, String>{},
    this.jobId,
    this.conversationId,
    this.workerId,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String messageKey;
  final Map<String, String> args;
  final String? jobId;
  final String? conversationId;
  final String? workerId;
  final bool read;
  final DateTime? createdAt;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        type: NotificationType.fromId(Json.asStringOrNull(map['type'])),
        messageKey: Json.asString(map['messageKey']),
        args: Json.asMap(map['args']).map(
          (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
        ),
        jobId: Json.asStringOrNull(map['jobId']),
        conversationId: Json.asStringOrNull(map['conversationId']),
        workerId: Json.asStringOrNull(map['workerId']),
        read: Json.asBool(map['read']),
        createdAt: Json.asDateOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type.id,
        'messageKey': messageKey,
        'args': args,
        'jobId': jobId,
        'conversationId': conversationId,
        'workerId': workerId,
        'read': read,
        'createdAt': createdAt?.toIso8601String(),
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        messageKey: messageKey,
        args: args,
        jobId: jobId,
        conversationId: conversationId,
        workerId: workerId,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
