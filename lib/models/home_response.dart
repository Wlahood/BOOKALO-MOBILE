// lib/models/home_response.dart
class HomeResponse {
  final HomeData data;
  HomeResponse({required this.data});

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      data: HomeData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class HomeData {
  final DateRange range;
  final HomeFilters filters;
  final HomeAvailable available;
  final PaginatedEvents events;

  HomeData({
    required this.range,
    required this.filters,
    required this.available,
    required this.events,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      range: DateRange.fromJson(json['range']),
      filters: HomeFilters.fromJson(json['filters']),
      available: HomeAvailable.fromJson(json['available']),
      events: PaginatedEvents.fromJson(json['events']),
    );
  }
}

class DateRange {
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  DateRange({required this.startDate, required this.endDate});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
    );
  }
}

class HomeFilters {
  final int? bandId;
  final int? venueId;
  final String? provinceCode;
  final String? city;

  HomeFilters({this.bandId, this.venueId, this.provinceCode, this.city});

  factory HomeFilters.fromJson(Map<String, dynamic> json) {
    return HomeFilters(
      bandId: json['band_id'] as int?,
      venueId: json['venue_id'] as int?,
      provinceCode: json['province_code'] as String?,
      city: json['city'] as String?,
    );
  }
}

class HomeAvailable {
  final List<String> provinces;
  final List<String> cities;

  HomeAvailable({required this.provinces, required this.cities});

  factory HomeAvailable.fromJson(Map<String, dynamic> json) {
    return HomeAvailable(
      provinces: (json['provinces'] as List).cast<String>(),
      cities: (json['cities'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class PaginatedEvents {
  final List<EventCompact> data;
  final PaginationMeta meta;
  final PaginationLinks links;

  PaginatedEvents({
    required this.data,
    required this.meta,
    required this.links,
  });

  factory PaginatedEvents.fromJson(Map<String, dynamic> json) {
    return PaginatedEvents(
      data: (json['data'] as List)
          .map((e) => EventCompact.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
      links: PaginationLinks.fromJson(json['links'] as Map<String, dynamic>),
    );
  }
}

class PaginationLinks {
  final String? next;
  final String? prev;
  PaginationLinks({this.next, this.prev});

  factory PaginationLinks.fromJson(Map<String, dynamic> json) {
    return PaginationLinks(
      next: json['next'] as String?,
      prev: json['prev'] as String?,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }
}

class EventCompact {
  final int id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final VenueMini? venue;
  final List<BandMini> bands;
  final String webUrl;

  EventCompact({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.venue,
    required this.bands,
    required this.webUrl,
  });

  factory EventCompact.fromJson(Map<String, dynamic> json) {
    return EventCompact(
      id: json['id'] as int,
      title: json['title'] as String,
      start: json['start_datetime'] != null
          ? DateTime.parse(json['start_datetime'])
          : null,
      end: json['end_datetime'] != null
          ? DateTime.parse(json['end_datetime'])
          : null,
      venue: json['venue'] != null ? VenueMini.fromJson(json['venue']) : null,
      bands: (json['bands'] as List? ?? const [])
          .map((e) => BandMini.fromJson(e as Map<String, dynamic>))
          .toList(),
      webUrl: (json['links']?['web_url'] as String?) ?? '',
    );
  }
}

class VenueMini {
  final int? id;
  final String? name;
  final LocationMini? location;

  VenueMini({this.id, this.name, this.location});

  factory VenueMini.fromJson(Map<String, dynamic> json) {
    return VenueMini(
      id: json['id'] as int?,
      name: json['name'] as String?,
      location: json['location'] != null
          ? LocationMini.fromJson(json['location'])
          : null,
    );
  }
}

class LocationMini {
  final int? id;
  final String? name; // city
  final String? region;
  final String? provinceCode;

  LocationMini({this.id, this.name, this.region, this.provinceCode});

  factory LocationMini.fromJson(Map<String, dynamic> json) {
    return LocationMini(
      id: json['id'] as int?,
      name: json['name'] as String?,
      region: json['region'] as String?,
      provinceCode: json['province_code'] as String?,
    );
  }
}

class BandMini {
  final int id;
  final String name;
  BandMini({required this.id, required this.name});

  factory BandMini.fromJson(Map<String, dynamic> json) {
    return BandMini(id: json['id'] as int, name: json['name'] as String);
  }
}
