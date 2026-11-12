import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';

void main() {
  testWidgets('Existing account email button opens a dialog via app Navigator',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: PublicEntryShell(
        termsUrl: 'https://example.com/terms/',
        privacyUrl: 'https://example.com/privacy/',
        onEmailSignIn: () {
          // The production root now uses this same in-app navigator context.
          showDialog<void>(
            context: navigatorKey.currentContext!,
            builder: (context) => AlertDialog(
              title: const Text('Iniciar sesión'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        },
      ),
    ));
    await tester.ensureVisible(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);

    final signInButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('email-entry')));
    expect(signInButton.onPressed, isNotNull);
    await tester.ensureVisible(find.byKey(const Key('email-entry')));
    await tester.tap(find.byKey(const Key('email-entry')));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
