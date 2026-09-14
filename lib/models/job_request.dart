import '../core/utils/json_utils.dart';

enum JobStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const JobStatus(this.id);

  final String id;

  static JobStatus fromId(String? id) => switch (id) {
        'accepted' => JobStatus.accepted,
        'rejected' => JobStatus.rejected,
        'in_progress' => JobStatus.inProgress,
        'completed' => JobStatus.completed,
        'cancelled' => JobStatus.cancelled,
        _ => JobStatus.pending,
      };

  bool get isOpen =>
      this == JobStatus.pending ||
      this == JobStatus.accepted ||
      this == JobStatus.inProgress;
}

enum PaymentMethod {
  moncash('moncash'),
  natcash('natcash'),
  card('card'),
  cash('cash');

  const PaymentMethod(this.id);

  final String id;

  static PaymentMethod fromId(String? id) => switch (id) {
        'natcash' => PaymentMethod.natcash,
        'card' => PaymentMethod.card,
        'cash' => PaymentMethod.cash,
        _ => PaymentMethod.moncash,
      };

  /// Methods that settle through a provider rather than hand to hand.
  bool get isElectronic => this != PaymentMethod.cash;

  /// Methods that need a phone number to charge (the mobile wallets).
  bool get needsPayerPhone =>
      this == PaymentMethod.moncash || this == PaymentMethod.natcash;
}

/// A row in `jobs/{jobId}`: one customer asking one worker for one job.
class JobRequest {
  const JobRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.workerId,
    required this.workerName,
    required this.categoryId,
    this.customCategory,
    required this.description,
    required this.status,
    required this.paymentMethod,
    this.customerPhotoUrl,
    this.workerPhotoUrl,
    this.departmentId,
    this.city,
    this.addressNote = '',
    this.latitude,
    this.longitude,
    this.budget = 0,
    this.agreedPrice,
    this.photoUrls = const <String>[],
    this.scheduledAt,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.reviewId,
    this.invoiceId,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhotoUrl;
  final String workerId;
  final String workerName;
  final String? workerPhotoUrl;
  final String categoryId;

  /// What the customer typed when [categoryId] is `other` — the job is for a
  /// trade the catalog does not list yet.
  final String? customCategory;

  final String description;
  final JobStatus status;
  final PaymentMethod paymentMethod;
  final String? departmentId;
  final String? city;
  final String addressNote;
  final double? latitude;
  final double? longitude;
  final double budget;
  final double? agreedPrice;
  final List<String> photoUrls;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? reviewId;
  final String? invoiceId;

  double get billableAmount => agreedPrice ?? budget;

  factory JobRequest.fromMap(String id, Map<String, dynamic> map) => JobRequest(
        id: id,
        customerId: Json.asString(map['customerId']),
        customerName: Json.asString(map['customerName']),
        customerPhotoUrl: Json.asStringOrNull(map['customerPhotoUrl']),
        workerId: Json.asString(map['workerId']),
        workerName: Json.asString(map['workerName']),
        workerPhotoUrl: Json.asStringOrNull(map['workerPhotoUrl']),
        categoryId: Json.asString(map['categoryId']),
        customCategory: Json.asStringOrNull(map['customCategory']),
        description: Json.asString(map['description']),
        status: JobStatus.fromId(Json.asStringOrNull(map['status'])),
        paymentMethod:
            PaymentMethod.fromId(Json.asStringOrNull(map['paymentMethod'])),
        departmentId: Json.asStringOrNull(map['departmentId']),
        city: Json.asStringOrNull(map['city']),
        addressNote: Json.asString(map['addressNote']),
        latitude: map['latitude'] == null ? null : Json.asDouble(map['latitude']),
        longitude:
            map['longitude'] == null ? null : Json.asDouble(map['longitude']),
        budget: Json.asDouble(map['budget']),
        agreedPrice:
            map['agreedPrice'] == null ? null : Json.asDouble(map['agreedPrice']),
        photoUrls: Json.asStringList(map['photoUrls']),
        scheduledAt: Json.asDateOrNull(map['scheduledAt']),
        createdAt: Json.asDateOrNull(map['createdAt']),
        updatedAt: Json.asDateOrNull(map['updatedAt']),
        completedAt: Json.asDateOrNull(map['completedAt']),
        reviewId: Json.asStringOrNull(map['reviewId']),
        invoiceId: Json.asStringOrNull(map['invoiceId']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'customerId': customerId,
        'customerName': customerName,
        'customerPhotoUrl': customerPhotoUrl,
        'workerId': workerId,
        'workerName': workerName,
        'workerPhotoUrl': workerPhotoUrl,
        'categoryId': categoryId,
        'customCategory': customCategory,
        'description': description,
        'status': status.id,
        'paymentMethod': paymentMethod.id,
        'departmentId': departmentId,
        'city': city,
        'addressNote': addressNote,
        'latitude': latitude,
        'longitude': longitude,
        'budget': budget,
        'agreedPrice': agreedPrice,
        'photoUrls': photoUrls,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'reviewId': reviewId,
        'invoiceId': invoiceId,
      };

  JobRequest copyWith({
    JobStatus? status,
    double? agreedPrice,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? reviewId,
    String? invoiceId,
  }) =>
      JobRequest(
        id: id,
        customerId: customerId,
        customerName: customerName,
        customerPhotoUrl: customerPhotoUrl,
        workerId: workerId,
        workerName: workerName,
        workerPhotoUrl: workerPhotoUrl,
        categoryId: categoryId,
        customCategory: customCategory,
        description: description,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        departmentId: departmentId,
        city: city,
        addressNote: addressNote,
        latitude: latitude,
        longitude: longitude,
        budget: budget,
        agreedPrice: agreedPrice ?? this.agreedPrice,
        photoUrls: photoUrls,
        scheduledAt: scheduledAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        reviewId: reviewId ?? this.reviewId,
        invoiceId: invoiceId ?? this.invoiceId,
      );
}
