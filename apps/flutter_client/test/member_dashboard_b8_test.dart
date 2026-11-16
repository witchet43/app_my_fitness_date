import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/activity_repository.dart';
import 'package:my_fitness_date/src/features/member_dashboard_b8.dart';

class FakeAgendaB8 implements ActivityRepository {
  List<Map<String, dynamic>> items = [];
  int fetches = 0;
  bool fail = false;

  @override
  Future<List<Map<String, dynamic>>> loadMyActivities() async {
    fetches++;
    if (fail) throw StateError('Offline: no private data exposed');
    return items;
  }

  @override
  Future<List<Map<String, dynamic>>> loadActivities() async => [];
  @override
  Future<String> confirmActivity(String eventId) async => 'confirmed';
  @override
  Future<bool> isApprovedActivityOrganizer() async => false;
  @override
  Future<Map<String, dynamic>> publishActivity(
      Map<String, dynamic> data) async => data;
  @override
  Future<String> cancelActivity(String id) async => 'cancelled';
  @override
  Future<List<Map<String, dynamic>>> loadOrganizedActivities() async => [];
  @override
  Future<String> cancelOrganizedActivity(String id) async => 'cancelled';
}

void main() {
  test('earliest upcoming confirmed only; excludes invalid/canceled', () {
    final now = DateTime.utc(2035, 1, 1);
    final result = nextConfirmedBookingB8([
      {'title':'old','starts_at':'2034-12-31T10:00:00Z'},
      {'title':'cancelled','starts_at':'2035-01-02T10:00:00Z',
        'cancelled_at':'2034-12-31T12:00:00Z'},
      {'title':'event-cancelled','starts_at':'2035-01-02T11:00:00Z',
        'event_cancelled':true},
      {'title':'malformed','starts_at':'not-a-date'},
      {'title':'later','starts_at':'2035-01-09T12:00:00Z'},
      {'title':'next','starts_at':'2035-01-03T12:00:00Z'},
    ], now);
    expect(result?['title'], 'next');
    expect(nextConfirmedBookingB8([], now), isNull);
  });

  testWidgets('empty is truthful, booking navigation refreshes state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = FakeAgendaB8();
    int opened = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: MemberAgendaB8(
        api: fake,
        onExplore: () async { opened++; },
        onReservations: () async { opened++; },
      )),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b8-agenda-empty')), findsOneWidget);
    expect(find.byKey(const Key('b8-agenda-confirmed')), findsNothing);
    await tester.tap(find.byKey(const Key('b8-explore-activities')));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(fake.fetches, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real next booking and recoverable offline error',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = FakeAgendaB8()
      ..items = [{
        'event_id':'a1', 'title':'Carrera verificada',
        'sport':'Running','city':'Querétaro',
        'starts_at':'2099-01-10T12:00:00Z',
        'cancelled_at':null,'event_cancelled':false,
      }];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: MemberAgendaB8(
        api: fake, onExplore: () async {}, onReservations: () async {},
      )),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Carrera verificada'), findsOneWidget);
    expect(find.byKey(const Key('b8-agenda-confirmed')), findsOneWidget);
    fake.fail = true;
    await tester.tap(find.byKey(const Key('b8-agenda-refresh')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b8-agenda-error')), findsOneWidget);
    expect(find.byKey(const Key('b8-agenda-confirmed')), findsNothing);
    fake.fail = false;
    await tester.tap(find.byKey(const Key('b8-agenda-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Carrera verificada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
