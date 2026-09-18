import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bookalo_mobile/services/api_client.dart';
import 'package:bookalo_mobile/services/token_store.dart';
import 'package:bookalo_mobile/repositories/workspace_repository.dart';
import 'package:bookalo_mobile/screens/workspace/workflow_form_screen.dart';
import 'package:bookalo_mobile/models/home_response.dart';
import 'package:bookalo_mobile/models/event_detail.dart';

class MemoryTokenStore extends TokenStore {
  String? token = 'test-token';
  @override
  Future<String?> readToken() async => token;
  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> clearToken() async {
    token = null;
  }
}

ApiClient client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(client: MockClient(handler), tokenStore: MemoryTokenStore());
void main() {
  test('sends bearer authentication and JSON body', () async {
    final api = client((request) async {
      expect(request.url.path, '/api/v1/workspace/my/threads/7/messages');
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {'body': 'Ciao'});
      return http.Response('{"data":{"success":"Inviato"}}', 200);
    });
    final result = await WorkspaceRepository(
      api,
    ).save('/workspace/my/threads/7/messages', {'body': 'Ciao'});
    expect(result['success'], 'Inviato');
  });
  test(
    'preserves Laravel field errors and does not follow redirects',
    () async {
      final api = client((request) async {
        expect(request.followRedirects, false);
        return http.Response(
          '{"message":"Invalid","errors":{"date":["Data non disponibile"]}}',
          422,
        );
      });
      await expectLater(
        api.postJson('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.errors['date'], 'field errors', [
            'Data non disponibile',
          ]),
        ),
      );
    },
  );
  test('handles empty 204 and lookup array responses', () async {
    final api = client(
      (request) async => request.method == 'DELETE'
          ? http.Response('', 204)
          : http.Response('[{"id":1,"name":"Band"}]', 200),
    );
    expect(await api.deleteJson('/test'), isEmpty);
    expect((await api.getJson('/test'))['data'], isA<List>());
  });
  test('uploads multipart with method override, arrays and booleans', () async {
    final api = client((request) async {
      expect(request.method, 'POST');
      expect(request.headers['content-type'], contains('multipart/form-data'));
      expect(request.body, contains('name="_method"'));
      expect(request.body, contains('PATCH'));
      expect(request.body, contains('name="genres[0]"'));
      expect(request.body, contains('filename="avatar.png"'));
      return http.Response('{"data":{"status":"OK"}}', 200);
    });
    await api.request(
      'PATCH',
      '/me/profile',
      body: {
        'genres': [1, 2],
        'enabled': false,
      },
      files: {
        'avatar': UploadFile('avatar.png', Uint8List.fromList([1, 2, 3])),
      },
    );
  });
  test('parses Laravel pagination metadata', () {
    final home = HomeResponse.fromJson({
      'data': {
        'events': {
          'data': [],
          'meta': {'current_page': 2, 'last_page': 4, 'total': 72},
        },
      },
    });
    expect(home.currentPage, 2);
    expect(home.lastPage, 4);
    expect(home.total, 72);
  });
  test('preserves custom event location and calendar link', () {
    final event = EventDetail.fromJson({
      'id': 1,
      'title': 'Festival',
      'effective_location': {
        'has_custom_location': true,
        'maps_query': 'Parco Roma',
      },
      'links': {'calendar_url': 'https://example.test/calendar'},
    });
    expect(event.effectiveLocation['maps_query'], 'Parco Roma');
    expect(event.calendarUrl, 'https://example.test/calendar');
  });
  testWidgets('does not submit missing required fields', (tester) async {
    var calls = 0;
    final api = client((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WorkflowFormScreen(
          title: 'Messaggio',
          path: '/test',
          fields: const [FormFieldSpec('body', 'Messaggio', required: true)],
          repository: WorkspaceRepository(api),
        ),
      ),
    );
    await tester.tap(find.text('Conferma'));
    await tester.pump();
    expect(find.text('Campo obbligatorio'), findsOneWidget);
    expect(calls, 0);
  });
  testWidgets('keeps typed values and displays validation errors', (
    tester,
  ) async {
    final api = client(
      (_) async => http.Response(
        '{"message":"Errore","errors":{"body":["Messaggio troppo lungo"]}}',
        422,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkflowFormScreen(
          title: 'Invio',
          path: '/test',
          fields: const [FormFieldSpec('body', 'Messaggio', required: true)],
          repository: WorkspaceRepository(api),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Testo da conservare');
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(find.text('Testo da conservare'), findsOneWidget);
    expect(find.textContaining('Messaggio troppo lungo'), findsWidgets);
  });
  testWidgets('submits a numeric value and prevents duplicate saves', (
    tester,
  ) async {
    var calls = 0;
    final api = client((request) async {
      calls++;
      expect(jsonDecode(request.body)['fee'], 150.5);
      return http.Response('{"data":{"success":"Proposta inviata"}}', 200);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WorkflowFormScreen(
          title: 'Proposta',
          path: '/test',
          fields: const [
            FormFieldSpec(
              'fee',
              'Compenso',
              kind: InputKind.number,
              required: true,
            ),
          ],
          repository: WorkspaceRepository(api),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '150,5');
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(find.text('Proposta inviata'), findsOneWidget);
    expect(calls, 1);
  });
}
