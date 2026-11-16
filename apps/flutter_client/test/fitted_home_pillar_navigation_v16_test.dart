import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/fitted_affinity_home_v16.dart';
import 'package:my_fitness_date/src/features/rhythm_concept_lab_b10.dart';
import 'package:my_fitness_date/src/widgets/fitted_rhythm_hero.dart';
import 'package:my_fitness_date/src/core/fitted_profile_insights_v29.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

void main() {
  testWidgets('Spanish home hero pillars are tappable at mobile width',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390,890));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final tapped=<int>[];
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(child:FittedRhythmHero(
        titleEs:'Tu ritmo',titleEn:'Your rhythm',
        subtitleEs:'Tu estilo de vida',subtitleEn:'Your lifestyle',
        onSelectPillar:tapped.add,
      )))));
    await tester.pumpAndSettle();
    expect(find.text('Cómo me muevo'),findsOneWidget);
    expect(find.text('Cómo vivo'),findsOneWidget);
    expect(find.text('Cómo me relaciono'),findsOneWidget);
    for(final key in ['hero-pillar-move','hero-pillar-live','hero-pillar-relate']){
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }
    expect(tapped,equals([0,1,2]));
    expect(tester.takeException(),isNull);
  });

  testWidgets('Direct navigation opens the requested private lifestyle editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1050,1200));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    for(final item in [
      (0,'Cómo me muevo · Mi actividad'),
      (1,'Cómo vivo · Mi ritmo'),
      (2,'Cómo me relaciono · Mi manera de conectar'),
    ]){
      await tester.pumpWidget(MaterialApp(
        theme:FitDateTheme.dark(),
        home:RhythmConceptLabB10(profileMode:true,initialPillar:item.$1)));
      await tester.pumpAndSettle();
      expect(find.text(item.$2),findsOneWidget);
      expect(find.byKey(Key('pillar-tab-${item.$1}')),findsOneWidget);
      expect(tester.takeException(),isNull);
    }
  });

  testWidgets('Home shows saved coverage, not a fictitious match score or agenda',
      (tester)async{
    await tester.binding.setSurfaceSize(const Size(390,900));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final sections=<int>[];
    var discovery=0;
    final rhythm={
      'answers':{
        'sport':'running','frequency':'two_three',
        'weekday':'early_training','intent':'long_term',
        'together':'balanced',
      },
    };
    final expected=FittedProfileInsights.overallProgress(rhythm);
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(
        child:FittedAffinityHomeV16(
          rhythm:rhythm,
          onConfigurePillar:sections.add,
          onDiscover:()=>discovery++,
        ),
      ))));
    await tester.pumpAndSettle();
    expect(find.text('Tu perfil de afinidad'),findsOneWidget);
    expect(find.text('$expected%'),findsOneWidget);
    expect(find.textContaining('no un porcentaje de compatibilidad'),
      findsOneWidget);
    expect(find.text('Tu próxima actividad'),findsNothing);
    await tester.ensureVisible(find.byKey(const Key('affinity-open-pillar-1')));
    await tester.tap(find.byKey(const Key('affinity-open-pillar-1')));
    await tester.pump();
    expect(sections,[1]);
    await tester.ensureVisible(find.byKey(const Key('affinity-see-matches')));
    await tester.tap(find.byKey(const Key('affinity-see-matches')));
    await tester.pump();
    expect(discovery,1);
    expect(tester.takeException(),isNull);
  });
}
