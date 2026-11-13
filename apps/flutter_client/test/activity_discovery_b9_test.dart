import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/activity_discovery_b9.dart';
import 'package:my_fitness_date/src/core/activity_repository.dart';
import 'package:my_fitness_date/src/features/activities_b1.dart';

const runIdB9 = 'ac8e3ef2-a487-46da-b3d1-d0747607a4b9';
const walkIdB9 = 'bc8e3ef2-a487-46da-b3d1-d0747607a4b9';
const oldIdB9 = 'cc8e3ef2-a487-46da-b3d1-d0747607a4b9';

List<Map<String, dynamic>> sampleB9() => [
  {
    'id':walkIdB9, 'title':'Senderismo en familia',
    'sport':'Senderismo','city':'Querétaro',
    'starts_at':'2035-03-20T16:00:00Z',
    'description':'Salida deportiva abierta',
    'capacity':18,'joined':false,
  },
  {
    'id':runIdB9,'title':'Running de domingo',
    'sport':'Running','city':'Ciudad de México',
    'starts_at':'2035-03-15T12:00:00Z',
    'description':'Carrera grupal al aire libre',
    'capacity':18,'joined':false,
  },
  {
    'id':oldIdB9,'title':'Carrera pasada',
    'sport':'Running','city':'Querétaro',
    'starts_at':'2025-01-01T12:00:00Z',
    'description':'Registro histórico',
    'capacity':18,'joined':false,
  },
  {
    'id':'dc8e3ef2-a487-46da-b3d1-d0747607a4b9',
    'title':'Actividad cancelada','sport':'Running',
    'city':'Querétaro','starts_at':'2035-03-14T12:00:00Z',
    'event_cancelled':true,
  },
];

class FakeDiscoveryB9 implements ActivityRepository {
  List<Map<String, dynamic>> records = sampleB9();
  @override
  Future<List<Map<String, dynamic>>> loadActivities() async =>
      records.map((r) => {...r}).toList();
  @override
  Future<String> confirmActivity(String eventId) async => 'confirmed';
  @override
  Future<bool> isApprovedActivityOrganizer() async => false;
  @override
  Future<Map<String, dynamic>> publishActivity(
      Map<String, dynamic> input) async => input;
  @override
  Future<List<Map<String, dynamic>>> loadMyActivities() async => [];
  @override
  Future<String> cancelActivity(String eventId) async => 'cancelled';
  @override
  Future<List<Map<String, dynamic>>> loadOrganizedActivities() async => [];
  @override
  Future<String> cancelOrganizedActivity(String eventId) async => 'cancelled';
}

void main() {
  test('accent-insensitive search, future order and cancelled exclusion', () {
    final next = discoverActivitiesB9(
      activities: sampleB9(), now: DateTime.utc(2030, 1, 1),
    );
    expect(next.map((e) => e['id']).toList(), [runIdB9, walkIdB9]);
    final city = discoverActivitiesB9(
      activities: sampleB9(), now: DateTime.utc(2030, 1, 1),
      query: '  QUERETARO ',
    );
    expect(city.map((e) => e['id']).toList(), [walkIdB9]);
    final sport = discoverActivitiesB9(
      activities: sampleB9(), now: DateTime.utc(2030, 1, 1),
      sport:'Running', city:'Ciudad de México',
    );
    expect(sport.single['id'], runIdB9);
    final history = discoverActivitiesB9(
      activities: sampleB9(), now: DateTime.utc(2030, 1, 1),
      upcomingOnly:false,
    );
    expect(history.map((e) => e['id']).toList(),
      [runIdB9, walkIdB9, oldIdB9]);
    expect(activityFilterOptionsB9(sampleB9(), 'sport'),
      ['Running', 'Senderismo']);
    expect(() => activityFilterOptionsB9(sampleB9(), 'gym_id'),
      throwsArgumentError);
  });

  testWidgets('member searches without inventing activities and can reset',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FakeDiscoveryB9();
    await tester.pumpWidget(MaterialApp(home: ActivitiesB1(api:repo)));
    await tester.pumpAndSettle();
    expect(find.text('2 actividades encontradas'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('b9-search')), 'sin coincidencias');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b9-no-results')), findsOneWidget);
    expect(find.byKey(const Key('b1-activity-$runIdB9')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('b9-reset')));
    await tester.tap(find.byKey(const Key('b9-reset')));
    await tester.pumpAndSettle();
    expect(find.text('2 actividades encontradas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sport, city and date filters work on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home:ActivitiesB1(api:FakeDiscoveryB9()),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('b9-only-upcoming')));
    await tester.tap(find.byKey(const Key('b9-only-upcoming')));
    await tester.pumpAndSettle();
    expect(find.text('3 actividades encontradas'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('b9-sport-filter')));
    await tester.tap(find.byKey(const Key('b9-sport-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running').last);
    await tester.pumpAndSettle();
    expect(find.text('2 actividades encontradas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
