class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.webUrl,
    required this.deepLink,
    required this.readAt,
    required this.createdAt,
    required this.payload,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? webUrl;
  final String? deepLink;
  final DateTime? readAt;
  final DateTime? createdAt;
  final Map<String, dynamic> payload;

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: json['body'] as String?,
      webUrl: json['web_url'] as String?,
      deepLink: json['deep_link'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      payload:
          (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
