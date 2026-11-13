import 'package:flutter/material.dart';

import '../core/activity_repository.dart';
import 'my_activities_b2.dart';

/// Returns only the next real, confirmed reservation owned by the signed-in
/// member. The backend authorizes loadMyActivities; the client never requests
/// or displays a participant roster or private gym/weekly schedule.
Map<String, dynamic>? nextConfirmedBookingB8(
  Iterable<Map<String, dynamic>> bookings,
  DateTime now,
) {
  Map<String, dynamic>? next;
  DateTime? soonest;
  for (final booking in bookings) {
    if (booking['cancelled_at'] != null ||
        booking['event_cancelled'] == true) {
      continue;
    }
    final date = DateTime.tryParse(
      (booking['starts_at'] ?? '').toString(),
    );
    if (date == null || !date.isAfter(now)) continue;
    if (soonest == null || date.isBefore(soonest)) {
      soonest = date;
      next = booking;
    }
  }
  return next;
}

/// B8 home value: real next booking, honest empty/error/loading states,
/// private by design, with clear paths to manage or find activities.
class MemberAgendaB8 extends StatefulWidget {
  const MemberAgendaB8({
    super.key,
    required this.api,
    required this.onExplore,
    required this.onReservations,
  });

  final ActivityRepository api;
  final Future<void> Function() onExplore;
  final Future<void> Function() onReservations;

  @override
  State<MemberAgendaB8> createState() => _MemberAgendaB8State();
}

class _MemberAgendaB8State extends State<MemberAgendaB8> {
  List<Map<String, dynamic>> reservations = const [];
  bool loading = true;
  String? error;
  int requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final currentRequest = ++requestGeneration;
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.api.loadMyActivities();
      if (!mounted || currentRequest != requestGeneration) return;
      setState(() => reservations = result);
    } catch (_) {
      if (!mounted || currentRequest != requestGeneration) return;
      setState(() {
        error = 'No pudimos consultar tus próximas actividades.';
      });
    } finally {
      if (mounted && currentRequest == requestGeneration) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> navigate(Future<void> Function() action) async {
    try {
      await action();
    } finally {
      if (mounted) await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = nextConfirmedBookingB8(
      reservations, DateTime.now(),
    );
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('b8-agenda-card'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.event_available_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Tu próxima actividad',
                style: Theme.of(context).textTheme.titleLarge,
              )),
              IconButton(
                key: const Key('b8-agenda-refresh'),
                tooltip: 'Actualizar mi próxima actividad',
                onPressed: loading ? null : reload,
                icon: const Icon(Icons.refresh),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              'Tu agenda es privada: solo muestra tus reservaciones.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (loading)
              const LinearProgressIndicator(key: Key('b8-agenda-loading'))
            else if (error != null) ...[
              Text(error!, key: const Key('b8-agenda-error'),
                style: TextStyle(color: scheme.error)),
              TextButton(
                key: const Key('b8-agenda-retry'),
                onPressed: reload,
                child: const Text('Volver a intentar'),
              ),
            ] else if (upcoming == null) ...[
              const Text(
                'Aún no tienes próximas actividades confirmadas.',
                key: Key('b8-agenda-empty'),
              ),
              const SizedBox(height: 4),
              Text('Explora actividades reales y reserva tu lugar.',
                style: Theme.of(context).textTheme.bodySmall),
            ] else
              Semantics(
                label: 'Próxima actividad confirmada',
                child: Column(
                  key: const Key('b8-agenda-confirmed'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((upcoming['title'] ?? 'Actividad deportiva').toString(),
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text('${upcoming['sport'] ?? 'Deporte'} · '
                      '${upcoming['city'] ?? 'Ciudad por confirmar'}'),
                    Text(b2LocalDate(upcoming['starts_at'])),
                    const SizedBox(height: 4),
                    Text('Participación confirmada',
                      style: TextStyle(color: scheme.primary)),
                  ],
                ),
              ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('b8-explore-activities'),
                  onPressed: () => navigate(widget.onExplore),
                  icon: const Icon(Icons.search),
                  label: const Text('Explorar actividades'),
                ),
                OutlinedButton.icon(
                  key: const Key('b8-view-reservations'),
                  onPressed: () => navigate(widget.onReservations),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Mis reservas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
