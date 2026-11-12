import 'package:flutter/material.dart';

import '../core/activity_repository.dart';
import '../core/member_v26_api.dart';

String b2LocalDate(dynamic value) {
  final date = DateTime.tryParse((value ?? '').toString())?.toLocal();
  if (date == null) return 'Fecha no disponible';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} · '
      '${two(date.hour)}:${two(date.minute)}';
}

/// B2: private, persistent booking history and cancellation.
/// No other participant identity or private gym/schedule is ever shown.
class MyActivitiesB2 extends StatefulWidget {
  const MyActivitiesB2({super.key, required this.api});
  final ActivityRepository api;

  @override
  State<MyActivitiesB2> createState() => _MyActivitiesB2State();
}

class _MyActivitiesB2State extends State<MyActivitiesB2> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? busyId;
  String? error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() { loading = true; error = null; });
    try {
      final result = await widget.api.loadMyActivities();
      if (mounted) setState(() => items = result);
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error =
          'No pudimos cargar tus participaciones. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> cancel(Map<String, dynamic> item) async {
    final id = (item['event_id'] ?? '').toString();
    if (busyId != null || id.isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancelar participación'),
        content: const Text('Dejarás de tener un lugar reservado en esta '
            'actividad. Podrás volver a inscribirte únicamente si sigue '
            'disponible y quedan lugares.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Conservar mi lugar')),
          FilledButton(
            key: const Key('b2-confirm-cancel'),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() { busyId = id; error = null; });
    try {
      await widget.api.cancelActivity(id);
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tu participación se canceló y guardó correctamente.'),
        ));
      }
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
          error = 'No se pudo cancelar. Reintenta.');
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  Widget card(Map<String, dynamic> item) {
    final id = (item['event_id'] ?? '').toString();
    final when = DateTime.tryParse((item['starts_at'] ?? '').toString());
    final future = when != null && when.isAfter(DateTime.now());
    final canceled = item['cancelled_at'] != null;
    final eventCanceled = item['event_cancelled'] == true;
    final state = eventCanceled ? 'Actividad cancelada por organizador'
        : canceled ? 'Participación cancelada'
        : future ? 'Participación confirmada' : 'Actividad finalizada';
    final allowed = future && !canceled && !eventCanceled;
    return Card(
      key: Key('b2-booking-$id'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((item['title'] ?? 'Actividad').toString(),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${item['sport'] ?? ''} · ${item['city'] ?? ''}'),
          Text(b2LocalDate(item['starts_at'])),
          const SizedBox(height: 10),
          Row(children: [
            Icon(canceled || eventCanceled ? Icons.cancel_outlined
              : Icons.check_circle_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(state, key: Key('b2-state-$id'))),
          ]),
          if (allowed) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: Key('b2-cancel-$id'),
              onPressed: busyId == null ? () => cancel(item) : null,
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(busyId == id ? 'Cancelando…'
                  : 'Cancelar mi participación'),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = items.where((item) {
      final date = DateTime.tryParse((item['starts_at'] ?? '').toString());
      return date != null && date.isAfter(DateTime.now());
    }).toList();
    final past = items.where((item) {
      final date = DateTime.tryParse((item['starts_at'] ?? '').toString());
      return date == null || !date.isAfter(DateTime.now());
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis actividades'),
        actions: [
          IconButton(
            key: const Key('b2-reload'),
            onPressed: loading ? null : reload,
            tooltip: 'Actualizar mis actividades',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              key: const Key('b2-my-activities'),
              padding: const EdgeInsets.all(18),
              children: [
                Text('Tus próximas experiencias',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Consulta tus confirmaciones privadas y gestiona '
                    'tu participación. Solo tú puedes ver esta lista.'),
                if (loading) const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text(error!, key: const Key('b2-error'),
                    style: const TextStyle(color: Colors.redAccent)),
                  TextButton(onPressed: reload,
                    child: const Text('Reintentar')),
                ],
                if (!loading && error == null && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Todavía no tienes actividades reservadas. '
                      'Explora el catálogo y confirma tu primera participación.',
                      key: Key('b2-empty')),
                  ),
                if (!loading && current.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('Próximas', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  for (final item in current) card(item),
                ],
                if (!loading && past.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('Anteriores',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  for (final item in past) card(item),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Approved organizers may see/cancel only the activities they created.
/// A cancellation keeps member history; it does not reveal participants.
class OrganizedActivitiesB2 extends StatefulWidget {
  const OrganizedActivitiesB2({super.key, required this.api});
  final ActivityRepository api;

  @override
  State<OrganizedActivitiesB2> createState() => _OrganizedActivitiesB2State();
}

class _OrganizedActivitiesB2State extends State<OrganizedActivitiesB2> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? busyId;
  String? error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() { loading = true; error = null; });
    try {
      final result = await widget.api.loadOrganizedActivities();
      if (mounted) setState(() => items = result);
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
          error = 'No se pudieron consultar tus actividades organizadas.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> cancel(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (busyId != null || id.isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancelar esta actividad'),
        content: const Text('La actividad dejará de aceptar reservas. '
            'Los participantes verán que fue cancelada. '
            'Esta operación no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Volver')),
          FilledButton(
            key: const Key('b2-organizer-confirm-cancel'),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Cancelar evento'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() { busyId = id; error = null; });
    try {
      await widget.api.cancelOrganizedActivity(id);
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Actividad cancelada. Se conserva el historial.'),
        ));
      }
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error =
          'No se pudo cancelar esta actividad.');
    } finally {
      if (mounted) setState(() => busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Actividades organizadas'),
      actions: [
        IconButton(
          onPressed: loading ? null : reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          key: const Key('b2-organizer-list'),
          padding: const EdgeInsets.all(18),
          children: [
            Text('Mis eventos publicados',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Como organizador autorizado, puedes revisar '
              'reservas totales y cancelar tus propios eventos.'),
            if (loading) const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            if (error != null) ...[
              Text(error!, key: const Key('b2-organizer-error'),
                style: const TextStyle(color: Colors.redAccent)),
              TextButton(onPressed: reload, child: const Text('Reintentar')),
            ],
            if (!loading && error == null && items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aún no has publicado actividades.',
                  key: Key('b2-organizer-empty')),
              ),
            if (!loading) for (final item in items) Builder(
              builder: (context) {
                final id = (item['id'] ?? '').toString();
                final date =
                  DateTime.tryParse((item['starts_at'] ?? '').toString());
                final canCancel = date != null &&
                  date.isAfter(DateTime.now()) &&
                  item['event_cancelled'] != true;
                return Card(
                  key: Key('b2-organizer-$id'),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((item['title'] ?? 'Evento').toString(),
                          style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('${item['sport'] ?? ''} · ${item['city'] ?? ''}'),
                        Text(b2LocalDate(item['starts_at'])),
                        Text('Reservas: ${item['active_reservations'] ?? 0} '
                          '/ ${item['capacity'] ?? '—'}'),
                        if (item['event_cancelled'] == true)
                          const Text('Cancelado'),
                        if (canCancel) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            key: Key('b2-organizer-cancel-$id'),
                            onPressed: busyId == null
                                ? () => cancel(item) : null,
                            child: Text(busyId == id
                                ? 'Cancelando…' : 'Cancelar evento'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
