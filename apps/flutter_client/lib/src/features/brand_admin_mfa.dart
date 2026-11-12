import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const brandAdminFactorName = 'My Fitness Date · Administrador';

/// Include unverified factors returned by listFactors().all (not .totp,
/// which only returns verified factors in the Supabase 2.x client).
Iterable<Factor> verifiedAdminTotpFactors(Iterable<Factor> factors) =>
    factors.where((f) =>
        f.factorType == FactorType.totp &&
        f.status == FactorStatus.verified);

Iterable<Factor> staleBrandAdminTotpFactors(Iterable<Factor> factors) =>
    factors.where((f) =>
        f.factorType == FactorType.totp &&
        f.status == FactorStatus.unverified &&
        f.friendlyName == brandAdminFactorName);

/// This widget is shown INSIDE the same My Fitness Date app after the database
/// recognizes a Brand Administrator. It grants no data permissions itself.
/// PostgreSQL RLS still checks the refreshed AAL2 JWT on every operation.
class BrandAdminMfaGate extends StatefulWidget {
  const BrandAdminMfaGate({
    super.key,
    required this.client,
    required this.onVerified,
    required this.onSignOut,
  });
  final SupabaseClient client;
  final VoidCallback onVerified;
  final Future<void> Function() onSignOut;

  @override
  State<BrandAdminMfaGate> createState() => _BrandAdminMfaGateState();
}

class _BrandAdminMfaGateState extends State<BrandAdminMfaGate> {
  final code = TextEditingController();
  bool _preparing = false;
  bool busy = true;
  bool enrollment = false;
  String? factorId;
  String? secret;
  String? error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    // Concurrent enrollment attempts create duplicate-name conflicts.
    if (!mounted || _preparing) return;
    _preparing = true;
    setState(() {
      busy = true; error = null; factorId = null;
      secret = null; enrollment = false;
    });
    try {
      final factors = await widget.client.auth.mfa.listFactors();
      // In Supabase 2.x, .totp only contains VERIFIED factors and status is
      // an enum, not the strings 'verified'/'unverified'. .all contains
      // incomplete enrollments too. Comparing to strings incorrectly caused
      // a new factor to be enrolled on each rebuild until Auth returned 422.
      final verified = verifiedAdminTotpFactors(factors.all).toList();
      if (verified.isNotEmpty) {
        factorId = verified.first.id;
        enrollment = false;
      } else {
        // Clear ONLY our own incomplete enrollment. The secret cannot be
        // retrieved again after reload. Never touch verified or foreign factors.
        final pending = staleBrandAdminTotpFactors(factors.all);
        for (final factor in pending) {
          await widget.client.auth.mfa.unenroll(factor.id);
        }
        final result = await widget.client.auth.mfa.enroll(
          factorType: FactorType.totp,
          friendlyName: brandAdminFactorName,
        );
        factorId = result.id;
        secret = result.totp?.secret;
        enrollment = true;
        if (secret == null || secret!.isEmpty) {
          throw StateError('No se recibió la clave TOTP');
        }
      }
    } catch (_) {
      error = 'No fue posible preparar la verificación. Puedes reintentar.';
    } finally {
      _preparing = false;
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(code.text.trim()) || factorId == null) {
      setState(() => error = 'Introduce seis dígitos de tu autenticador.');
      return;
    }
    setState(() {busy = true;error = null;});
    try {
      await widget.client.auth.mfa.challengeAndVerify(
        factorId: factorId!,
        code: code.text.trim(),
      );
      // The source of truth remains public.brand_admin_session() and RLS.
      final verified = await widget.client.rpc('brand_admin_session');
      if (verified != true) throw StateError('No se alcanzó AAL2');
      secret = null;
      code.clear();
      widget.onVerified();
    } catch (_) {
      if (mounted) setState(() =>
        error = 'No pudimos verificar el código. Revisa la hora del dispositivo.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    secret = null;
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Fitness Date · Administrador'),
      actions: [
        IconButton(onPressed: () => widget.onSignOut(),
          icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión'),
      ],
    ),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: ListView(shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.admin_panel_settings_outlined, size: 54),
          const SizedBox(height: 15),
          Text(enrollment ? 'Configura tu segundo factor'
            : 'Confirma tu identidad',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('El rol administrador tiene acceso a funciones '
            'privilegiadas. Utiliza un código temporal de tu autenticador.',
            textAlign: TextAlign.center),
          if (enrollment && secret != null) ...[
            const SizedBox(height: 20),
            const Text('Introduce esta clave en Google Authenticator o '
              'Microsoft Authenticator. No la compartas.'),
            const SizedBox(height: 10),
            SelectableText(secret!, key: const Key('admin-mfa-secret'),
              textAlign: TextAlign.center),
          ],
          const SizedBox(height: 22),
          TextField(
            key: const Key('admin-mfa-code'), controller: code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código temporal de seis dígitos'),
          ),
          if (error != null)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
          FilledButton(
            key: const Key('admin-mfa-verify'),
            onPressed: busy ? null : _verify,
            child: Text(busy ? 'Comprobando...' : 'Verificar y entrar al panel'),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: busy ? null : _prepare,
            child: const Text('Reintentar configuración')),
          TextButton(onPressed: () => widget.onSignOut(),
            child: const Text('Cerrar sesión')),
        ],
      ),
    )),
  );
}
