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
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Crear cuenta con correo'), findsOneWidget);
  });
}
