import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/dating_preferences_b5.dart';
import 'package:my_fitness_date/src/core/dating_repository_b5.dart';
import 'package:my_fitness_date/src/features/dating_v27.dart';

class FakeDatingB5 implements DatingRepositoryB5 {
  bool consented=false;
  bool requested=false;
  int candidateCalls=0;
  int saves=0;
  int disabled=0;
  Map<String,dynamic> choices={
    'intent':'serious',
    'frequency':'flexible',
    'mode':'other_gyms',
    'sports':<String>[],
    'requested':false,
  };

  @override
  Future<Map<String,dynamic>> datingStatus() async => {
    'status':'available','enabled':false,
    'age_verified':false,'dating_consent':consented,
    'pilot_member':false,'independent_provider_ready':false,
    'discovery_release_ready':false,
    'relationship_intent':choices['intent'],
    'lifestyle_frequency':choices['frequency'],
    'gym_privacy_mode':choices['mode'],
    'sports':choices['sports'],
    'participation_requested':requested,
  };

  @override
  Future<void> acceptDating() async {consented=true;}

  @override
  Future<List<Map<String,dynamic>>> datingCandidates() async {
    candidateCalls++;
    throw StateError('No discovery while release is closed');
  }

  @override
  Future<String> saveDatingPreferences(Map<String,dynamic> draft) async {
    choices=draft;
    requested=draft['requested']==true;
    saves++;
    return 'saved';
  }

  @override
  Future<String> disableDating() async {
    requested=false;
    disabled++;
    return 'disabled';
  }
}

void main(){
  test('preferences reject invalid inputs and never carry gym ID',(){
    expect(validateDatingChoicesB5(
      intent:'serious',frequency:'weekly',privacyMode:'other_gyms',
      sports:{'running'},requested:true,consent:false),
      contains('consentimiento'));
    final json=datingDraftB5(
      intent:'serious',frequency:'weekly',
      privacyMode:'other_gyms',sports:{'running','hyrox'},
      requested:false);
    expect(json.containsKey('user_id'),false);
    expect(json.containsKey('gym_id'),false);
    expect(json.containsKey('weekly_slots'),false);
    expect(json['sports'],['hyrox','running']);
  });

  testWidgets('age gate closed means no discovery and safe readiness',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,900));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final fake=FakeDatingB5();
    await tester.pumpWidget(MaterialApp(home:DatingV27(api:fake)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b5-dating-readiness')),findsOneWidget);
    expect(find.text('Preparación privada · descubrimiento deshabilitado'),
      findsOneWidget);
    expect(fake.candidateCalls,0);
    // ListView lazily builds off-screen controls; scroll before finding.
    await tester.scrollUntilVisible(
      find.byKey(const Key('b5-save-preferences')),300,
      scrollable:find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('b5-save-preferences')),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('preferences save after consent, and disable is reversible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100,1400));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final fake=FakeDatingB5();
    await tester.pumpWidget(MaterialApp(home:DatingV27(api:fake)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('b5-separate-consent')),300,
      scrollable:find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('b5-separate-consent')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('b5-request-participation')));
    await tester.tap(find.byKey(const Key('b5-request-participation')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('b5-save-preferences')));
    await tester.tap(find.byKey(const Key('b5-save-preferences')));
    await tester.pumpAndSettle();
    expect(fake.consented,true);
    expect(fake.saves,1);
    expect(fake.requested,true);
    expect(fake.candidateCalls,0);
    await tester.ensureVisible(find.byKey(const Key('b5-disable')));
    await tester.tap(find.byKey(const Key('b5-disable')));
    await tester.pumpAndSettle();
    expect(fake.disabled,1);
    expect(fake.requested,false);
    expect(tester.takeException(),isNull);
  });
}
