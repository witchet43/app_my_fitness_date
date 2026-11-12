import 'package:flutter/material.dart';

import '../core/curator_repository.dart';
import '../core/member_v26_api.dart';
import 'my_activities_b2.dart';

/// AAL2 owner-only curator view inside the SAME My Fitness Date Flutter app.
/// The backend checks ownership for each operation; this widget is not a grant.
class AdminCuratedActivitiesB2 extends StatefulWidget {
  const AdminCuratedActivitiesB2({super.key, required this.api});
  final CuratorRepository api;

  @override
  State<AdminCuratedActivitiesB2> createState() =>
      _AdminCuratedActivitiesB2State();
}

class _AdminCuratedActivitiesB2State
    extends State<AdminCuratedActivitiesB2> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  bool busy = false;
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
      final rows = await widget.api.adminActivities();
      if (mounted) setState(() => items = rows);
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
          error = 'No fue posible consultar el catálogo global.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> create() async {
    if (busy) return;
    final name = TextEditingController();
    final description = TextEditingController();
    final sport = TextEditingController();
    final city = TextEditingController();
    final seats = TextEditingController(text: '24');
    DateTime start = DateTime.now().add(const Duration(days: 2));
    String? validation;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Publicar actividad curada'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: name,
                  key: const Key('b2-admin-title'), maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la actividad')),
                TextField(controller: description,
                  key: const Key('b2-admin-description'), maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción')),
                TextField(controller: sport, maxLength: 40,
                  key: const Key('b2-admin-sport'),
                  decoration: const InputDecoration(labelText: 'Deporte')),
                TextField(controller: city, maxLength: 100,
                  key: const Key('b2-admin-city'),
                  decoration: const InputDecoration(
                    labelText: 'Ciudad o zona general')),
                TextField(controller: seats,
                  key: const Key('b2-admin-capacity'),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cupo (1–200)')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('b2-admin-date'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(b2LocalDate(start.toIso8601String())),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: dialog,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: now.add(const Duration(days: 180)),
                      initialDate: start,
                    );
                    if (picked == null || !dialog.mounted) return;
                    final time = await showTimePicker(
                      context: dialog,
                      initialTime: TimeOfDay.fromDateTime(start),
                    );
                    if (time == null || !dialog.mounted) return;
                    update(() => start = DateTime(
                      picked.year, picked.month, picked.day,
                      time.hour, time.minute,
                    ));
                  },
                ),
                if (validation != null) Text(validation!,
                  style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 8),
                const Text('Solo publica actividades verificadas. '
                  'No inventes eventos ni incluyas domicilios o '
                  'horarios personales.'),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Volver'),
            ),
            FilledButton.icon(
              key: const Key('b2-admin-create-submit'),
              icon: const Icon(Icons.check),
              label: const Text('Publicar actividad'),
              onPressed: () {
                final capacity = int.tryParse(seats.text.trim());
                final minutes = start.difference(DateTime.now()).inMinutes;
                if (name.text.trim().length < 4 ||
                    description.text.trim().length < 10 ||
                    sport.text.trim().length < 2 ||
                    city.text.trim().length < 2 ||
                    capacity == null || capacity < 1 || capacity > 200 ||
                    minutes < 11 || minutes > 180 * 24 * 60) {
                  update(() => validation = 'Revisa texto, cupos y fecha futura.');
                  return;
                }
                Navigator.pop(dialog, {
                  'title': name.text.trim(),
                  'description': description.text.trim(),
                  'sport': sport.text.trim(),
                  'city': city.text.trim(),
                  'capacity': capacity,
                  'starts_at': start.toUtc().toIso8601String(),
                });
              },
            ),
          ],
        ),
      ),
    );
    name.dispose();
    description.dispose();
    sport.dispose();
    city.dispose();
    seats.dispose();
    if (data == null || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.api.adminPublishActivity(data);
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Actividad guardada y visible en el catálogo.'),
        ));
      }
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
          error = 'No fue posible publicar el evento. Comprueba tu sesión MFA.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cancel(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (id.isEmpty || busy) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancelar actividad publicada'),
        content: const Text('Este evento dejará de recibir reservas. '
          'Los participantes conservarán su historial y podrán ver '
          'que el organizador lo canceló.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Conservar actividad'),
          ),
          FilledButton(
            key: const Key('b2-admin-confirm-cancel'),
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Cancelar evento'),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.api.adminCancelActivity(id);
      await reload();
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
          error = 'No fue posible cancelar el evento.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administrar actividades')),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 850),
      child: ListView(
        key: const Key('b2-admin-curation'),
        padding: const EdgeInsets.all(20),
        children: [
          Text('Actividades de My Fitness Date',
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text('Lo que publiques aquí aparecerá en el catálogo '
            'de miembros. No requiere compilar o desplegar la aplicación. '
            'Exige tu sesión de propietario con MFA.'),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('b2-admin-create'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: busy ? null : create,
            label: Text(busy ? 'Guardando…' : 'Publicar actividad real'),
          ),
          if (loading) const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(error!, key: const Key('b2-admin-error'),
              style: const TextStyle(color: Colors.redAccent)),
            TextButton(onPressed: reload, child: const Text('Reintentar')),
          ],
          if (!loading && error == null && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Todavía no hay actividades publicadas. '
                'Crea una actividad verificada para poblar el catálogo.',
                key: Key('b2-admin-empty')),
            ),
          if (!loading) for (final item in items) Builder(
            builder: (context) {
              final id = (item['id'] ?? '').toString();
              final when =
                DateTime.tryParse((item['starts_at'] ?? '').toString());
              final canCancel = when != null &&
                when.isAfter(DateTime.now()) &&
                item['event_cancelled'] != true;
              return Card(
                key: Key('b2-admin-event-$id'),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((item['title'] ?? 'Actividad').toString(),
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('${item['sport'] ?? ''} · ${item['city'] ?? ''}'),
                      Text(b2LocalDate(item['starts_at'])),
                      Text('Reservas: ${item['active_reservations'] ?? 0}'
                          ' / ${item['capacity'] ?? '—'}'),
                      if (item['event_cancelled'] == true)
                        const Text('Evento cancelado'),
                      if (canCancel)
                        OutlinedButton.icon(
                          key: Key('b2-admin-cancel-$id'),
                          onPressed: busy ? null : () => cancel(item),
                          icon: const Icon(Icons.event_busy_outlined),
                          label: const Text('Cancelar esta actividad'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    )),
  );
}
