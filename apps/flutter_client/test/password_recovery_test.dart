import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/password_recovery.dart';
import 'package:my_fitness_date/src/features/password_recovery_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('password recovery returns to the same Flutter app', () {
    expect(passwordRecoveryRedirect('https://my-fitness-date.pages.dev/'),
      'https://my-fitness-date.pages.dev/?password_reset=1');
    expect(passwordRecoveryRedirect('https://example.test/?a=1'),
      'https://example.test/?a=1&password_reset=1');
  });

  test('only HTTPS callback URLs are accepted', () {
    expect(() => passwordRecoveryRedirect('http://example.test/'),
      throwsFormatException);
    expect(() => passwordRecoveryRedirect('javascript:alert(1)'),
      throwsFormatException);
  });

  testWidgets('native recovery screen validates password before network call',
    (tester) async {
      final client = SupabaseClient('https://example.supabase.co', 'anon-test');
      client.auth.stopAutoRefresh();
      addTearDown(client.dispose);
      await tester.pumpWidget(MaterialApp(home: PasswordRecoveryScreen(
        client: client, onFinished: () async {})));
      expect(find.text('Crea tu contraseña'), findsOneWidget);
      await tester.tap(find.byKey(const Key('recovery-save-password')));
      await tester.pump();
      expect(find.text('Utiliza entre 12 y 128 caracteres.'), findsOneWidget);
    });
}
