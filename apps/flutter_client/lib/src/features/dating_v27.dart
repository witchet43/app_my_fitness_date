import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import '../theme/fitness_date_theme.dart';

/// FitDating: genuine backend gated flow. Nobody is searchable unless independently
/// age verified, explicitly opted in and enabled in the existing database RPC.
/// Consent alone never bypasses the database's adult-eligibility check.
class DatingV27 extends StatefulWidget {
  const DatingV27({super.key, required this.api});
  final MemberV26Api api;
  @override
  State<DatingV27> createState() => _DatingV27State();
}

class _DatingV27State extends State<DatingV27> {
  Map<String, dynamic>? status;
  List<Map<String, dynamic>> people = [];
  bool busy = false;
  bool consentChecked = false;
  String? error;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final result = await widget.api.datingStatus();
      List<Map<String, dynamic>> matches = [];
      if (result['enabled'] == true) {
        matches = await widget.api.datingCandidates();
      }
      if (mounted) setState(() {
        status = result;
        people = matches;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'FitDating no está disponible. Comprueba tu conexión.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> optIn() async {
    if (!consentChecked) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.api.acceptDating();
      await refresh();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'No pudimos guardar tu consentimiento. No se activaron citas.');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = status?['age_verified'] == true;
    final opted = status?['dating_consent'] == true;
    final enabled = status?['enabled'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('FitDating')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(padding: const EdgeInsets.all(22), children: [
          const Icon(Icons.favorite_outline, color: FitDateColors.coral, size: 52),
          const SizedBox(height: 10),
          const Text('Conecta a tu ritmo',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30)),
          const SizedBox(height: 8),
          const Text('Intereses deportivos reales, privacidad por defecto y '
            'consentimiento independiente. No compartimos tu gimnasio, '
            'rutas, horarios ni localización exacta.',
            style: TextStyle(color: FitDateColors.muted)),
          const SizedBox(height: 22),
          if (busy) const LinearProgressIndicator(),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
          if (status != null) ...[
            ListTile(
              leading: Icon(age ? Icons.verified_user : Icons.lock_outline,
                color: age ? FitDateColors.lime : FitDateColors.coral),
              title: Text(age ? 'Mayoría de edad verificada' :
                'Verificación independiente de edad pendiente'),
              subtitle: Text(age ?
                'Estado de verificación confirmado por el servidor.' :
                'Declara tu edad en el perfil. Para activar citas es necesaria '
                'una revisión de edad por un operador autorizado. '
                'Solicítala a witchet43@gmail.com sin enviar documentos '
                'de identidad por este medio.'),
            ),
            const Divider(),
            if (!opted) ...[
              CheckboxListTile(
                value: consentChecked,
                onChanged: busy ? null : (value) =>
                    setState(() => consentChecked = value ?? false),
                title: const Text('Acepto participar voluntariamente en FitDating'),
                subtitle: const Text('Consentimiento separado de los términos '
                  'y del perfil deportivo. No activa la búsqueda sin '
                  'verificación de edad y demás requisitos.'),
              ),
              FilledButton(
                key: const Key('fitdating-opt-in'),
                onPressed: consentChecked && !busy ? optIn : null,
                child: const Text('Guardar mi consentimiento'),
              ),
            ] else const ListTile(
              leading: Icon(Icons.check_circle_outline, color: FitDateColors.lime),
              title: Text('Consentimiento para FitDating registrado'),
            ),
            const SizedBox(height: 18),
            if (enabled) ...[
              Text('Personas compatibles', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (people.isEmpty)
                const Text('Todavía no hay perfiles compatibles disponibles.'),
              for (final person in people)
                Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text((person['display_name'] ?? 'Deportista').toString()),
                  subtitle: Text((person['city'] ?? '').toString()),
                  trailing: const Icon(Icons.shield_outlined),
                )),
            ] else const Card(child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('La búsqueda de personas permanece protegida '
                'hasta completar todos los requisitos. No se muestran '
                'perfiles ficticios ni datos privados.'),
            )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: busy ? null : refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar mi estado'),
            ),
          ],
        ]),
      )),
    );
  }
}
