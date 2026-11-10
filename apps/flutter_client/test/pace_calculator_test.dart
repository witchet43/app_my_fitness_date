import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/pace_calculator.dart';

void main() {
  testWidgets('Calculadora pública muestra 5 km en 30 min = 6:00 min/km',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: PaceCalculator())),
    ));
    expect(find.text('6:00 min/km'), findsOneWidget);
    expect(find.text('10.0 km/h'), findsOneWidget);
  });

  testWidgets('Recalcula ritmo al cambiar distancia, sin enviar datos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: PaceCalculator())),
    ));
    await tester.enterText(find.byKey(const Key('pace-distance')), '10');
    await tester.pump();
    expect(find.text('3:00 min/km'), findsOneWidget);
    expect(find.text('20.0 km/h'), findsOneWidget);
  });

  testWidgets('Entrada inválida se rechaza sin dividir entre cero',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: PaceCalculator())),
    ));
    await tester.enterText(find.byKey(const Key('pace-distance')), '0');
    await tester.pump();
    expect(find.byKey(const Key('pace-validation')), findsOneWidget);
    expect(find.byKey(const Key('pace-result')), findsNothing);
    await tester.enterText(find.byKey(const Key('pace-distance')), '5,5');
    await tester.pump();
    expect(find.byKey(const Key('pace-result')), findsOneWidget);
  });
}
