import '../models/search_response.dart';
import '../services/api_client.dart';

class SearchRepository {
  final ApiClient apiClient;

  SearchRepository(this.apiClient);

  Future<SearchResponse> search({
    required String q,
    String? region,
    String? provinceCode,
    String? startDate,
    String? endDate,
    int limit = 10,
  }) async {
    final query = <String, String>{'q': q, 'limit': limit.toString()};

    if (region != null && region.isNotEmpty) {
      query['region'] = region;
    }
    if (provinceCode != null && provinceCode.isNotEmpty) {
      query['province_code'] = provinceCode;
    }
    if (startDate != null && startDate.isNotEmpty) {
      query['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      query['end_date'] = endDate;
    }

    final json = await apiClient.getJson('/search', query: query);
    return SearchResponse.fromJson(json);
  }
}
