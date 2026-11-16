import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/fitted_two_panel_home_b18.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

void main(){
  testWidgets('Approved Fitted design unifies pillars, personal story and photo',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1160,950));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final tapped=<int>[];
    var edit=0,consent=0;
    final rhythm={'answers':{
      'sport':'running','frequency':'four_five',
      'window':'morning','training_mode':'focused',
      'weekday':'active','sleep':'early','travel':'flexible',
      'intent':'long_term','together':'balanced','train_partner':'sometimes',
    }};
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(
        child:FittedIdentityPanelB18(
          name:'Alex',rhythm:rhythm,photo:null,
          summary:{'available':true,'summary_es':'Alex corre y disfruta actividades al aire libre. Busca conexiones que respeten el espacio personal y valora la conversación.',
            'summary_en':'Alex enjoys running and outdoor activities. Looking for meaningful conversations.','share_consented':false,'mode':'editorial'},
          summaryBusy:false,
          onPillar:tapped.add,onEdit:()=>edit++,
          onSummaryConsent:()=>consent++,
        ),
      ))));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Alex. Sigue tu ritmo.'),findsOneWidget);
    expect(find.text('Cómo me muevo'),findsOneWidget);
    expect(find.text('Cómo vivo'),findsOneWidget);
    expect(find.text('Cómo me relaciono'),findsOneWidget);
    expect(find.byKey(const Key('b18-profile-summary')),findsOneWidget);
    expect(find.byKey(const Key('b18-owner-portrait')),findsOneWidget);
    for(var i=0;i<3;i++){
      await tester.tap(find.byKey(Key('b18-pillar-$i')));
    }
    expect(tapped,[0,1,2]);
    await tester.tap(find.byKey(const Key('b18-summary-consent')));
    expect(consent,1);
    await tester.tap(find.byKey(const Key('b18-owner-portrait')));
    expect(edit,1);
    expect(tester.takeException(),isNull);
  });

  testWidgets('Mobile personal story stays private and does not create fake photos',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(390,840));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(child:
        FittedIdentityPanelB18(
          name:'Ana',rhythm:null,photo:null,summary:null,
          summaryBusy:false,onPillar:(_){},onEdit:(){},
          onSummaryConsent:(){},
        ),
      ))));
    await tester.pumpAndSettle();
    expect(find.text('Privado hasta que autorices compartirlo.'),findsOneWidget);
    expect(find.text('Completa tu perfil para construir tu historia personal.'),
      findsOneWidget);
    expect(find.text('0%'),findsNWidgets(3));
    expect(tester.takeException(),isNull);
  });
}
