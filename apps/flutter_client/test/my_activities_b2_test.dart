import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/activity_repository.dart';
import 'package:my_fitness_date/src/features/my_activities_b2.dart';

const bookingId = 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc';

class B2FakeRepository implements ActivityRepository {
  bool cancelled = false;
  bool eventCancelled = false;
  bool organizer = false;
  int cancelCalls = 0;
  int organizerCancelCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> loadActivities() async => [];

  @override
  Future<String> confirmActivity(String id) async => 'confirmed';

  @override
  Future<bool> isApprovedActivityOrganizer() async => organizer;

  @override
  Future<Map<String, dynamic>> publishActivity(Map<String, dynamic> data)
    async => data;

  @override
  Future<List<Map<String, dynamic>>> loadMyActivities() async => [
    {
      'event_id': bookingId,
      'title': 'Caminata del domingo',
      'description': 'Actividad curada',
      'sport': 'Senderismo',
      'city': 'Querétaro',
      'starts_at': '2035-03-15T13:00:00Z',
      'capacity': 20,
      'joined_at': '2035-01-01T11:00:00Z',
      'cancelled_at': cancelled ? '2035-01-02T11:00:00Z' : null,
      'event_cancelled': eventCancelled,
    }
  ];

  @override
  Future<String> cancelActivity(String eventId) async {
    expect(eventId, bookingId);
    cancelCalls++;
    cancelled = true;
    return 'cancelled';
  }

  @override
  Future<List<Map<String, dynamic>>> loadOrganizedActivities() async => [
    {
      'id': bookingId,
      'title': 'Caminata del domingo',
      'sport': 'Senderismo',
      'city': 'Querétaro',
      'starts_at': '2035-03-15T13:00:00Z',
      'capacity': 20,
      'active_reservations': 3,
      'event_cancelled': eventCancelled,
    }
  ];

  @override
  Future<String> cancelOrganizedActivity(String eventId) async {
    expect(eventId, bookingId);
    organizerCancelCalls++;
    eventCancelled = true;
    return 'cancelled';
  }
}

void main() {
  testWidgets('member can confirm cancellation, persisted status is shown',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = B2FakeRepository();
    await tester.pumpWidget(MaterialApp(home: MyActivitiesB2(api: fake)));
    await tester.pumpAndSettle();
    expect(find.text('Caminata del domingo'), findsOneWidget);
    expect(find.text('Participación confirmada'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('b2-cancel-$bookingId')));
    await tester.tap(find.byKey(const Key('b2-cancel-$bookingId')));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar participación'), findsOneWidget);
    await tester.tap(find.byKey(const Key('b2-confirm-cancel')));
    await tester.pumpAndSettle();
    expect(fake.cancelCalls, 1);
    expect(find.text('Participación cancelada'), findsOneWidget);
    expect(find.byKey(const Key('b2-cancel-$bookingId')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('organizer may only manage own events via repository',
    (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = B2FakeRepository()..organizer = true;
    await tester.pumpWidget(
      MaterialApp(home: OrganizedActivitiesB2(api: fake)));
    await tester.pumpAndSettle();
    expect(find.text('Reservas: 3 / 20'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('b2-organizer-cancel-$bookingId')));
    await tester.tap(find.byKey(
      const Key('b2-organizer-cancel-$bookingId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b2-organizer-confirm-cancel')));
    await tester.pumpAndSettle();
    expect(fake.organizerCancelCalls, 1);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
