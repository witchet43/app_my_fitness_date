import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fitness_date/src/core/live_brand.dart';
import 'package:my_fitness_date/src/features/public_entry_shell.dart';

void main() {
  test('safe global settings reject arbitrary domains and untrusted font', () {
    final data = LiveBrandSettings.fallback.toMap();
    data['name'] = 'Ritmo y Vida';
    data['logo'] = 'https://attacker.example/logo.svg';
    data['font'] = 'evil-script';
    data['media'] = {'cover_desktop':'https://example.test/cover.png'};
    final resolved = LiveBrandSettings.fromMap(data);
    expect(resolved.name,'Ritmo y Vida');
    expect(resolved.logo,'catalog:0');
    expect(resolved.font,'Arial');
    expect(resolved.media,isEmpty);
  });

  test('brand colors and contrast change without recompilation', () {
    final data = LiveBrandSettings.fallback.toMap();
    data['colors'] = {
      'primary':'#28463D',
      'accent':'#B49A6A',
      'background':'#F7F5F0',
    };
    data['mode'] = 'light';
    final brand = LiveBrandSettings.fromMap(data);
    expect(brand.primaryColor,const Color(0xFF28463D));
    expect(brand.toTheme().brightness,Brightness.light);
    expect(brand.toTheme().scaffoldBackgroundColor,
      const Color(0xFFF7F5F0));
  });

  test('public asset path must be from single approved Storage bucket', () {
    const good = 'https://jtrdvnwbxpfdnbzasvcj.supabase.co/storage/v1/object/'
      'public/mfd-brand-live/bc8e3ef2-a487-46da-b3d1-d0747607a4bc/'
      '1987634467-e12a.png';
    expect(LiveBrandSettings.safeAssetUrl(good),isTrue);
    expect(LiveBrandSettings.safeAssetUrl(good+'?x=1'),isFalse);
    expect(LiveBrandSettings.safeAssetUrl(
      good.replaceFirst('mfd-brand-live/','mfd-brand-drafts/')),isFalse);
    expect(LiveBrandSettings.safeAssetUrl(
      good.replaceFirst('.png','.svg')),isFalse);
  });

  testWidgets('anonymous landing renders stored name, headline and copy',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = LiveBrandSettings.fallback.toMap();
      data['name'] = 'Ritmo y Vida';
      data['title'] = 'Personas que disfrutan moverse.';
      data['description'] = 'Comparte actividades deportivas auténticas.';
      data['tagline'] = 'En movimiento.';
      data['logo'] = 'catalog:3';
      final brand=LiveBrandSettings.fromMap(data);
      await tester.pumpWidget(MaterialApp(
        theme:brand.toTheme(),
        home:LiveBrandScope(brand:brand,child:const PublicEntryShell()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Ritmo y Vida'),findsOneWidget);
      expect(find.text('Personas que disfrutan moverse.'),findsOneWidget);
      expect(find.text('Comparte actividades deportivas auténticas.'),
        findsOneWidget);
      expect(find.text('EN MOVIMIENTO.'),findsOneWidget);
      expect(tester.takeException(),isNull);
    },
  );
}
