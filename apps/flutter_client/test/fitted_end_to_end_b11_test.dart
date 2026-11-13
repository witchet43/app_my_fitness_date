import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/dating_repository_b11.dart';
import 'package:my_fitness_date/src/features/rhythm_concept_lab_b10.dart';
import 'package:my_fitness_date/src/features/dating_discovery_b11.dart';
import 'package:my_fitness_date/src/features/gym_shield_activation_b11.dart';

const candidateIdB11='bc8e3ef2-a487-46da-b3d1-d0747607a411';
const matchIdB11='cc8e3ef2-a487-46da-b3d1-d0747607a411';
class FakeDatingB11 implements DatingRepositoryB11 {
  Map<String,dynamic>? doc;
  int saveCalls=0,likeCalls=0,reportCalls=0,sendCalls=0,activationCalls=0;
  @override
  Future<Map<String,dynamic>?> loadRhythmB11() async => doc;
  @override
  Future<void> saveRhythmB11(Map<String,dynamic> draft) async {
    saveCalls++;doc={...draft};
  }
  @override
  Future<List<Map<String,dynamic>>> gymCatalogB11() async => [{
    'id':'ab8e3ef2-a487-46da-b3d1-d0747607a411',
    'name':'Gimnasio de QA','city':'Ciudad de prueba',
  }];

  @override
  Future<String> activateB11(
      String gymId,List<Map<String,int>> weeklySlots) async {
    expect(gymId,'ab8e3ef2-a487-46da-b3d1-d0747607a411');
    activationCalls++;
    return 'activated';
  }

  @override
  Future<List<Map<String,dynamic>>> discoverB11() async => [{
    'user_id':candidateIdB11,'display_name':'QA Candidate',
    'city':'Ciudad de prueba','sports':['Running'],
    'reason_codes':['intent_aligned','sport_different_ok'],
  }];
  @override
  Future<String> likeB11(String id) async {
    expect(id,candidateIdB11);likeCalls++;return 'matched';
  }
  @override
  Future<List<Map<String,dynamic>>> matchesB11() async => [
    {'id':matchIdB11,'display_name':'QA Mutual Match'}
  ];
  @override
  Future<List<Map<String,dynamic>>> messagesB11(String id) async {
    expect(id,matchIdB11);
    return [{'body':'Mensaje sintético solo de QA'}];
  }
  @override
  Future<String> sendB11(String id,String body) async {
    expect(id,matchIdB11);
    expect(body,'Hola');sendCalls++;return 'sent';
  }
  @override
  Future<String> reportB11(String id,String reason,{String detail=''}) async {
    expect(id,matchIdB11);expect(reason,'unsafe');
    reportCalls++;return 'reported_and_blocked';
  }
  @override
  Future<List<String>> ideasB11(String id) async => ['walk_coffee'];
  @override
  Future<Map<String,dynamic>> datingStatus() async => {
    'status':'available','enabled':false,'dating_consent':false,
  };
  @override
  Future<void> acceptDating() async {}
  @override
  Future<List<Map<String,dynamic>>> datingCandidates() async => [];
  @override
  Future<String> saveDatingPreferences(Map<String,dynamic> values) async => 'saved';
  @override
  Future<String> disableDating() async => 'disabled';
}

void main(){
  testWidgets('three rhythms save only with consent and never send gym data',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100,1500));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      final repo=FakeDatingB11();
      await tester.pumpWidget(MaterialApp(
        home:RhythmConceptLabB10(repository:repo,canSave:true)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('b11-save-rhythm')),350,
        scrollable:find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(const Key('b11-save-rhythm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('b11-save-rhythm')));
      await tester.pumpAndSettle();
      expect(repo.saveCalls,1);
      expect(repo.doc?['answers'],isA<Map>());
      expect((repo.doc?['answers'] as Map).containsKey('privacy'),false);
      expect(repo.doc!.containsKey('gym_id'),false);
      expect(repo.doc!.containsKey('exact_schedule'),false);
      expect(find.byKey(const Key('b11-save-success')),findsOneWidget);
      expect(tester.takeException(),isNull);
    });

  testWidgets('no separate consent means no save operation',
    (tester) async {
      final repo=FakeDatingB11();
      await tester.pumpWidget(MaterialApp(
        home:RhythmConceptLabB10(repository:repo,canSave:false)));
      await tester.pumpAndSettle();
      expect(repo.saveCalls,0);
      expect(find.byKey(const Key('b11-save-rhythm')),findsNothing);
      expect(tester.takeException(),isNull);
    });

  testWidgets('candidate reasons are public codes, mutual likes are confirmed',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100,1600));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      final repo=FakeDatingB11();
      await tester.pumpWidget(MaterialApp(home:DatingDiscoveryB11(api:repo)));
      await tester.pumpAndSettle();
      expect(find.text('QA Candidate'),findsOneWidget);
      expect(find.text('Comparten intención de relación.'),findsOneWidget);
      expect(find.text('QA Mutual Match'),findsOneWidget);
      await tester.tap(find.byKey(const Key('b11-like-$candidateIdB11')));
      await tester.pumpAndSettle();
      expect(find.text('¿Te interesa conocer a esta persona?'),findsOneWidget);
      await tester.tap(find.text('Expresar interés'));
      await tester.pumpAndSettle();
      expect(repo.likeCalls,1);
      expect(tester.takeException(),isNull);
    });

  testWidgets('chat is after match and report blocks the other participant',
    (tester) async {
      final repo=FakeDatingB11();
      await tester.binding.setSurfaceSize(const Size(1100,1000));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home:DatingChatB11(api:repo,matchId:matchIdB11,title:'QA Mutual Match')));
      await tester.pumpAndSettle();
      expect(find.text('Mensaje sintético solo de QA'),findsOneWidget);
      await tester.enterText(find.byKey(const Key('b11-message-input')),'Hola');
      await tester.tap(find.byKey(const Key('b11-send')));
      await tester.pumpAndSettle();
      expect(repo.sendCalls,1);
      await tester.tap(find.byKey(const Key('b11-report')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riesgo de seguridad'));
      await tester.pumpAndSettle();
      expect(repo.reportCalls,1);
      expect(tester.takeException(),isNull);
    });

testWidgets('Gym Shield mode A uses an explicit real catalog selection',
  (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,1100));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final repo=FakeDatingB11();
    await tester.pumpWidget(MaterialApp(
      home:GymShieldActivationB11(api:repo,mode:'other_gyms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b11-gym-select')),findsOneWidget);
    expect(find.byKey(const Key('b11-activate-confirm')),findsOneWidget);
    expect(find.byKey(const Key('b11-add-slot')),findsNothing);
    await tester.tap(find.byKey(const Key('b11-gym-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gimnasio de QA · Ciudad de prueba').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b11-activate-confirm')));
    await tester.pumpAndSettle();
    expect(repo.activationCalls,1);
    expect(tester.takeException(),isNull);
  });

testWidgets('Gym Shield mode B cannot activate without private slots',
  (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,1300));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final repo=FakeDatingB11();
    await tester.pumpWidget(MaterialApp(
      home:GymShieldActivationB11(
        api:repo,mode:'same_gym_other_time')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b11-add-slot')),findsOneWidget);
    expect(find.byKey(const Key('b11-slot-start')),findsOneWidget);
    expect(repo.activationCalls,0);
    expect(tester.takeException(),isNull);
  });

}
