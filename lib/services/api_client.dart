// lib/services/api_client.dart
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const String baseUrl =
      apiBaseUrl; // usa il default  // es: http://10.0.2.2:8090/api/v1

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: base.path.endsWith('/')
          ? '${base.path}${path.startsWith('/') ? path.substring(1) : path}'
          : '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
