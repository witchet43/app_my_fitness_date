/// B10 FITTED concept study. PRIVATE IN-MEMORY PREVIEW ONLY.
/////// No storage, network, identity, gym, precise schedule, personal location,
/// real candidates, match/chat, opaque score or monetized safety operation.
/// The PDF is exploratory; this model is not a production matching service.
const rhythmOptionsB10 = <String,List<String>>{
  'sport':['running','strength','cycling','hyrox','crossfit','boxing','yoga',
    'pilates','barre','swimming','hiking','climbing','racket','walking','other'],
  'frequency':['flexible','two_three','four_five','six_plus'],
  'window':['early_morning','morning','midday','evening','flexible'],
  'training_mode':['recreational','consistent','focused','competitive'],
  'training_with':['solo','friends','partner','mixed'],
  'competitions':['never','sometimes','regularly'],
  'weekday':['home','sometimes_out','often_out'],
  'weekend':['early_training','brunch','nightlife','outdoors','recovery','family'],
  'sleep':['early_bird','flexible','night_owl'],
  'alcohol':['prefer_not','none','occasional','social','frequent'],
  'food':['prefer_not','unrestricted','vegetarian','vegan','other'],
  'travel':['flexible','train_away','rest_and_disconnect'],
  'interests':['music','art','writing','gaming','cooking','pets','concerts',
    'outdoors','books','culture'],
  'intent':['long_term','open_to_serious','intentional','exploring'],
  'together':['balanced','more_together','independent'],
  'train_partner':['often','sometimes','rarely','separately'],
  'active_importance':['not_required','nice_to_have','important'],
  'privacy':['exclude_gym','same_gym_different_time'],
};

/// Local defaults are settings, not claims about the person using the app.
Map<String,String> emptyRhythmB10() => {
  'sport':'running',
  'frequency':'flexible',
  'window':'flexible',
  'training_mode':'recreational',
  'training_with':'mixed',
  'competitions':'never',
  'weekday':'home',
  'sleep':'flexible',
  'alcohol':'prefer_not',
  'food':'prefer_not',
  'travel':'flexible',
  'intent':'exploring',
  'together':'balanced',
  'train_partner':'sometimes',
  'active_importance':'nice_to_have',
  'privacy':'exclude_gym',
};

String? validateRhythmB10(Map<String,String> answers, {
  required Set<String> additionalSports,
  required Set<String> weekends,
  required Set<String> interests,
  String challenge = '',
  String support = '',
  String weeknight = '',
}) {
  if (answers.keys.any((key)=>!rhythmOptionsB10.containsKey(key)) ||
      answers.entries.any((entry)=>
          !rhythmOptionsB10[entry.key]!.contains(entry.value)) ||
      answers.keys.any((key)=>key == 'gym_id' || key == 'exact_address')) {
    return 'unknown_field';
  }
  if (additionalSports.length>7 ||
      additionalSports.any((x)=>!rhythmOptionsB10['sport']!.contains(x)) ||
      weekends.any((x)=>!rhythmOptionsB10['weekend']!.contains(x)) ||
      interests.any((x)=>!rhythmOptionsB10['interests']!.contains(x)) ||
      challenge.length>100 || support.length>120 || weeknight.length>120) {
    return 'invalid_preference';
  }
  return null;
}

class RhythmReasonB10 {
  const RhythmReasonB10(this.layer,this.reasonEs,this.reasonEn,
      {required this.importance});
  final String layer;
  final String reasonEs;
  final String reasonEn;
  final String importance; // high / medium / low, never a personal score
  String message({required bool english}) => english ? reasonEn : reasonEs;
}

/// Only hypothetical, literal public preference codes. No private gym times
/// or third-party identity are accepted by this function.
List<RhythmReasonB10> explainRhythmB10(
    Map<String,String> self, Map<String,String> example) {
  final reasons = <RhythmReasonB10>[];
  if (self['sleep'] == example['sleep']) {
    reasons.add(const RhythmReasonB10('life',
      'Sus ritmos de descanso declarados coinciden.',
      'Their stated sleep rhythms align.',
      importance:'high'));
  } else {
    reasons.add(const RhythmReasonB10('life',
      'Sus horarios de descanso difieren: vale la pena conversarlo.',
      'Their sleep rhythms differ: worth discussing.',
      importance:'high'));
  }
  if (self['weekday'] == example['weekday']) {
    reasons.add(const RhythmReasonB10('life',
      'Prefieren un ritmo entre semana similar.',
      'They prefer a similar weekday rhythm.',
      importance:'high'));
  } else {
    reasons.add(const RhythmReasonB10('life',
      'Disfrutan semanas distintas; conviene hablar de planes.',
      'Their weekday styles differ; discuss plans.',
      importance:'high'));
  }
  if (self['intent'] == example['intent']) {
    reasons.add(const RhythmReasonB10('relationship',
      'Comparten expectativas declaradas sobre la relación.',
      'They share stated relationship expectations.',
      importance:'high'));
  } else {
    reasons.add(const RhythmReasonB10('relationship',
      'Buscan cosas distintas; aclaren las expectativas.',
      'Their dating intentions differ; clarify expectations.',
      importance:'high'));
  }
  if (self['together'] == example['together']) {
    reasons.add(const RhythmReasonB10('relationship',
      'Su preferencia entre compartir e independencia coincide.',
      'Their preference for togetherness and autonomy aligns.',
      importance:'high'));
  } else {
    reasons.add(const RhythmReasonB10('relationship',
      'Conviene acordar cuánto tiempo desean compartir.',
      'Discuss how much shared time each person prefers.',
      importance:'high'));
  }
  if (self['frequency'] == example['frequency']) {
    reasons.add(const RhythmReasonB10('activity',
      'Su frecuencia deportiva declarada es similar.',
      'Their stated training frequency is similar.',
      importance:'medium'));
  } else {
    reasons.add(const RhythmReasonB10('activity',
      'Pueden respetar intensidades deportivas diferentes.',
      'They can respect different activity frequencies.',
      importance:'medium'));
  }
  if (self['sport'] == example['sport']) {
    reasons.add(const RhythmReasonB10('sport',
      'Disfrutan una actividad común, sin que eso determine el match.',
      'They enjoy a sport in common; that alone does not define a match.',
      importance:'low'));
  } else {
    reasons.add(const RhythmReasonB10('sport',
      'Practican deportes distintos: eso no impide encajar.',
      'They train differently: that does not prevent compatibility.',
      importance:'low'));
  }
  return List<RhythmReasonB10>.unmodifiable(reasons);
}

/// A purely fictitious lifestyle scenario. Never label as a real user.
Map<String,String> hypotheticalRhythmB10(String scenario) {
  if (scenario == 'same_sport_other_rhythm') {
    return {
      'sport':'running','frequency':'six_plus','sleep':'night_owl',
      'weekday':'often_out','intent':'long_term','together':'more_together',
    };
  }
  return {
    'sport':'yoga','frequency':'flexible','sleep':'flexible',
    'weekday':'home','intent':'exploring','together':'balanced',
  };
}

/// Activity ideas ONLY for hypothetical demonstrations. In a real product
/// these may be offered only after a verified mutual match; no location, gym,
/// route, booking, contact or personal schedules are ever included.
List<String> hypotheticalActiveDatesB10(
    Map<String,String> self, Map<String,String> example) {
  final sports = {self['sport'],example['sport']};
  if (sports.contains('yoga') || sports.contains('pilates')) {
    return const ['yoga_brunch','museum_walk'];
  }
  if (sports.contains('hiking') || sports.contains('walking')) {
    return const ['walk_coffee','outdoor_market'];
  }
  return const ['walk_coffee','museum_walk'];
}
