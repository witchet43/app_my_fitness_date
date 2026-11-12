import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/activity_repository.dart';
import 'package:my_fitness_date/src/features/activities_b1.dart';

const testId = 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc';
class FakeActivities implements ActivityRepository {
  bool joined = false;
  int confirmed = 0;
  bool approved = false;
  List<Map<String,dynamic>> records = [{
    'id':testId,
    'title':'Senderismo del domingo',
    'description':'Una caminata segura en un grupo pequeño.',
    'sport':'Senderismo',
    'city':'Querétaro',
    'starts_at':'2026-11-15T15:00:00Z',
    'capacity':20,
    'joined':false,
  }];
  @override
  Future<List<Map<String,dynamic>>> loadActivities() async =>
    records.map((x) => {...x,'joined': joined}).toList();
  @override
  Future<String> confirmActivity(String id) async {
    expect(id, testId);
    confirmed++;
    joined = true;
    return 'confirmed';
  }
  @override
  Future<List<Map<String, dynamic>>> loadMyActivities() async => [];
  @override
  Future<String> cancelActivity(String eventId) async => 'cancelled';
  @override
  Future<List<Map<String, dynamic>>> loadOrganizedActivities() async => [];
  @override
  Future<String> cancelOrganizedActivity(String eventId) async => 'cancelled';
  @override
  Future<bool> isApprovedActivityOrganizer() async => approved;
  @override
  Future<Map<String,dynamic>> publishActivity(Map<String,dynamic> data) async =>
    data;
}

void main() {
  testWidgets('member can view a genuine card and confirm private RSVP',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = FakeActivities();
    await tester.pumpWidget(MaterialApp(home: ActivitiesB1(api: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Senderismo del domingo'), findsOneWidget);
    expect(find.byKey(const Key('b1-organizer-create')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('b1-rsvp-$testId')));
    await tester.tap(find.byKey(const Key('b1-rsvp-$testId')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(fake.confirmed, 1);
    expect(find.text('Participación confirmada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty catalogue never pretends to contain real activities',
      (tester) async {
    final fake = FakeActivities()..records = [];
    await tester.pumpWidget(MaterialApp(home: ActivitiesB1(api: fake)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(const Key('b1-activities-empty')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
