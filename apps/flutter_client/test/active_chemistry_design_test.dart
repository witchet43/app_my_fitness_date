import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/app.dart';
import 'package:my_fitness_date/src/core/api_client.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

void main() {
  testWidgets('Marca Active Chemistry, contraste y CTA real en desktop',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    expect(find.text('My Fitness Date'), findsOneWidget);
    expect(find.byKey(const Key('brand-hero-headline')), findsOneWidget);
    expect(find.text('FitCommunity'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    final theme = Theme.of(tester.element(find.byType(NavigationRail)));
    expect(theme.colorScheme.primary, FitDateColors.coral);
    expect(theme.colorScheme.secondary, FitDateColors.lime);
    expect(theme.scaffoldBackgroundColor, FitDateColors.inkDeep);
    await tester.tap(find.byKey(const Key('go-to-pace')));
    await tester.pumpAndSettle();
    expect(find.text('Calculadora de ritmo de carrera'), findsOneWidget);
    expect(find.text('6:00 min/km'), findsOneWidget);
  });

  testWidgets('Vista móvil sin perfiles inventados y Gym Shield ilustrativo',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.text('Citas'));
    await tester.pumpAndSettle();
    expect(find.text('FitDating · Gym Shield'), findsOneWidget);
    expect(find.text('VISTA PREVIA · SIN PERFILES REALES'), findsOneWidget);
    expect(find.textContaining('sin perfiles reales'), findsNothing);
    expect(find.byKey(const Key('qa-identity-action')), findsNothing);
  });

  testWidgets('El héroe conduce a vista previa, no a registros ficticios',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    await tester.ensureVisible(find.byKey(const Key('go-to-dating')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('go-to-dating')));
    await tester.pumpAndSettle();
    expect(find.text('FitDating · Gym Shield'), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.textContaining('Esta selección es solo ilustrativa'),
        findsOneWidget);
  });
}
