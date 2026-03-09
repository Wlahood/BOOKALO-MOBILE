class EventDetailResponse {
  final EventDetail data;

  EventDetailResponse({required this.data});

  factory EventDetailResponse.fromJson(Map<String, dynamic> json) {
    return EventDetailResponse(
      data: EventDetail.fromJson((json['data'] as Map).cast<String, dynamic>()),
    );
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
  final String? posterImageUrl;
  final String? facebookUrl;
  final String? instagramUrl;

  EventDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.venue,
    required this.bands,
    required this.webUrl,
    required this.posterImageUrl,
    required this.facebookUrl,
    required this.instagramUrl,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    return EventDetail(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      start: json['start_datetime'] != null
          ? DateTime.tryParse(json['start_datetime'].toString())
          : null,
      end: json['end_datetime'] != null
          ? DateTime.tryParse(json['end_datetime'].toString())
          : null,
      venue: json['venue'] != null
          ? VenueDetail.fromJson((json['venue'] as Map).cast<String, dynamic>())
          : null,
      bands: (json['bands'] as List? ?? const [])
          .map((e) => BandMini.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      webUrl: json['links']?['web_url']?.toString() ?? '',
      posterImageUrl: json['poster_image_url']?.toString(),
      facebookUrl: json['facebook_url']?.toString(),
      instagramUrl: json['instagram_url']?.toString(),
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
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      location: json['location'] != null
          ? LocationDetail.fromJson(
              (json['location'] as Map).cast<String, dynamic>(),
            )
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
      name: json['name']?.toString(),
      region: json['region']?.toString(),
      provinceCode: json['province_code']?.toString(),
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
    return BandMini(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
    );
  }
}
