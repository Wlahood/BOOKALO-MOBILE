class VenueDetailResponse {
  final VenueDetail data;
  VenueDetailResponse({required this.data});

  factory VenueDetailResponse.fromJson(Map<String, dynamic> json) {
    return VenueDetailResponse(
      data: VenueDetail.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class VenueDetail {
  final int id;
  final String name;
  final bool verified;

  final String? imageUrl;

  final LocationMini? location;

  final VenueAddress address;

  final String? email;
  final String? website;

  final Map<String, String?> socials;
  final String? bio;

  VenueDetail({
    required this.id,
    required this.name,
    required this.verified,
    required this.imageUrl,
    required this.location,
    required this.address,
    required this.email,
    required this.website,
    required this.socials,
    required this.bio,
  });

  factory VenueDetail.fromJson(Map<String, dynamic> json) {
    final profile = (json['profile_image'] as Map?)?.cast<String, dynamic>();
    final loc = json['location'] as Map<String, dynamic>?;

    final addressJson =
        (json['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final contacts = (json['contacts'] as Map?)?.cast<String, dynamic>() ?? {};
    final socials = (json['socials'] as Map?)?.cast<String, dynamic>() ?? {};
    final about = (json['about'] as Map?)?.cast<String, dynamic>() ?? {};

    return VenueDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      verified: (json['verified'] as bool?) ?? false,
      imageUrl: profile?['url'] as String?,
      location: loc == null ? null : LocationMini.fromJson(loc),
      address: VenueAddress.fromJson(addressJson),
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

class VenueAddress {
  final String? street;
  final String? streetNumber;
  final String? postalCode;
  final String? city;
  final String? freeText;

  VenueAddress({
    required this.street,
    required this.streetNumber,
    required this.postalCode,
    required this.city,
    required this.freeText,
  });

  factory VenueAddress.fromJson(Map<String, dynamic> json) {
    return VenueAddress(
      street: json['street'] as String?,
      streetNumber: json['street_number'] as String?,
      postalCode: json['postal_code'] as String?,
      city: json['city'] as String?,
      freeText: json['free_text'] as String?,
    );
  }

  String toOneLine() {
    final parts = <String>[
      if ((street ?? '').trim().isNotEmpty) street!.trim(),
      if ((streetNumber ?? '').trim().isNotEmpty) streetNumber!.trim(),
      if ((postalCode ?? '').trim().isNotEmpty) postalCode!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((freeText ?? '').trim().isNotEmpty) freeText!.trim(),
    ];
    return parts.join(' ');
  }
}
