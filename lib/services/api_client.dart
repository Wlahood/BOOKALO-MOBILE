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

  static const String baseUrl = apiBaseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);

    return base.replace(
      path: base.path.endsWith('/')
          ? '${base.path}${path.startsWith('/') ? path.substring(1) : path}'
          : '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query == null || query.isEmpty ? null : query,
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

  Map<String, dynamic> _decodeJsonResponse(http.Response res) {
    if (res.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(res.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'data': decoded};
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _client.get(_uri(path, query), headers: await _headers());

    _ensureSuccess(res);
    return _decodeJsonResponse(res);
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

    _ensureSuccess(res);
    return _decodeJsonResponse(res);
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

    _ensureSuccess(res);
    return _decodeJsonResponse(res);
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

    _ensureSuccess(res);
    return _decodeJsonResponse(res);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client.delete(
      _uri(path, query),
      headers: await _headers(extra: {'Content-Type': 'application/json'}),
      body: body == null ? null : jsonEncode(body),
    );

    _ensureSuccess(res);
    return _decodeJsonResponse(res);
  }
}
