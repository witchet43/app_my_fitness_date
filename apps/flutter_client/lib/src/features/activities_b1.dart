import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import '../core/activity_repository.dart';

/// B1 value journey: browse real, curated activities and confirm a private RSVP.
/// No fake events, attendee list, gym, exact routes or training schedules.
class ActivitiesB1 extends StatefulWidget {
  const ActivitiesB1({super.key, required this.api});
  final ActivityRepository api;

  @override
  State<ActivitiesB1> createState() => _ActivitiesB1State();
}

class _ActivitiesB1State extends State<ActivitiesB1> {
  List<Map<String, dynamic>> activities = [];
  bool loading = true;
  bool organizer = false;
  String? activeRsvp;
  bool publishing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {loading = true; error = null;});
    try {
      final result = await widget.api.loadActivities();
      // Being unable to query organizer status must never hide the member
      // catalogue or accidentally grant elevated access.
      bool isOrganizer = false;
      try {
        isOrganizer = await widget.api.isApprovedActivityOrganizer();
      } catch (_) {}
      if (mounted) {
        setState(() {
          activities = result;
          organizer = isOrganizer;
        });
      }
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
        error = 'No pudimos consultar las actividades. Reintenta.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String formatStart(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'Fecha no disponible';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} · '
      '${two(date.hour)}:${two(date.minute)} (hora local)';
  }

  Future<void> confirm(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    if (activeRsvp != null || id.isEmpty || item['joined'] == true) return;
    setState(() { activeRsvp = id; error = null; });
    try {
      await widget.api.confirmActivity(id);
      if (!mounted) return;
      setState(() => item['joined'] = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Participación confirmada y guardada de forma privada.'),
      ));
    } on MemberApiException catch (e) {
      if (mounted) {
        setState(() => error = e.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) setState(() =>
        error = 'No fue posible confirmar tu participación. Reintenta.');
    } finally {
      if (mounted) setState(() => activeRsvp = null);
    }
  }

  Future<void> createActivity() async {
    if (!organizer || publishing) return;
    final title = TextEditingController();
    final description = TextEditingController();
    final sport = TextEditingController();
    final city = TextEditingController();
    final capacity = TextEditingController(text: '24');
    DateTime scheduled = DateTime.now().add(const Duration(days: 2));
    String? validation;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Crear actividad deportiva'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(key: const Key('b1-create-title'), controller: title,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Título')),
                TextField(key: const Key('b1-create-description'),
                  controller: description, maxLength: 500, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción')),
                TextField(key: const Key('b1-create-sport'), controller: sport,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Disciplina')),
                TextField(key: const Key('b1-create-city'), controller: city,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad o zona general (sin domicilio)')),
                TextField(key: const Key('b1-create-capacity'),
                  controller: capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Límite de participantes (1–200)')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('b1-create-date'),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(formatStart(scheduled.toIso8601String())),
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: dialog,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: now.add(const Duration(days: 180)),
                      initialDate: scheduled,
                    );
                    if (date == null || !dialog.mounted) return;
                    final time = await showTimePicker(
                      context: dialog,
                      initialTime: TimeOfDay.fromDateTime(scheduled),
                    );
                    if (time == null || !dialog.mounted) return;
                    update(() => scheduled = DateTime(
                      date.year, date.month, date.day,
                      time.hour, time.minute,
                    ));
                  },
                ),
                if (validation != null) Text(validation!,
                  style: const TextStyle(color: Colors.redAccent)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancelar')),
            FilledButton(
              key: const Key('b1-create-submit'),
              onPressed: () {
                final seats = int.tryParse(capacity.text.trim());
                final hours = scheduled.difference(DateTime.now()).inMinutes;
                if (title.text.trim().length < 4 ||
                    description.text.trim().length < 10 ||
                    sport.text.trim().length < 2 ||
                    city.text.trim().length < 2 ||
                    seats == null || seats < 1 || seats > 200 ||
                    hours <= 10 || hours > 180 * 24 * 60) {
                  update(() => validation =
                    'Completa todos los campos, cupos y fecha futura.');
                  return;
                }
                Navigator.pop(dialog, {
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'sport': sport.text.trim(),
                  'city': city.text.trim(),
                  'capacity': seats,
                  'starts_at': scheduled.toUtc().toIso8601String(),
                });
              },
              child: const Text('Publicar actividad'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    sport.dispose();
    city.dispose();
    capacity.dispose();
    if (payload == null || !mounted) return;
    setState(() { publishing = true; error = null; });
    try {
      await widget.api.publishActivity(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Actividad publicada correctamente.'),
        ));
        await load();
      }
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() =>
        error = 'No fue posible publicar. Confirma tu autorización de organizador.');
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Widget activityCard(Map<String, dynamic> item) {
    final joined = item['joined'] == true;
    final id = (item['id'] ?? '').toString();
    final busy = activeRsvp != null;
    final title = (item['title'] ?? 'Actividad deportiva').toString();
    return Card(
      key: Key('b1-activity-$id'),
      margin: const EdgeInsets.only(bottom: 13),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${item['sport'] ?? ''} · ${item['city'] ?? ''}',
            style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 5),
          Text(formatStart(item['starts_at'])),
          const SizedBox(height: 12),
          Text((item['description'] ?? '').toString()),
          const SizedBox(height: 12),
          Text('Cupo máximo: ${item['capacity'] ?? '—'} personas.',
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: Key('b1-rsvp-$id'),
            onPressed: joined || busy ? null : () => confirm(item),
            icon: Icon(joined ? Icons.check_circle : Icons.event_available),
            label: Text(joined ? 'Participación confirmada' :
              activeRsvp == id ? 'Confirmando…' : 'Confirmar participación'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Explorar actividades'),
      actions: [
        IconButton(
          key: const Key('b1-reload'),
          tooltip: 'Actualizar actividades',
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            key: const Key('b1-activities-list'),
            padding: const EdgeInsets.all(18),
            children: [
              Text('Muévete en buena compañía',
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Actividades publicadas por organizadores autorizados. '
                'No compartimos tu gimnasio, ubicación exacta ni rutina.'),
              if (organizer) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  key: const Key('b1-organizer-create'),
                  onPressed: publishing ? null : createActivity,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(publishing ? 'Publicando…' : 'Crear actividad'),
                ),
              ],
              if (loading) const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              if (error != null) ...[
                const SizedBox(height: 18),
                Text(error!, key: const Key('b1-activities-error'),
                  style: const TextStyle(color: Colors.redAccent)),
                TextButton(onPressed: load,
                  child: const Text('Reintentar')),
              ],
              if (!loading && error == null && activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'Aún no hay actividades publicadas. No mostramos '
                    'actividades ficticias como si fueran reales.',
                    key: Key('b1-activities-empty'),
                  ),
                ),
              const SizedBox(height: 18),
              if (!loading) for (final item in activities) activityCard(item),
              const SizedBox(height: 24),
              const Text('La participación es voluntaria. '
                'La confirmación no publica tus horarios privados.'),
            ],
          ),
        ),
      ),
    ),
  );
}
