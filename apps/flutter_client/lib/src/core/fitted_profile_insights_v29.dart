/// Private, deterministic profile insights. Segment affinity is not a match
/// percentage, a clinical label or a ranking of people.
/// Never consume private venue, Gym Shield, address or precise schedule data.
abstract final class FittedProfileInsights {
  static const segments=[
    'move_for_fun','consistent','training_focused','competitive',
  ];
  static const pillars=[
    ['sport','frequency','window','training_mode','training_with','competitions'],
    ['weekday','sleep','travel','weekend','interests'],
    ['intent','together','train_partner','active_importance','weeknight','support'],
  ];
  static const weights=[35,35,30];

  static Map<String,dynamic> answers(Map<String,dynamic>? rhythm){
    final raw=rhythm?['answers'];
    return raw is Map ? Map<String,dynamic>.from(raw) : <String,dynamic>{};
  }

  static List<int> pillarProgress(Map<String,dynamic>? rhythm) {
    final a=answers(rhythm);
    final values=<String,bool>{
      for(final key in a.keys)
        if(a[key] is String && (a[key] as String).trim().isNotEmpty)
          key:true,
    };
    final weekend=rhythm?['weekends'];
    final interests=rhythm?['interests'];
    final weeknight=rhythm?['weeknight'];
    final support=rhythm?['support'];
    values['weekend']=weekend is List && weekend.isNotEmpty;
    values['interests']=interests is List && interests.isNotEmpty;
    values['weeknight']=weeknight is String && weeknight.trim().isNotEmpty;
    values['support']=support is String && support.trim().isNotEmpty;
    return [
      for(final group in pillars)
        ((group.where((k)=>values[k]==true).length/group.length)*100).round(),
    ];
  }

  static int overallProgress(Map<String,dynamic>? rhythm){
    final v=pillarProgress(rhythm);
    return ((v[0]*weights[0]+v[1]*weights[1]+v[2]*weights[2])/100).round();
  }

  /// Returns zero classification until at least two explicit behavioral
  /// signals including training frequency or mode are recorded.
  static FittedSegmentResult? classify(Map<String,dynamic>? rhythm){
    final a=answers(rhythm);
    final frequency=a['frequency'] as String?;
    final mode=a['training_mode'] as String?;
    final competition=a['competitions'] as String?;
    final hasEnough=(frequency!=null && mode!=null)||
      (mode!=null && competition!=null)||
      (frequency!=null && competition!=null);
    if(!hasEnough)return null;
    final raw=<String,double>{
      for(final s in segments) s:0,
    };
    void evidence(String key,String? value,int strength,
        Map<String,List<String>> associations){
      if(value==null)return;
      for(final pair in associations.entries){
        if(pair.value.contains(value)){
          raw[pair.key]=raw[pair.key]!+strength;
        }
      }
    }
    evidence('frequency',frequency,3,{
      'move_for_fun':['flexible','two_three'],
      'consistent':['two_three','four_five'],
      'training_focused':['four_five','six_plus'],
      'competitive':['four_five','six_plus'],
    });
    evidence('training_mode',mode,5,{
      'move_for_fun':['recreational'],
      'consistent':['consistent'],
      'training_focused':['focused'],
      'competitive':['competitive'],
    });
    evidence('competitions',competition,4,{
      'move_for_fun':['never'],
      'consistent':['never','sometimes'],
      'training_focused':['sometimes','regularly'],
      'competitive':['regularly'],
    });
    final challenge=rhythm?['challenge'];
    if(challenge is String && challenge.trim().isNotEmpty){
      raw['training_focused']=raw['training_focused']!+1;
    }
    final maxScore=raw.values.reduce((x,y)=>x>y?x:y);
    if(maxScore<=0)return null;
    // An affinity chart, not calibrated probabilities; these are bounded
    // soft scores and the displayed values deliberately are not percentages.
    final normalized=<String,int>{
      for(final key in segments)
        key:(raw[key]!/maxScore*100).round().clamp(0,100),
    };
    var winner=segments.first;
    for(final key in segments){
      if(raw[key]!>raw[winner]!)winner=key;
    }
    final signals=<String>[];
    if(frequency!=null)signals.add('frequency');
    if(mode!=null)signals.add('training_mode');
    if(competition!=null)signals.add('competitions');
    if(challenge is String && challenge.trim().isNotEmpty){
      signals.add('challenge');
    }
    return FittedSegmentResult(
      primary:winner,affinities:normalized,signals:signals,
      version:'behavioral-rhythm-v1',
    );
  }
}

class FittedSegmentResult{
  const FittedSegmentResult({
    required this.primary,required this.affinities,
    required this.signals,required this.version,
  });
  final String primary,version;
  final Map<String,int> affinities;
  final List<String> signals;
}
