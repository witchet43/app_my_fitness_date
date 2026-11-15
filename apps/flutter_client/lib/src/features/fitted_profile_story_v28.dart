import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/live_brand.dart';
import '../widgets/mfd_branding.dart';
import 'rhythm_concept_lab_b10.dart';
import 'fitted_profile_progress_v29.dart';

/// Editorial story built exclusively from the member's saved actions and
/// choices. No inferred facts, no locations, no detailed schedules.
class FittedProfileStoryV28 extends StatelessWidget {
  const FittedProfileStoryV28({
    super.key,required this.profile,required this.rhythm,
    required this.onConfigure,required this.onEditIdentity,
    required this.startingPreference,required this.onChooseStarting,
  });
  final Map<String,dynamic> profile;
  final Map<String,dynamic>? rhythm;
  final VoidCallback onConfigure;
  final VoidCallback onEditIdentity;
  final String? startingPreference;
  final Future<void> Function(String?) onChooseStarting;

  @override
  Widget build(BuildContext context) {
    final en=FittedLocaleScope.languageOf(context)=='en';
    final theme=Theme.of(context);
    final answers=rhythm?['answers'] is Map
      ?Map<String,dynamic>.from(rhythm!['answers'] as Map)
      :<String,dynamic>{};
    String field(String key) {
      final raw=answers[key]?.toString()??'';
      return rhythmLabelsB10[raw]?[en?'en':'es']??'';
    }
    String choice(String key,String emptyEs,String emptyEn)=>
      field(key).isEmpty?(en?emptyEn:emptyEs):field(key);
    final displayName=(profile['display_name']??'').toString().trim();
    final city=(profile['city']??'').toString().trim();
    final moves=[
      choice('sport','Aún sin disciplina principal','No primary activity yet'),
      choice('frequency','Frecuencia por definir','Frequency to be set'),
      choice('training_mode','Modo por definir','Training mode to be set'),
    ];
    final lives=[
      choice('weekday','Entre semana por definir','Weekday rhythm to be set'),
      choice('sleep','Descanso por definir','Rest rhythm to be set'),
      choice('travel','Viajes por definir','Travel style to be set'),
    ];
    final relates=[
      choice('intent','Intención por definir','Intention to be set'),
      choice('together','Autonomía por definir','Independence to be set'),
      choice('train_partner','Entrenar juntos por definir',
        'Training together to be set'),
    ];
    final week=field('weekday'),sleep=field('sleep');
    final isKnown=rhythm!=null&&answers.isNotEmpty;
    final statement=isKnown
      ?en
        ?'My routine combines ${field('frequency').isEmpty?'movement':field('frequency').toLowerCase()} with ${week.isEmpty?'an evolving weekday rhythm':week.toLowerCase()} and ${sleep.isEmpty?'room for recovery':sleep.toLowerCase()}.'
        :'Mi rutina combina ${field('frequency').isEmpty?'movimiento':field('frequency').toLowerCase()}, ${week.isEmpty?'mis días entre semana':week.toLowerCase()} y ${sleep.isEmpty?'espacio para recuperarme':sleep.toLowerCase()}.'
      :en
        ?'Your story will take shape through what you do, not a generic bio.'
        :'Tu historia se construye con lo que haces, no con una biografía genérica.';
    return LayoutBuilder(builder:(context,limits){
      final wide=limits.maxWidth>=790;
      final identity=Container(
        key:const Key('profile-compact-identity'),
        padding:const EdgeInsets.all(23),
        decoration:BoxDecoration(
          color:const Color(0xFF1C3031),
          borderRadius:BorderRadius.circular(22),
          border:Border.all(color:const Color(0xFF566C62).withValues(alpha:.48)),
        ),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            const MfdBranding(full:false,width:55),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(en?'PRIVATE PROFILE':'PERFIL PRIVADO',
                  style:const TextStyle(color:Color(0xFFA5B9AC),
                    letterSpacing:1.7,fontSize:11,fontWeight:FontWeight.w700)),
                const SizedBox(height:3),
                Text(LiveBrandScope.of(context).name,
                  maxLines:1,overflow:TextOverflow.ellipsis,
                  style:theme.textTheme.labelMedium),
              ])),
            IconButton(
              key:const Key('profile-edit-identity'),
              tooltip:en?'Edit basic information':'Editar datos básicos',
              onPressed:onEditIdentity,
              icon:const Icon(Icons.edit_outlined)),
          ]),
          const SizedBox(height:18),
          Text(displayName.isEmpty?(en?'Your name':'Tu nombre'):displayName,
            key:const Key('v26-member-name'),
            style:theme.textTheme.headlineMedium?.copyWith(
              fontWeight:FontWeight.w800)),
          if(city.isNotEmpty)...[
            const SizedBox(height:5),
            Text(city,style:theme.textTheme.bodyMedium?.copyWith(
              color:const Color(0xFFB3C3B9))),
          ],
          const SizedBox(height:16),
          Text(statement,key:const Key('profile-behavior-story'),
            style:theme.textTheme.bodyLarge?.copyWith(height:1.5)),
          const SizedBox(height:14),
          Text(en?'BASED ON YOUR SAVED ROUTINE':'BASADO EN TU RUTINA GUARDADA',
            style:const TextStyle(color:Color(0xFFD5BE8A),
              letterSpacing:1,fontWeight:FontWeight.w700,fontSize:10)),
          const SizedBox(height:18),
          FilledButton.icon(
            key:const Key('profile-configure-pulse'),
            onPressed:onConfigure,
            icon:const Icon(Icons.tune),
            label:Text(en?'Edit my lifestyle':'Configurar mi estilo de vida')),
        ]),
      );
      final rhythmCards=Column(
        key:const Key('profile-rhythm-snapshot'),
        crossAxisAlignment:CrossAxisAlignment.stretch,
        children:[
          Text(en?'MY RHYTHM AT A GLANCE':'MI RITMO EN TRES DIMENSIONES',
            style:const TextStyle(color:Color(0xFFD5BE8A),
              fontSize:11,letterSpacing:1.7,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          FittedProfileProgressV29(
            rhythm:rhythm,
            startingPreference:startingPreference,
            onChooseStarting:onChooseStarting,
            onConfigure:onConfigure),
          const SizedBox(height:10),
          _rhythmTile(context,Icons.directions_run_outlined,
            'How I Move',en?'How I train':'Cómo me muevo',moves),
          const SizedBox(height:8),
          _rhythmTile(context,Icons.nights_stay_outlined,
            'How I Live',en?'How I organize my life':'Cómo organizo mi vida',lives),
          const SizedBox(height:8),
          _rhythmTile(context,Icons.people_outline,
            'How I Relate',en?'How I make room for someone':'Cómo comparto mi vida',relates),
        ],
      );
      return wide?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(flex:6,child:identity),const SizedBox(width:16),
        Expanded(flex:5,child:rhythmCards),
      ]):Column(children:[identity,const SizedBox(height:20),rhythmCards]);
    });
  }

  Widget _rhythmTile(BuildContext context,IconData icon,String title,
      String subtitle,List<String> lines){
    final theme=Theme.of(context);
    return Container(
      padding:const EdgeInsets.symmetric(horizontal:15,vertical:12),
      decoration:BoxDecoration(
        color:const Color(0xFF19272C),
        borderRadius:BorderRadius.circular(15),
        border:Border.all(color:const Color(0xFF425150)),
      ),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,color:const Color(0xFFD5BE8A),size:23),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text(title,style:theme.textTheme.titleSmall?.copyWith(
              fontWeight:FontWeight.bold)),
            Text(subtitle,style:theme.textTheme.bodySmall?.copyWith(
              color:const Color(0xFFB3C3B9))),
            const SizedBox(height:7),
            Wrap(spacing:5,runSpacing:5,children:[
              for(final line in lines)
                Container(
                  constraints:const BoxConstraints(maxWidth:255),
                  padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                  decoration:BoxDecoration(color:const Color(0xFF263B3A),
                    borderRadius:BorderRadius.circular(7)),
                  child:Text(line,maxLines:1,overflow:TextOverflow.ellipsis,
                    style:theme.textTheme.labelSmall),
                ),
            ]),
          ])),
      ]),
    );
  }
}
