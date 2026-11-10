import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_fitness_date/src/core/api_client.dart';

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
}
