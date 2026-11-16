import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_fitness_date/src/core/member_v26_api.dart';
import 'package:my_fitness_date/src/features/fitted_immersive_home_b17.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

const ids=[
  '00000000-0000-4000-8000-0000000017a1',
  '00000000-0000-4000-8000-0000000017a2',
  '00000000-0000-4000-8000-0000000017a3',
];
class FakeB17MemberApi extends MemberV26Api {
  FakeB17MemberApi({this.eligible=false}):super(
    gatewayUrl:'https://example.invalid',
    auth:SupabaseClient('https://example.supabase.co','fake-publishable'));
  final bool eligible;
  int interest=0;
  bool shared=false;
  @override
  Future<Map<String,dynamic>> mySummaryB17() async => {
    'available':true,
    'summary_es':'Alex disfruta correr, valora la autenticidad y busca '
      'conexiones con intención, respetando el espacio de cada persona.',
    'summary_en':'Alex enjoys running, values authenticity and seeks '
      'intentional connections while respecting personal space.',
    'mode':'editorial','share_consented':shared,'ai_consented':shared,
  };
  @override
  Future<Map<String,dynamic>> summaryAiCapabilityB17()async=>
    {'available':false,'private_until_opt_in':true};
  @override
  Future<Map<String,dynamic>> datingStatus()async=>{
    'status':'available',
    'enabled':eligible,'age_verified':eligible,
    'dating_consent':eligible,'participation_requested':eligible,
  };
  @override
  Future<List<Map<String,dynamic>>> discoverB11()async=>[
    for(var i=0;i<3;i++)
      {'user_id':ids[i],'display_name':'Persona de QA '+(i+1).toString(),
       'city':'Ciudad general','sports':['running']},
  ];
  @override
  Future<Map<String,dynamic>> candidateCardB17(String id)async=>{
    'visible':true,'summary_es':'Disfruta actividades deportivas '
      'y conversaciones auténticas.','photo_key':null,
  };
  @override
  Future<Map<String,dynamic>> compatibilityB11(String id)async=>
    {'available':true,'percent':88,'coverage':100};
  @override
  Future<String> likeB11(String id)async{interest++;return 'liked';}
  @override
  Future<String> setSummaryConsentB17({
    required bool ai,required bool share})async{
    shared=share;return 'updated';
  }
  @override
  Future<Map<String,dynamic>> regenerateSummaryB17()async=>
    {'status':'editorial_ready','ai_available':false};
}

Widget home(FakeB17MemberApi api,List<int> chosen,
  {VoidCallback? onDiscover,VoidCallback? onAge}){
  return MaterialApp(theme:FitDateTheme.dark(),
    home:Scaffold(body:ListView(children:[
      FittedImmersiveHomeB17(
        api:api,
        profile:{'display_name':'Alex','onboarding_complete':true},
        rhythm:{'answers':{
          'sport':'running','frequency':'two_three',
          'window':'morning','training_mode':'consistent',
          'weekday':'early_training','sleep':'early_bird',
          'travel':'train_away','intent':'long_term',
          'together':'balanced','train_partner':'nice_to_have',
        }},
        photos:const [],
        onConfigurePillar:chosen.add,
        onEditProfile:(){},
        onUploadPhoto:(){},
        onDiscover:onDiscover??(){},
        onVerifyAge:onAge??(){},
      ),
    ])));
}

void main(){
  testWidgets('B17 wide-screen screenshot layout has only two core panels',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1448,1086));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final chosen=<int>[];
    final api=FakeB17MemberApi();
    await tester.pumpWidget(home(api,chosen));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fitted-member-dashboard')),findsOneWidget);
    expect(find.byKey(const Key('b17-fits-panel')),findsOneWidget);
    expect(find.byKey(const Key('b17-ai-story')),findsOneWidget);
    expect(find.byKey(const Key('b17-my-photo')),findsOneWidget);
    expect(find.text('Cómo me muevo'),findsOneWidget);
    expect(find.text('Cómo vivo'),findsOneWidget);
    expect(find.text('Cómo me relaciono'),findsOneWidget);
    expect(find.byKey(const Key('b17-dating-checklist')),findsOneWidget);
    expect(find.byKey(const Key('b17-fits-empty-real')),findsOneWidget);
    expect(find.byKey(const Key('b17-real-fit-'+ids[0])),findsNothing);
    expect(find.text('Tu próxima actividad'),findsNothing);
    await tester.tap(find.byKey(const Key('b17-pillar-1')));
    await tester.pump();
    expect(chosen,[1]);
    expect(tester.takeException(),isNull);
  });

  testWidgets('B17 mobile home keeps two accessible panels and real gates',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(390,870));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final chosen=<int>[];
    int openAge=0;
    await tester.pumpWidget(home(FakeB17MemberApi(),chosen,
      onAge:()=>openAge++));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b17-ai-story')),findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('b17-readiness-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b17-readiness-1')));
    await tester.pump();
    expect(openAge,1);
    expect(tester.takeException(),isNull);
  });

  testWidgets('B17 carousel navigates ONLY true API candidates',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1448,1300));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final chosen=<int>[];
    await tester.pumpWidget(home(FakeB17MemberApi(eligible:true),chosen));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('b17-real-fit-'+ids[0])),findsOneWidget);
    expect(find.byKey(Key('b17-real-fit-'+ids[1])),findsOneWidget);
    expect(find.byKey(Key('b17-real-fit-'+ids[2])),findsNothing);
    await tester.ensureVisible(find.byKey(const Key('b17-fit-next')));
    await tester.tap(find.byKey(const Key('b17-fit-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('b17-real-fit-'+ids[2])),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
