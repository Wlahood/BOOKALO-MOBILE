import '../models/search_response.dart';
import '../services/api_client.dart';

class SearchRepository {
  final ApiClient api;

  SearchRepository(this.api);

  Future<SearchData> search(String q) async {
    final json = await api.getJson('/search', query: {'q': q});
    return SearchResponse.fromJson(json).data;
  }
}
