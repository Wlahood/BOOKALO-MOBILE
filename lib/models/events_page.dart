// lib/models/events_page.dart

class EventsPageResponse {
  final List<EventListItem> data;
  final EventsPageMeta? meta;

  EventsPageResponse({required this.data, required this.meta});

  factory EventsPageResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List? ?? const []);
    return EventsPageResponse(
      data: list
          .map((e) => EventListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] is Map<String, dynamic>
          ? EventsPageMeta.fromJson(json['meta'])
          : null,
    );
  }
}

class EventsPageMeta {
  final int currentPage;
  final int lastPage;
  final int total;

  EventsPageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory EventsPageMeta.fromJson(Map<String, dynamic> json) {
    return EventsPageMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
    );
  }
}

class EventListItem {
  final int id;
  final String title;
  final DateTime? start;
  final DateTime? end;

  final String? venueName;
  final String? city;
  final String webUrl;

  EventListItem({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.venueName,
    required this.city,
    required this.webUrl,
  });

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'] as Map<String, dynamic>?;
    final location = venue?['location'] as Map<String, dynamic>?;

    return EventListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      start: json['start_datetime'] != null
          ? DateTime.tryParse(json['start_datetime'])
          : null,
      end: json['end_datetime'] != null
          ? DateTime.tryParse(json['end_datetime'])
          : null,
      venueName: venue?['name'] as String?,
      city: (location?['name'] as String?) ?? (location?['city'] as String?),
      webUrl: (json['links']?['web_url'] as String?) ?? '',
    );
  }
}
