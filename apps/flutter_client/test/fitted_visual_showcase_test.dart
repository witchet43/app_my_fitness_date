import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/qa/fitted_visual_showcase.dart';

void main() {
  testWidgets('visual QA is explicitly synthetic and shows all real screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1050, 900));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FittedVisualShowcase());
    expect(find.textContaining('PREVIEW NO PRODUCTIVA'), findsOneWidget);
    expect(find.byKey(const Key('landing-hero')), findsOneWidget);
    await tester.tap(find.byKey(const Key('preview-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-compact-identity')), findsOneWidget);
    expect(find.text('How I Move'), findsWidgets);
    expect(find.text('How I Live'), findsWidgets);
    expect(find.text('How I Relate'), findsWidgets);
    await tester.tap(find.byKey(const Key('preview-tab-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('v26-profile-editor')), findsOneWidget);
    expect(find.byKey(const Key('fitted-rhythm-hero')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
