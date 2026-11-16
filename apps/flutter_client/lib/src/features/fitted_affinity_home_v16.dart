import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/fitted_profile_insights_v29.dart';
import '../theme/fitness_date_theme.dart';

/// Private, truthful completion indicator. No fake matches or probabilities,
/// reservations or scheduled locations on the dating-first home.
class FittedAffinityHomeV16 extends StatelessWidget {
  const FittedAffinityHomeV16({
    super.key,required this.rhythm,required this.onConfigurePillar,
    required this.onDiscover,
  });
  final Map<String,dynamic>? rhythm;
  final ValueChanged<int> onConfigurePillar;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context){
    final en=FittedLocaleScope.languageOf(context)=='en';
    final progress=FittedProfileInsights.pillarProgress(rhythm);
    final overall=FittedProfileInsights.overallProgress(rhythm);
    const icons=[
      Icons.directions_run_rounded,
      Icons.wb_twilight_outlined,
      Icons.connect_without_contact_outlined,
    ];
    final labels=en
      ?const ['How I Move','How I Live','How I Relate']
      :const ['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
    final accents=[
      FitDateColors.aqua,
      FitDateColors.apricot,
      FitDateColors.lilac,
    ];
    return Card(
      key:const Key('fitted-home-affinity-v16'),
      margin:EdgeInsets.zero,
      clipBehavior:Clip.antiAlias,
      child:Padding(
        padding:const EdgeInsets.all(20),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Row(children:[
              Container(
                padding:const EdgeInsets.all(10),
                decoration:BoxDecoration(
                  color:FitDateColors.lilac.withValues(alpha:.12),
                  borderRadius:BorderRadius.circular(14)),
                child:const Icon(Icons.auto_awesome_outlined,
                  color:FitDateColors.lilac)),
              const SizedBox(width:12),
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(en?'Your compatibility profile':'Tu perfil de afinidad',
                    style:Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height:3),
                  Text(en?'Your lifestyle, your pace':
                    'Tu estilo de vida, a tu ritmo',
                    style:Theme.of(context).textTheme.bodySmall),
                ],
              )),
              Text('$overall%',
                key:const Key('fitted-affinity-coverage'),
                style:Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:FitDateColors.lilac,fontWeight:FontWeight.w800)),
            ]),
            const SizedBox(height:9),
            Text(en
              ?'This is how much of your private profile is complete—not a match score.'
              :'Esto muestra cuánto has completado de tu perfil privado, no un porcentaje de compatibilidad.',
              style:Theme.of(context).textTheme.bodySmall),
            const SizedBox(height:14),
            for(var i=0;i<3;i++)...[
              InkWell(
                key:Key('affinity-open-pillar-$i'),
                borderRadius:BorderRadius.circular(12),
                onTap:()=>onConfigurePillar(i),
                child:Padding(
                  padding:const EdgeInsets.symmetric(
                    vertical:10,horizontal:6),
                  child:Column(children:[
                    Row(children:[
                      Icon(icons[i],color:accents[i],size:18),
                      const SizedBox(width:10),
                      Expanded(child:Text(labels[i],
                        style:Theme.of(context).textTheme.titleSmall)),
                      Text('${progress[i]}%',
                        style:Theme.of(context).textTheme.labelLarge),
                      const SizedBox(width:6),
                      const Icon(Icons.chevron_right,size:19),
                    ]),
                    const SizedBox(height:7),
                    ClipRRect(
                      borderRadius:BorderRadius.circular(6),
                      child:LinearProgressIndicator(
                        key:Key('affinity-progress-$i'),
                        value:progress[i]/100,
                        minHeight:6,
                        color:accents[i],
                        backgroundColor:FitDateColors.outline.withValues(alpha:.3),
                      ),
                    ),
                  ]),
                ),
              ),
              if(i!=2)const Divider(height:8),
            ],
            const SizedBox(height:13),
            Wrap(spacing:10,runSpacing:8,children:[
              FilledButton.icon(
                key:const Key('affinity-finish-profile'),
                onPressed:()=>onConfigurePillar(
                  progress.indexWhere((p)=>p<100)==-1
                    ?0:progress.indexWhere((p)=>p<100)),
                icon:const Icon(Icons.tune_outlined),
                label:Text(en?'Complete my lifestyle':
                  'Completar mi estilo de vida'),
              ),
              OutlinedButton.icon(
                key:const Key('affinity-see-matches'),
                onPressed:onDiscover,
                icon:const Icon(Icons.explore_outlined),
                label:Text(en?'Discover compatible people':
                  'Descubrir personas afines'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
