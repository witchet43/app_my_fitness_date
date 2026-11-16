import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_fitness_date/src/core/member_v26_api.dart';
import 'package:my_fitness_date/src/features/fitted_two_panel_home_b18.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient{}

class FakeFitsApi extends MemberV26Api{
  FakeFitsApi():super(
    gatewayUrl:'https://example.invalid',
    auth:FakeSupabaseClient());
  @override
  Future<List<Map<String,dynamic>>> discoverB11() async =>[
    {'user_id':'00000000-0000-4000-8000-000000000101',
      'display_name':'Persona 1','city':'Ciudad de prueba'},
    {'user_id':'00000000-0000-4000-8000-000000000102',
      'display_name':'Persona 2','city':'Ciudad de prueba'},
    {'user_id':'00000000-0000-4000-8000-000000000103',
      'display_name':'Persona 3','city':'Ciudad de prueba'},
  ];
  @override
  Future<Map<String,dynamic>> compatibilityB11(String id)async=>
    {'available':true,'percent':91};
  @override
  Future<Map<String,dynamic>> candidateShowcaseB18(String id)async=>
    {'available':false};
  @override
  Future<String> likeB11(String id)async=>'liked';
}
void main(){
  testWidgets('Blocked matching shows five real prerequisites, no sample accounts',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1100,1150));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    var tapped=0,verified=0;
    final api=FakeFitsApi();
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(child:
      FittedFitsPanelB18(
        api:api,pillarProgress:const [50,80,0],
        status:const {'enabled':false,'age_verified':false,
          'participation_requested':false,'dating_consent':false,
          'discovery_release_ready':false},
        onPrepare:()=>tapped++,onVerifyAge:()=>verified++,
      )))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b18-fits-matching-panel')),findsOneWidget);
    expect(find.byKey(const Key('b18-readiness-0')),findsOneWidget);
    expect(find.byKey(const Key('b18-readiness-4')),findsOneWidget);
    expect(find.text('Tus conexiones seguras empiezan aquí'),findsOneWidget);
    expect(find.text('Persona 1'),findsNothing);
    await tester.tap(find.byKey(const Key('b18-readiness-1')));
    expect(verified,1);
    expect(tester.takeException(),isNull);

  });

  testWidgets('Eligible matching carousel uses server candidates and next arrow',
    (tester)async{
    await tester.binding.setSurfaceSize(const Size(1200,1150));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final api=FakeFitsApi();
    await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
      home:Scaffold(body:SingleChildScrollView(child:
      FittedFitsPanelB18(
        api:api,pillarProgress:const [100,100,100],
        status:const {'enabled':true,'age_verified':true,
          'participation_requested':true,'dating_consent':true,
          'discovery_release_ready':true},
        onPrepare:(){},onVerifyAge:(){},
      )))));
    await tester.pumpAndSettle();
    expect(find.text('Persona 1'),findsOneWidget);
    expect(find.text('Persona 2'),findsOneWidget);
    expect(find.text('Persona 3'),findsNothing);
    await tester.tap(find.byKey(const Key('b18-fit-next')));
    await tester.pumpAndSettle();
    expect(find.text('Persona 2'),findsOneWidget);
    expect(find.text('Persona 3'),findsOneWidget);
    expect(find.text('Persona 1'),findsNothing);
    expect(tester.takeException(),isNull);

  });
}
