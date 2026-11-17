import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/fit_ia_repository.dart';
import 'package:my_fitness_date/src/features/fit_ia_natural_chat_page.dart';

class FakeNatural implements FitIaRepository{
  final Map<String,List<Map<String,dynamic>>> chats={
    for(final key in FitIaDepth.keys)key:[],
  };
  final Map<String,int> useful={
    for(final key in FitIaDepth.keys)key:0,
  };
  final Map<String,String> descriptions={
    'move':'',
    'live':'',
    'relate':'',
  };
  bool consent=true;
  bool fakeOutage=false;
  int sent=0,reads=0,retries=0,consentActions=0;
  FakeNatural(){
    for(final key in FitIaDepth.keys){
      chats[key]!.add({
        'id':1,'role':'assistant','kind':'assistant_text',
        'text':key=='move'
          ?'¡Hola! ¿Qué actividad te hace sentir más en movimiento?'
          :'¡Hola! ¿Qué aspecto de este pilar te gustaría compartir?',
      });
    }
  }
  Map<String,dynamic> chat(String pillar)=>{
    'status':!consent?'consent_required':
      fakeOutage?'ai_unavailable':'ok',
    'pillar':pillar,'ai_enabled':consent,
    'conversation_mode':'ai_only',
    'messages':chats[pillar],
    'quick_options':[
      'Me gusta correr','Caminar sin prisas',
      'Entrenar con amigos','Prefiero variar',
    ],
    'depth':{
      'level':useful[pillar]!>=4?'medium':'weak',
      'answered':useful[pillar],'topics':useful[pillar],
    },
    'brief':{
      'es':descriptions[pillar],
      'en':descriptions[pillar],
    },
    'needs_response':fakeOutage,
    'total_messages':chats[pillar]!.length,
    'has_more':false,
  };
  @override
  Future<Map<String,dynamic>> fitIaChatState(String pillar,
    {String locale='es'})async{reads++;return chat(pillar);}
  @override
  Future<Map<String,dynamic>> fitIaChatSend(String pillar,String text,
      String clientId,{String locale='es'})async{
    sent++;
    chats[pillar]!.add({
      'id':sent*2,'role':'user','kind':'user_text',
      'text':text,
    });
    if(!fakeOutage){
      if(text.toLowerCase().contains('correr'))useful[pillar]=useful[pillar]!+1;
      descriptions[pillar]='Compartiste que: '+text+'.';
      chats[pillar]!.add({
        'id':sent*2+1,'role':'assistant','kind':'assistant_text',
        'text':text.toLowerCase().contains('nada')
          ?'¡Vaya giro! Sigamos con algo que te mueva. '
           '¿Qué actividad disfrutas más?'
          :'Me interesa ese detalle. ¿Qué parte te gusta más?',
      });
    }
    return chat(pillar);
  }
  @override
  Future<Map<String,dynamic>> fitIaChatRetry(String pillar,
      {String locale='es'})async{
    retries++;
    fakeOutage=false;
    chats[pillar]!.add({
      'id':100+retries,'role':'assistant','kind':'assistant_text',
      'text':'Volvamos a tu deporte. ¿Qué es lo que más disfrutas?',
    });
    return chat(pillar);
  }
  @override
  Future<Map<String,dynamic>> fitIaInsights(String pillar)async=>{
    'answers':[
      for(final entry in chats[pillar]!.where(
        (x)=>x['role']=='user'))
      {
        'question_es':'¿Qué te gusta de esta actividad?',
        'question_en':'What do you enjoy about this activity?',
        'answer_es':entry['text'],
        'answer_en':entry['text'],
      },
    ],
  };
  @override
  Future<Map<String,dynamic>> fitIaConsent(bool enabled)async{
    consent=enabled;consentActions++;
    return {'ai_enabled':enabled};
  }
  @override
  Future<Map<String,dynamic>> fitIaOverview()async=>{
    for(final key in FitIaDepth.keys)key:{
      'level':'weak','answered':useful[key],'topics':useful[key],
    },
    'ai_enabled':consent,
  };
  @override
  Future<Map<String,dynamic>> fitIaState(String pillar)async=>{};
  @override
  Future<Map<String,dynamic>> fitIaAnswer(
      String pillar,String questionId,String choiceKey,
      {String locale='es'})async=>{};
  @override
  Future<Map<String,dynamic>> fitIaForm(String pillar)async=>{};
  @override
  Future<Map<String,dynamic>> fitIaSubmitForm(String pillar,
      List<Map<String,String>> answers)async=>{};
  @override
  Future<Map<String,dynamic>> fitIaGenerateSummary()async=>{};
  @override
  Future<void> fitIaDeleteMyData()async{
    for(final key in FitIaDepth.keys){
      chats[key]!.clear();useful[key]=0;descriptions[key]='';
    }
    consent=false;
  }
}
void main(){
  testWidgets('Desktop AI-only chat offers free typing, four dynamic choices '
    'and evolving summary', (tester)async{
    await tester.binding.setSurfaceSize(const Size(1370,940));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final api=FakeNatural();
    await tester.pumpWidget(MaterialApp(
      home:FitIaNaturalChatPage(repository:api)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-natural-conversation-page')),
      findsOneWidget);
    expect(find.byKey(const Key('fit-ia-insights-panel')),
      findsOneWidget);
    expect(find.byKey(const Key('fit-ia-executive-summary')),
      findsOneWidget);
    expect(find.byKey(const Key('fit-ia-message-input')),
      findsOneWidget);
    expect(find.text('Formulario'),findsNothing);
    for(var i=0;i<4;i++){
      expect(find.byKey(Key('fit-ia-quick-option-$i')),findsOneWidget);
    }
    await tester.enterText(find.byKey(const Key('fit-ia-message-input')),
      'Me gusta correr por las mañanas');
    await tester.tap(find.byKey(const Key('fit-ia-send')));
    await tester.pumpAndSettle();
    expect(api.sent,1);
    expect(api.chats['move']!.length,3);
    expect(find.text('Me gusta correr por las mañanas'),findsWidgets);
    expect(find.textContaining('Compartiste que:'),findsOneWidget);
    await tester.tap(find.byKey(const Key('fit-ia-pillar-1')));
    await tester.pumpAndSettle();
    expect(api.chats['live']!.length,1);
    await tester.tap(find.byKey(const Key('fit-ia-pillar-0')));
    await tester.pumpAndSettle();
    expect(api.chats['move']!.length,3,
      reason:'Return to any pillar must preserve the dialogue');
    expect(tester.takeException(),isNull);
  });

  testWidgets('Mobile quick replies and nonsense are still guided by agent',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(414,880));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final api=FakeNatural();
    await tester.pumpWidget(MaterialApp(
      home:FitIaNaturalChatPage(repository:api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fit-ia-quick-option-0')));
    await tester.pumpAndSettle();
    expect(api.sent,1);
    expect(api.useful['move'],1);
    await tester.enterText(find.byKey(const Key('fit-ia-message-input')),
      'nada nada bla bla');
    await tester.tap(find.byKey(const Key('fit-ia-send')));
    await tester.pumpAndSettle();
    expect(api.sent,2);
    expect(api.useful['move'],1,
      reason:'Off-topic/nonsense must not increase depth');
    expect(find.textContaining('Sigamos con algo'),findsWidgets);
    await tester.tap(find.byKey(const Key('fit-ia-mobile-insights')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-executive-summary')),
      findsWidgets);
    expect(tester.takeException(),isNull);
  });

  testWidgets('AI-only gate requires explicit permission, then resumes',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(420,880));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final api=FakeNatural()..consent=false;
    await tester.pumpWidget(MaterialApp(
      home:FitIaNaturalChatPage(repository:api)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fit-ia-enable-ai')),findsOneWidget);
    expect(find.byKey(const Key('fit-ia-message-input')),findsNothing);
    await tester.tap(find.byKey(const Key('fit-ia-enable-ai')));
    await tester.pumpAndSettle();
    expect(api.consentActions,0,
      reason:'Opening consent dialog cannot enable AI');
    await tester.tap(find.byKey(const Key('fit-ia-confirm-consent')));
    await tester.pumpAndSettle();
    expect(api.consentActions,1);
    expect(find.byKey(const Key('fit-ia-message-input')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('Provider outage preserves the user message and retries',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1200,880));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final api=FakeNatural();
    await tester.pumpWidget(MaterialApp(
      home:FitIaNaturalChatPage(repository:api)));
    await tester.pumpAndSettle();
    api.fakeOutage=true;
    await tester.enterText(find.byKey(const Key('fit-ia-message-input')),
      'Correr sin prisa');
    await tester.tap(find.byKey(const Key('fit-ia-send')));
    await tester.pumpAndSettle();
    expect(api.chats['move']!.where((x)=>x['role']=='user').length,1);
    expect(find.byKey(const Key('fit-ia-retry')),findsOneWidget);
    await tester.tap(find.byKey(const Key('fit-ia-retry')));
    await tester.pumpAndSettle();
    expect(api.retries,1);
    expect(api.chats['move']!.where((x)=>x['role']=='user').length,1,
      reason:'Retry must never duplicate a saved user message');
    expect(tester.takeException(),isNull);
  });
}
