import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/password_recovery.dart';

/// Native Flutter password recovery, shared by member and administrator.
/// A valid Supabase recovery session is required; this screen never confers
/// any role or bypasses the independently enforced administrator AAL2 gate.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    required this.client,
    required this.onFinished,
  });

  final SupabaseClient client;
  final Future<void> Function() onFinished;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  bool saved = false;
  String? error;

  Future<void> _save() async {
    if (busy) return;
    final newPassword = password.text;
    final validation = passwordValidationMessage(
      newPassword, confirmation.text);
    if (validation != null) {
      setState(() => error = validation);
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      // The Auth server validates the recovery session. No client-side
      // administrator claims, service-role key or custom recovery token.
      await widget.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      password.clear();
      confirmation.clear();
      if (mounted) setState(() => saved = true);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'No se pudo guardar la contraseña. '
            'Solicita otro enlace si el actual ha caducado.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    password.clear();
    confirmation.clear();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Fitness Date')),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.lock_reset_outlined, size: 54),
          const SizedBox(height: 16),
          Text(saved ? 'Contraseña establecida' : 'Crea tu contraseña',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(saved
            ? 'La contraseña se actualizó. Vuelve a iniciar sesión. '
              'Si eres administrador, también deberás completar tu segundo factor.'
            : 'Estás en My Fitness Date. El enlace recibido por correo '
              'permite establecer una contraseña para esta cuenta.',
            textAlign: TextAlign.center),
          if (!saved) ...[
            const SizedBox(height: 20),
            TextField(
              key: const Key('recovery-new-password'),
              controller: password, obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Contraseña nueva (12 caracteres mínimo)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('recovery-confirm-password'),
              controller: confirmation, obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
            ),
            if (error != null) Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('recovery-save-password'),
              onPressed: busy ? null : _save,
              child: Text(busy ? 'Guardando...' : 'Guardar contraseña'),
            ),
          ] else ...[
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('recovery-return-login'),
              onPressed: busy ? null : () => widget.onFinished(),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
          const SizedBox(height: 12),
          const Text('No compartas tu contraseña ni el enlace de recuperación.',
            textAlign: TextAlign.center),
        ],
      ),
    ))),
  );
}
