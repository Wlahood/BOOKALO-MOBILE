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

  const HomeResponse({
    required this.range,
    required this.filters,
    required this.available,
    required this.events,
    this.currentPage,
    this.lastPage,
    this.total,
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
      currentPage: _asInt(eventsBlock['current_page']),
      lastPage: _asInt(eventsBlock['last_page']),
      total: _asInt(eventsBlock['total']),
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
