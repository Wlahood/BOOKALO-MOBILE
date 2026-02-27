class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String? role;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: json['role'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
