import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_fitness_date/src/core/api_client.dart';
import 'package:my_fitness_date/src/core/identity_session_manager.dart';

const _user = '{"id":"10000000-0000-4000-8000-000000000001",'
    '"email":"qa@example.test","email_verified":true}';

String session(String refresh, int expires) =>
    '{"access_token":"access-$refresh","refresh_token":"$refresh",'
    '"expires_in":$expires,"user":$_user}';

void main() {
  test('refresh uses rotated credential and retains verified user', () async {
    var refreshes = 0;
    final api = ApiClient(baseUrl: 'https://api.example.test', client:
        MockClient((request) async {
      if (request.url.path.endsWith('/refresh')) {
        expect(request.body, contains('old-refresh'));
        refreshes++;
        return http.Response(session('new-refresh', 3600), 200);
      }
      return http.Response(session('old-refresh', 1), 200);
    }));
    final manager = IdentitySessionManager(api);
    await manager.signIn('qa@example.test', 'synthetic-password');
    await manager.refreshIfNeeded();
    expect(manager.session!.refreshToken, 'new-refresh');
    expect(refreshes, 1);
    await manager.refreshIfNeeded();
    expect(refreshes, 1);
    manager.dispose();
    api.close();
  });

  test('logout clears local tokens even when provider is unavailable', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
      if (request.method == 'DELETE') return http.Response('', 503);
      return http.Response(session('old-refresh', 3600), 200);
    }));
    final manager = IdentitySessionManager(api);
    await manager.signIn('qa@example.test', 'synthetic-password');
    await expectLater(manager.signOut(), throwsException);
    expect(manager.signedIn, isFalse);
    manager.dispose();
    api.close();
  });

  test('unavailable refresh clears local session', () async {
    final api = ApiClient(baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
      if (request.url.path.endsWith('/refresh')) {
        return http.Response('{"detail":"invalid"}', 401);
      }
      return http.Response(session('old-refresh', 1), 200);
    }));
    final manager = IdentitySessionManager(api);
    await manager.signIn('qa@example.test', 'synthetic-password');
    await expectLater(manager.refreshIfNeeded(), throwsException);
    expect(manager.session, isNull);
    manager.dispose();
    api.close();
  });
}
