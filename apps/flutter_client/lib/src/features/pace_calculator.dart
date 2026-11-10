import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/fitness_date_theme.dart';

/// An anonymous tool: calculations run locally; no HTTP or persistence.
class PaceCalculator extends StatefulWidget {
  const PaceCalculator({super.key});

  @override
  State<PaceCalculator> createState() => _PaceCalculatorState();
}

class _PaceCalculatorState extends State<PaceCalculator> {
  final _distance = TextEditingController(text: '5');
  final _duration = TextEditingController(text: '30');

  @override
  void dispose() {
    _distance.dispose();
    _duration.dispose();
    super.dispose();
  }

  double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  Widget _numericInput({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        color: FitDateColors.pearl,
        fontSize: 17, fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label.startsWith('Distancia')
              ? Icons.route_outlined : Icons.timer_outlined,
          color: FitDateColors.lime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _parse(_distance.text);
    final duration = _parse(_duration.text);
    final valid = distance != null && duration != null &&
        distance.isFinite && duration.isFinite &&
        distance >= 0.1 && distance <= 200 &&
        duration >= 1 && duration <= 1440;
    final secondsPerKm = valid ? (duration * 60 / distance).round() : 0;
    final pace = valid
        ? '${secondsPerKm ~/ 60}:${(secondsPerKm % 60).toString().padLeft(2, '0')}'
        : '—';
    final speed = valid ? (distance * 60 / duration).toStringAsFixed(1) : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt_rounded, color: FitDateColors.lime),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'HERRAMIENTA ACTIVA · SIN REGISTRO',
                style: TextStyle(
                  color: FitDateColors.lime,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1, fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Calculadora de ritmo de carrera',
          style: TextStyle(
            color: FitDateColors.pearl,
            fontSize: 24, fontWeight: FontWeight.w900,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Cada kilómetro cuenta. Descubre tu ritmo, '
          'define tus metas y disfruta el movimiento.',
          style: TextStyle(
            fontSize: 14, height: 1.48,
            color: FitDateColors.muted,
          ),
        ),
        const SizedBox(height: 21),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 440;
            final distanceInput = _numericInput(
              key: const Key('pace-distance'),
              controller: _distance,
              label: 'Distancia (km)',
            );
            final durationInput = _numericInput(
              key: const Key('pace-duration'),
              controller: _duration,
              label: 'Tiempo (minutos)',
            );
            return compact
                ? Column(children: [
                    distanceInput,
                    const SizedBox(height: 12),
                    durationInput,
                  ])
                : Row(children: [
                    Expanded(child: distanceInput),
                    const SizedBox(width: 12),
                    Expanded(child: durationInput),
                  ]);
          },
        ),
        const SizedBox(height: 19),
        if (!valid)
          Container(
            key: const Key('pace-validation'),
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF41262E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Ingresa una distancia entre 0.1 y 200 km y un '
              'tiempo entre 1 y 1440 minutos.',
              style: TextStyle(color: Color(0xFFFFC2C2)),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: const LinearGradient(
                colors: [Color(0xFF273A29), Color(0xFF252E39)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF455840)),
            ),
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 35,
              runSpacing: 15,
              children: [
                _Result(
                  label: 'TU RITMO PROMEDIO',
                  value: '$pace min/km',
                  resultKey: const Key('pace-result'),
                  icon: Icons.speed_rounded,
                  color: FitDateColors.lime,
                ),
                _Result(
                  label: 'VELOCIDAD PROMEDIO',
                  value: '$speed km/h',
                  resultKey: const Key('pace-speed'),
                  icon: Icons.trending_up_rounded,
                  color: FitDateColors.pearl,
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 17, color: FitDateColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Este cálculo ocurre en tu dispositivo. '
                'No se guarda ni se comparte información.',
                style: TextStyle(
                  color: FitDateColors.muted,
                  fontSize: 12, height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.resultKey,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Key resultKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: FitDateColors.muted,
                letterSpacing: .8,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          key: resultKey,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
            color: color,
          ),
        ),
      ],
    );
  }
}
