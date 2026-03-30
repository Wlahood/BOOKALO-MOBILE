class LocationOption {
  final int id;
  final String code;
  final String label;

  const LocationOption({
    required this.id,
    required this.code,
    required this.label,
  });

  factory LocationOption.fromJson(Map<String, dynamic> json) {
    return LocationOption(
      id: (json['id'] as num).toInt(),
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}
