import '../core/utils/json_utils.dart';

enum ReviewStatus {
  published('published'),
  pending('pending'),
  hidden('hidden');

  const ReviewStatus(this.id);

  final String id;

  static ReviewStatus fromId(String? id) => switch (id) {
        'pending' => ReviewStatus.pending,
        'hidden' => ReviewStatus.hidden,
        _ => ReviewStatus.published,
      };
}

/// A row in `reviews/{reviewId}`. Written once per completed job; the rating
/// aggregate on `workers/{uid}` is recomputed by a Cloud Function.
class Review {
  const Review({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment = '',
    this.customerPhotoUrl,
    this.status = ReviewStatus.published,
    this.workerReply,
    this.createdAt,
  });

  final String id;
  final String jobId;
  final String workerId;
  final String customerId;
  final String customerName;
  final String? customerPhotoUrl;
  final double rating;
  final String comment;
  final ReviewStatus status;
  final String? workerReply;
  final DateTime? createdAt;

  factory Review.fromMap(String id, Map<String, dynamic> map) => Review(
        id: id,
        jobId: Json.asString(map['jobId']),
        workerId: Json.asString(map['workerId']),
        customerId: Json.asString(map['customerId']),
        customerName: Json.asString(map['customerName']),
        customerPhotoUrl: Json.asStringOrNull(map['customerPhotoUrl']),
        rating: Json.asDouble(map['rating']),
        comment: Json.asString(map['comment']),
        status: ReviewStatus.fromId(Json.asStringOrNull(map['status'])),
        workerReply: Json.asStringOrNull(map['workerReply']),
        createdAt: Json.asDateOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'jobId': jobId,
        'workerId': workerId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'rating': rating,
        'comment': comment,
        'status': status.id,
        'workerReply': workerReply,
        'createdAt': createdAt?.toIso8601String(),
      };

  Review copyWith({ReviewStatus? status, String? workerReply}) => Review(
        id: id,
        jobId: jobId,
        workerId: workerId,
        customerId: customerId,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        rating: rating,
        comment: comment,
        status: status ?? this.status,
        workerReply: workerReply ?? this.workerReply,
        createdAt: createdAt,
      );
}
