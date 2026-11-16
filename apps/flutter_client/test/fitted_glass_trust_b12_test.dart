import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/dating_repository_b11.dart';
import 'package:my_fitness_date/src/features/fitted_pulse_real_b12.dart';
import 'package:my_fitness_date/src/widgets/fitted_rhythm_hero.dart';
import 'package:my_fitness_date/src/widgets/fitted_glass_atmosphere.dart';
import 'package:my_fitness_date/src/theme/fitness_date_theme.dart';

class _PulseFake extends Fake implements DatingRepositoryB11 {
  String? lastDimension,lastObservation;
  bool consented = true;
  @override
  Future<Map<String,dynamic>> pulseRealStatusB12(String matchId) async => {
    'available':true,'both_confirmed':true,
    'my_confirmation':true,
    'my_consent':consented,
    'both_consented':consented,
    'my_observations':0,'public_visible':false,
  };
  @override
  Future<String> submitPulseRealB12(
      String matchId,String dimension,String observation) async {
    lastDimension=dimension; lastObservation=observation;
    return 'pending_moderation';
  }
  @override
  Future<String> setPulseRealConsentB12(bool accepted) async {
    consented=accepted;
    return accepted?'accepted':'withdrawn';
  }
  @override
  Future<String> confirmMeetupB12(String matchId) async=>'both_confirmed';
}

void main(){
  testWidgets('glass, curved lines and content remain semantic on narrow screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375,780));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
        home:const Scaffold(body:SingleChildScrollView(child:
          FittedRhythmHero(
            titleEs:'Lo que te mueve, te conecta.',
            titleEn:'What moves you, connects you.',
            subtitleEs:'Afinidad de estilo de vida.',
            subtitleEn:'Lifestyle compatibility.',
          ),
        ))));
      expect(find.byType(FittedRhythmLines),findsOneWidget);
      expect(find.byType(FittedGlassPanel),findsOneWidget);
      expect(find.text('Cómo me muevo'),findsOneWidget);
      expect(find.text('Cómo vivo'),findsOneWidget);
      expect(find.text('Cómo me relaciono'),findsOneWidget);
      expect(tester.takeException(),isNull);
    });

  testWidgets('post-date feedback stays private and records a subjective signal',
    (tester) async{
      await tester.binding.setSurfaceSize(const Size(800,1100));
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      final api=_PulseFake();
      await tester.pumpWidget(MaterialApp(theme:FitDateTheme.dark(),
        home:Scaffold(body:SingleChildScrollView(
          child:FittedPulseRealPanel(api:api,
            matchId:'88888888-8888-4888-8888-888888888888')))));
      await tester.pumpAndSettle();
      expect(find.text('PULSO REAL'),findsOneWidget);
      expect(find.textContaining('Sin acusaciones automáticas'),findsOneWidget);
      expect(find.byKey(const Key('pulse-real-submit')),findsOneWidget);
      await tester.tap(find.byKey(const Key('pulse-real-signal-not_aligned')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('pulse-real-submit')));
      await tester.tap(find.byKey(const Key('pulse-real-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('¿Enviar tu observación privada?'),findsOneWidget);
      await tester.tap(find.text('Enviar').last);
      await tester.pumpAndSettle();
      expect(api.lastDimension,'move');
      expect(api.lastObservation,'not_aligned');
      expect(find.textContaining('pendiente de moderación'),findsWidgets);
      expect(tester.takeException(),isNull);
    });
}
