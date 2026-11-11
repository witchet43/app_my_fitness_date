import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/app.dart';
import 'package:my_fitness_date/src/core/api_client.dart';

void main() {
  testWidgets('Public landing never exposes private app without PROD auth',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(
      api: ApiClient(baseUrl: ''),
      requireMemberAuth: true,
      qaLoginEnabled: false,
    ));
    expect(find.byKey(const Key('landing-headline')), findsOneWidget);
    expect(find.byKey(const Key('signup-closed')), findsOneWidget);
    expect(find.text('FitCommunity'), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    final google = tester.widget<OutlinedButton>(
      find.byKey(const Key('google-signin-entry')));
    expect(google.onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('switch-entry-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  testWidgets('Landing remains usable on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(FitnessDateApp(
      api: ApiClient(baseUrl: ''),
      requireMemberAuth: true,
      qaLoginEnabled: false,
    ));
    expect(find.byKey(const Key('landing-headline')), findsOneWidget);
    // Allow the framework to report a full layout exception if one occurs.
    await tester.pump();
  });
}
