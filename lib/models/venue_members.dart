class VenueMembersResponse {
  final VenueMembersData data;

  VenueMembersResponse({required this.data});

  factory VenueMembersResponse.fromJson(Map<String, dynamic> json) {
    return VenueMembersResponse(
      data: VenueMembersData.fromJson(
        (json['data'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}

class VenueMembersData {
  final VenueMembersVenue venue;
  final List<VenueMemberItem> members;
  final List<VenueInviteItem> pendingInvites;
  final List<String> assignableRoles;
  final List<String> invitableRoles;
  final int ownersCount;

  VenueMembersData({
    required this.venue,
    required this.members,
    required this.pendingInvites,
    required this.assignableRoles,
    required this.invitableRoles,
    required this.ownersCount,
  });

  factory VenueMembersData.fromJson(Map<String, dynamic> json) {
    return VenueMembersData(
      venue: VenueMembersVenue.fromJson(
        (json['venue'] as Map).cast<String, dynamic>(),
      ),
      members: ((json['members'] as List?) ?? const [])
          .map(
            (e) => VenueMemberItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      pendingInvites: ((json['pending_invites'] as List?) ?? const [])
          .map(
            (e) => VenueInviteItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      assignableRoles: ((json['assignable_roles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      invitableRoles: ((json['invitable_roles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      ownersCount: (json['owners_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class VenueMembersVenue {
  final int id;
  final String name;

  VenueMembersVenue({required this.id, required this.name});

  factory VenueMembersVenue.fromJson(Map<String, dynamic> json) {
    return VenueMembersVenue(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class VenueMemberItem {
  final int id;
  final String name;
  final String email;
  final String role;

  VenueMemberItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory VenueMemberItem.fromJson(Map<String, dynamic> json) {
    return VenueMemberItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }
}

class VenueInviteItem {
  final int id;
  final String email;
  final String role;
  final String? expiresAt;

  VenueInviteItem({
    required this.id,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  factory VenueInviteItem.fromJson(Map<String, dynamic> json) {
    return VenueInviteItem(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}
