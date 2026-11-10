import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Funcionalidad pública y anónima: cálculo local, sin APIs ni persistencia.
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
        const Text('Calculadora de ritmo de carrera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Planea tu entrenamiento en segundos, sin crear cuenta. '
            'Tus números se calculan en este dispositivo y no se envían '
            'a un servidor.'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              key: const Key('pace-distance'),
              controller: _distance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Distancia (km)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const Key('pace-duration'),
              controller: _duration,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Tiempo (minutos)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        if (!valid)
          const Text('Ingresa una distancia entre 0.1 y 200 km y un '
              'tiempo entre 1 y 1440 minutos.',
              key: Key('pace-validation'))
        else
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ritmo promedio'),
                  Text('$pace min/km',
                      key: const Key('pace-result'),
                      style: const TextStyle(
                          fontSize: 27, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Velocidad promedio'),
                  Text('$speed km/h',
                      key: const Key('pace-speed'),
                      style: const TextStyle(
                          fontSize: 27, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        const Text(
          'Los eventos y encuentros grupales estarán disponibles '
          'cuando se completen los controles de identidad y privacidad.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
