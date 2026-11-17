import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/fit_ia_repository.dart';
import 'package:my_fitness_date/src/features/fit_ia_conversation_page.dart';

class FakeFitIa implements FitIaRepository{
  final questions=<String,String>{
    'move':'¿Qué actividad disfrutas más?',
    'live':'¿Cómo te gusta comenzar el día?',
    'relate':'¿Qué valor buscas en una relación?',
  };
  final chosen=<String,String>{};
  final counts=<String,int>{'move':0,'live':0,'relate':0};
  bool ai=false;
  int saveCalls=0,consentCalls=0,deleteCalls=0,summaryCalls=0;
  String level(String pillar)=>counts[pillar]!>=10?'strong':
    counts[pillar]!>=4?'medium':'weak';
  Map<String,dynamic> depth(String pillar)=>{
    'level':level(pillar),'answered':counts[pillar],'topics':counts[pillar],
  };
  Map<String,dynamic> question(String pillar)=>{
    'id':pillar+'_001','es':questions[pillar],
    'en':'A question about '+pillar,
    'choices_es':[
      {'key':'opt_1','label':'Mi favorita'},
      {'key':'opt_2','label':'La segunda'},
      {'key':'opt_3','label':'La tercera'},
      {'key':'opt_4','label':'Depende'},
    ],
    'choices_en':[
      {'key':'opt_1','label':'My favorite'},
      {'key':'opt_2','label':'Second'},
      {'key':'opt_3','label':'Third'},
      {'key':'opt_4','label':'It depends'},
    ],
  };
  Map<String,dynamic> current(String pillar)=>{
    'pillar':pillar,
    'ai_enabled':ai,
    'conversation_mode':ai?'ai':'guided',
    'depth':depth(pillar),
    'question':question(pillar),
    'messages':[
      {'kind':'question','id':1,'es':questions[pillar],
        'en':'A question about '+pillar,
        'comment':counts[pillar]!>0?'Entiendo, me cuentas más.':''},
      if(chosen.containsKey(pillar))
        {'kind':'answer','id':2,'answer_es':chosen[pillar],
          'answer_en':'My favorite'},
    ],
  };
  @override
  Future<Map<String,dynamic>> fitIaChatState(String pillar,
      {String locale='es'})async=>current(pillar);
  @override
  Future<Map<String,dynamic>> fitIaChatSend(String pillar,
      String text,String clientId,{String locale='es'})async=>
      current(pillar);
  @override
  Future<Map<String,dynamic>> fitIaChatRetry(String pillar,
      {String locale='es'})async=>current(pillar);
  @override
  Future<Map<String,dynamic>> fitIaState(String pillar)async=>current(pillar);
  @override
  Future<Map<String,dynamic>> fitIaOverview()async=>{
    for(final key in FitIaDepth.keys)key:depth(key),
    'ai_enabled':ai,
  };
  @override
  Future<Map<String,dynamic>> fitIaForm(String pillar)async=>{
    'pillar':pillar,
    'questions':[question(pillar)],
    'depth':depth(pillar),
  };
  @override
  Future<Map<String,dynamic>> fitIaInsights(String pillar)async=>{
    'brief':{
      'es':chosen.containsKey(pillar)
        ?'Compartiste: '+chosen[pillar]!+'.'
        :'Aún no hay respuestas.',
      'en':'What you shared',
      'count':counts[pillar],
      'topics':counts[pillar],
    },
    'answers':[
      if(chosen.containsKey(pillar)){
        'question_id':pillar+'_001',
        'question_es':questions[pillar],
        'question_en':'A question about '+pillar,
        'answer_es':chosen[pillar],
        'answer_en':'My favorite',
      },
    ],
  };
  @override
  Future<Map<String,dynamic>> fitIaSubmitForm(
      String pillar,List<Map<String,String>> answers)async{
    for(final entry in answers){
      counts[pillar]=counts[pillar]!+1;
      chosen[pillar]=entry['choice_key']=='opt_1'
        ?'Mi favorita':'La segunda';
      saveCalls++;
    }
    return {'status':'saved','saved':answers.length,'depth':depth(pillar)};
  }
  @override
  Future<Map<String,dynamic>> fitIaAnswer(
      String pillar,String questionId,String choice,{String locale='es'})async{
    saveCalls++;
    counts[pillar]=counts[pillar]!+1;
    chosen[pillar]='Mi favorita';
    return current(pillar);
  }
  @override
  Future<Map<String,dynamic>> fitIaConsent(bool enabled)async{
    consentCalls++;ai=enabled;return {'ai_enabled':enabled};
  }
  @override
  Future<Map<String,dynamic>> fitIaGenerateSummary()async{
    summaryCalls++;return {'status':'more_information_needed'};
  }
  @override
  Future<void> fitIaDeleteMyData()async{
    deleteCalls++;chosen.clear();
    for(final key in counts.keys)counts[key]=0;
    ai=false;
  }
}
void main(){
  test('depth levels describe coverage, never percentages',(){
    expect(FitIaDepth.label('weak',false),'Débil');
    expect(FitIaDepth.label('medium',false),'Medio');
    expect(FitIaDepth.label('strong',false),'Fuerte');
    expect(FitIaDepth.level({'move':{'level':'strong'}},'move'),'strong');
    expect(FitIaDepth.level(null,'live'),'weak');
  });
  testWidgets('Fit-IA offers three conversations and saves each choice',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(430,930));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final repository=FakeFitIa();
    await tester.pumpWidget(MaterialApp(home:FitIaConversationPage(
      repository:repository)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-conversation-page')),findsOneWidget);
    expect(find.text('Cómo me muevo'),findsWidgets);
    expect(find.text('Cómo vivo'),findsOneWidget);
    expect(find.text('Cómo me relaciono'),findsOneWidget);
    expect(find.byKey(const Key('fit-ia-mobile-insights')),findsOneWidget);
    expect(find.text('¿Qué actividad disfrutas más?'),findsOneWidget);
    expect(find.textContaining('%'),findsNothing);
    await tester.tap(find.byKey(const Key('fit-ia-option-opt_1')));
    await tester.pumpAndSettle();
    expect(repository.saveCalls,1);
    expect(repository.chosen['move'],'Mi favorita');
    await tester.tap(find.byKey(const Key('fit-ia-pillar-1')));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo te gusta comenzar el día?'),findsOneWidget);
    await tester.tap(find.byKey(const Key('fit-ia-option-opt_1')));
    await tester.pumpAndSettle();
    expect(repository.saveCalls,2);
    await tester.tap(find.byKey(const Key('fit-ia-pillar-0')));
    await tester.pumpAndSettle();
    expect(repository.chosen['move'],'Mi favorita',
      reason:'Returning to a pillar must preserve previously saved answers.');
    expect(tester.takeException(),isNull);
  });
  testWidgets('Desktop split view, executive summary and traditional form persist',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1390,940));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final fake=FakeFitIa();
    await tester.pumpWidget(MaterialApp(home:FitIaConversationPage(
      repository:fake)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-insights-panel')),findsOneWidget);
    expect(find.byKey(const Key('fit-ia-executive-summary')),findsOneWidget);
    expect(find.text('Resumen ejecutivo'),findsOneWidget);
    expect(find.text('Nivel de conocimiento'),findsOneWidget);
    expect(find.text('Lo que he aprendido'),findsOneWidget);
    await tester.tap(find.text('Formulario'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-traditional-form')),findsOneWidget);
    await tester.tap(find.byKey(const Key('fit-ia-form-move_001-opt_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fit-ia-save-form')));
    await tester.pumpAndSettle();
    expect(fake.saveCalls,1);
    expect(fake.chosen['move'],'Mi favorita');
    expect(find.textContaining('Compartiste'),findsWidgets);
    expect(tester.takeException(),isNull);
  });

  testWidgets('AI consent is opt-in; pause retains answers',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(600,940));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final fake=FakeFitIa();
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:Builder(
      builder:(ctx)=>TextButton(onPressed:()=>Navigator.of(ctx).push(
        MaterialPageRoute<void>(builder:(_)=>FitIaConversationPage(
          repository:fake,initialPillar:2))),
        child:const Text('Start'))))));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(fake.ai,false);
    await tester.tap(find.byKey(const Key('fit-ia-enable-ai')));
    await tester.pumpAndSettle();
    expect(fake.consentCalls,0,
      reason:'Simply opening the consent dialog must never enable AI.');
    await tester.tap(find.byKey(const Key('fit-ia-confirm-consent')));
    await tester.pumpAndSettle();
    expect(fake.consentCalls,1);
    expect(fake.ai,true);
    await tester.tap(find.byKey(const Key('fit-ia-option-opt_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fit-ia-pause')));
    await tester.pumpAndSettle();
    expect(find.text('Start'),findsOneWidget);
    expect(fake.chosen['relate'],'Mi favorita');
    expect(tester.takeException(),isNull);
  });
}
