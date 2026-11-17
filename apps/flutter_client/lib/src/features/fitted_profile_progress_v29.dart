import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/fitted_profile_insights_v29.dart';
import '../core/fit_ia_repository.dart';
import '../theme/fitness_date_theme.dart';

/// Pure presentation: caller supplies saved, consented rhythm; no network.
/// A voluntary starting preference is NOT copied into behavioral answers.
class FittedProfileProgressV29 extends StatelessWidget {
  const FittedProfileProgressV29({
    super.key,required this.rhythm,
    required this.startingPreference,required this.onChooseStarting,
    required this.onConfigure,this.fitIaOverview,
    this.showCompletion=true,this.showRhythm=true,
  });
  final Map<String,dynamic>? rhythm;
  final Map<String,dynamic>? fitIaOverview;
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

  Widget _depthRow(BuildContext context,String title,String key,bool en){
    final depth=FitIaDepth.level(fitIaOverview,key);
    return Padding(
      padding:const EdgeInsets.only(top:12),
      child:Row(children:[
        const Icon(Icons.chat_bubble_outline,size:17),
        const SizedBox(width:9),
        Expanded(child:Text(title,style:Theme.of(context).textTheme.bodyMedium)),
        Container(
          key:Key('fit-ia-depth-'+key),
          padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),
          decoration:BoxDecoration(
            borderRadius:BorderRadius.circular(12),
            color:Theme.of(context).colorScheme.primary.withValues(alpha:.12)),
          child:Text(FitIaDepth.label(depth,en),
            style:Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight:FontWeight.w800)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context){
    final en=FittedLocaleScope.languageOf(context)=='en';
    // Coverage of information replaces artificial profile percentages.
    final segment=FittedProfileInsights.classify(rhythm);
    final label=en?labelEn:labelEs;
    return Card(
      key:const Key('fitted-profile-progress-v29'),
      margin:EdgeInsets.zero,
      child:Padding(
        padding:const EdgeInsets.all(18),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(showCompletion)...[
            Text(en?'YOUR STORY IS TAKING SHAPE':
              'TU HISTORIA ESTÁ TOMANDO FORMA',
              style:TextStyle(letterSpacing:1.2,
                color:Theme.of(context).colorScheme.primary,
                fontWeight:FontWeight.w800,fontSize:11)),
            const SizedBox(height:7),
            Text(en
              ?'Fit-IA learns about three areas of your lifestyle '
               'through optional conversations, never a percentage.'
              :'Fit-IA descubre tres dimensiones de tu estilo de vida '
               'con conversaciones voluntarias, nunca porcentajes.',
              style:Theme.of(context).textTheme.bodySmall),
            const SizedBox(height:9),
            _depthRow(context,en?'How I Move':'Cómo me muevo','move',en),
            _depthRow(context,en?'How I Live':'Cómo vivo','live',en),
            _depthRow(context,en?'How I Relate':'Cómo me relaciono','relate',en),
            const SizedBox(height:13),
            FilledButton.tonalIcon(
              key:const Key('fitted-progress-complete'),
              onPressed:onConfigure,
              icon:const Icon(Icons.auto_awesome_outlined),
              label:Text(en?'Chat with Fit-IA':'Conversar con Fit-IA')),
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
            const SizedBox(height:11),
            Text(en
              ?'This description comes from previously saved activity preferences.'
              :'Esta descripción proviene de preferencias de actividad guardadas anteriormente.',
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
