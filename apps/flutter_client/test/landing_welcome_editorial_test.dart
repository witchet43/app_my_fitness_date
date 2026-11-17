import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: LiveBrandScope(brand: LiveBrandSettings.fallback, child: child),
  );

  testWidgets('welcome sells the product without pace calculator',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(const PublicEntryShell(
      termsUrl: 'https://example.org/terms',
      privacyUrl: 'https://example.org/privacy',
    )));
    expect(find.byKey(const Key('landing-hero')), findsOneWidget);
    expect(find.byKey(const Key('landing-access')), findsOneWidget);
    expect(find.byKey(const Key('anonymous-pace-tool')), findsNothing);
    expect(find.textContaining('Calculadora de ritmo'), findsNothing);
    expect(find.byKey(const Key('google-signin-entry')), findsOneWidget);
    expect(find.byKey(const Key('apple-signin-entry')), findsOneWidget);
    expect(find.byKey(const Key('email-entry')), findsOneWidget);
  });

  testWidgets('existing member login never asks legal or adult consent',
      (tester) async {
    await tester.pumpWidget(wrap(PublicEntryShell(
      termsUrl: 'https://example.org/terms',
      privacyUrl: 'https://example.org/privacy',
      onEmailSignIn: () {},
      onEmailRegister: () {},
    )));
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Términos'), findsOneWidget);
    expect(find.text('Privacidad'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('email-entry')));
    expect(find.text('Crear cuenta con correo'), findsOneWidget);
  });
  testWidgets('configured access buttons invoke real supplied sign-in actions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    var google = 0;
    var apple = 0;
    var email = 0;
    await tester.pumpWidget(wrap(PublicEntryShell(
      termsUrl: 'https://example.org/terms',
      privacyUrl: 'https://example.org/privacy',
      onGoogle: () => google++,
      onApple: () => apple++,
      onEmailSignIn: () => email++,
    )));
    for (final key in const [
      'google-signin-entry',
      'apple-signin-entry',
      'email-entry',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pump();
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
    expect(google, 1);
    expect(apple, 1);
    expect(email, 1);
    expect(find.textContaining('Acceso aún no configurado'), findsNothing);
    expect(find.textContaining('Al crear una cuenta se te solicitará'), findsNothing);
  });

}
