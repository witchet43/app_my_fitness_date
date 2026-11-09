import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/app.dart';
import 'package:my_fitness_date/src/core/api_client.dart';

void main() {
  testWidgets('Flutter starts in Community with API off by default',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    expect(find.text('FitCommunity'), findsOneWidget);
    expect(find.textContaining('API sin configurar'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Gym Shield navigation shows two privacy modes',
      (tester) async {
    await tester.pumpWidget(FitnessDateApp(api: ApiClient(baseUrl: '')));
    await tester.tap(find.text('Citas'));
    await tester.pump();
    expect(find.text('FitDating · Gym Shield'), findsOneWidget);
    expect(find.text('Otros gimnasios'), findsOneWidget);
    expect(find.text('Otro horario'), findsOneWidget);
  });
}
