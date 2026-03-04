class MyEntity {
  MyEntity({
    required this.id,
    required this.name,
    this.slug,
    this.role,
    required this.type, // "band" | "venue"
  });

  final int id;
  final String name;
  final String? slug;
  final String? role;
  final String type;

  factory MyEntity.fromJson(Map<String, dynamic> json, {required String type}) {
    return MyEntity(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      slug: json['slug'] as String?,
      role: json['role'] as String?,
      type: type,
    );
  }
}
