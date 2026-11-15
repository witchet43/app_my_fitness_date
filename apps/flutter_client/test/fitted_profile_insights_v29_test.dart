import 'package:flutter_test/flutter_test.dart';
import 'package:my_fitness_date/src/core/fitted_profile_insights_v29.dart';

void main(){
  test('new profile shows zero and no invented rhythm',(){
    expect(FittedProfileInsights.pillarProgress(null),[0,0,0]);
    expect(FittedProfileInsights.overallProgress(null),0);
    expect(FittedProfileInsights.classify(null),isNull);
  });

  test('profile completion tracks only saved core behavior',(){
    final rhythm=<String,dynamic>{'answers':{
      'sport':'running','frequency':'four_five','window':'early_morning',
      'training_mode':'focused',
      'weekday':'home','sleep':'early_bird','travel':'flexible',
      'intent':'long_term','together':'balanced','train_partner':'sometimes',
    }};
    expect(FittedProfileInsights.pillarProgress(rhythm),[100,100,100]);
    expect(FittedProfileInsights.overallProgress(rhythm),100);
    expect(FittedProfileInsights.classify(rhythm)?.primary,'training_focused');
  });

  test('optional answers are not required and cannot inflate completion',(){
    final sensitive=<String,dynamic>{'answers':{
      'alcohol':'none','food':'vegetarian',
    },'weekends':['brunch'],'interests':['music'],
      'weeknight':'private','support':'support'};
    expect(FittedProfileInsights.overallProgress(sensitive),0);
    expect(FittedProfileInsights.classify(sensitive),isNull);
  });

  test('classification follows actions rather than selected starting label',(){
    final a=<String,dynamic>{'answers':{
      'frequency':'six_plus',
      'training_mode':'competitive',
      'competitions':'regularly',
    }};
    final result=FittedProfileInsights.classify(a)!;
    expect(result.primary,'competitive');
    expect(result.affinities['competitive'],100);
    expect(result.signals,contains('training_mode'));
  });

  test('movement regularity is not mistakenly called competition',(){
    final a=<String,dynamic>{'answers':{
      'frequency':'four_five',
      'training_mode':'consistent',
      'competitions':'never',
    }};
    expect(FittedProfileInsights.classify(a)?.primary,'consistent');
  });

  test('evidence must include multiple user-entered behavioral answers',(){
    final a=<String,dynamic>{'answers':{
      'frequency':'two_three','sport':'running',
    }};
    expect(FittedProfileInsights.classify(a),isNull);
  });
}
