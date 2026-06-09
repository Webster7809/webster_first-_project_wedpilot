enum UserRole { couple, vendor, admin }

class User {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.role,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['user_id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: UserRole.values.byName(json['role'] as String),
        isVerified: json['is_verified'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'role': role.name,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
      };
}
