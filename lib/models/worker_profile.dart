import '../core/utils/json_utils.dart';

enum VerificationStatus {
  unverified('unverified'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const VerificationStatus(this.id);

  final String id;

  static VerificationStatus fromId(String? id) => switch (id) {
        'pending' => VerificationStatus.pending,
        'approved' => VerificationStatus.approved,
        'rejected' => VerificationStatus.rejected,
        _ => VerificationStatus.unverified,
      };
}

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.imageUrl,
    this.caption = '',
    this.categoryId,
    this.uploadedAt,
  });

  final String id;
  final String imageUrl;
  final String caption;
  final String? categoryId;
  final DateTime? uploadedAt;

  factory PortfolioItem.fromMap(Map<String, dynamic> map) => PortfolioItem(
        id: Json.asString(map['id']),
        imageUrl: Json.asString(map['imageUrl']),
        caption: Json.asString(map['caption']),
        categoryId: Json.asStringOrNull(map['categoryId']),
        uploadedAt: Json.asDateOrNull(map['uploadedAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'imageUrl': imageUrl,
        'caption': caption,
        'categoryId': categoryId,
        'uploadedAt': uploadedAt?.toIso8601String(),
      };
}

class Certificate {
  const Certificate({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.issuer = '',
    this.issuedAt,
  });

  final String id;
  final String title;
  final String fileUrl;
  final String issuer;
  final DateTime? issuedAt;

  factory Certificate.fromMap(Map<String, dynamic> map) => Certificate(
        id: Json.asString(map['id']),
        title: Json.asString(map['title']),
        fileUrl: Json.asString(map['fileUrl']),
        issuer: Json.asString(map['issuer']),
        issuedAt: Json.asDateOrNull(map['issuedAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'fileUrl': fileUrl,
        'issuer': issuer,
        'issuedAt': issuedAt?.toIso8601String(),
      };
}

/// A row in `workers/{uid}`: the public, searchable half of a worker account.
///
/// Sensitive verification artefacts (the ID scan) are never stored here — only
/// the resulting status — so the document can stay world-readable.
class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    required this.categoryIds,
    required this.departmentId,
    required this.city,
    this.headline = '',
    this.bio = '',
    this.photoUrl,
    this.phone,
    this.hourlyRate = 0,
    this.currency = 'HTG',
    this.rating = 0,
    this.reviewCount = 0,
    this.jobsCompleted = 0,
    this.yearsExperience = 0,
    this.verification = VerificationStatus.unverified,
    this.availableNow = false,
    this.serviceDepartmentIds = const <String>[],
    this.serviceCities = const <String>[],
    this.portfolio = const <PortfolioItem>[],
    this.certificates = const <Certificate>[],
    this.latitude,
    this.longitude,
    this.acceptedPaymentMethods = const <String>['moncash', 'natcash', 'cash'],
    this.suspended = false,
    this.createdAt,
    this.distanceKm,
  });

  final String id;
  final String fullName;
  final List<String> categoryIds;
  final String departmentId;
  final String city;
  final String headline;
  final String bio;
  final String? photoUrl;
  final String? phone;
  final double hourlyRate;
  final String currency;
  final double rating;
  final int reviewCount;
  final int jobsCompleted;
  final int yearsExperience;
  final VerificationStatus verification;
  final bool availableNow;
  final List<String> serviceDepartmentIds;
  final List<String> serviceCities;
  final List<PortfolioItem> portfolio;
  final List<Certificate> certificates;
  final double? latitude;
  final double? longitude;
  final List<String> acceptedPaymentMethods;
  final bool suspended;
  final DateTime? createdAt;

  /// Computed client-side against the customer's position; never persisted.
  final double? distanceKm;

  bool get isVerified => verification == VerificationStatus.approved;

  factory WorkerProfile.fromMap(String id, Map<String, dynamic> map) =>
      WorkerProfile(
        id: id,
        fullName: Json.asString(map['fullName']),
        categoryIds: Json.asStringList(map['categoryIds']),
        departmentId: Json.asString(map['departmentId']),
        city: Json.asString(map['city']),
        headline: Json.asString(map['headline']),
        bio: Json.asString(map['bio']),
        photoUrl: Json.asStringOrNull(map['photoUrl']),
        phone: Json.asStringOrNull(map['phone']),
        hourlyRate: Json.asDouble(map['hourlyRate']),
        currency: Json.asString(map['currency'], fallback: 'HTG'),
        rating: Json.asDouble(map['rating']),
        reviewCount: Json.asInt(map['reviewCount']),
        jobsCompleted: Json.asInt(map['jobsCompleted']),
        yearsExperience: Json.asInt(map['yearsExperience']),
        verification:
            VerificationStatus.fromId(Json.asStringOrNull(map['verification'])),
        availableNow: Json.asBool(map['availableNow']),
        serviceDepartmentIds: Json.asStringList(map['serviceDepartmentIds']),
        serviceCities: Json.asStringList(map['serviceCities']),
        portfolio: Json.asMapList(map['portfolio'])
            .map(PortfolioItem.fromMap)
            .toList(),
        certificates: Json.asMapList(map['certificates'])
            .map(Certificate.fromMap)
            .toList(),
        latitude: map['latitude'] == null ? null : Json.asDouble(map['latitude']),
        longitude:
            map['longitude'] == null ? null : Json.asDouble(map['longitude']),
        acceptedPaymentMethods: Json.asStringList(map['acceptedPaymentMethods'])
            .isEmpty
            ? const <String>['moncash', 'natcash', 'cash']
            : Json.asStringList(map['acceptedPaymentMethods']),
        suspended: Json.asBool(map['suspended']),
        createdAt: Json.asDateOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fullName': fullName,
        'categoryIds': categoryIds,
        'departmentId': departmentId,
        'city': city,
        'headline': headline,
        'bio': bio,
        'photoUrl': photoUrl,
        'phone': phone,
        'hourlyRate': hourlyRate,
        'currency': currency,
        'rating': rating,
        'reviewCount': reviewCount,
        'jobsCompleted': jobsCompleted,
        'yearsExperience': yearsExperience,
        'verification': verification.id,
        'availableNow': availableNow,
        'serviceDepartmentIds': serviceDepartmentIds,
        'serviceCities': serviceCities,
        'portfolio':
            portfolio.map((PortfolioItem item) => item.toMap()).toList(),
        'certificates':
            certificates.map((Certificate item) => item.toMap()).toList(),
        'latitude': latitude,
        'longitude': longitude,
        'acceptedPaymentMethods': acceptedPaymentMethods,
        'suspended': suspended,
        'createdAt': createdAt?.toIso8601String(),
      };

  WorkerProfile copyWith({
    String? fullName,
    List<String>? categoryIds,
    String? departmentId,
    String? city,
    String? headline,
    String? bio,
    String? photoUrl,
    String? phone,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    int? jobsCompleted,
    int? yearsExperience,
    VerificationStatus? verification,
    bool? availableNow,
    List<String>? serviceDepartmentIds,
    List<String>? serviceCities,
    List<PortfolioItem>? portfolio,
    List<Certificate>? certificates,
    double? latitude,
    double? longitude,
    List<String>? acceptedPaymentMethods,
    bool? suspended,
    double? distanceKm,
  }) =>
      WorkerProfile(
        id: id,
        fullName: fullName ?? this.fullName,
        categoryIds: categoryIds ?? this.categoryIds,
        departmentId: departmentId ?? this.departmentId,
        city: city ?? this.city,
        headline: headline ?? this.headline,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        phone: phone ?? this.phone,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        currency: currency,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        jobsCompleted: jobsCompleted ?? this.jobsCompleted,
        yearsExperience: yearsExperience ?? this.yearsExperience,
        verification: verification ?? this.verification,
        availableNow: availableNow ?? this.availableNow,
        serviceDepartmentIds: serviceDepartmentIds ?? this.serviceDepartmentIds,
        serviceCities: serviceCities ?? this.serviceCities,
        portfolio: portfolio ?? this.portfolio,
        certificates: certificates ?? this.certificates,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        acceptedPaymentMethods:
            acceptedPaymentMethods ?? this.acceptedPaymentMethods,
        suspended: suspended ?? this.suspended,
        createdAt: createdAt,
        distanceKm: distanceKm ?? this.distanceKm,
      );
}
