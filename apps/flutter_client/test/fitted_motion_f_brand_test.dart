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
    expect(FitDateColors.aqua,Color.lerp(
      const Color(0xFF8EF0D5),const Color(0xFFB7C6CF),.44));
    expect(FitDateColors.pulsePink,Color.lerp(
      const Color(0xFF68D4C7),const Color(0xFFB7C6CF),.42));
    final theme=brand.toTheme();
    expect(theme.colorScheme.primary,const Color(0xFF8EF0D5));
    expect(theme.scaffoldBackgroundColor,const Color(0xFF1A2D38));
    expect(theme.colorScheme.onPrimary,Colors.black);
  });

  test('changing Brand Designer name and palette updates all semantic tokens',(){
    final custom=LiveBrandSettings.fromMap({
      ...LiveBrandSettings.fallback.toMap(),
      'name':'Nueva Marca',
      'paletteName':'Grafito',
      'colors':{'primary':'#DDE7EC','accent':'#8196A2','background':'#101B21'},
      'mode':'dark',
    });
    final appTheme=custom.toTheme();
    expect(custom.name,'Nueva Marca');
    expect(appTheme.colorScheme.primary,const Color(0xFFDDE7EC));
    expect(appTheme.scaffoldBackgroundColor,const Color(0xFF101B21));
    expect(appTheme.appBarTheme.backgroundColor,const Color(0xFF101B21));
    expect(FitDateColors.coral,const Color(0xFFDDE7EC));
    expect(FitDateColors.lime,const Color(0xFF8196A2));
    expect(FitDateColors.inkDeep,const Color(0xFF101B21));
    expect(FitDateColors.lilac,isNot(const Color(0xFF8EF0D5)));
    final light=LiveBrandSettings.fromMap({
      ...custom.toMap(),
      'colors':{'primary':'#435766','accent':'#708FA2','background':'#F4F5F2'},
      'mode':'light',
    });
    light.toTheme();
    expect(FitDateColors.pearl,const Color(0xFF172731));
    expect(FitDateColors.surface,isNot(const Color(0xFF101B21)));
    LiveBrandSettings.fallback.toTheme();
    expect(FitDateColors.coral,const Color(0xFF8EF0D5));
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
