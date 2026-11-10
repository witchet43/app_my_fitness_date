import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/identity_session_manager.dart';
import 'features/pace_calculator.dart';
import 'qa_sign_in_dialog.dart';
import 'theme/fitness_date_theme.dart';

/// Active Chemistry: public-facing identity for fitness + mindful dating.
/// The published Web build remains anonymous and does not activate dating.
class FitnessDateApp extends StatefulWidget {
  const FitnessDateApp({
    super.key,
    required this.api,
    this.qaLoginEnabled = const bool.fromEnvironment('MFD_QA_LOGIN_UI'),
  });

  final ApiClient api;
  final bool qaLoginEnabled;

  @override
  State<FitnessDateApp> createState() => _FitnessDateAppState();
}

class _FitnessDateAppState extends State<FitnessDateApp>
    with WidgetsBindingObserver {
  static const bool _publicProduction =
      bool.fromEnvironment('MFD_PUBLIC_PRODUCTION', defaultValue: false);

  late final IdentitySessionManager _identity;
  final _messageKey = GlobalKey<ScaffoldMessengerState>();
  int _section = 0;
  String _apiStatus = 'API sin configurar';
  String _mode = 'other_gyms';

  @override
  void initState() {
    super.initState();
    _identity = IdentitySessionManager(widget.api);
    _identity.addListener(_identityChanged);
    WidgetsBinding.instance.addObserver(this);
    if (widget.api.isConfigured) {
      _apiStatus = 'Comprobando servicio…';
      _checkConnection();
    }
  }

  Future<void> _checkConnection() async {
    try {
      final ready = await widget.api.readiness();
      if (mounted) {
        setState(() => _apiStatus =
            ready ? 'Servicio disponible' : 'Servicio no disponible');
      }
    } catch (_) {
      if (mounted) setState(() => _apiStatus = 'Servicio no disponible');
    }
  }

  void _identityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _identity.signedIn) {
      _checkSessionOnResume();
    }
  }

  Future<void> _checkSessionOnResume() async {
    try {
      await _identity.validateCurrentIdentity();
    } catch (_) {
      if (mounted) {
        _messageKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Sesión QA finalizada. Inicia sesión de nuevo.'),
        ));
      }
    }
  }

  Future<void> _openQaLogin(BuildContext dialogContext) async {
    await showDialog<bool>(
      context: dialogContext,
      builder: (_) => QaSignInDialog(manager: _identity),
    );
  }

  Future<void> _signOutQa() async {
    try {
      await _identity.signOut();
    } catch (_) {
      if (mounted) {
        _messageKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Sesión local cerrada. Revocación remota no confirmada.'),
        ));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _identity.removeListener(_identityChanged);
    _identity.dispose();
    super.dispose();
  }

  void _navigate(int section) {
    if (section != _section) {
      setState(() => _section = section);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    return MaterialApp(
      title: 'My Fitness Date',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messageKey,
      theme: FitDateTheme.dark(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: FitDateColors.inkDeep,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 76,
          titleSpacing: 18,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandMark(size: 42),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'My Fitness Date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FitDateColors.pearl,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (width >= 780)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: _StatusPill(
                    title: _publicProduction
                        ? 'EXPERIENCIA PÚBLICA'
                        : 'DEV · ' + _apiStatus,
                    color: FitDateColors.lime,
                  ),
                ),
              ),
            if (widget.qaLoginEnabled && widget.api.isConfigured)
              IconButton(
                key: const Key('qa-identity-action'),
                tooltip: _identity.signedIn
                    ? 'Cerrar sesión QA' : 'Iniciar sesión QA',
                onPressed: _identity.signedIn
                    ? _signOutQa
                    : () => _openQaLogin(context),
                icon: Icon(_identity.signedIn
                    ? Icons.logout : Icons.account_circle_outlined),
              ),
          ],
        ),
        body: Row(
          children: [
            if (wide)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: FitDateColors.outline, width: .7),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: _section,
                  onDestinationSelected: _navigate,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 100,
                  groupAlignment: -.62,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      selectedIcon: Icon(Icons.people_alt_rounded),
                      label: Text('Comunidad'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_run_outlined),
                      selectedIcon: Icon(Icons.directions_run),
                      label: Text('Actividades'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: Text('Citas'),
                    ),
                  ],
                ),
              ),
            Expanded(child: _content()),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : SafeArea(
                top: false,
                child: NavigationBar(
                  height: 72,
                  selectedIndex: _section,
                  onDestinationSelected: _navigate,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      selectedIcon: Icon(Icons.people_alt_rounded),
                      label: 'Comunidad',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.directions_run_outlined),
                      selectedIcon: Icon(Icons.directions_run),
                      label: 'Actividades',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: 'Citas',
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _content() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: ListView(
          key: ValueKey('content-section-' + _section.toString()),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            if (widget.qaLoginEnabled && widget.api.isConfigured)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _identity.signedIn
                      ? 'Sesión QA: ' + _identity.session!.user.email +
                          ' · No autoriza FitDating'
                      : 'Sin sesión QA · registro público cerrado',
                  key: const Key('qa-session-status'),
                  style: const TextStyle(
                    color: FitDateColors.muted, fontSize: 12,
                  ),
                ),
              ),
            if (_section == 0) _communityHome(),
            if (_section == 1) _activities(),
            if (_section == 2) _dating(),
            const SizedBox(height: 26),
            const Divider(color: FitDateColors.outline, thickness: .7),
            const SizedBox(height: 14),
            const Text(
              'My Fitness Date · Muévete con propósito. Conecta con respeto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FitDateColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Versión pública: herramientas anónimas. '
              'Perfiles, citas y mensajería todavía no están disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FitDateColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _communityHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _Eyebrow('FitCommunity  /  FITNESS + CONEXIÓN'),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, box) {
            final horizontal = box.maxWidth >= 820;
            final copy = _HeroCopy(
              onActivity: () => _navigate(1),
              onDating: () => _navigate(2),
              large: horizontal,
            );
            const art = _ChemistryArt();
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF29203A),
                    Color(0xFF1A1B2D),
                    Color(0xFF15241E),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF474257), width: .8,
                ),
              ),
              padding: EdgeInsets.all(horizontal ? 36 : 24),
              child: horizontal
                  ? Row(
                      children: [
                        Expanded(flex: 5, child: copy),
                        const SizedBox(width: 18),
                        const Expanded(flex: 4, child: art),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy,
                        const SizedBox(height: 6),
                        const Center(child: SizedBox(
                          height: 220, child: art,
                        )),
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 26),
        const _Eyebrow('UNA IDEA, TRES FORMAS DE CONECTAR'),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, box) {
          final columns = box.maxWidth >= 800 ? 3 : 1;
          final width = columns == 3
              ? (box.maxWidth - 26) / 3 : box.maxWidth;
          return Wrap(
            spacing: 13, runSpacing: 13,
            children: [
              _ValueCard(
                width: width,
                icon: Icons.directions_run,
                color: FitDateColors.lime,
                title: 'Comparte el movimiento',
                description: 'Desde una carrera hasta una sesión de fuerza: '
                    'el ejercicio puede ser un gran punto de partida.',
                note: 'Hoy: calcula tu ritmo',
                onTap: () => _navigate(1),
              ),
              _ValueCard(
                width: width,
                icon: Icons.people_alt_outlined,
                color: FitDateColors.lilac,
                title: 'Conecta con afinidad',
                description: 'Una comunidad pensada para personas que '
                    'disfrutan entrenar, caminar o mantenerse activas.',
                note: 'Comunidad en preparación',
              ),
              _ValueCard(
                width: width,
                icon: Icons.favorite_border_rounded,
                color: FitDateColors.coral,
                title: 'Algo más que ejercicio',
                description: 'Conocer a alguien con quien compartir '
                    'hábitos, metas y una conexión auténtica.',
                note: 'FitDating en preparación',
                onTap: () => _navigate(2),
              ),
            ],
          );
        }),
        const SizedBox(height: 24),
        _PrivacyBanner(onDetails: () => _navigate(2)),
      ],
    );
  }

  Widget _activities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _Eyebrow('FITTOGETHER  /  TU ENERGÍA EN MOVIMIENTO'),
        const SizedBox(height: 14),
        const Text(
          'Entrena a tu ritmo.',
          style: TextStyle(
            color: FitDateColors.pearl,
            fontSize: 36, fontWeight: FontWeight.w900, height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Empieza por una meta personal. Lo que te mueve también '
          'puede ayudarte a conectar.',
          style: TextStyle(color: FitDateColors.muted, fontSize: 16),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: FitDateColors.surface,
            border: Border.all(color: FitDateColors.outline),
          ),
          padding: const EdgeInsets.all(22),
          child: const PaceCalculator(),
        ),
        const SizedBox(height: 20),
        const _ComingSoonCard(
          icon: Icons.event_available_outlined,
          title: 'Actividades para compartir',
          description: 'Encuentros deportivos, grupos y eventos '
              'se habilitarán cuando estén listos sus controles de '
              'seguridad y consentimiento.',
          color: FitDateColors.lilac,
        ),
      ],
    );
  }

  Widget _dating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _Eyebrow('FITDATING  /  CONEXIÓN CON INTENCIÓN'),
        const SizedBox(height: 14),
        const Text(
          'FitDating · Gym Shield',
          style: TextStyle(
            color: FitDateColors.pearl, fontSize: 34,
            fontWeight: FontWeight.w900, letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Que exista química no significa renunciar a tu privacidad.',
          style: TextStyle(color: FitDateColors.muted, fontSize: 17),
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF38213D), Color(0xFF1B2231)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF5D3D5B)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StatusPill(
                title: 'VISTA PREVIA · SIN PERFILES REALES',
                color: FitDateColors.coral,
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 31, color: FitDateColors.coral),
                  SizedBox(width: 9),
                  Icon(Icons.bolt_rounded,
                      size: 29, color: FitDateColors.lime),
                  SizedBox(width: 9),
                  Icon(Icons.shield_outlined,
                      size: 28, color: FitDateColors.lilac),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Tu entrenamiento es tu espacio. '
                'Tus conexiones, tu elección.',
                style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w800,
                  height: 1.18, color: FitDateColors.pearl,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Gym Shield está diseñado para proteger datos privados '
                'del gimnasio y los horarios. Las coincidencias aún no '
                'están disponibles en la versión pública.',
                style: TextStyle(color: FitDateColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: FitDateColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FitDateColors.outline),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacidad del gimnasio · vista previa',
                style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Elige cómo te gustaría proteger tu espacio '
                'de entrenamiento cuando esté disponible:',
                style: TextStyle(color: FitDateColors.muted),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  multiSelectionEnabled: false,
                  selected: {_mode},
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? FitDateColors.inkDeep : FitDateColors.pearl,
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? FitDateColors.lime : FitDateColors.surfaceRaised,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'other_gyms',
                      label: Text('Otros gimnasios'),
                    ),
                    ButtonSegment(
                      value: 'same_gym_other_time',
                      label: Text('Otro horario'),
                    ),
                  ],
                  onSelectionChanged: (values) =>
                      setState(() => _mode = values.first),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta selección es solo ilustrativa y no se guarda. '
                'No expone gimnasio, ubicación precisa ni horarios. '
                'Las decisiones de elegibilidad corresponden al servidor.',
                style: TextStyle(
                  color: FitDateColors.muted, fontSize: 13, height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _ComingSoonCard(
          icon: Icons.verified_user_outlined,
          title: 'Conexiones seguras, primero',
          description: 'Antes de abrir FitDating habrá verificación de edad, '
              'consentimiento, moderación y revisión de seguridad.',
          color: FitDateColors.lime,
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'My Fitness Date, corazón y energía deportiva',
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [FitDateColors.coral, Color(0xFFFF9B79)],
          ),
          borderRadius: BorderRadius.circular(size * .30),
        ),
        child: Icon(
          Icons.favorite_rounded,
          color: FitDateColors.inkDeep,
          size: size * .57,
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: FitDateColors.lime,
        letterSpacing: 1.9,
        fontSize: 11, fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10, fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.onActivity,
    required this.onDating,
    required this.large,
  });

  final VoidCallback onActivity;
  final VoidCallback onDating;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StatusPill(
          title: 'MOVIMIENTO + CONEXIONES REALES',
          color: FitDateColors.lime,
        ),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Encuentra tu ritmo.\n'),
              TextSpan(
                text: 'Conecta de verdad.',
                style: TextStyle(color: FitDateColors.coral),
              ),
            ],
          ),
          key: const Key('brand-hero-headline'),
          style: TextStyle(
            fontSize: large ? 48 : 36,
            fontWeight: FontWeight.w900,
            height: 1.11,
            letterSpacing: -1.5,
            color: FitDateColors.pearl,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'El movimiento nos une. Conoce el concepto de una comunidad '
          'donde el ejercicio, las metas y las conexiones auténticas '
          'tienen algo en común: tú.',
          style: TextStyle(
            color: FitDateColors.muted,
            fontSize: 16, height: 1.48,
          ),
        ),
        const SizedBox(height: 23),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const Key('go-to-pace'),
              onPressed: onActivity,
              icon: const Icon(Icons.directions_run, size: 19),
              label: const Text('Calcula tu ritmo'),
            ),
            OutlinedButton.icon(
              key: const Key('go-to-dating'),
              onPressed: onDating,
              icon: const Icon(Icons.favorite_border_rounded, size: 18),
              label: const Text('Explora FitDating'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'La calculadora ya funciona. Comunidad y citas aún '
          'no admiten usuarios reales.',
          style: TextStyle(color: FitDateColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ChemistryArt extends StatelessWidget {
  const _ChemistryArt();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ilustración abstracta de corazón, actividad y conexión',
      image: true,
      child: SizedBox(
        height: 290,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide.clamp(170.0, 270.0);
            return Center(
              child: SizedBox(
                width: side, height: side,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: side, height: side,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FitDateColors.lilac.withValues(alpha: .30),
                        ),
                      ),
                    ),
                    Container(
                      width: side * .78, height: side * .78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: FitDateColors.coral.withValues(alpha: .45),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -.15,
                      child: Container(
                        width: side * .57, height: side * .66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(side * .21),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              FitDateColors.coral,
                              Color(0xFFB759A9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: FitDateColors.coral.withValues(alpha: .26),
                              blurRadius: 42,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: FitDateColors.pearl,
                          size: side * .30,
                        ),
                      ),
                    ),
                    Positioned(
                      top: side * .11, right: side * .05,
                      child: _FloatingIcon(
                        color: FitDateColors.lime,
                        icon: Icons.bolt_rounded,
                      ),
                    ),
                    Positioned(
                      bottom: side * .13, left: side * .04,
                      child: _FloatingIcon(
                        color: FitDateColors.lilac,
                        icon: Icons.directions_run,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: FitDateColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .45)),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 18),
        ],
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.note,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 218),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FitDateColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FitDateColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46, width: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: FitDateColors.pearl,
              fontSize: 18, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(
              color: FitDateColors.muted, fontSize: 13, height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            note,
            style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Semantics(
      button: true,
      label: title + '. ' + note,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.onDetails});

  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A282B),
        border: Border.all(color: const Color(0xFF3A5350)),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: FitDateColors.lime, size: 30),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu privacidad también importa',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: FitDateColors.pearl, fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gym Shield protegerá la privacidad de tus espacios '
                  'y horarios al habilitar las citas.',
                  style: TextStyle(
                    color: FitDateColors.muted, fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDetails,
            tooltip: 'Conocer Gym Shield',
            icon: const Icon(
              Icons.arrow_forward_rounded, color: FitDateColors.lime,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FitDateColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FitDateColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: FitDateColors.pearl,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13, color: FitDateColors.muted, height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
