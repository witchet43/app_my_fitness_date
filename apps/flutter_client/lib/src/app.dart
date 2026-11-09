import 'package:flutter/material.dart';

import 'core/api_client.dart';

class FitnessDateApp extends StatefulWidget {
  const FitnessDateApp({super.key, required this.api});

  final ApiClient api;

  @override
  State<FitnessDateApp> createState() => _FitnessDateAppState();
}

class _FitnessDateAppState extends State<FitnessDateApp> {
  int _section = 0;
  String _apiStatus = 'API sin configurar';
  String _mode = 'other_gyms';

  @override
  void initState() {
    super.initState();
    if (widget.api.isConfigured) {
      _apiStatus = 'Comprobando API…';
      _checkConnection();
    }
  }

  Future<void> _checkConnection() async {
    try {
      final ready = await widget.api.health();
      if (mounted) {
        setState(() => _apiStatus =
            ready ? 'Gateway disponible' : 'Gateway no disponible');
      }
    } catch (_) {
      if (mounted) setState(() => _apiStatus = 'Gateway no disponible');
    }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text('DEV · $_apiStatus',
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
                        const Text('Privacidad de gimnasio',
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
                        const Text('La elegibilidad se decide exclusivamente '
                            'en el servidor. La búsqueda permanece desactivada '
                            'hasta completar autenticación y verificación de edad.'),
                      ])
                  : Text(_section == 0
                      ? 'La comunidad se conectará a su microservicio mediante '
                        'API versionada. Sin datos reales en esta entrega.'
                      : 'Actividades y eventos se conectarán a su microservicio '
                        'mediante API versionada. Sin datos reales en esta entrega.'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Candidato de arquitectura V22 · No es beta pública',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
