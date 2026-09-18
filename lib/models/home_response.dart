import 'events_page.dart';
import 'location_filters.dart';

class HomeResponse {
  final HomeRange range;
  final HomeFilters filters;
  final HomeAvailable available;
  final List<EventListItem> events;
  final int? currentPage;
  final int? lastPage;
  final int? total;
  final Map<String, dynamic> content;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> featuredBands;
  final List<Map<String, dynamic>> featuredVenues;

  const HomeResponse({
    required this.range,
    required this.filters,
    required this.available,
    required this.events,
    this.currentPage,
    this.lastPage,
    this.total,
    this.content = const {},
    this.stats = const {},
    this.featuredBands = const [],
    this.featuredVenues = const [],
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>? ?? {});
    final eventsBlock = (data['events'] as Map<String, dynamic>? ?? {});
    final eventsList = (eventsBlock['data'] as List? ?? const []);

    return HomeResponse(
      range: HomeRange.fromJson(
        (data['range'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      filters: HomeFilters.fromJson(
        (data['filters'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      available: HomeAvailable.fromJson(
        (data['available'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      events: eventsList
          .map(
            (e) => EventListItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      currentPage: _asInt(
        eventsBlock['meta']?['current_page'] ?? eventsBlock['current_page'],
      ),
      lastPage: _asInt(
        eventsBlock['meta']?['last_page'] ?? eventsBlock['last_page'],
      ),
      total: _asInt(eventsBlock['meta']?['total'] ?? eventsBlock['total']),
      content: Map<String, dynamic>.from(data['home_content'] ?? {}),
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      featuredBands: (data['featured_bands'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      featuredVenues: (data['featured_venues'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}

class HomeRange {
  final String? startDate;
  final String? endDate;

  const HomeRange({this.startDate, this.endDate});

  factory HomeRange.fromJson(Map<String, dynamic> json) {
    return HomeRange(
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }
}

class HomeFilters {
  final int? bandId;
  final int? venueId;
  final String? region;
  final String? provinceCode;

  const HomeFilters({
    this.bandId,
    this.venueId,
    this.region,
    this.provinceCode,
  });

  factory HomeFilters.fromJson(Map<String, dynamic> json) {
    return HomeFilters(
      bandId: _asInt(json['band_id']),
      venueId: _asInt(json['venue_id']),
      region: json['region']?.toString(),
      provinceCode: json['province_code']?.toString(),
    );
  }
}

class HomeAvailable {
  final List<RegionOption> regions;
  final List<ProvinceOption> provinces;

  const HomeAvailable({required this.regions, required this.provinces});

  factory HomeAvailable.fromJson(Map<String, dynamic> json) {
    final regionsJson = (json['regions'] as List? ?? const []);
    final provincesJson = (json['provinces'] as List? ?? const []);

    return HomeAvailable(
      regions: regionsJson
          .map((e) => RegionOption.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      provinces: provincesJson
          .map(
            (e) => ProvinceOption.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value == null) return null;
  return int.tryParse(value.toString());
}
