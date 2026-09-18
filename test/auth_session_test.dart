import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bookalo_mobile/services/api_client.dart';
import 'package:bookalo_mobile/services/auth_controller.dart';
import 'workspace_test.dart' show MemoryTokenStore;

void main() {
  test('temporary server failure preserves the stored session', () async {
    final store = MemoryTokenStore();
    final auth = AuthController(
      tokenStore: store,
      api: ApiClient(
        tokenStore: store,
        client: MockClient(
          (_) async => http.Response('{"message":"Unavailable"}', 503),
        ),
      ),
    );
    await auth.bootstrap();
    expect(store.token, 'test-token');
    expect(auth.state.value.status, AuthStatus.unauthenticated);
  });
  test('rejected token is removed on bootstrap', () async {
    final store = MemoryTokenStore();
    final auth = AuthController(
      tokenStore: store,
      api: ApiClient(
        tokenStore: store,
        client: MockClient(
          (_) async => http.Response('{"message":"Unauthenticated"}', 401),
        ),
      ),
    );
    await auth.bootstrap();
    expect(store.token, isNull);
    expect(auth.state.value.status, AuthStatus.unauthenticated);
  });
  test('failed login exits the loading state', () async {
    final store = MemoryTokenStore();
    final auth = AuthController(
      tokenStore: store,
      api: ApiClient(
        tokenStore: store,
        client: MockClient(
          (_) async => http.Response('{"message":"Invalid credentials"}', 422),
        ),
      ),
    );
    await expectLater(
      auth.login(email: 'test@example.test', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(auth.state.value.status, AuthStatus.unauthenticated);
  });
}
