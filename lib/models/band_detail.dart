class BandDetailResponse {
  final BandDetail data;
  BandDetailResponse({required this.data});

  factory BandDetailResponse.fromJson(Map<String, dynamic> json) {
    return BandDetailResponse(
      data: BandDetail.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class BandDetail {
  final int id;
  final String name;
  final bool verified;

  final String? imageUrl;

  final LocationMini? location;
  final List<GenreMini> genres;

  final String? email;
  final String? website;

  final Map<String, String?> socials;
  final String? bio;

  BandDetail({
    required this.id,
    required this.name,
    required this.verified,
    required this.imageUrl,
    required this.location,
    required this.genres,
    required this.email,
    required this.website,
    required this.socials,
    required this.bio,
  });

  factory BandDetail.fromJson(Map<String, dynamic> json) {
    final profile = (json['profile_image'] as Map?)?.cast<String, dynamic>();
    final loc = json['location'] as Map<String, dynamic>?;
    final genresJson = (json['genres'] as List?) ?? const [];

    final contacts = (json['contacts'] as Map?)?.cast<String, dynamic>() ?? {};
    final socials = (json['socials'] as Map?)?.cast<String, dynamic>() ?? {};
    final about = (json['about'] as Map?)?.cast<String, dynamic>() ?? {};

    return BandDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      verified: (json['verified'] as bool?) ?? false,
      imageUrl: profile?['url'] as String?,
      location: loc == null ? null : LocationMini.fromJson(loc),
      genres: genresJson
          .map((e) => GenreMini.fromJson(e as Map<String, dynamic>))
          .toList(),
      email: contacts['email'] as String?,
      website: contacts['website'] as String?,
      socials: socials.map((k, v) => MapEntry(k, v as String?)),
      bio: about['bio'] as String?,
    );
  }
}

class LocationMini {
  final int id;
  final String name;
  final String? region;
  final String? provinceCode;

  LocationMini({
    required this.id,
    required this.name,
    required this.region,
    required this.provinceCode,
  });

  factory LocationMini.fromJson(Map<String, dynamic> json) {
    return LocationMini(
      id: json['id'] as int,
      name: json['name'] as String,
      region: json['region'] as String?,
      provinceCode: json['province_code'] as String?,
    );
  }
}

class GenreMini {
  final int id;
  final String name;

  GenreMini({required this.id, required this.name});

  factory GenreMini.fromJson(Map<String, dynamic> json) {
    return GenreMini(id: json['id'] as int, name: json['name'] as String);
  }
}
