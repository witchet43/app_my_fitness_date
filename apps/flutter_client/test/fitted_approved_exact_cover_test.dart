import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';

void main() {
  test('approved Fitted photograph is the exact bundled 1672x941 PNG',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data=await rootBundle.load(
      'assets/branding/fitted_approved_cover_reference.png');
    expect(data.lengthInBytes,greaterThan(1000000));
    // PNG's IHDR records original dimensions at byte offsets 16 and 20.
    // Read it without a frame codec: image decoding inside fake-async widget
    // tests can block a CI runner while waiting for the native engine.
    expect(data.getUint32(16),1672);
    expect(data.getUint32(20),941);
  });

  testWidgets('desktop cover is a SINGLE panel with portrait floating above',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(1672,941));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme:LiveBrandSettings.fallback.toTheme(),
      home:LiveBrandScope(
        brand:LiveBrandSettings.fallback,
        child:const PublicEntryShell(
          termsUrl:'https://example.org/terms',
          privacyUrl:'https://example.org/privacy',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landing-hero')),findsOneWidget);
    expect(find.byKey(const Key('landing-editorial-photo')),findsOneWidget);
    expect(find.byKey(const Key('landing-approved-image-source')),
      findsOneWidget);
    expect(find.byKey(const Key('landing-access')),findsOneWidget);
    expect(find.text('TU ESPACIO EN FITTED'),findsNothing);
    expect(find.text('Bienvenido'),findsNothing);
    expect(find.byKey(const Key('landing-create-profile')),findsNothing);
    expect(find.byKey(const Key('google-signin-entry')),findsOneWidget);
    expect(find.byKey(const Key('apple-signin-entry')),findsOneWidget);
    expect(find.byKey(const Key('email-entry')),findsOneWidget);
    expect(find.text('Personas auténticas'),findsOneWidget);
    expect(find.text('Afinidad real'),findsOneWidget);
    expect(find.text('Protección'),findsOneWidget);
    expect(find.text('Términos'),findsOneWidget);
    expect(find.text('Privacidad'),findsOneWidget);
    final coverTop=tester.getTopLeft(
      find.byKey(const Key('landing-hero'))).dy;
    final portraitTop=tester.getTopLeft(
      find.byKey(const Key('landing-editorial-photo'))).dy;
    expect(portraitTop,lessThan(coverTop),
      reason:'Portrait hair must float above the top edge of the panel');
    expect(tester.takeException(),isNull);
  });

  testWidgets('mobile retains live access, sign-up and one-panel composition',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(390,850));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    var registered=0;
    await tester.pumpWidget(MaterialApp(
      theme:LiveBrandSettings.fallback.toTheme(),
      home:LiveBrandScope(
        brand:LiveBrandSettings.fallback,
        child:PublicEntryShell(
          termsUrl:'https://example.org/terms',
          privacyUrl:'https://example.org/privacy',
          onEmailRegister:()=>registered++,
        ),
      ),
    ));
    expect(find.byKey(const Key('landing-hero')),findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('switch-entry-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-entry-mode')));
    await tester.pump();
    expect(find.text('Crear cuenta con correo'),findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('email-entry')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('email-entry')));
    expect(registered,1);
    expect(tester.takeException(),isNull);
  });
}
