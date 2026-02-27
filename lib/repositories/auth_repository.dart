import '../models/auth_user.dart';
import '../services/api_client.dart';

class LoginResult {
  LoginResult({required this.token, required this.user});
  final String token;
  final AuthUser user;
}

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;

  Future<LoginResult> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final json = await api.postJson(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        if (deviceName != null && deviceName.isNotEmpty)
          'device_name': deviceName,
      },
    );

    final token = (json['token'] ?? '') as String;
    final userJson = (json['user'] as Map<String, dynamic>);
    return LoginResult(token: token, user: AuthUser.fromJson(userJson));
  }

  Future<LoginResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    final json = await api.postJson(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (deviceName != null && deviceName.isNotEmpty)
          'device_name': deviceName,
      },
    );

    final token = (json['token'] ?? '') as String;
    final userJson = (json['user'] as Map<String, dynamic>);
    return LoginResult(token: token, user: AuthUser.fromJson(userJson));
  }

  Future<AuthUser> me() async {
    final json = await api.getJson('/auth/me');
    final userJson = (json['user'] as Map<String, dynamic>);
    return AuthUser.fromJson(userJson);
  }

  Future<void> logout() async {
    await api.postJson('/auth/logout');
  }
}
