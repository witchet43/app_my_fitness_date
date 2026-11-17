/// Owner-scoped private Fit-IA conversation API.
abstract class FitIaRepository {
  Future<Map<String,dynamic>> fitIaState(String pillar);
  Future<Map<String,dynamic>> fitIaAnswer(
    String pillar,String questionId,String choiceKey,{String locale='es'});
  Future<Map<String,dynamic>> fitIaOverview();
  Future<Map<String,dynamic>> fitIaChatState(String pillar,{String locale='es'});
  Future<Map<String,dynamic>> fitIaChatSend(
      String pillar,String text,String clientId,{String locale='es'});
  Future<Map<String,dynamic>> fitIaChatRetry(String pillar,{String locale='es'});
  /// The conversation stays on the server even beyond the most recent 120 messages.
  Future<Map<String,dynamic>> fitIaChatOlder(String pillar,int before)async=>
      {'messages':<Map<String,dynamic>>[],'has_more':false};
  Future<Map<String,dynamic>> fitIaForm(String pillar);
  Future<Map<String,dynamic>> fitIaSubmitForm(
    String pillar,List<Map<String,String>> answers);
  Future<Map<String,dynamic>> fitIaInsights(String pillar);
  Future<Map<String,dynamic>> fitIaConsent(bool enabled);
  Future<Map<String,dynamic>> fitIaGenerateSummary();
  Future<void> fitIaDeleteMyData();
}

/// Coverage is about how well a person's answers cover the available topics,
/// NOT a person's value, compatibility or psychological quality.
abstract final class FitIaDepth {
  static const keys=['move','live','relate'];
  static const labelsEs=['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
  static const labelsEn=['How I Move','How I Live','How I Relate'];
  static const levels=['weak','medium','strong'];
  static String level(Map<String,dynamic>? overview,String pillar) {
    final raw=overview?[pillar];
    if(raw is Map){
      final value=raw['level'];
      if(levels.contains(value))return value.toString();
    }
    return 'weak';
  }
  static String label(String level,bool english){
    return switch(level){
      'strong'=>english?'Strong':'Fuerte',
      'medium'=>english?'Medium':'Medio',
      _=>english?'Starting':'Débil',
    };
  }
  static String message(String level,bool english){
    return switch(level){
      'strong'=>english?'You have shared diverse details. You can still keep talking.':
        'Ya compartiste detalles variados. Puedes seguir platicando.',
      'medium'=>english?'We know several sides of your life. Let’s explore others.':
        'Ya conocemos varias facetas tuyas. Sigamos descubriendo otras.',
      _=>english?'We are just getting to know you; there is no rush.':
        'Apenas empezamos a conocerte; no hay prisa.',
    };
  }
  static int answered(Map<String,dynamic>? overview,String pillar){
    final x=overview?[pillar];
    return x is Map && x['answered'] is num
      ?(x['answered'] as num).toInt():0;
  }
}
