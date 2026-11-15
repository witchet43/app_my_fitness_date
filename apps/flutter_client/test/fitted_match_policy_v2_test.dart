import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/fitted_match_engine.dart';

void main(){
  const runner=<String,String>{
    'sport':'running','intent':'long_term','weekday':'home',
    'travel':'flexible','frequency':'four_five','training_mode':'consistent',
    'sleep':'early_bird','together':'balanced','train_partner':'sometimes',
    'competitions':'sometimes','alcohol':'occasional',
  };
  const gym=<String,String>{
    'sport':'strength','intent':'open_to_serious','weekday':'home',
    'travel':'train_away','frequency':'four_five','training_mode':'focused',
    'sleep':'early_bird','together':'balanced','train_partner':'sometimes',
    'competitions':'sometimes','alcohol':'occasional',
  };
  test('policy supports adding and removing only known factors',(){
    expect(FittedMatchEngine.validWeights({
      'intent':40,'lifestyle':35,'interests':25,
    }),isTrue);
    expect(FittedMatchEngine.validWeights({
      'intent':50,'lifestyle':50,
    }),isFalse);
    expect(FittedMatchEngine.validWeights({
      'intent':35,'lifestyle':35,'unknown':30,
    }),isFalse);
  });
  test('different sports remain compatible when life rhythm aligns',(){
    final value=FittedMatchEngine.evaluate(
      a:runner,b:gym,weights:FittedMatchEngine.defaults)!;
    expect(value.percent,greaterThanOrEqualTo(75));
    expect(value.reasonCodes['sport'],'complementary_sports');
    expect(value.reasonCodes['recovery'],'shared_early_sleep');
    expect(value.coverage,100);
  });
  test('interest factor uses explicit shared-interest evidence',(){
    final weights={'intent':35,'lifestyle':35,'interests':30};
    final score=FittedMatchEngine.evaluate(
      a:runner,b:gym,weights:weights,
      aInterests:{'music','culture'},
      bInterests:{'music','books'})!;
    expect(score.coverage,100);
    expect(score.reasonCodes['interests'],'aligned_interests');
  });
  test('score fails closed for missing evidence',(){
    final weights={'intent':35,'lifestyle':35,'interests':30};
    expect(FittedMatchEngine.evaluate(
      a:runner,b:gym,weights:weights),isNull);
  });
  test('concrete explanations exist in ES and EN',(){
    expect(explainMatchReason('shared_early_sleep'),contains('temprano'));
    expect(explainMatchReason('shared_quiet_weekdays',language:'en'),
      contains('weeknights'));
  });
}
