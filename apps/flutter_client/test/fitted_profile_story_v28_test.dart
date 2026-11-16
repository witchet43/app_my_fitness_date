import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/fitted_profile_story_v28.dart';

void main(){
  Widget view({Map<String,dynamic>? rhythm,VoidCallback? onEdit}) =>
    MaterialApp(home:Scaffold(body:SingleChildScrollView(child:
      FittedProfileStoryV28(
        profile:const {
          'display_name':'Persona de prueba',
          'city':'Querétaro, México',
          'headline':'No utilizar una biografía cliché',
        },
        rhythm:rhythm,
        startingPreference:null,
        onChooseStarting:(_)async{},
        onConfigure:(){},
        onEditIdentity:onEdit??(){},
      ),
    )));

  testWidgets('compact layout uses width and avoids generic bio',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200,950));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(view());
    expect(find.byKey(const Key('profile-compact-identity')),findsOneWidget);
    expect(find.byKey(const Key('profile-rhythm-snapshot')),findsOneWidget);
    expect(find.text('Cómo me muevo'),findsWidgets);
    expect(find.text('Cómo vivo'),findsWidgets);
    expect(find.text('Cómo me relaciono'),findsWidgets);
    expect(find.textContaining('Tu historia se construye con lo que haces'),
      findsOneWidget);
    expect(find.textContaining('No utilizar una biografía cliché'),findsNothing);
  });

  testWidgets('behavioral story is derived only from saved answers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430,960));
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(view(rhythm:{
      'answers':{
        'sport':'running','frequency':'four_five',
        'sleep':'early_bird','weekday':'home',
        'intent':'long_term','together':'balanced',
      },
    }));
    expect(find.textContaining('Mi rutina combina'),findsOneWidget);
    expect(find.textContaining('4–5'),findsWidgets);
    expect(find.byKey(const Key('profile-configure-pulse')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
