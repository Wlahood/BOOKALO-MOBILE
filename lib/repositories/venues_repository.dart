import '../models/venue_detail.dart';
import '../services/api_client.dart';

class VenuesRepository {
  final ApiClient api;
  VenuesRepository(this.api);

  Future<VenueDetail> fetchVenue(int id) async {
    final json = await api.getJson('/venues/$id');
    return VenueDetailResponse.fromJson(json).data;
  }
}
