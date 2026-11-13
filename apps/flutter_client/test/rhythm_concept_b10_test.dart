import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/rhythm_concept_b10.dart';
import 'package:my_fitness_date/src/features/rhythm_concept_lab_b10.dart';

void main() {
  test('cross-sport compatibility is explained without an arbitrary score', () {
    final self = emptyRhythmB10();
    final example = hypotheticalRhythmB10('cross_sport');
    final reasons = explainRhythmB10(self,example);
    expect(reasons.length,6);
    expect(reasons.take(4).every((r)=>r.importance=='high'),true);
    expect(reasons[4].importance,'medium');
    expect(reasons.last.importance,'low');
    expect(reasons.last.reasonEs,contains('deportes distintos'));
    expect(reasons.map((r)=>r.message(english:true)).join(' '),
      isNot(contains('%')));
    expect(reasons.map((r)=>r.message(english:false)).join(' '),
      isNot(contains('gimnasio')));
    expect(reasons.map((r)=>r.message(english:true)).join(' '),
      isNot(contains('location')));
    expect(()=>reasons.add(reasons.first),throwsUnsupportedError);
  });

  test('explainable reasons do not reveal private gym or exact routine', () {
    final owner = emptyRhythmB10();
    owner['gym_id']='PRIVATE_GYM_DO_NOT_LEAK';
    owner['exact_schedule']='06:35';
    final reasons = explainRhythmB10(
      owner,hypotheticalRhythmB10('same_sport_other_rhythm'),
    );
    final full = reasons.map((r)=>r.reasonEs+' '+r.reasonEn).join(' ');
    expect(full, isNot(contains('PRIVATE_GYM_DO_NOT_LEAK')));
    expect(full, isNot(contains('06:35')));
    expect(validateRhythmB10(owner,
      additionalSports:{},weekends:{},interests:{}),'unknown_field');
  });

  test('three layer selectors validate multi-sport and never Gym Shield C', () {
    final draft = emptyRhythmB10();
    expect(validateRhythmB10(draft,
      additionalSports:{'yoga','hyrox'},
      weekends:{'brunch'},interests:{'music'}),isNull);
    expect(rhythmOptionsB10['privacy'],
      ['exclude_gym','same_gym_different_time']);
    expect(rhythmOptionsB10['sport'],containsAll([
      'running','cycling','strength','hyrox','boxing','yoga',
      'pilates','barre','swimming','hiking','climbing','racket','crossfit',
    ]));
    expect(validateRhythmB10(draft,
      additionalSports:{'PRIVATE_GYM_DO_NOT_LEAK'},
      weekends:{},interests:{}),'invalid_preference');
    expect(hypotheticalActiveDatesB10(
      draft,hypotheticalRhythmB10('cross_sport')),
      ['yoga_brunch','museum_walk']);
  });

  testWidgets('bilingual local studio discloses no save and no real match',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,1200));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home:RhythmConceptLabB10()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b10-lab')),findsOneWidget);
    expect(find.byKey(const Key('b10-prototype-only')),findsOneWidget);
    expect(find.textContaining('No es un perfil guardado'),findsOneWidget);
    expect(find.byKey(const Key('b10-language')),findsOneWidget);
    await tester.tap(find.byKey(const Key('b10-language')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not a saved profile'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('gym mode C stays locked and Active Date is explicitly mock',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,1400));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home:RhythmConceptLabB10()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('b10-gym-c-locked')),
      380,scrollable:find.byType(Scrollable).first);
    expect(find.textContaining('No disponible'),findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('b10-active-date-ideas')),
      320,scrollable:find.byType(Scrollable).first);
    await tester.ensureVisible(find.byKey(const Key('b10-active-date-ideas')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b10-active-date-ideas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b10-after-mutual')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
