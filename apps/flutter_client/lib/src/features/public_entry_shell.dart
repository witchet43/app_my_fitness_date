import 'package:flutter/material.dart';
import '../theme/fitness_date_theme.dart';

/// Marketing is public; member screens require verified authentication.
/// No real OAuth/registration buttons are enabled until PROD is configured.
class PublicEntryShell extends StatefulWidget {
  const PublicEntryShell({super.key, this.onGoogle, this.onEmail});
  final VoidCallback? onGoogle;
  final VoidCallback? onEmail;
  @override
  State<PublicEntryShell> createState() => _PublicEntryShellState();
}

class _PublicEntryShellState extends State<PublicEntryShell> {
  bool register = true;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final story = Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [
          Color(0xFF3C243F), Color(0xFF1A2430), Color(0xFF1C3227),
        ]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ACTIVE CHEMISTRY',
          style: TextStyle(color: FitDateColors.lime,
            letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        const Text('Tu próxima conexión también puede compartir tu ritmo.',
          key: Key('landing-headline'),
          style: TextStyle(fontSize: 34, height: 1.12,
            color: FitDateColors.pearl, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        const Text('Muestra quién eres, lo que te apasiona y cómo vives '
          'el deporte. Comunidad, actividades y citas opcionales con privacidad.',
          style: TextStyle(color: FitDateColors.muted, height: 1.5)),
        const SizedBox(height: 20),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          Chip(label: Text('Gym & fuerza')),
          Chip(label: Text('Running')),
          Chip(label: Text('Yoga & studios')),
          Chip(label: Text('Aventuras')),
        ]),
      ]),
    );
    final access = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FitDateColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: FitDateColors.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(register ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
          style: const TextStyle(
            fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Tu perfil comienza privado y tú decides qué compartir.',
          style: TextStyle(color: FitDateColors.muted)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('google-signin-entry'),
          onPressed: widget.onGoogle,
          icon: const Icon(Icons.account_circle_outlined),
          label: const Text('Continuar con Google'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('email-entry'),
          onPressed: widget.onEmail,
          icon: const Icon(Icons.mail_outline),
          label: Text(register ? 'Registro con correo' : 'Acceso con correo'),
        ),
        if (widget.onGoogle == null || widget.onEmail == null) ...[
          const SizedBox(height: 16),
          const Text('Registro cerrado hasta configurar Google OAuth '
            'y el entorno de identidad de producción.',
            key: Key('signup-closed'),
            style: TextStyle(color: FitDateColors.muted, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        TextButton(
          key: const Key('switch-entry-mode'),
          onPressed: () => setState(() => register = !register),
          child: Text(register ? 'Ya tengo cuenta' : 'Crear cuenta'),
        ),
        const Text('Solo adultos. FitDating requiere consentimiento '
          'independiente y verificación de edad. '
          'Tus gimnasios y horarios serán privados por defecto.',
          style: TextStyle(color: FitDateColors.muted, fontSize: 11)),
      ]),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite, color: FitDateColors.coral),
          SizedBox(width: 8),
          Text('My Fitness Date',
            style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1110),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (width >= 780)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: story),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: access),
            ])
          else ...[story, const SizedBox(height: 18), access],
          const SizedBox(height: 25),
          const Text('Perfiles y actividades de otras personas '
            'solo después de iniciar sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FitDateColors.muted, fontSize: 12)),
        ]),
      ))),
    );
  }
}
