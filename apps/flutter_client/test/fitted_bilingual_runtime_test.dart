import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_fitness_date/src/core/fitted_locale.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ES and EN update member text without restarting',
      (tester) async {
    final client=SupabaseClient('https://localhost.supabase.co','test-key');
    final controller=FittedLocaleController(client);
    addTearDown(() {controller.dispose();client.dispose();});
    await tester.pumpWidget(FittedLocaleScope(
      controller:controller,
      child:const MaterialApp(home:Scaffold(body:Column(
        children:[
          FittedLanguageSelector(),
          FittedText('Tu próxima actividad'),
          FittedText('Comunidad deportiva'),
          FittedText('Calculadora del match'),
        ],
      ))),
    ));
    expect(find.text('Tu próxima actividad'),findsOneWidget);
    await controller.choose('en');
    await tester.pumpAndSettle();
    expect(find.text('Your next activity'),findsOneWidget);
    expect(find.text('Sports community'),findsOneWidget);
    expect(find.text('Match Calculator'),findsOneWidget);
    await controller.choose('es');
    await tester.pumpAndSettle();
    expect(find.text('Tu próxima actividad'),findsOneWidget);
  });

  testWidgets('EN translates the full live marketing welcome',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280,1100));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    final client=SupabaseClient('https://localhost.supabase.co','test-key');
    final controller=FittedLocaleController(client);
    addTearDown(() {controller.dispose();client.dispose();});
    await tester.pumpWidget(FittedLocaleScope(controller:controller,
      child:MaterialApp(home:LiveBrandScope(
        brand:LiveBrandSettings.fallback,
        child:const PublicEntryShell(
          termsUrl:'https://example.com/terms/',
          privacyUrl:'https://example.com/privacy/',
        ),
      )),
    ));
    await controller.choose('en');
    await tester.pumpAndSettle();
    expect(find.text('A CONNECTION THAT MATCHES YOUR AMBITION'),findsOneWidget);
    expect(find.text('YOUR NEXT CHAPTER'),findsOneWidget);
    expect(find.text('Welcome'),findsOneWidget);
    expect(find.text('Sign in with email'),findsOneWidget);
    expect(find.text('People in motion. Connections that go further.'),findsOneWidget);
    expect(find.text('A lifestyle in common'),findsOneWidget);
    expect(find.text('Privacy comes first'),findsOneWidget);
    expect(find.text('Términos'),findsNothing);
  });
}
