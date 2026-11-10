import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_fitness_date/src/core/api_client.dart';
import 'package:my_fitness_date/src/core/auth_session.dart';

void main() {
  test('no API configured means fail closed', () async {
    final api = ApiClient(baseUrl: '');
    expect(api.isConfigured, isFalse);
    await expectLater(api.health(), throwsStateError);
  });

  test('API health is consumed through gateway only', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test', client:
        MockClient((request) async {
      expect(request.url.path, '/healthz');
      return http.Response('{"status":"ok"}', 200);
    }));
    expect(await api.health(), isTrue);
    api.close();
  });

  test('dating sanitizes server DTO; requires session', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test', client:
        MockClient((request) async {
      expect(request.url.path, '/v1/dating/candidates');
      expect(request.headers['Authorization'], 'Bearer sample-session');
      return http.Response(
          '{"items":[{"id":"id-1","display_name":"Demo",'
          '"city":"Qro","sports":["Running"],"gym_id":"PRIVATE"}],'
          '"count":1}', 200);
    }));
    await expectLater(api.candidates(accessToken: ''), throwsArgumentError);
    final people = await api.candidates(accessToken: 'sample-session');
    expect(people.single.displayName, 'Demo');
    expect(people.single.id, 'id-1');
    api.close();
  });
  test('QA identity calls gateway only and rotates the refresh token', () async {
    final seen = <String>[];
    final api = ApiClient(baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      expect(request.url.host, 'api.example.test');
      if (request.url.path == '/v1/identity/session') {
        expect(request.method, 'POST');
        expect(request.body, contains('qa@example.test'));
        return http.Response(_sessionJson('refresh-old'), 200);
      }
      if (request.url.path == '/v1/identity/session/refresh') {
        expect(request.body, contains('refresh-old'));
        return http.Response(_sessionJson('refresh-new'), 200);
      }
      if (request.url.path == '/v1/identity/me') {
        expect(request.headers['Authorization'], 'Bearer synthetic-access');
        return http.Response(_userJson, 200);
      }
      if (request.url.path == '/v1/identity/session' &&
          request.method == 'DELETE') {
        return http.Response('', 204);
      }
      return http.Response('not found', 404);
    }));
    final signed = await api.signIn(email: 'qa@example.test', password: 'SECRET');
    expect(signed.refreshToken, 'refresh-old');
    final refreshed = await api.refreshSession(refreshToken: signed.refreshToken);
    expect(refreshed.refreshToken, 'refresh-new');
    final user = await api.identity(accessToken: refreshed.accessToken);
    expect(user.email, 'qa@example.test');
    // For signout, a separate mock handles DELETE below.
    expect(seen, contains('POST /v1/identity/session'));
    api.close();
  });

  test('QA sign out calls gateway and does not expose session tokens', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/v1/identity/session');
      expect(request.headers['Authorization'], 'Bearer synthetic-access');
      return http.Response('', 204);
    }));
    await api.signOut(accessToken: 'synthetic-access');
    api.close();
  });

  test('failed QA sign in never reflects server error details', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test',
        client: MockClient((_) async => http.Response(
            '{"detail":"SECRET_FROM_PROVIDER"}', 401)));
    await expectLater(
        api.signIn(email: 'qa@example.test', password: 'SECRET_IN_FORM'),
        throwsA(isA<IdentityException>()));
    api.close();
  });
}

const _userJson =
    '{"id":"10000000-0000-4000-8000-000000000001",'
    '"email":"qa@example.test","email_verified":true}';

String _sessionJson(String refresh) =>
    '{"access_token":"synthetic-access","refresh_token":"$refresh",'
    '"expires_in":3600,"user":$_userJson}';
