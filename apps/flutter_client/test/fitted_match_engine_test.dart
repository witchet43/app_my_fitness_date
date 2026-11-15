import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/fitted_match_engine.dart';

void main(){
  const runner=<String,String>{
    'sport':'running','intent':'long_term','weekday':'home',
    'travel':'flexible','frequency':'four_five',
    'training_mode':'consistent','sleep':'early_bird',
    'together':'balanced','train_partner':'sometimes',
  };
  const gym=<String,String>{
    'sport':'strength','intent':'open_to_serious','weekday':'home',
    'travel':'train_away','frequency':'four_five',
    'training_mode':'focused','sleep':'early_bird',
    'together':'balanced','train_partner':'sometimes',
  };
  test('weights must sum to 100 and have exactly six valid factors',(){
    expect(FittedMatchEngine.validWeights(FittedMatchEngine.defaults),isTrue);
    expect(FittedMatchEngine.validWeights({
      ...FittedMatchEngine.defaults,'intent':10}),isFalse);
    expect(FittedMatchEngine.validWeights({
      ...FittedMatchEngine.defaults,'secret':0}),isFalse);
  });
  test('running and gym can be strongly compatible',(){
    final r=FittedMatchEngine.evaluate(
      a:runner,b:gym,weights:FittedMatchEngine.defaults)!;
    expect(r.percent,greaterThanOrEqualTo(75));
    expect(r.reasonCodes['sport'],'complementary_sports');
    expect(r.coverage,100);
  });
  test('missing or unverifiable answers never produce a false precise score',(){
    expect(FittedMatchEngine.evaluate(
      a:{'sport':'running'},b:{'sport':'strength'},
      weights:FittedMatchEngine.defaults),isNull);
    expect(FittedMatchEngine.evaluate(
      a:runner,b:{...gym,'intent':'unknown'},
      weights:FittedMatchEngine.defaults),isNull);
  });
  test('a matching sport does not outweigh incompatible intentions',(){
    final differing=<String,String>{
      ...gym,'sport':'running','intent':'exploring',
      'sleep':'night_owl','weekday':'often_out',
      'together':'independent','train_partner':'separately',
      'frequency':'six_plus',
    };
    final a=FittedMatchEngine.evaluate(
      a:runner,b:gym,weights:FittedMatchEngine.defaults)!;
    final b=FittedMatchEngine.evaluate(
      a:runner,b:differing,weights:FittedMatchEngine.defaults)!;
    expect(a.percent,greaterThan(b.percent));
  });
  test('reason text available in Spanish and English',(){
    expect(explainMatchReason('complementary_sports'),contains('disciplinas'));
    expect(explainMatchReason('complementary_sports',language:'en'),contains('Different'));
  });
}
