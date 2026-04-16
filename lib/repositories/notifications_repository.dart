import '../models/notification_item.dart';
import '../models/notification_preference.dart';
import '../services/api_client.dart';

class NotificationsRepository {
  NotificationsRepository(this.api);

  final ApiClient api;

  Future<List<NotificationItem>> fetchNotifications({int perPage = 20}) async {
    final json = await api.getJson(
      '/me/notifications',
      query: {'per_page': '$perPage'},
    );

    final items = (json['data'] as List<dynamic>? ?? const []);
    return items
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final json = await api.getJson('/me/notifications/unread-count');
    return (json['unread_count'] as num? ?? 0).toInt();
  }

  Future<NotificationItem> markAsRead(String notificationId) async {
    final json = await api.postJson('/me/notifications/$notificationId/read');
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return NotificationItem.fromJson(data);
  }

  Future<void> markAllAsRead() async {
    await api.postJson('/me/notifications/read-all');
  }

  Future<List<NotificationPreference>> fetchPreferences() async {
    final json = await api.getJson('/me/notification-preferences');
    final items = (json['data'] as List<dynamic>? ?? const []);
    return items
        .map((e) => NotificationPreference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePreferences(
    List<NotificationPreference> preferences,
  ) async {
    await api.putJson(
      '/me/notification-preferences',
      body: {'preferences': preferences.map((e) => e.toJson()).toList()},
    );
  }
}
