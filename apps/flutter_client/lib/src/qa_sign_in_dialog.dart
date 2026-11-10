import 'package:flutter/material.dart';

import 'core/auth_session.dart';
import 'core/identity_session_manager.dart';

/// A controlled QA sign-in only; no sign-up or password recovery flow is exposed.
class QaSignInDialog extends StatefulWidget {
  const QaSignInDialog({super.key, required this.manager});

  final IdentitySessionManager manager;

  @override
  State<QaSignInDialog> createState() => _QaSignInDialogState();
}

class _QaSignInDialogState extends State<QaSignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _working = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.manager.signIn(_email.text.trim(), _password.text);
      _password.clear();
      if (mounted) Navigator.of(context).pop(true);
    } on IdentityException catch (error) {
      _password.clear();
      if (mounted) setState(() => _error = error.safeMessage);
    } catch (_) {
      _password.clear();
      if (mounted) setState(() => _error = 'No fue posible iniciar sesión.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Acceso de pruebas'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Solo cuentas QA existentes y autorizadas. '
                  'No hay registro público.'),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('qa-email'),
                controller: _email,
                enabled: !_working,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo QA', border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Indica un correo válido.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('qa-password'),
                controller: _password,
                enabled: !_working,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _signIn(),
                decoration: const InputDecoration(
                  labelText: 'Contraseña', border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Indica tu contraseña.' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, key: const Key('qa-error'),
                     style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('qa-submit'),
          onPressed: _working ? null : _signIn,
          child: Text(_working ? 'Verificando…' : 'Entrar'),
        ),
      ],
    );
  }
}
