class SearchResponse {
  final SearchData data;

  SearchResponse({required this.data});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(data: SearchData.fromJson(json['data']));
  }
}

class SearchData {
  final List<SearchEvent> events;
  final List<SearchBand> bands;
  final List<SearchVenue> venues;

  SearchData({required this.events, required this.bands, required this.venues});

  factory SearchData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
      dynamic raw = v;

      // Supporta sia List diretta sia wrapper Laravel ResourceCollection: { "data": [...] }
      if (raw is Map<String, dynamic> && raw['data'] is List) {
        raw = raw['data'];
      }

      final list = (raw as List?) ?? const [];
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return SearchData(
      events: parseList(json['events'], (m) => SearchEvent.fromJson(m)),
      bands: parseList(json['bands'], (m) => SearchBand.fromJson(m)),
      venues: parseList(json['venues'], (m) => SearchVenue.fromJson(m)),
    );
  }
}

class SearchEvent {
  final int id;
  final String title;
  final String? startDatetime;
  final String? venueName;
  final String? locationName;

  SearchEvent({
    required this.id,
    required this.title,
    required this.startDatetime,
    required this.venueName,
    required this.locationName,
  });

  factory SearchEvent.fromJson(Map<String, dynamic> json) {
    return SearchEvent(
      id: json['id'],
      title: json['title'],
      startDatetime: json['start_datetime'] as String?,
      venueName: json['venue']?['name'] as String?,
      locationName: json['location']?['name'] as String?,
    );
  }
}

class SearchBand {
  final int id;
  final String name;

  SearchBand({required this.id, required this.name});

  factory SearchBand.fromJson(Map<String, dynamic> json) {
    return SearchBand(id: json['id'], name: json['name']);
  }
}

class SearchVenue {
  final int id;
  final String name;

  SearchVenue({required this.id, required this.name});

  factory SearchVenue.fromJson(Map<String, dynamic> json) {
    return SearchVenue(id: json['id'], name: json['name']);
  }
}
