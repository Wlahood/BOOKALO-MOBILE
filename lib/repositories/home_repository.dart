import '../models/home_response.dart';
import '../services/api_client.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository(this.apiClient);

  Future<HomeResponse> fetchHome({
    String? startDate,
    String? endDate,
    String? region,
    String? provinceCode,
    int? bandId,
    int? venueId,
    int perPage = 20,
  }) async {
    final query = <String, String>{};

    if (startDate != null && startDate.isNotEmpty) {
      query['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      query['end_date'] = endDate;
    }
    if (region != null && region.isNotEmpty) {
      query['region'] = region;
    }
    if (provinceCode != null && provinceCode.isNotEmpty) {
      query['province_code'] = provinceCode;
    }
    if (bandId != null) {
      query['band_id'] = bandId.toString();
    }
    if (venueId != null) {
      query['venue_id'] = venueId.toString();
    }

    query['per_page'] = perPage.toString();

    final json = await apiClient.getJson('/home', query: query);
    return HomeResponse.fromJson(json);
  }
}
