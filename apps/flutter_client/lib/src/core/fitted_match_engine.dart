/// Fitted · transparent compatibility prototype. No AI generates the numeric
/// score. AI may later rephrase ONLY these verified evidence codes.
library;

class MatchFactor {
  const MatchFactor(this.id, this.es, this.en, this.defaultWeight);
  final String id, es, en;
  final int defaultWeight;
}

abstract final class FittedMatchEngine {
  static const factors = <MatchFactor>[
    MatchFactor('intent', 'Intención de relación', 'Relationship intention', 25),
    MatchFactor('lifestyle', 'Estilo de vida', 'Lifestyle alignment', 20),
    MatchFactor('rhythm', 'Ritmo de entrenamiento', 'Training rhythm', 20),
    MatchFactor('recovery', 'Descanso y recovery', 'Rest and recovery', 15),
    MatchFactor('autonomy', 'Autonomía y tiempo juntos', 'Autonomy and togetherness', 10),
    MatchFactor('sport', 'Disciplinas complementarias', 'Complementary sports', 10),
  ];

  static Map<String,int> get defaults => {
    for (final f in factors) f.id:f.defaultWeight,
  };

  static bool validWeights(Map<String,int> weights) =>
    weights.length == factors.length &&
    factors.every((f) => (weights[f.id] ?? -1) >= 0 &&
      (weights[f.id] ?? -1) <= 100) &&
    weights.values.fold<int>(0,(a,b)=>a+b)==100;

  /// More than same-sport matching: different disciplines can fit when
  /// relationship intent, recovery and life priorities agree.
  static MatchBreakdown? evaluate({
    required Map<String,String> a,
    required Map<String,String> b,
    required Map<String,int> weights,
  }) {
    if(!validWeights(weights)) return null;
    final contributions=<String,double>{};
    final reasons=<String,String>{};
    const allowed = <String,Set<String>>{
      'intent':{'long_term','open_to_serious','intentional','exploring'},
      'weekday':{'home','sometimes_out','often_out'},
      'travel':{'flexible','train_away','rest_and_disconnect'},
      'frequency':{'flexible','two_three','four_five','six_plus'},
      'training_mode':{'recreational','consistent','focused','competitive'},
      'sleep':{'early_bird','flexible','night_owl'},
      'together':{'balanced','more_together','independent'},
      'train_partner':{'often','sometimes','rarely','separately'},
      'sport':{'running','strength','cycling','hyrox','crossfit','boxing',
        'yoga','pilates','barre','swimming','hiking','climbing',
        'racket','walking','other'},
    };
    bool known(String key) => allowed[key]!.contains(a[key]) &&
      allowed[key]!.contains(b[key]);
    double similarity(String key) => a[key]==b[key] ? 1 :
      (a[key]=='flexible'||b[key]=='flexible') ? .8 : .45;
    double? group(List<String> keys) {
      final available=keys.where(known).toList();
      if(available.isEmpty)return null;
      return available.map(similarity).reduce((x,y)=>x+y)/available.length;
    }
    double? factor(String key) {
      if(key=='intent') {
        if(!known('intent'))return null;
        if(a['intent']==b['intent'])return 1;
        if({'long_term','open_to_serious','intentional'}.contains(a['intent']) &&
           {'long_term','open_to_serious','intentional'}.contains(b['intent']))return .85;
        return .25;
      }
      if(key=='lifestyle')return group(['weekday','travel']);
      if(key=='rhythm')return group(['frequency','training_mode']);
      if(key=='recovery')return group(['sleep']);
      if(key=='autonomy')return group(['together','train_partner']);
      if(key=='sport') {
        if(!known('sport'))return null;
        if(a['sport']==b['sport'])return 1;
        // Cross-training is complementary, not a rejection or a penalty
        // equivalent to incompatible intentions.
        return .75;
      }
      return null;
    }
    double earned=0,availableWeight=0;
    for(final f in factors){
      final value=factor(f.id);
      if(value==null)continue;
      final w=weights[f.id]!;
      availableWeight+=w;
      earned+=w*value;
      contributions[f.id]=value*100;
      if(f.id=='sport'&&a['sport']!=b['sport']){
        reasons[f.id]='complementary_sports';
      } else if(value>=.8){
        reasons[f.id]='aligned_${f.id}';
      } else {
        reasons[f.id]='discuss_${f.id}';
      }
    }
    // Do not present a certainty-looking score from sparse evidence.
    if(availableWeight<70 || !known('intent'))return null;
    return MatchBreakdown(
      percent:(earned/availableWeight*100).round().clamp(0,100),
      coverage:(availableWeight).round(),
      factors:contributions,
      reasonCodes:reasons,
      algorithmVersion:'fitted-compatibility-v1',
    );
  }
}

class MatchBreakdown {
  const MatchBreakdown({
    required this.percent,
    required this.coverage,
    required this.factors,
    required this.reasonCodes,
    required this.algorithmVersion,
  });
  final int percent;
  final int coverage;
  final Map<String,double> factors;
  final Map<String,String> reasonCodes;
  final String algorithmVersion;
}

String explainMatchReason(String code,{String language='es'}) {
  final en=language=='en';
  return switch(code) {
    'complementary_sports' => en
      ? 'Different activities, compatible active lifestyles'
      : 'Practican disciplinas diferentes, pero comparten una vida activa',
    'aligned_intent' => en ? 'Similar relationship intentions'
      : 'Buscan un tipo de relación compatible',
    'aligned_lifestyle' => en ? 'Their everyday lifestyles align'
      : 'Comparten prioridades de vida cotidiana',
    'aligned_rhythm' => en ? 'Their training rhythms fit'
      : 'Sus ritmos de entrenamiento son compatibles',
    'aligned_recovery' => en ? 'Compatible rest and recovery habits'
      : 'Sus hábitos de descanso y recuperación son compatibles',
    'aligned_autonomy' => en ? 'Similar balance of independence and togetherness'
      : 'Comparten un equilibrio entre autonomía y tiempo juntos',
    _ => en ? 'A difference worth discussing'
      : 'Una diferencia que pueden conversar',
  };
}
