import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/curator_repository.dart';
import 'package:my_fitness_date/src/features/admin_curated_activities_b2.dart';

class CuratorFake implements CuratorRepository {
  int creations = 0;
  bool cancelled = false;
  @override
  Future<List<Map<String, dynamic>>> adminActivities() async => [
    {
      'id':'bc8e3ef2-a487-46da-b3d1-d0747607a4bc',
      'title':'Carrera del domingo',
      'description':'Actividad deportiva',
      'sport':'Running',
      'city':'Querétaro',
      'starts_at':'2035-03-15T13:00:00Z',
      'capacity':25,
      'active_reservations':4,
      'event_cancelled':cancelled,
    }
  ];
  @override
  Future<Map<String, dynamic>> adminPublishActivity(
    Map<String, dynamic> draft) async {
    creations++;
    expect(draft['capacity'], 20);
    expect(draft['city'], 'Querétaro');
    return {'id': 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc', ...draft};
  }
  @override
  Future<String> adminCancelActivity(String id) async {
    expect(id, 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc');
    cancelled = true;
    return 'cancelled';
  }
}

void main() {
  testWidgets('owner curator sees a real backend response and controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = CuratorFake();
    await tester.pumpWidget(
      MaterialApp(home: AdminCuratedActivitiesB2(api: fake)));
    await tester.pumpAndSettle();
    expect(find.text('Carrera del domingo'), findsOneWidget);
    expect(find.byKey(const Key('b2-admin-create')), findsOneWidget);
    expect(find.text('Reservas: 4 / 25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin cancel requires confirmation and leaves history',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = CuratorFake();
    await tester.pumpWidget(
      MaterialApp(home: AdminCuratedActivitiesB2(api: fake)));
    await tester.pumpAndSettle();
    const id = 'bc8e3ef2-a487-46da-b3d1-d0747607a4bc';
    await tester.ensureVisible(find.byKey(const Key('b2-admin-cancel-$id')));
    await tester.tap(find.byKey(const Key('b2-admin-cancel-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('b2-admin-confirm-cancel')));
    await tester.pumpAndSettle();
    expect(fake.cancelled, isTrue);
    expect(find.text('Evento cancelado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
