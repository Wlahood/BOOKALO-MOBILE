import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';
import 'api_client.dart';
import 'token_store.dart';

enum AuthStatus { unknown, loading, unauthenticated, authenticated }

class AuthState {
  const AuthState._(this.status, {this.user});

  final AuthStatus status;
  final AuthUser? user;

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.authenticated(AuthUser user)
    : this._(AuthStatus.authenticated, user: user);
}

class AuthController {
  AuthController({TokenStore? tokenStore, ApiClient? api})
    : tokenStore = tokenStore ?? TokenStore(),
      state = ValueNotifier<AuthState>(const AuthState.unknown()) {
    this.api = api ?? ApiClient(tokenStore: this.tokenStore);
    repo = AuthRepository(this.api);
  }

  static final AuthController instance = AuthController();

  final TokenStore tokenStore;
  late final ApiClient api;
  late final AuthRepository repo;

  final ValueNotifier<AuthState> state;

  Future<void> bootstrap() async {
    state.value = const AuthState.loading();

    final token = await tokenStore.readToken();
    if (token == null || token.isEmpty) {
      state.value = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await repo.me();
      state.value = AuthState.authenticated(user);
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        await tokenStore.clearToken();
      }
      state.value = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    state.value = const AuthState.loading();
    try {
      final res = await repo.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
      await tokenStore.writeToken(res.token);
      state.value = AuthState.authenticated(res.user);
    } catch (_) {
      state.value = const AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    state.value = const AuthState.loading();
    try {
      final res = await repo.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        deviceName: deviceName,
      );
      await tokenStore.writeToken(res.token);
      state.value = AuthState.authenticated(res.user);
    } catch (_) {
      state.value = const AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    state.value = const AuthState.loading();
    try {
      await repo.logout();
    } catch (_) {
      // anche se fallisce lato server, puliamo localmente
    }
    await tokenStore.clearToken();
    state.value = const AuthState.unauthenticated();
  }
}
