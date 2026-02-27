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
  AuthController._()
    : tokenStore = TokenStore(),
      api = ApiClient(),
      state = ValueNotifier<AuthState>(const AuthState.unknown()) {
    repo = AuthRepository(api);
  }

  static final AuthController instance = AuthController._();

  final TokenStore tokenStore;
  final ApiClient api;
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
    } catch (_) {
      await tokenStore.clearToken();
      state.value = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    state.value = const AuthState.loading();
    final res = await repo.login(
      email: email,
      password: password,
      deviceName: deviceName,
    );
    await tokenStore.writeToken(res.token);
    state.value = AuthState.authenticated(res.user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    state.value = const AuthState.loading();
    final res = await repo.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      deviceName: deviceName,
    );
    await tokenStore.writeToken(res.token);
    state.value = AuthState.authenticated(res.user);
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
