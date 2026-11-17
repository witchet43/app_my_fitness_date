import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/live_brand.dart';
import 'package:my_fitness_date/src/widgets/fitted_color_picker.dart';
import 'package:my_fitness_date/src/widgets/fitted_logo_catalog.dart';
import 'package:my_fitness_date/src/widgets/fitted_font_catalog.dart';
import 'package:my_fitness_date/src/widgets/mfd_branding.dart';

void main(){
  test('font catalogue offers over 100 real Google Font families',(){
    expect(FittedFontCatalog.available.length,greaterThan(100));
    expect(FittedFontCatalog.accepts('Arial'),isTrue);
    expect(FittedFontCatalog.accepts('Montserrat'),isTrue);
    expect(FittedFontCatalog.accepts('___UNTRUSTED___'),isFalse);
  });

  test('athletic icon names describe movement, shared activities and fitness',(){
    expect(FittedLogoCatalog.names.length,21);
    expect(FittedLogoCatalog.names[1],'Zancada compartida');
    expect(FittedLogoCatalog.names[2],'Fuerza en pareja');
    expect(FittedLogoCatalog.names[3],'Ciclismo en dúo');
    expect(FittedLogoCatalog.names.toSet().length,21);
  });

  test('twenty distinct vector proposals plus approved F are stable IDs',(){
    expect(FittedLogoCatalog.names.length,21);
    expect(FittedLogoCatalog.descriptions.length,21);
    expect(FittedLogoCatalog.names.toSet().length,21);
    for(var i=0;i<21;i++){
      final s=LiveBrandSettings.fallback.toMap();
      s['logo']='catalog:$i';
      expect(LiveBrandSettings.fromMap(s).logo,'catalog:$i');
    }
    final invalid=LiveBrandSettings.fallback.toMap();
    invalid['logo']='catalog:21';
    expect(LiveBrandSettings.fromMap(invalid).logo,'catalog:0');
  });

  testWidgets('all twenty original vector symbols paint without overflows',
    (tester)async{
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:
      SingleChildScrollView(child:Wrap(children:[
        for(var i=1;i<=20;i++)
          FittedLogoGlyph(
            key:Key('original-logo-$i'),
            index:i,size:54,
            primary:const Color(0xFFDDE7EC),
            accent:const Color(0xFF8196A2)),
      ])))));
    await tester.pumpAndSettle();
    for(var i=1;i<=20;i++){
      expect(find.byKey(Key('original-logo-$i')),findsOneWidget);
    }
    expect(tester.takeException(),isNull);
  });

  testWidgets('selected brand name remains next to alternative vector logo',
    (tester)async{
    final data=LiveBrandSettings.fallback.toMap();
    data['name']='Nuevo Nombre';
    data['logo']='catalog:20';
    final active=LiveBrandSettings.fromMap(data);
    await tester.pumpWidget(MaterialApp(
      theme:active.toTheme(),
      home:LiveBrandScope(brand:active,
        child:const Scaffold(body:MfdBranding(full:true,width:260)))));
    await tester.pumpAndSettle();
    expect(find.text('NUEVO NOMBRE'),findsOneWidget);
    expect(find.byType(FittedLogoGlyph),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('HSV picker supports visual color selection and cancel',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(360,760));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    Color? selected;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:
      Builder(builder:(context)=>FilledButton(
        onPressed:()async=>selected=await FittedColorPicker.show(context,
          label:'Primario',initialColor:const Color(0xFFDDE7EC)),
        child:const Text('Abrir selector'))))));
    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brand-hsv-sv')),findsOneWidget);
    expect(find.byKey(const Key('brand-hsv-hue')),findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('brand-preset-#8EF0D5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('brand-preset-#8EF0D5')));
    await tester.pump();
    final field=tester.widget<TextField>(find.byKey(const Key('brand-hsv-hex')));
    expect(field.controller?.text,'#8EF0D5');
    await tester.tap(find.byKey(const Key('brand-hsv-apply')));
    await tester.pumpAndSettle();
    expect(selected,const Color(0xFF8EF0D5));
    expect(tester.takeException(),isNull);
  });
}
