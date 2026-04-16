class NotificationPreference {
  NotificationPreference({
    required this.type,
    required this.label,
    required this.mailEnabled,
  });

  final String type;
  final String label;
  final bool mailEnabled;

  NotificationPreference copyWith({
    String? type,
    String? label,
    bool? mailEnabled,
  }) {
    return NotificationPreference(
      type: type ?? this.type,
      label: label ?? this.label,
      mailEnabled: mailEnabled ?? this.mailEnabled,
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      type: (json['type'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      mailEnabled: (json['mail_enabled'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'mail_enabled': mailEnabled};
  }
}
