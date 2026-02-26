import '../models/band_detail.dart';
import '../services/api_client.dart';

class BandsRepository {
  final ApiClient api;
  BandsRepository(this.api);

  Future<BandDetail> fetchBand(int id) async {
    final json = await api.getJson('/bands/$id');
    return BandDetailResponse.fromJson(json).data;
  }
}
