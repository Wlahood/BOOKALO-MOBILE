class EventsPageResponse {
  final List<EventListItem> data;
  final EventsPageMeta? meta;

  EventsPageResponse({required this.data, required this.meta});

  factory EventsPageResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List? ?? const []);
    return EventsPageResponse(
      data: list
          .map(
            (e) => EventListItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      meta: json['meta'] is Map<String, dynamic>
          ? EventsPageMeta.fromJson(json['meta'] as Map<String, dynamic>)
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
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      total: _asInt(json['total']) ?? 0,
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
  final String? provinceCode;
  final List<String> bandNames;
  final String? posterImageUrl;
  final String webUrl;

  EventListItem({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.venueName,
    required this.city,
    required this.provinceCode,
    required this.bandNames,
    required this.posterImageUrl,
    required this.webUrl,
  });

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'] is Map<String, dynamic>
        ? json['venue'] as Map<String, dynamic>
        : null;

    final location = venue?['location'] is Map<String, dynamic>
        ? venue!['location'] as Map<String, dynamic>
        : null;

    final bandsRaw = (json['bands'] as List? ?? const []);

    return EventListItem(
      id: _asInt(json['id']) ?? 0,
      title: (json['title'] ?? '').toString(),
      start: json['start_datetime'] != null
          ? DateTime.tryParse(json['start_datetime'].toString())
          : null,
      end: json['end_datetime'] != null
          ? DateTime.tryParse(json['end_datetime'].toString())
          : null,
      venueName: venue?['name']?.toString(),
      city: location?['name']?.toString() ?? location?['city']?.toString(),
      provinceCode: location?['province_code']?.toString(),
      bandNames: bandsRaw
          .map((e) {
            if (e is Map<String, dynamic>) return (e['name'] ?? '').toString();
            if (e is Map) return (e['name'] ?? '').toString();
            return '';
          })
          .where((name) => name.trim().isNotEmpty)
          .toList(),
      posterImageUrl: json['poster_image_url']?.toString(),
      webUrl: (json['links'] is Map
          ? (json['links']['web_url'] ?? '').toString()
          : ''),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value == null) return null;
  return int.tryParse(value.toString());
}
