import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/fitted_two_panel_home_b18.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

void main(){
  const realManual='Me interesa crear una conexión tranquila y auténtica. '
    'Disfruto salir a correr, conocer rutas nuevas y cuidar mi equilibrio '
    'entre el deporte, mis actividades cotidianas y el tiempo para conversar. '
    'Para mí la constancia, el respeto y la comunicación son importantes. '
    'Me gusta que cada quien conserve su independencia y construir confianza '
    'de forma gradual, sin prisas ni expectativas superficiales.';

  testWidgets('Story dominates the hero; three pillars are compact at top right',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1210,950));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    var edited=0;final tapped=<int>[];
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(
        child:FittedIdentityPanelB18(
          name:'Alex',rhythm:null,photo:null,
          summary:{
            'ai_consented':false,'share_consented':false,
            'summary_es':realManual,'summary_en':realManual,
            'mode':'manual',
          },
          summaryBusy:false,onEdit:(){},
          onPillar:tapped.add,onSummaryConsent:(){},
          onManualEdit:()=>edited++,
        )))));
    await tester.pumpAndSettle();
    final corner=find.byKey(const Key('b19-compact-pillars'));
    final story=find.byKey(const Key('b18-profile-summary'));
    expect(corner,findsOneWidget);
    expect(story,findsOneWidget);
    expect(find.text('Tu ritmo, en palabras'),findsOneWidget);
    expect(find.text(realManual),findsOneWidget);
    expect(tester.getTopLeft(corner).dx,
      greaterThan(tester.getTopLeft(story).dx));
    expect(tester.getTopLeft(corner).dy,
      lessThan(tester.getTopLeft(story).dy));
    expect(find.byKey(const Key('b19-edit-manual-story')),findsOneWidget);
    await tester.tap(find.byKey(const Key('b19-edit-manual-story')));
    expect(edited,1);
    await tester.tap(find.byKey(const Key('b18-pillar-2')));
    expect(tapped,[2]);
    expect(tester.takeException(),isNull);
  });

  testWidgets('AI on hides manual writing pen and displays full long narrative',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1200,980));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final story=List.generate(4,(_)=>
      'Esta persona disfruta actividades al aire libre y señala '
      'que aprecia la comunicación, la constancia y el respeto.')
      .join('\n\n');
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(
        child:FittedIdentityPanelB18(
          name:'Ana',rhythm:null,photo:null,
          summary:{'ai_consented':true,'mode':'ai',
            'share_consented':false,'summary_es':story,'summary_en':story},
          summaryBusy:false,onPillar:(_){},onEdit:(){},
          onSummaryConsent:(){},
          onManualEdit:()=>fail('AI mode must not expose editing'),
        )))));
    await tester.pumpAndSettle();
    expect(find.text(story),findsOneWidget);
    expect(find.byKey(const Key('b19-edit-manual-story')),findsNothing);
    expect(find.text('IA'),findsOneWidget);
    expect(find.text('Gestionar IA y visibilidad'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('Mobile puts compact pillars below heading and keeps writing readable',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(390,830));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(
        child:FittedIdentityPanelB18(
          name:'Ana',rhythm:null,photo:null,
          summary:{'ai_consented':false,'mode':'manual',
            'summary_es':realManual,'summary_en':realManual},
          summaryBusy:false,onPillar:(_){},onEdit:(){},
          onSummaryConsent:(){},onManualEdit:(){},
        )))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b19-compact-pillars')),findsOneWidget);
    expect(find.byKey(const Key('b19-edit-manual-story')),findsOneWidget);
    expect(find.text(realManual),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
