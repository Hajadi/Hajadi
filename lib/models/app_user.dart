import '../core/utils/json_utils.dart';

enum UserRole {
  customer('customer'),
  worker('worker'),
  admin('admin');

  const UserRole(this.id);

  final String id;

  static UserRole fromId(String? id) => switch (id) {
        'worker' => UserRole.worker,
        'admin' => UserRole.admin,
        _ => UserRole.customer,
      };
}

enum AccountStatus {
  active('active'),
  suspended('suspended'),
  deleted('deleted');

  const AccountStatus(this.id);

  final String id;

  static AccountStatus fromId(String? id) => switch (id) {
        'suspended' => AccountStatus.suspended,
        'deleted' => AccountStatus.deleted,
        _ => AccountStatus.active,
      };
}

/// A row in `users/{uid}` — identity only. Trade details live in
/// `workers/{uid}` so a customer document stays small and cheap to sync.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.photoUrl,
    this.languageCode = 'ht',
    this.departmentId,
    this.city,
    this.latitude,
    this.longitude,
    this.phoneVerified = false,
    this.status = AccountStatus.active,
    this.favoriteWorkerIds = const <String>[],
    this.fcmTokens = const <String>[],
    this.createdAt,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String languageCode;
  final String? departmentId;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool phoneVerified;
  final AccountStatus status;
  final List<String> favoriteWorkerIds;
  final List<String> fcmTokens;
  final DateTime? createdAt;

  bool get isWorker => role == UserRole.worker;
  bool get isAdmin => role == UserRole.admin;
  bool get isSuspended => status == AccountStatus.suspended;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        fullName: Json.asString(map['fullName']),
        role: UserRole.fromId(Json.asStringOrNull(map['role'])),
        email: Json.asStringOrNull(map['email']),
        phone: Json.asStringOrNull(map['phone']),
        photoUrl: Json.asStringOrNull(map['photoUrl']),
        languageCode: Json.asString(map['languageCode'], fallback: 'ht'),
        departmentId: Json.asStringOrNull(map['departmentId']),
        city: Json.asStringOrNull(map['city']),
        latitude: map['latitude'] == null ? null : Json.asDouble(map['latitude']),
        longitude:
            map['longitude'] == null ? null : Json.asDouble(map['longitude']),
        phoneVerified: Json.asBool(map['phoneVerified']),
        status: AccountStatus.fromId(Json.asStringOrNull(map['status'])),
        favoriteWorkerIds: Json.asStringList(map['favoriteWorkerIds']),
        fcmTokens: Json.asStringList(map['fcmTokens']),
        createdAt: Json.asDateOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fullName': fullName,
        'role': role.id,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'languageCode': languageCode,
        'departmentId': departmentId,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'phoneVerified': phoneVerified,
        'status': status.id,
        'favoriteWorkerIds': favoriteWorkerIds,
        'fcmTokens': fcmTokens,
        'createdAt': createdAt?.toIso8601String(),
      };

  AppUser copyWith({
    String? fullName,
    UserRole? role,
    String? email,
    String? phone,
    String? photoUrl,
    String? languageCode,
    String? departmentId,
    String? city,
    double? latitude,
    double? longitude,
    bool? phoneVerified,
    AccountStatus? status,
    List<String>? favoriteWorkerIds,
    List<String>? fcmTokens,
    DateTime? createdAt,
  }) =>
      AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        languageCode: languageCode ?? this.languageCode,
        departmentId: departmentId ?? this.departmentId,
        city: city ?? this.city,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        phoneVerified: phoneVerified ?? this.phoneVerified,
        status: status ?? this.status,
        favoriteWorkerIds: favoriteWorkerIds ?? this.favoriteWorkerIds,
        fcmTokens: fcmTokens ?? this.fcmTokens,
        createdAt: createdAt ?? this.createdAt,
      );
}
