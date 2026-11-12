import 'package:flutter/material.dart';
import '../core/member_onboarding_validation.dart';

/// One-screen, minimal, private onboarding for the first useful B1 journey.
/// The date of birth is stored ONLY in the owner-only profile for adult gating;
/// age is self-declared and does not bypass independent FitDating verification.
class MemberOnboardingB1 extends StatefulWidget {
  const MemberOnboardingB1({super.key, this.initial,
    required this.onSave, this.onCancel});
  final Map<String, dynamic>? initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback? onCancel;

  @override
  State<MemberOnboardingB1> createState() => _MemberOnboardingB1State();
}

class _MemberOnboardingB1State extends State<MemberOnboardingB1> {
  late final TextEditingController name;
  late final TextEditingController city;
  late final TextEditingController sports;
  DateTime? birthday;
  String frequency = 'flexible';
  bool adultDeclared = false;
  bool saving = false;
  String? warning;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? <String, dynamic>{};
    name = TextEditingController(text: (p['display_name'] ?? '').toString());
    city = TextEditingController(text: (p['city'] ?? '').toString());
    sports = TextEditingController(
      text: (p['sports'] is List) ? (p['sports'] as List).join(', ') : '',
    );
    birthday = DateTime.tryParse((p['date_of_birth'] ?? '').toString());
    adultDeclared = p['onboarding_complete'] == true;
    final selection = (p['training_frequency'] ?? 'flexible').toString();
    if (const ['starting', 'one_to_two', 'three_to_four', 'five_plus',
      'flexible'].contains(selection)) {
      frequency = selection;
    }
  }

  @override
  void dispose() {
    name.dispose();
    city.dispose();
    sports.dispose();
    super.dispose();
  }

  Future<void> chooseBirthday() async {
    final now = DateTime.now();
    final last = DateTime(now.year - 18, now.month, now.day);
    final initial = birthday != null && !birthday!.isAfter(last)
        ? birthday! : DateTime(1990, 1, 1);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900), lastDate: last, initialDate: initial,
      helpText: 'Fecha de nacimiento privada',
    );
    if (picked != null && mounted) setState(() => birthday = picked);
  }

  Future<void> save() async {
    if (saving) return;
    final issue = validateMemberBasics(
      name: name.text, city: city.text, sports: sports.text,
      dateOfBirth: birthday, adultDeclared: adultDeclared,
    );
    if (issue != null) {
      setState(() => warning = issue);
      return;
    }
    setState(() { saving = true; warning = null; });
    try {
      await widget.onSave({
        'display_name': name.text.trim(),
        'city': city.text.trim(),
        'sports': normalizedSports(sports.text),
        'training_frequency': frequency,
        'date_of_birth': dateOnly(birthday!),
        // Community participation never enables romantic discoverability.
        'social_visibility': 'private',
        'onboarding_complete': true,
      });
    } catch (_) {
      if (mounted) setState(() =>
        warning = 'No pudimos guardar tu perfil. Comprueba la conexión e inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Icon(Icons.directions_run, size: 43),
          const SizedBox(height: 12),
          Text('Tu perfil deportivo', key: const Key('b1-onboarding-title'),
            style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Solo lo esencial para encontrar actividades. '
            'Tu fecha de nacimiento y lugares de entrenamiento no se muestran '
            'a otras personas.'),
          const SizedBox(height: 22),
          TextField(
            key: const Key('b1-name'), controller: name,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Cómo quieres que te llamemos'),
          ),
          TextField(
            key: const Key('b1-city'), controller: city,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Ciudad (sin dirección exacta)'),
          ),
          TextField(
            key: const Key('b1-sports'), controller: sports,
            maxLength: 400,
            decoration: const InputDecoration(
              labelText: 'Tus deportes',
              helperText: 'Ej. correr, senderismo, ciclismo'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('b1-frequency'),
            initialValue: frequency,
            decoration: const InputDecoration(
              labelText: '¿Con qué frecuencia entrenas?'),
            items: const [
              DropdownMenuItem(value: 'starting', child: Text('Estoy empezando')),
              DropdownMenuItem(value: 'one_to_two', child: Text('1–2 días')),
              DropdownMenuItem(value: 'three_to_four', child: Text('3–4 días')),
              DropdownMenuItem(value: 'five_plus', child: Text('5 o más días')),
              DropdownMenuItem(value: 'flexible', child: Text('Variable')),
            ],
            onChanged: saving ? null : (v) {
              if (v != null) setState(() => frequency = v);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('b1-birthday'),
            onPressed: saving ? null : chooseBirthday,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(birthday == null
              ? 'Indicar fecha de nacimiento privada'
              : 'Nacimiento: ${dateOnly(birthday!)}'),
          ),
          CheckboxListTile(
            key: const Key('b1-adult'),
            value: adultDeclared,
            onChanged: saving ? null : (value) =>
              setState(() => adultDeclared = value ?? false),
            title: const Text('Declaro ser mayor de 18 años'),
            subtitle: const Text('Esta declaración no sustituye la '
              'verificación independiente requerida para FitDating.'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (warning != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(warning!, key: const Key('b1-error'),
              style: const TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('b1-save'),
            onPressed: saving ? null : save,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(saving ? 'Guardando…' : 'Guardar y explorar actividades'),
          ),
          if (widget.onCancel != null)
            TextButton(onPressed: saving ? null : widget.onCancel,
              child: const Text('Volver a mi perfil')),
        ],
      ),
    ),
  );
}
