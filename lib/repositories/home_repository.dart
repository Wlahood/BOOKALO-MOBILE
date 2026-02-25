// lib/repositories/home_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/home_response.dart';
import '../services/api_client.dart';

class HomeRepository {
  HomeRepository(this.api);
  final ApiClient api;

  Future<HomeResponse> fetchHome({
    String? startDate,
    String? endDate,
    String? provinceCode,
    String? city,
    int perPage = 20,
    int? page,
  }) async {
    final q = <String, String>{
      'per_page': perPage.toString(),
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (provinceCode != null && provinceCode.isNotEmpty)
        'province_code': provinceCode,
      if (city != null && city.isNotEmpty) 'city': city,
      if (page != null) 'page': page.toString(),
    };

    final json = await api.getJson('/home', query: q);
    return HomeResponse.fromJson(json);
  }

  Future<PaginatedEvents> fetchNextPage(String nextUrl) async {
    final res = await http.get(Uri.parse(nextUrl));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (json['data'] as Map<String, dynamic>);
    final events = data['events'] as Map<String, dynamic>;
    return PaginatedEvents.fromJson(events);
  }
}
