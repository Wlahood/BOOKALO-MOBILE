import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, [this.errors = const {}]);
  final int statusCode;
  final String message;
  final Map<String, dynamic> errors;
  @override
  String toString() => errors.isEmpty
      ? message
      : errors.values.map((e) => e is List ? e.join('\n') : '$e').join('\n');
}

class UploadFile {
  const UploadFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

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
      path:
          '${base.path.replaceFirst(RegExp(r'/$'), '')}/${path.replaceFirst(RegExp(r'^/'), '')}',
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStore.readToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic value;
    try {
      value = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        response.statusCode,
        'Risposta del server non valida. Riprova più tardi.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = value is Map<String, dynamic> ? value : <String, dynamic>{};
      throw ApiException(
        response.statusCode,
        data['message']?.toString() ??
            'Richiesta non riuscita (${response.statusCode}).',
        Map<String, dynamic>.from(data['errors'] ?? {}),
      );
    }
    return value is Map<String, dynamic> ? value : {'data': value};
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, UploadFile> files = const {},
  }) async {
    http.BaseRequest request;
    if (files.isNotEmpty) {
      final multi = http.MultipartRequest('POST', _uri(path, query));
      if (method != 'POST') multi.fields['_method'] = method;
      void field(String key, dynamic value) {
        if (value is List) {
          if (value.isEmpty) return;
          for (var i = 0; i < value.length; i++) {
            field('$key[$i]', value[i]);
          }
        } else if (value is Map) {
          value.forEach((k, v) => field('$key[$k]', v));
        } else {
          multi.fields[key] = value == null
              ? ''
              : value is bool
              ? (value ? '1' : '0')
              : '$value';
        }
      }

      (body ?? {}).forEach(field);
      files.forEach(
        (key, file) => multi.files.add(
          http.MultipartFile.fromBytes(key, file.bytes, filename: file.name),
        ),
      );
      request = multi;
    } else {
      final json = http.Request(method, _uri(path, query));
      if (body != null) {
        json.headers['Content-Type'] = 'application/json';
        json.body = jsonEncode(body);
      }
      request = json;
    }
    request.headers.addAll(await _headers());
    request.followRedirects = false;
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 45));
    return _decode(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) => request('GET', path, query: query);
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => request('POST', path, query: query, body: body ?? {});
  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => request('PUT', path, query: query, body: body ?? {});
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => request('PATCH', path, query: query, body: body ?? {});
  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => request('DELETE', path, query: query, body: body);
}
