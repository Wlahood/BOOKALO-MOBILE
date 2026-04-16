import '../models/location_option.dart';
import '../models/venue_detail.dart';
import '../services/api_client.dart';
import '../models/venue_members.dart';

class VenuesRepository {
  final ApiClient api;
  VenuesRepository(this.api);

  Future<VenueDetail> fetchVenue(int id) async {
    final json = await api.getJson('/venues/$id');
    return VenueDetailResponse.fromJson(json).data;
  }

  Future<List<String>> fetchRegions() async {
    final json = await api.getJson('/locations/regions');
    final list = (json['data'] as List? ?? const []);
    return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  Future<List<LocationOption>> fetchProvinces(String region) async {
    final json = await api.getJson(
      '/locations/provinces',
      query: {'region': region},
    );

    final list = (json['data'] as List? ?? const []);
    return list
        .map((e) => LocationOption.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<VenueDetail> updateVenue(int id, Map<String, dynamic> body) async {
    final json = await api.putJson('/me/venues/$id', body: body);
    return VenueDetailResponse.fromJson(json).data;
  }

  Future<VenueMembersData> fetchVenueMembers(int venueId) async {
    final json = await api.getJson('/me/venues/$venueId/members');
    return VenueMembersResponse.fromJson(json).data;
  }

  Future<void> inviteVenueMember(
    int venueId, {
    required String email,
    required String role,
  }) async {
    await api.postJson(
      '/me/venues/$venueId/invites',
      body: {'email': email, 'role': role},
    );
  }

  Future<void> updateVenueMemberRole(
    int venueId, {
    required int userId,
    required String role,
  }) async {
    await api.patchJson(
      '/me/venues/$venueId/members/$userId',
      body: {'role': role},
    );
  }

  Future<void> revokeInvite(int inviteId) async {
    await api.deleteJson('/me/invites/$inviteId');
  }

  Future<void> removeVenueMember(int venueId, {required int userId}) async {
    await api.deleteJson('/me/venues/$venueId/members/$userId');
  }
}
