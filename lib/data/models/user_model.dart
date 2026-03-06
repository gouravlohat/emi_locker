import 'package:equatable/equatable.dart';

enum UserRole { admin, agent, customer }

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  // Real API field names:
  //   Client user: { _id, fullName, mobile, email, status (optional), createdAt }
  //   Admin user:  { _id, name, email, mobile, role, status (1|0), createdAt }
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        // client users have 'fullName'; admins/agents have 'name'
        name: json['fullName'] as String? ?? json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        // client users have 'mobile'; fall back to 'phone'
        phone: json['mobile'] as String? ?? json['phone'] as String? ?? '',
        role: _parseRole(json['role'] as String?),
        avatarUrl: json['avatar_url'] as String?,
        // status field: 1 = active, 0 = blocked (admins/agents); absent for clients
        isActive: json['status'] != null
            ? (json['status'] as int?) == 1
            : json['is_active'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String)
                : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'mobile': phone,
        'role': role.name,
        'is_active': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };

  static UserRole _parseRole(String? raw) => switch (raw?.toLowerCase()) {
        'admin' || 'superadmin' => UserRole.admin,
        'agent' => UserRole.agent,
        _ => UserRole.customer,
      };

  String get roleLabel => switch (role) {
        UserRole.admin => 'Administrator',
        UserRole.agent => 'Field Agent',
        UserRole.customer => 'Customer',
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isAgent => role == UserRole.agent;
  bool get isCustomer => role == UserRole.customer;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, email, phone, role, isActive];
}

class AuthResponse {
  final String accessToken;
  final UserModel user;
  final bool deviceLocked;

  const AuthResponse({
    required this.accessToken,
    required this.user,
    this.deviceLocked = false,
  });

  // Real API login response (already unwrapped from { success, data: {...} }):
  //   { token, user: {...}, deviceLocked: bool }
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        deviceLocked: json['deviceLocked'] as bool? ?? false,
      );
}
