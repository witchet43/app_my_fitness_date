import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/fitted_profile_insights_v29.dart';
import '../theme/fitness_date_theme.dart';

/// Pure presentation: caller supplies saved, consented rhythm; no network.
/// A voluntary starting preference is NOT copied into behavioral answers.
class FittedProfileProgressV29 extends StatelessWidget {
  const FittedProfileProgressV29({
    super.key,required this.rhythm,
    required this.startingPreference,required this.onChooseStarting,
    required this.onConfigure,
    this.showCompletion=true,this.showRhythm=true,
  });
  final Map<String,dynamic>? rhythm;
  final String? startingPreference;
  final Future<void> Function(String?) onChooseStarting;
  final VoidCallback onConfigure;
  final bool showCompletion,showRhythm;

  static const labelEs={
    'move_for_fun':'Me muevo por disfrutar',
    'consistent':'Movimiento constante',
    'training_focused':'Entreno con propósito',
    'competitive':'Entreno para competir',
  };
  static const labelEn={
    'move_for_fun':'Move for Fun',
    'consistent':'Consistent',
    'training_focused':'Training-Focused',
    'competitive':'Competitive',
  };
  static const reasonsEs={
    'move_for_fun':'Tu actividad refleja una relación flexible y recreativa con el movimiento.',
    'consistent':'Tus respuestas muestran una rutina frecuente y sostenida.',
    'training_focused':'Tus respuestas reflejan entrenamiento estructurado u objetivos de progresión.',
    'competitive':'Tus respuestas reflejan preparación y participación en competencias.',
  };
  static const reasonsEn={
    'move_for_fun':'Your answers describe flexible, recreational movement.',
    'consistent':'Your answers indicate a regular, consistent training routine.',
    'training_focused':'Your answers suggest structured training and progression goals.',
    'competitive':'Your answers reflect competition and event preparation.',
  };

  Widget _track(BuildContext context,String label,int value) {
    return Padding(
      padding:const EdgeInsets.only(top:9),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Text(label,
            style:Theme.of(context).textTheme.labelMedium)),
          Text('$value%',style:Theme.of(context).textTheme.labelMedium),
        ]),
        const SizedBox(height:5),
        ClipRRect(borderRadius:BorderRadius.circular(5),child:
          LinearProgressIndicator(
            key:Key('pillar-progress-$label'),
            value:value/100,minHeight:7,
            backgroundColor:Theme.of(context).colorScheme.outline.withValues(alpha:.2),
            color:Theme.of(context).colorScheme.primary,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context){
    final en=FittedLocaleScope.languageOf(context)=='en';
    final pillar=FittedProfileInsights.pillarProgress(rhythm);
    final overall=FittedProfileInsights.overallProgress(rhythm);
    final segment=FittedProfileInsights.classify(rhythm);
    final label=en?labelEn:labelEs;
    return Card(
      key:const Key('fitted-profile-progress-v29'),
      margin:EdgeInsets.zero,
      child:Padding(
        padding:const EdgeInsets.all(18),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(showCompletion)...[
          Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(en?'YOUR PROFILE IS TAKING SHAPE':'TU PERFIL ESTÁ TOMANDO FORMA',
                  style:TextStyle(letterSpacing:1.2,
                    color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w700,
                    fontSize:11)),
                const SizedBox(height:5),
                Text(en?'A measure of what you have shared, not your value.':
                  'Mide lo que has compartido, no tu valor como persona.',
                  style:Theme.of(context).textTheme.bodySmall),
              ])),
            const SizedBox(width:8),
            Text('$overall%',key:const Key('fitted-profile-completion'),
              style:Theme.of(context).textTheme.headlineMedium),
          ]),
          const SizedBox(height:8),
          _track(context,en?'How I Move':'Cómo me muevo',pillar[0]),
          _track(context,en?'How I Live':'Cómo vivo',pillar[1]),
          _track(context,en?'How I Relate':'Cómo me relaciono',pillar[2]),
          const SizedBox(height:13),
          Text(en
            ?'Optional answers do not block your progress.'
            :'Las respuestas opcionales no bloquean tu avance.',
            style:Theme.of(context).textTheme.bodySmall),
          const SizedBox(height:10),
          TextButton.icon(
            key:const Key('fitted-progress-complete'),
            onPressed:onConfigure,icon:const Icon(Icons.arrow_forward),
            label:Text(en?'Continue my profile':'Continuar mi perfil')),
          ],
          if(showRhythm)...[
          Text(en?'MY CURRENT MOVEMENT RHYTHM':'MI RITMO ACTUAL',
            style:TextStyle(color:FitDateColors.lilac,
              fontSize:11,letterSpacing:1.2,fontWeight:FontWeight.w700)),
          const SizedBox(height:9),
          if(segment==null)...[
            Text(en?'Still discovering your rhythm':
              'Estamos descubriendo tu ritmo',
              style:Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:7),
            Text(en
              ?'You can choose a starting point. Your saved habits, not this choice, determine the classification.'
              :'Puedes elegir un punto de partida. Tu clasificación dependerá de tus hábitos guardados, no de esta elección.',
              style:Theme.of(context).textTheme.bodySmall),
          ]else...[
            Text(label[segment.primary]!,
              key:const Key('fitted-rhythm-primary'),
              style:Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:7),
            Text((en?reasonsEn:reasonsEs)[segment.primary]!,
              style:Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height:12),
            Text(en?'SIMILARITY WITH FOUR RHYTHMS':
              'AFINIDAD CON CUATRO RITMOS',
              style:Theme.of(context).textTheme.labelSmall),
            for(final id in FittedProfileInsights.segments)
              _track(context,label[id]!,segment.affinities[id]!),
            const SizedBox(height:8),
            Text(en
              ?'Illustrative affinities, not statistical probabilities or match percentages.'
              :'Afinidades orientativas, no probabilidades estadísticas ni porcentajes de match.',
              style:Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height:11),
          ExpansionTile(
            key:const Key('fitted-starting-rhythm'),
            tilePadding:EdgeInsets.zero,
            title:Text(en?'Optional starting point':'Punto de partida opcional',
              style:Theme.of(context).textTheme.titleSmall),
            subtitle:Text(en?'This choice never pre-fills your answers.':
              'Esta elección nunca rellena respuestas por ti.'),
            children:[
              Wrap(spacing:6,runSpacing:6,children:[
                for(final id in FittedProfileInsights.segments)
                  ChoiceChip(
                    key:Key('starting-rhythm-$id'),
                    selected:startingPreference==id,
                    label:Text(label[id]!),
                    onSelected:(selected)=>
                      onChooseStarting(selected?id:null),
                  ),
              ]),
              if(startingPreference!=null)
                TextButton(
                  key:const Key('clear-starting-rhythm'),
                  onPressed:()=>onChooseStarting(null),
                  child:Text(en?'Clear choice':'Borrar selección'),
                ),
            ],
          ),
          ],
        ]),
      ),
    );
  }
}
