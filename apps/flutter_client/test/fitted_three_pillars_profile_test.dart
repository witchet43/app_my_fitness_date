import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/rhythm_concept_lab_b10.dart';

void main() {
  testWidgets('profile shows three steps and keeps answers across navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1150,900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home:RhythmConceptLabB10(
      profileMode:true,
    )));
    expect(find.text('Cómo me muevo'),findsWidgets);
    expect(find.text('Cómo vivo'),findsWidgets);
    expect(find.text('Cómo me relaciono'),findsWidgets);
    expect(find.text('Actividad principal'),findsOneWidget);
    expect(find.text('Ritmo de sueño'),findsNothing);
    await tester.tap(find.byKey(const Key('pillar-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('Ritmo de sueño'),findsOneWidget);
    expect(find.text('Actividad principal'),findsNothing);
    await tester.tap(find.byKey(const Key('pillar-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('Qué busco'),findsOneWidget);
    expect(find.text('Tiempo juntos e independencia'),findsOneWidget);
    expect(find.text('Guardar mis tres pilares'),findsOneWidget);
    final button=tester.widget<FilledButton>(find.byKey(const Key('pillars-save')));
    expect(button.onPressed,isNull,
      reason:'Saving is blocked before separate FitDating consent');
    await tester.tap(find.byKey(const Key('pillar-tab-0')));
    await tester.pumpAndSettle();
    expect(find.text('Actividad principal'),findsOneWidget);
  });
}
