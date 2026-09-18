import '../services/api_client.dart';

class WorkspaceRepository {
  WorkspaceRepository([ApiClient? api]) : api = api ?? ApiClient();
  final ApiClient api;
  Future<Map<String, dynamic>> load(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await api.getJson(path, query: query);
    return response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
  }

  Future<Map<String, dynamic>> save(
    String path,
    Map<String, dynamic> body, {
    String method = 'POST',
    Map<String, UploadFile> files = const {},
  }) async {
    final response = await api.request(method, path, body: body, files: files);
    return response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
  }
}
