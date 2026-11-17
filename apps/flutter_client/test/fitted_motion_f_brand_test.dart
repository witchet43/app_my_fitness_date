import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';
import 'package:my_fitness_date/src/widgets/mfd_branding.dart';

void main(){
  test('Fitted Slate Mint palette keeps public brand and Flutter in sync',(){
    const brand=LiveBrandSettings.fallback;
    expect(brand.name,'Fitted');
    expect(brand.logo,'catalog:0');
    expect(brand.primary,'#8EF0D5');
    expect(brand.accent,'#68D4C7');
    expect(brand.background,'#1A2D38');
    expect(FitDateColors.inkDeep,const Color(0xFF1A2D38));
    expect(FitDateColors.aqua,const Color(0xFF8EF0D5));
    expect(FitDateColors.pulsePink,const Color(0xFF6BD6B7));
    final theme=brand.toTheme();
    expect(theme.colorScheme.primary,const Color(0xFF8EF0D5));
    expect(theme.scaffoldBackgroundColor,const Color(0xFF1A2D38));
    expect(theme.colorScheme.onPrimary,Colors.black);
  });

  testWidgets('real bundled motion F loads as the shared icon and wordmark',
    (tester)async{
    final bytes=await rootBundle.load('assets/branding/mfd_icon.webp');
    expect(bytes.lengthInBytes,greaterThan(2000));
    await tester.pumpWidget(MaterialApp(
      theme:LiveBrandSettings.fallback.toTheme(),
      home:LiveBrandScope(
        brand:LiveBrandSettings.fallback,
        child:const Scaffold(body:Column(children:[
          MfdBranding(full:false,width:42),
          MfdBranding(full:true,width:240),
        ])),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fitted-motion-f-mark')),findsNWidgets(2));
    expect(find.byKey(const Key('fitted-motion-wordmark')),findsOneWidget);
    expect(find.text('FITTED'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
