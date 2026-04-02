import '../models/band_detail.dart';
import '../models/location_option.dart';
import '../services/api_client.dart';
import '../models/band_members.dart';

class BandsRepository {
  final ApiClient api;
  BandsRepository(this.api);

  Future<BandDetail> fetchBand(int id) async {
    final json = await api.getJson('/bands/$id');
    return BandDetailResponse.fromJson(json).data;
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

  Future<List<GenreMini>> fetchGenres() async {
    final json = await api.getJson('/genres');
    final list = (json['data'] as List? ?? const []);
    return list
        .map((e) => GenreMini.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<BandDetail> updateBand(int id, Map<String, dynamic> body) async {
    final json = await api.putJson('/me/bands/$id', body: body);
    return BandDetailResponse.fromJson(json).data;
  }

  Future<BandMembersData> fetchBandMembers(int bandId) async {
    final json = await api.getJson('/me/bands/$bandId/members');
    return BandMembersResponse.fromJson(json).data;
  }

  Future<void> inviteBandMember(
    int bandId, {
    required String email,
    required String role,
  }) async {
    await api.postJson(
      '/me/bands/$bandId/invites',
      body: {'email': email, 'role': role},
    );
  }

  Future<void> updateBandMemberRole(
    int bandId, {
    required int userId,
    required String role,
  }) async {
    await api.patchJson(
      '/me/bands/$bandId/members/$userId',
      body: {'role': role},
    );
  }

  Future<void> removeBandMember(int bandId, {required int userId}) async {
    await api.deleteJson('/me/bands/$bandId/members/$userId');
  }

  Future<void> revokeInvite(int inviteId) async {
    await api.deleteJson('/me/invites/$inviteId');
  }
}
