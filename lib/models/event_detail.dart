class EventDetailResponse {
  final EventDetail data;

  EventDetailResponse({required this.data});

  factory EventDetailResponse.fromJson(Map<String, dynamic> json) {
    return EventDetailResponse(data: EventDetail.fromJson(json['data']));
  }
}

class EventDetail {
  final int id;
  final String title;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final VenueDetail? venue;
  final List<BandMini> bands;
  final String webUrl;

  EventDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.venue,
    required this.bands,
    required this.webUrl,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      start: json['start_datetime'] != null
          ? DateTime.parse(json['start_datetime'])
          : null,
      end: json['end_datetime'] != null
          ? DateTime.parse(json['end_datetime'])
          : null,
      venue: json['venue'] != null ? VenueDetail.fromJson(json['venue']) : null,
      bands: (json['bands'] as List? ?? [])
          .map((e) => BandMini.fromJson(e))
          .toList(),
      webUrl: json['links']?['web_url'] ?? '',
    );
  }
}

class VenueDetail {
  final int id;
  final String name;
  final LocationDetail? location;

  VenueDetail({required this.id, required this.name, required this.location});

  factory VenueDetail.fromJson(Map<String, dynamic> json) {
    return VenueDetail(
      id: json['id'],
      name: json['name'],
      location: json['location'] != null
          ? LocationDetail.fromJson(json['location'])
          : null,
    );
  }
}

class LocationDetail {
  final String? name;
  final String? region;
  final String? provinceCode;
  final double? lat;
  final double? lng;

  LocationDetail({
    this.name,
    this.region,
    this.provinceCode,
    this.lat,
    this.lng,
  });

  factory LocationDetail.fromJson(Map<String, dynamic> json) {
    double? parse(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return LocationDetail(
      name: json['name'],
      region: json['region'],
      provinceCode: json['province_code'],
      lat: parse(json['lat']),
      lng: parse(json['lng']),
    );
  }
}

class BandMini {
  final int id;
  final String name;

  BandMini({required this.id, required this.name});

  factory BandMini.fromJson(Map<String, dynamic> json) {
    return BandMini(id: json['id'], name: json['name']);
  }
}
