/// FITTED: deterministic and explainable compatibility simulation.
/// Production calculation is exclusively server-side; never trust client
/// weights or return raw private answers to other users.
library;

class MatchFactor {
  const MatchFactor(this.id,this.es,this.en,this.defaultWeight,
    this.descriptionEs,this.descriptionEn);
  final String id,es,en,descriptionEs,descriptionEn;
  final int defaultWeight;
}
abstract final class FittedMatchEngine {
  static const factors=<MatchFactor>[
    MatchFactor('intent','Intención de relación','Relationship intent',25,
      'Qué buscan y cuánto quieren compartir.',
      'Intentions and desired shared time.'),
    MatchFactor('lifestyle','Ritmo de vida','Life rhythm',20,
      'Días entre semana, fines de semana y viajes.',
      'Weekday, weekend and travel patterns.'),
    MatchFactor('rhythm','Compatibilidad de actividad','Activity compatibility',20,
      'Frecuencia, intensidad y rutina de entrenamiento.',
      'Training frequency, intensity and routines.'),
    MatchFactor('recovery','Descanso y recuperación','Sleep and recovery',15,
      'Hábitos de sueño y respeto por la recuperación.',
      'Sleep habits and recovery needs.'),
    MatchFactor('autonomy','Autonomía y tiempo juntos','Shared time and independence',10,
      'Espacio personal y actividades en pareja.',
      'Independence and shared activities.'),
    MatchFactor('sport','Deporte compartido','Shared sport',10,
      'Puede ayudar, pero no es indispensable.',
      'Helpful but never a prerequisite.'),
    MatchFactor('interests','Intereses compartidos','Shared interests',0,
      'Música, cultura, mascotas y otros intereses.',
      'Music, culture, pets and shared interests.'),
    MatchFactor('social','Ritmo social','Social rhythm',0,
      'Preferencias declaradas de convivencia cotidiana.',
      'Declared everyday social preferences.'),
    MatchFactor('competition','Relación con las competencias','Competition lifestyle',0,
      'Entrenamiento recreativo, retos y competencias.',
      'Recreation, challenges and event preparation.'),
  ];
  static Map<String,int> get defaults=>{
    for(final f in factors)if(f.defaultWeight>0)f.id:f.defaultWeight,
  };
  static bool validWeights(Map<String,int> weights)=>
    weights.keys.every((k)=>factors.any((f)=>f.id==k)) &&
    weights.values.where((v)=>v>0).length>=3 &&
    weights.values.every((v)=>v>=0&&v<=100) &&
    weights.values.fold<int>(0,(a,b)=>a+b)==100;

  /// Local simulator exactly mirrors supported server-side factor keys.
  static MatchBreakdown? evaluate({
    required Map<String,String> a,
    required Map<String,String> b,
    required Map<String,int> weights,
    Set<String> aInterests=const {},
    Set<String> bInterests=const {},
  }){
    if(!validWeights(weights))return null;
    final contributions=<String,double>{};
    final reasonCodes=<String,String>{};
    const allowed=<String,Set<String>>{
      'intent':{'long_term','open_to_serious','intentional','exploring'},
      'weekday':{'home','sometimes_out','often_out'},
      'travel':{'flexible','train_away','rest_and_disconnect'},
      'frequency':{'flexible','two_three','four_five','six_plus'},
      'training_mode':{'recreational','consistent','focused','competitive'},
      'sleep':{'early_bird','flexible','night_owl'},
      'together':{'balanced','more_together','independent'},
      'train_partner':{'often','sometimes','rarely','separately'},
      'alcohol':{'prefer_not','none','occasional','social','frequent'},
      'competitions':{'never','sometimes','regularly'},
      'sport':{'running','strength','cycling','hyrox','crossfit','boxing',
        'yoga','pilates','barre','swimming','hiking','climbing','racket',
        'walking','other'},
    };
    bool known(String key)=>allowed[key]!.contains(a[key]) &&
      allowed[key]!.contains(b[key]);
    double similarity(String key)=>a[key]==b[key]?1:
      (a[key]=='flexible'||b[key]=='flexible')?.8:.45;
    double? group(List<String> keys){
      final v=keys.where(known).toList();
      return v.isEmpty?null:
        v.map(similarity).reduce((x,y)=>x+y)/v.length;
    }
    double? factor(String key){
      switch(key){
        case 'intent':
          if(!known('intent'))return null;
          if(a['intent']==b['intent'])return 1;
          if({'long_term','open_to_serious','intentional'}.contains(a['intent'])&&
             {'long_term','open_to_serious','intentional'}.contains(b['intent'])){
            return .85;
          }
          return .25;
        case 'sport':
          if(!known('sport'))return null;
          return a['sport']==b['sport']?1:.75;
        case 'lifestyle':return group(['weekday','travel']);
        case 'rhythm':return group(['frequency','training_mode']);
        case 'recovery':return group(['sleep']);
        case 'autonomy':return group(['together','train_partner']);
        case 'social':return group(['weekday','alcohol']);
        case 'competition':return group(['competitions','training_mode']);
        case 'interests':
          if(aInterests.isEmpty||bInterests.isEmpty)return null;
          final combined=aInterests.union(bInterests);
          final shared=aInterests.intersection(bInterests);
          return .35+.65*shared.length/combined.length;
        default:return null;
      }
    }
    double earned=0,covered=0;
    for(final f in factors){
      final weight=weights[f.id]??0;
      if(weight<=0)continue;
      final v=factor(f.id);
      if(v==null)continue;
      covered+=weight;
      earned+=weight*v;
      contributions[f.id]=v*100;
      final code=f.id=='sport'&&a['sport']!=b['sport']
        ?'complementary_sports'
        :v>=.8?'aligned_${f.id}':'discuss_${f.id}';
      reasonCodes[f.id]=code;
      if(f.id=='interests'&&aInterests.intersection(bInterests).isNotEmpty){
        reasonCodes[f.id]='aligned_interests';
      }else if(v>=.8 && f.id=='recovery'&&a['sleep']=='early_bird'){
        reasonCodes[f.id]='shared_early_sleep';
      }else if(v>=.8&&f.id=='lifestyle'&&a['weekday']=='home'&&
        b['weekday']=='home'){
        reasonCodes[f.id]='shared_quiet_weekdays';
      }else if(v>=.8&&f.id=='autonomy'&&a['together']=='balanced'&&
        b['together']=='balanced'){
        reasonCodes[f.id]='shared_independence_balance';
      }
    }
    if(covered<70||!known('intent'))return null;
    return MatchBreakdown(
      percent:(earned/covered*100).round().clamp(0,100),
      coverage:covered.round(),factors:contributions,
      reasonCodes:reasonCodes,algorithmVersion:'fitted-compatibility-v2');
  }
}

class MatchBreakdown{
  const MatchBreakdown({required this.percent,required this.coverage,
    required this.factors,required this.reasonCodes,required this.algorithmVersion});
  final int percent,coverage;
  final Map<String,double> factors;
  final Map<String,String> reasonCodes;
  final String algorithmVersion;
}

String explainMatchReason(String code,{String language='es'}){
  final en=language=='en';
  return switch(code){
    'shared_early_sleep'=>en
      ?'Both prefer an early sleep schedule'
      :'Ambos prefieren descansar temprano',
    'shared_quiet_weekdays'=>en
      ?'Both usually keep weeknights quiet'
      :'Ambos prefieren noches tranquilas entre semana',
    'shared_independence_balance'=>en
      ?'Both value independence and shared time'
      :'Ambos valoran el equilibrio entre independencia y tiempo compartido',
    'shared_training_frequency'=>en
      ?'They train with a similar weekly frequency'
      :'Entrenan con una frecuencia semanal similar',
    'complementary_sports'=>en
      ?'Different sports, compatible active lifestyles'
      :'Practican deportes distintos, sin dejar de tener hábitos compatibles',
    'aligned_intent'=>en
      ?'Their relationship intentions align'
      :'Sus intenciones de relación son compatibles',
    'aligned_lifestyle'=>en
      ?'Their everyday lifestyles align'
      :'Sus ritmos cotidianos tienen puntos en común',
    'aligned_rhythm'=>en
      ?'Their training habits are compatible'
      :'Sus hábitos de entrenamiento son compatibles',
    'aligned_recovery'=>en
      ?'Their rest routines are compatible'
      :'Sus rutinas de descanso son compatibles',
    'aligned_autonomy'=>en
      ?'They seek a similar balance of personal and shared time'
      :'Buscan un equilibrio parecido entre tiempo propio y compartido',
    'aligned_interests'=>en
      ?'They share interests beyond sports'
      :'Comparten intereses fuera del deporte',
    'aligned_social'=>en
      ?'Their social habits show compatible patterns'
      :'Sus hábitos sociales muestran ritmos compatibles',
    'aligned_competition'=>en
      ?'They relate to training goals in a similar way'
      :'Se relacionan de forma similar con los retos deportivos',
    _=>en?'A difference to discuss together'
      :'Una diferencia que vale la pena conversar',
  };
}
