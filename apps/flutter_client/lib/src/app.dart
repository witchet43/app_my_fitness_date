import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/identity_session_manager.dart';
import 'qa_sign_in_dialog.dart';
import 'features/pace_calculator.dart';

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
  final GlobalKey<ScaffoldMessengerState> _messageKey = GlobalKey<ScaffoldMessengerState>();

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

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB6F266);
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF091319),
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ),
    );
    return MaterialApp(
      title: 'my_fitness_date',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messageKey,
      theme: theme,
      home: LayoutBuilder(builder: (context, size) {
        final wide = size.maxWidth >= 720;
        final destinations = [
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined), label: 'Comunidad'),
          const NavigationDestination(
            icon: Icon(Icons.directions_run), label: 'Actividades'),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border), label: 'Citas'),
        ];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF091319),
            title: const Text('my_fitness_date',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              if (widget.qaLoginEnabled && widget.api.isConfigured)
                IconButton(
                  key: const Key('qa-identity-action'),
                  tooltip: _identity.signedIn
                      ? 'Cerrar sesión QA' : 'Iniciar sesión QA',
                  onPressed: _identity.signedIn
                      ? _signOutQa : () => _openQaLogin(context),
                  icon: Icon(_identity.signedIn
                      ? Icons.logout : Icons.account_circle_outlined),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(_publicProduction
                      ? 'PRODUCCIÓN · herramientas públicas'
                      : 'DEV · $_apiStatus',
                      style: const TextStyle(fontSize: 12)),
                ),
              )
            ],
          ),
          body: Row(children: [
            if (wide)
              NavigationRail(
                selectedIndex: _section,
                onDestinationSelected: (index) =>
                    setState(() => _section = index),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.groups_outlined),
                      label: Text('Comunidad')),
                  NavigationRailDestination(
                      icon: Icon(Icons.directions_run),
                      label: Text('Actividades')),
                  NavigationRailDestination(
                      icon: Icon(Icons.favorite_border),
                      label: Text('Citas')),
                ],
              ),
            Expanded(child: _content()),
          ]),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _section,
                  destinations: destinations,
                  onDestinationSelected: (index) =>
                      setState(() => _section = index),
                ),
        );
      }),
    );
  }

  Widget _content() {
    final title = switch (_section) {
      0 => 'FitCommunity',
      1 => 'FitTogether',
      _ => 'FitDating · Gym Shield',
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('TRAIN · CONNECT · BELONG',
              style: TextStyle(letterSpacing: 2, fontSize: 11)),
          if (widget.qaLoginEnabled && widget.api.isConfigured)
            Text(
              _identity.signedIn
                  ? 'Sesión QA: ${_identity.session!.user.email} · '
                    'No autoriza FitDating'
                  : 'Sin sesión QA · registro público cerrado',
              key: const Key('qa-session-status'),
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
              fontSize: 27, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Flutter · Web / Android / iOS · API Gateway'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _section == 2
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Privacidad de gimnasio · vista previa',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          multiSelectionEnabled: false,
                          selected: {_mode},
                          segments: const [
                            ButtonSegment(
                              value: 'other_gyms',
                              label: Text('Otros gimnasios')),
                            ButtonSegment(
                              value: 'same_gym_other_time',
                              label: Text('Otro horario')),
                          ],
                          onSelectionChanged: (values) =>
                              setState(() => _mode = values.first),
                        ),
                        const SizedBox(height: 14),
                        const Text('Esta selección no se guarda todavía. '
                            'La elegibilidad se decide exclusivamente '
                            'en el servidor. La búsqueda permanece desactivada '
                            'hasta completar autenticación y verificación de edad.'),
                      ])
                  : _section == 1
                      ? const PaceCalculator()
                      : const Text(
                          'FitCommunity está en preparación. Mientras tanto, '
                          'puedes utilizar la calculadora de ritmo en '
                          'Actividades sin crear una cuenta. '
                          'Aún no se publican perfiles ni datos de personas.'),
            ),
          ),
          const SizedBox(height: 12),
          Text(_publicProduction
                  ? 'Primera entrega pública segura · sin registro ni citas activas'
                  : 'Candidato de arquitectura V22 · No es beta pública',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
