class RegionOption {
  final String name;

  const RegionOption({required this.name});

  factory RegionOption.fromJson(Map<String, dynamic> json) {
    return RegionOption(name: (json['name'] ?? '').toString());
  }
}

class ProvinceOption {
  final String code;
  final String label;

  const ProvinceOption({required this.code, required this.label});

  factory ProvinceOption.fromJson(Map<String, dynamic> json) {
    return ProvinceOption(
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}
