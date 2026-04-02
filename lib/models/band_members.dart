class BandMembersResponse {
  final BandMembersData data;

  BandMembersResponse({required this.data});

  factory BandMembersResponse.fromJson(Map<String, dynamic> json) {
    return BandMembersResponse(
      data: BandMembersData.fromJson(
        (json['data'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}

class BandMembersData {
  final BandMembersBand band;
  final List<BandMemberItem> members;
  final List<BandInviteItem> pendingInvites;
  final List<String> assignableRoles;
  final List<String> invitableRoles;
  final int ownersCount;

  BandMembersData({
    required this.band,
    required this.members,
    required this.pendingInvites,
    required this.assignableRoles,
    required this.invitableRoles,
    required this.ownersCount,
  });

  factory BandMembersData.fromJson(Map<String, dynamic> json) {
    return BandMembersData(
      band: BandMembersBand.fromJson(
        (json['band'] as Map).cast<String, dynamic>(),
      ),
      members: ((json['members'] as List?) ?? const [])
          .map(
            (e) => BandMemberItem.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
      pendingInvites: ((json['pending_invites'] as List?) ?? const [])
          .map(
            (e) => BandInviteItem.fromJson((e as Map).cast<String, dynamic>()),
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

class BandMembersBand {
  final int id;
  final String name;

  BandMembersBand({required this.id, required this.name});

  factory BandMembersBand.fromJson(Map<String, dynamic> json) {
    return BandMembersBand(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class BandMemberItem {
  final int id;
  final String name;
  final String email;
  final String role;

  BandMemberItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory BandMemberItem.fromJson(Map<String, dynamic> json) {
    return BandMemberItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }
}

class BandInviteItem {
  final int id;
  final String email;
  final String role;
  final String? expiresAt;

  BandInviteItem({
    required this.id,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  factory BandInviteItem.fromJson(Map<String, dynamic> json) {
    return BandInviteItem(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}
