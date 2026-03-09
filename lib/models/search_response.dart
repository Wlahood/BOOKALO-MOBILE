class SearchResponse {
  final SearchQuery query;
  final List<SearchBandItem> bands;
  final List<SearchVenueItem> venues;
  final List<SearchEventItem> events;

  const SearchResponse({
    required this.query,
    required this.bands,
    required this.venues,
    required this.events,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>? ?? {});

    final bandsList = _extractList(data['bands']);
    final venuesList = _extractList(data['venues']);
    final eventsList = _extractList(data['events']);

    return SearchResponse(
      query: SearchQuery.fromJson(
        (data['query'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      bands: bandsList
          .map(
            (e) => SearchBandItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      venues: venuesList
          .map(
            (e) => SearchVenueItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      events: eventsList
          .map(
            (e) => SearchEventItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

class SearchQuery {
  final String q;
  final String? region;
  final String? provinceCode;
  final String? startDate;
  final String? endDate;
  final int? limit;

  const SearchQuery({
    required this.q,
    this.region,
    this.provinceCode,
    this.startDate,
    this.endDate,
    this.limit,
  });

  factory SearchQuery.fromJson(Map<String, dynamic> json) {
    return SearchQuery(
      q: (json['q'] ?? '').toString(),
      region: json['region']?.toString(),
      provinceCode: json['province_code']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      limit: _asInt(json['limit']),
    );
  }
}

class SearchBandItem {
  final int id;
  final String name;
  final String? city;
  final String? provinceCode;
  final String? region;

  const SearchBandItem({
    required this.id,
    required this.name,
    this.city,
    this.provinceCode,
    this.region,
  });

  factory SearchBandItem.fromJson(Map<String, dynamic> json) {
    final location = (json['location'] as Map<String, dynamic>? ?? {});
    return SearchBandItem(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      city: location['city']?.toString() ?? location['name']?.toString(),
      provinceCode: location['province_code']?.toString(),
      region: location['region']?.toString(),
    );
  }
}

class SearchVenueItem {
  final int id;
  final String name;
  final String? city;
  final String? provinceCode;
  final String? region;
  final String? address;

  const SearchVenueItem({
    required this.id,
    required this.name,
    this.city,
    this.provinceCode,
    this.region,
    this.address,
  });

  factory SearchVenueItem.fromJson(Map<String, dynamic> json) {
    final location = (json['location'] as Map<String, dynamic>? ?? {});
    return SearchVenueItem(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      city: location['city']?.toString() ?? location['name']?.toString(),
      provinceCode: location['province_code']?.toString(),
      region: location['region']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class SearchEventItem {
  final int id;
  final String title;
  final DateTime? start;
  final String? venueName;
  final String? city;
  final String? provinceCode;
  final List<String> bandNames;
  final String? posterImageUrl;

  const SearchEventItem({
    required this.id,
    required this.title,
    required this.start,
    required this.venueName,
    required this.city,
    required this.provinceCode,
    required this.bandNames,
    required this.posterImageUrl,
  });

  factory SearchEventItem.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'] is Map<String, dynamic>
        ? json['venue'] as Map<String, dynamic>
        : null;

    final location = venue?['location'] is Map<String, dynamic>
        ? venue!['location'] as Map<String, dynamic>
        : null;

    final bandsRaw = (json['bands'] as List? ?? const []);

    return SearchEventItem(
      id: _asInt(json['id']) ?? 0,
      title: (json['title'] ?? '').toString(),
      start: json['start_datetime'] != null
          ? DateTime.tryParse(json['start_datetime'].toString())
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
    );
  }
}

List _extractList(dynamic value) {
  if (value is List) return value;

  if (value is Map<String, dynamic>) {
    final inner = value['data'];
    if (inner is List) return inner;
  }

  if (value is Map) {
    final inner = value['data'];
    if (inner is List) return inner;
  }

  return const [];
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value == null) return null;
  return int.tryParse(value.toString());
}
