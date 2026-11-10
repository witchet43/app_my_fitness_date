import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/app.dart';
import 'package:my_fitness_date/src/core/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Flutter starts in Community with API off by default',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    expect(find.text('FitCommunity'), findsOneWidget);
    expect(find.textContaining('API sin configurar'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('Gym Shield navigation shows two privacy modes',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    await tester.tap(find.text('Citas'));
    await tester.pump();
    expect(find.text('FitDating · Gym Shield'), findsOneWidget);
    expect(find.text('Otros gimnasios'), findsOneWidget);
    expect(find.text('Otro horario'), findsOneWidget);
  });
  testWidgets('QA login is hidden without explicit build opt-in', (tester) async {
    await tester.pumpWidget(FitnessDateApp(
      api: ApiClient(baseUrl: ''), qaLoginEnabled: false,
    ));
    expect(find.byKey(const Key('qa-identity-action')), findsNothing);
  });

  testWidgets('QA login appears only for configured API and opt-in',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(
      api: ApiClient(baseUrl: 'https://api.example.test',
          client: MockClient((_) async => http.Response(
              '{"status":"degraded"}', 503))),
      qaLoginEnabled: true,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-identity-action')));
    await tester.pumpAndSettle();
    expect(find.text('Acceso de pruebas'), findsOneWidget);
    expect(find.textContaining('No hay registro público.'), findsOneWidget);
    expect(find.byKey(const Key('qa-password')), findsOneWidget);
    expect(find.byKey(const Key('qa-submit')), findsOneWidget);
  });

  testWidgets('QA sign-in and remote sign-out are reflected in Flutter',
      (tester) async {
    final api = ApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        if (request.url.path == '/readyz') {
          return http.Response(
              '{"status":"ok","dependencies":{"database":"ok"},'
              '"checked_at":"2026-11-10T00:00:00Z"}', 200);
        }
        if (request.method == 'POST' &&
            request.url.path == '/v1/identity/session') {
          return http.Response(
              '{"access_token":"synthetic-access",'
              '"refresh_token":"synthetic-refresh","expires_in":3600,'
              '"user":{"id":"10000000-0000-4000-8000-000000000001",'
              '"email":"qa@example.test","email_verified":true}}', 200);
        }
        if (request.method == 'DELETE' &&
            request.url.path == '/v1/identity/session') {
          expect(request.headers['Authorization'],
              'Bearer synthetic-access');
          return http.Response('', 204);
        }
        return http.Response('Not found', 404);
      }),
    );
    await tester.pumpWidget(FitnessDateApp(
      api: api, qaLoginEnabled: true,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qa-identity-action')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('qa-email')),
        'qa@example.test');
    await tester.enterText(find.byKey(const Key('qa-password')),
        'synthetic-password');
    await tester.tap(find.byKey(const Key('qa-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sesión QA: qa@example.test'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('qa-identity-action')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin sesión QA'), findsOneWidget);
    api.close();
  });
}
