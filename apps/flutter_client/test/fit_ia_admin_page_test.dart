import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/features/fit_ia_admin_page.dart';

class FakeFitIaAdmin implements FitIaAdminRepository{
  int questionSaves=0,depthSaves=0;
  final Map<String,Map<String,dynamic>> rules={
    for(final p in ['move','live','relate'])p:{
      'pillar':p,'medium_answers':4,'medium_topics':3,
      'strong_answers':10,'strong_topics':6,
    },
  };
  final questions={
    for(final p in ['move','live','relate'])p:[
      <String,dynamic>{
        'id':p+'_001','pillar':p,'topic':'consistency',
        'prompt_es':'¿Cómo disfrutas moverte durante la semana?',
        'prompt_en':'How do you enjoy moving during the week?',
        'choices_es':[
          for(var i=1;i<=4;i++){'key':'opt_'+i.toString(),'label':'Opción '+i.toString()},
        ],
        'choices_en':[
          for(var i=1;i<=4;i++){'key':'opt_'+i.toString(),'label':'Option '+i.toString()},
        ],
        'enabled':true,
      },
    ],
  };
  @override
  Future<Map<String,dynamic>> load(String pillar)async=>{
    'questions':questions[pillar],
    'rule':rules[pillar],
  };
  @override
  Future<void> saveQuestion(Map<String,dynamic> item)async{
    questionSaves++;
    questions[item['pillar']]![0]=item;
  }
  @override
  Future<void> saveDepth(String pillar,int ma,int mt,int sa,int st)async{
    depthSaves++;
    rules[pillar]={
      'pillar':pillar,'medium_answers':ma,'medium_topics':mt,
      'strong_answers':sa,'strong_topics':st,
    };
  }
}
void main(){
  testWidgets('admin manages each pillar and editable depth rules',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1250,950));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final fake=FakeFitIaAdmin();
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:FitIaAdminPage(
      repository:fake))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-admin-page')),findsOneWidget);
    expect(find.text('Administrar Fit-IA'),findsOneWidget);
    expect(find.byKey(const Key('fit-ia-admin-question-move_001')),findsOneWidget);
    await tester.tap(find.byKey(const Key('fit-ia-admin-configure-depth')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-admin-save-depth')),findsOneWidget);
    await tester.tap(find.byKey(const Key('fit-ia-admin-save-depth')));
    await tester.pumpAndSettle();
    expect(fake.depthSaves,1);
    await tester.tap(find.byKey(const Key('fit-ia-admin-edit-move_001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fit-ia-admin-save-question')));
    await tester.pumpAndSettle();
    expect(fake.questionSaves,1);
    await tester.tap(find.byKey(const Key('fit-ia-admin-pillar-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-admin-question-live_001')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
