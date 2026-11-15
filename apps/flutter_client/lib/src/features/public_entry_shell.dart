import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/live_brand.dart';

/// Public marketing experience. Account consent is recorded in the
/// authenticated registration gate, never duplicated on the landing page.
class PublicEntryShell extends StatefulWidget {
  const PublicEntryShell({
    super.key,
    this.onGoogle,
    this.onApple,
    this.onEmail,
    this.onEmailRegister,
    this.onEmailSignIn,
    this.termsUrl = '',
    this.privacyUrl = '',
  });
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onEmail;
  final VoidCallback? onEmailRegister;
  final VoidCallback? onEmailSignIn;
  final String termsUrl;
  final String privacyUrl;

  @override
  State<PublicEntryShell> createState() => _PublicEntryShellState();
}

class _PublicEntryShellState extends State<PublicEntryShell> {
  bool register = false;
  static const navy = Color(0xFF101B21);
  static const gold = Color(0xFFD5BE8A);
  static const ivory = Color(0xFFF4F0E8);
  static const sage = Color(0xFF9FB5A9);

  bool get legalConfigured =>
      widget.termsUrl.startsWith('https://') &&
      widget.privacyUrl.startsWith('https://');

  Future<void> openPolicy(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'https') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _wordmark(LiveBrandSettings brand, {bool compact = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: compact ? 40 : 56,
        height: compact ? 40 : 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: gold.withValues(alpha: .75)),
          borderRadius: BorderRadius.circular(compact ? 11 : 15),
          color: const Color(0xFF1A2B30),
        ),
        child: Text('M', style: TextStyle(
          color: gold, fontFamily: 'Georgia',
          fontSize: compact ? 27 : 38, fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic, height: 1,
        )),
      ),
      const SizedBox(width: 12),
      Flexible(child: Text(brand.name,
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(color: ivory, fontSize: compact ? 17 : 24,
          fontWeight: FontWeight.w600, letterSpacing: .3))),
    ]);
  }

  Widget _feature(IconData icon, String heading, String detail) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 330),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: gold, size: 27),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: const TextStyle(color: ivory,
              fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(detail, style: const TextStyle(color: sage,
              fontSize: 13, height: 1.45)),
          ])),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = LiveBrandScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final emailAction = register
        ? (widget.onEmailRegister ?? widget.onEmail)
        : (widget.onEmailSignIn ?? widget.onEmail);
    final enabled = legalConfigured;
    final cover = brand.media[wide ? 'cover_desktop' : 'cover_mobile'];
    final hero = Container(
      key: const Key('landing-hero'),
      constraints: BoxConstraints(minHeight: wide ? 590 : 460),
      padding: EdgeInsets.all(wide ? 54 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: gold.withValues(alpha: .23)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1F3437), navy, Color(0xFF26392E)],
        ),
        image: cover == null ? null : DecorationImage(
          image: NetworkImage(cover), fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            navy.withValues(alpha: .78), BlendMode.darken),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
          _wordmark(brand),
          const SizedBox(height: 38),
          const Text('UNA CONEXIÓN A TU ALTURA',
            style: TextStyle(color: gold, letterSpacing: 2.2,
              fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Text(brand.title,
            key: const Key('landing-headline'),
            style: TextStyle(color: ivory, height: 1.09,
              fontFamily: 'Georgia', fontSize: wide ? 48 : 37)),
          const SizedBox(height: 22),
          Text(brand.description, key: const Key('landing-brand-description'),
            style: const TextStyle(color: Color(0xFFD7DFD8),
              height: 1.65, fontSize: 16)),
          const SizedBox(height: 30),
          Container(width: 72, height: 2, color: gold),
          const SizedBox(height: 25),
          const Text('Para personas activas que buscan algo auténtico. '
            'Porque compartir valores importa tanto como compartir una pasión.',
            style: TextStyle(color: sage, height: 1.6, fontSize: 14)),
        ]),
    );
    final access = Container(
      key: const Key('landing-access'),
      padding: EdgeInsets.all(wide ? 32 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF19272C),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: gold.withValues(alpha: .28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, children: [
          const Text('TU PRÓXIMO CAPÍTULO',
            style: TextStyle(fontSize: 11, letterSpacing: 2,
              color: gold, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(register ? 'Comienza aquí' : 'Bienvenido',
            style: const TextStyle(fontFamily: 'Georgia',
              fontSize: 33, color: ivory)),
          const SizedBox(height: 12),
          Text(register
            ? 'Crea tu cuenta y descubre una forma distinta de conectar.'
            : 'Accede a tu espacio y continúa donde lo dejaste.',
            style: const TextStyle(color: sage, fontSize: 14, height: 1.5)),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            key: const Key('google-signin-entry'),
            onPressed: enabled ? widget.onGoogle : null,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Continuar con Google'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('apple-signin-entry'),
            onPressed: enabled ? widget.onApple : null,
            icon: const Icon(Icons.apple),
            label: const Text('Continuar con Apple'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('email-entry'),
            onPressed: enabled ? emailAction : null,
            style: FilledButton.styleFrom(backgroundColor: gold,
              foregroundColor: navy, minimumSize: const Size(0, 54)),
            icon: const Icon(Icons.mail_outline),
            label: Text(register ? 'Crear cuenta con correo' : 'Entrar con correo'),
          ),
          const SizedBox(height: 22),
          TextButton(
            key: const Key('switch-entry-mode'),
            onPressed: () => setState(() => register = !register),
            child: Text(register
              ? '¿Ya tienes cuenta? Inicia sesión'
              : '¿Aún no tienes cuenta? Regístrate',
              style: const TextStyle(color: gold)),
          ),
          const Divider(color: Color(0xFF425150)),
          const SizedBox(height: 12),
          const Text('Al crear una cuenta se te solicitará aceptar '
            'los documentos legales y declarar tu mayoría de edad. '
            'No volveremos a pedirlo en cada inicio de sesión.',
            style: TextStyle(color: sage, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: [
            TextButton(onPressed: enabled
              ? () => openPolicy(widget.termsUrl) : null,
              child: const Text('Términos', style: TextStyle(color: ivory))),
            TextButton(onPressed: enabled
              ? () => openPolicy(widget.privacyUrl) : null,
              child: const Text('Privacidad', style: TextStyle(color: ivory))),
          ]),
          if (!enabled || (widget.onGoogle == null &&
              widget.onApple == null && emailAction == null))
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Acceso aún no configurado para este entorno.',
                key: Key('signup-closed'),
                style: TextStyle(color: sage, fontSize: 12)),
            ),
        ]),
    );
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        title: _wordmark(brand, compact: true),
        actions: [
          if (wide) const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('CONEXIONES CON INTENCIÓN',
              style: TextStyle(color: sage, fontSize: 11,
                letterSpacing: 1.4)))),
        ],
      ),
      body: SafeArea(child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 36 : 16, vertical: 22),
        children: [
          Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1380),
            child: Column(children: [
              if (wide)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 7, child: hero),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: access),
                ])
              else ...[hero, const SizedBox(height: 20), access],
              const SizedBox(height: 34),
              Wrap(alignment: WrapAlignment.spaceBetween,
                spacing: 24, runSpacing: 6, children: [
                  _feature(Icons.directions_run_outlined,
                    'Un estilo de vida en común',
                    'Conoce personas que valoran el bienestar y el movimiento.'),
                  _feature(Icons.auto_awesome_outlined,
                    'Afinidad con intención',
                    'Conecta por valores, intereses y manera de vivir.'),
                  _feature(Icons.shield_outlined,
                    'Privacidad antes que exposición',
                    'Tu rutina y tus espacios de entrenamiento son privados.'),
                ]),
              const SizedBox(height: 36),
              const Divider(color: Color(0xFF425150)),
              const SizedBox(height: 14),
              const Text('My Fitness Date · Conexiones con intención. '
                'Las funciones de citas se habilitarán cuando concluyan '
                'las verificaciones de seguridad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: sage, fontSize: 12, height: 1.5)),
            ]),
          )),
        ],
      )),
    );
  }
}
