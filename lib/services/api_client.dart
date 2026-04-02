import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_store.dart';

class ApiClient {
  ApiClient({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? TokenStore();

  final http.Client _client;
  final TokenStore _tokenStore;

  static const String baseUrl = apiBaseUrl; // es: http://10.0.2.2:8090/api/v1

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: base.path.endsWith('/')
          ? '${base.path}${path.startsWith('/') ? path.substring(1) : path}'
          : '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (extra != null) ...extra,
    };

    final token = await _tokenStore.readToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query), headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client.post(
      _uri(path, query),
      headers: await _headers(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client.put(
      _uri(path, query),
      headers: await _headers(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client.patch(
      _uri(path, query),
      headers: await _headers(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    return res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final req = http.Request('DELETE', _uri(path, query));
    req.headers.addAll(
      await _headers(extra: {'Content-Type': 'application/json'}),
    );
    if (body != null) {
      req.body = jsonEncode(body);
    }

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    return res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
  }
}
