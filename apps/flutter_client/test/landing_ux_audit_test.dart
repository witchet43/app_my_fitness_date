import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';

void main(){
  Widget page({VoidCallback? email,Size? viewport})=>MaterialApp(
    builder:(context,child)=>viewport==null?child!:
      MediaQuery(data:MediaQueryData(size:viewport),child:child!),
    home:LiveBrandScope(
      brand:LiveBrandSettings.fallback,
      child:PublicEntryShell(
        termsUrl:'https://example.org/terms',
        privacyUrl:'https://example.org/privacy',
        onGoogle:(){},onApple:(){},
        onEmailSignIn:email??(){},
      ),
    ),
  );
  testWidgets('mobile keeps access near top, without duplicate brand',
    (tester) async{
      await tester.binding.setSurfaceSize(const Size(375,812));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('landing-hero')),findsOneWidget);
      expect(find.byKey(const Key('landing-access')),findsOneWidget);
      expect(find.text('Fitted'),findsOneWidget);
      expect(find.text('Términos'),findsOneWidget);
      expect(find.text('Privacidad'),findsOneWidget);
      final heroTop=tester.getTopLeft(find.byKey(const Key('landing-hero'))).dy;
      final accessTop=tester.getTopLeft(find.byKey(const Key('landing-access'))).dy;
      expect(accessTop,greaterThan(heroTop));
      expect(accessTop,lessThan(1100),
        reason:'The photographic hero must be followed by an accessible registration panel');
      expect(find.byKey(const Key('landing-create-profile')),findsNothing);
      expect(find.ancestor(of:find.byKey(const Key('landing-access')),
        matching:find.byKey(const Key('landing-hero'))),findsOneWidget);
      expect(tester.takeException(),isNull);
    });
  testWidgets('desktop integrates image and registration inside the same hero',
    (tester) async{
      await tester.binding.setSurfaceSize(const Size(1280,900));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(page(viewport:const Size(1280,900)));
      await tester.pumpAndSettle();
      final hero=tester.getTopLeft(find.byKey(const Key('landing-hero')));
      final login=tester.getTopLeft(find.byKey(const Key('landing-access')));
      expect(hero.dy,isNonNegative);
      expect(login.dy,greaterThan(hero.dy));
      expect(find.ancestor(of:find.byKey(const Key('landing-access')),
        matching:find.byKey(const Key('landing-hero'))),findsOneWidget);
      expect(find.byKey(const Key('landing-editorial-photo')),findsOneWidget);
      expect(find.byKey(const Key('anonymous-pace-tool')),findsNothing);
      expect(tester.takeException(),isNull);
    });
  testWidgets('legal links do not require consent on returning login',
    (tester) async{
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile),findsNothing);
      expect(find.byKey(const Key('switch-entry-mode')),findsOneWidget);
      expect(find.byType(CheckboxListTile),findsNothing);
    });
}
