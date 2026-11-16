/// Small, pure B5 model. Never contains date of birth, gym identifier,
/// exact workout location, training slot, contact info or another member ID.
const datingSportOptionsB5 = <String,String>{
  'running':'Running',
  'cycling':'Ciclismo',
  'hiking':'Senderismo',
  'strength':'Fuerza',
  'yoga':'Yoga',
  'hyrox':'HYROX',
  'walking':'Caminata',
  'swimming':'Natación',
  'other':'Otros deportes',
};
const datingIntentOptionsB5 = <String,String>{
  'serious':'Relación seria',
  'companionship':'Compañía y actividades',
  'exploring':'Conocer con calma',
};
const datingFrequencyOptionsB5 = <String,String>{
  'starting':'Estoy empezando',
  'weekly':'Algunas veces por semana',
  'frequent':'Entreno con frecuencia',
  'flexible':'Flexible',
};
const datingPrivacyOptionsB5 = <String,String>{
  'other_gyms':'Únicamente personas de otros gimnasios',
  'same_gym_other_time':'Mismo gimnasio únicamente con horario compatible',
};

String? validateDatingChoicesB5({
  required String intent,
  required String frequency,
  required String privacyMode,
  required Set<String> sports,
  required bool requested,
  required bool consent,
}) {
  if (!datingIntentOptionsB5.containsKey(intent) ||
      !datingFrequencyOptionsB5.containsKey(frequency) ||
      !datingPrivacyOptionsB5.containsKey(privacyMode) ||
      sports.length > 8 ||
      sports.any((sport)=>!datingSportOptionsB5.containsKey(sport))) {
    return 'Revisa las preferencias seleccionadas.';
  }
  if (requested && !consent) {
    return 'Antes de solicitar participación debes dar tu consentimiento.';
  }
  return null;
}

Map<String,dynamic> datingDraftB5({
  required String intent,
  required String frequency,
  required String privacyMode,
  required Set<String> sports,
  required bool requested,
}) => {
  'intent':intent,
  'frequency':frequency,
  'mode':privacyMode,
  'sports':sports.toList()..sort(),
  'requested':requested,
};
