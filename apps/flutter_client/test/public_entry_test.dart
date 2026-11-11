import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';

void main() {
  testWidgets('The landing never exposes member actions without a configured backend',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PublicEntryShell()));
    expect(find.byKey(const Key('landing-headline')), findsOneWidget);
    expect(find.byKey(const Key('signup-closed')), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    final google = tester.widget<OutlinedButton>(
      find.byKey(const Key('google-signin-entry')));
    expect(google.onPressed, isNull);
    final email = tester.widget<OutlinedButton>(
      find.byKey(const Key('email-entry')));
    expect(email.onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('switch-entry-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });
  testWidgets('Small devices render the entry shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PublicEntryShell()));
    expect(find.byKey(const Key('landing-headline')), findsOneWidget);
  });
}
