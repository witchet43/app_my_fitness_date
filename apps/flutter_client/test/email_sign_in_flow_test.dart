import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/member_v26_api.dart';
import 'package:my_fitness_date/src/member_v26_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Existing account email button opens the native login dialog',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = SupabaseClient('https://example.supabase.co', 'anon-test');
    client.auth.stopAutoRefresh();
    addTearDown(client.dispose);

    // Exercise the REAL root widget. A stand-alone PublicEntryShell test
    // cannot catch the missing Navigator above MemberV26App.
    await tester.pumpWidget(MemberV26App(
      auth: client,
      api: MemberV26Api(
          gatewayUrl: 'https://example.supabase.co/functions/v1/api',
          auth: client),
      termsUrl: 'https://example.com/terms/',
      privacyUrl: 'https://example.com/privacy/',
      redirectUrl: 'https://example.com/',
      termsVersion: 'test-terms',
      privacyVersion: 'test-privacy',
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.ensureVisible(
        find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);

    final signInButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('email-entry')));
    expect(signInButton.onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('email-entry')));
    await tester.tap(find.byKey(const Key('email-entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byKey(const Key('request-password-recovery')),
        findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
