import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/live_brand.dart';
import '../widgets/mfd_branding.dart';
import 'rhythm_concept_lab_b10.dart';
import 'fitted_profile_progress_v29.dart';
import '../theme/fitness_date_theme.dart';
import '../widgets/fitted_glass_atmosphere.dart';

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
        key:Key('profile-compact-identity'),
        padding:EdgeInsets.all(26),
        decoration:BoxDecoration(
          gradient:LinearGradient(
            begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:[Color(0xFF1A4246),Color(0xFF1B2E38),Color(0xFF252A3D)]),
          borderRadius:BorderRadius.circular(27),
          border:Border.all(color:FitDateColors.aqua.withValues(alpha:.34)),
          boxShadow:[BoxShadow(color:FitDateColors.aqua.withValues(alpha:.07),
            blurRadius:24,offset:Offset(0,12))],
        ),
        child:Stack(children:[
          Positioned.fill(child:FittedRhythmLines(density:.45)),
          Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            MfdBranding(full:false,width:55),
            SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(en?'PRIVATE PROFILE':'PERFIL PRIVADO',
                  style:TextStyle(color:FitDateColors.aqua,
                    letterSpacing:1.7,fontSize:11,fontWeight:FontWeight.w800)),
                SizedBox(height:3),
                Text(LiveBrandScope.of(context).name,
                  maxLines:1,overflow:TextOverflow.ellipsis,
                  style:theme.textTheme.labelMedium),
              ])),
            IconButton(
              key:Key('profile-edit-identity'),
              tooltip:en?'Edit basic information':'Editar datos básicos',
              onPressed:onEditIdentity,
              icon:Icon(Icons.edit_outlined)),
          ]),
          SizedBox(height:18),
          Row(children:[
            Container(width:26,height:3,decoration:BoxDecoration(
              color:FitDateColors.aqua,borderRadius:BorderRadius.circular(3))),
            SizedBox(width:8),
            Text(en?'MORE THAN A PROFILE':'MÁS QUE UN PERFIL',
              style:TextStyle(color:FitDateColors.muted,
                fontSize:10,letterSpacing:1.5,fontWeight:FontWeight.w800)),
          ]),
          SizedBox(height:13),
          Text(displayName.isEmpty?(en?'Your name':'Tu nombre'):displayName,
            key:Key('v26-member-name'),
            style:theme.textTheme.displayMedium?.copyWith(
              fontSize:34,fontWeight:FontWeight.w700)),
          if(city.isNotEmpty)...[
            SizedBox(height:5),
            Text(city,style:theme.textTheme.bodyMedium?.copyWith(
              color:Color(0xFFB3C3B9))),
          ],
          SizedBox(height:17),
          Container(width:42,height:2,
            decoration:BoxDecoration(color:FitDateColors.apricot.withValues(alpha:.8),
              borderRadius:BorderRadius.circular(2))),
          SizedBox(height:13),
          Text(statement,key:Key('profile-behavior-story'),
            style:theme.textTheme.bodyLarge?.copyWith(height:1.5)),
          SizedBox(height:14),
          Text(en?'BASED ON YOUR SAVED ROUTINE':'BASADO EN TU RUTINA GUARDADA',
            style:TextStyle(color:FitDateColors.apricot,
              letterSpacing:1,fontWeight:FontWeight.w700,fontSize:10)),
          SizedBox(height:18),
          FilledButton.icon(
            key:Key('profile-configure-pulse'),
            onPressed:onConfigure,
            icon:Icon(Icons.tune),
            label:Text(en?'Edit my lifestyle':'Configurar mi estilo de vida')),
          SizedBox(height:17),
          FittedProfileProgressV29(
            rhythm:rhythm,startingPreference:startingPreference,
            onChooseStarting:onChooseStarting,onConfigure:onConfigure,
            showRhythm:false),
        ]),
        ]),
      );
      final rhythmCards=Column(
        key:Key('profile-rhythm-snapshot'),
        crossAxisAlignment:CrossAxisAlignment.stretch,
        children:[
          Text(en?'MY RHYTHM AT A GLANCE':'MI RITMO EN TRES DIMENSIONES',
            style:TextStyle(color:FitDateColors.aqua,
              fontSize:11,letterSpacing:1.7,fontWeight:FontWeight.bold)),
          SizedBox(height:10),
          _rhythmTile(context,Icons.directions_run_outlined,
            en?'How I Move':'Cómo me muevo',en?'How I train':'Mi actividad',moves),
          SizedBox(height:8),
          _rhythmTile(context,Icons.nights_stay_outlined,
            en?'How I Live':'Cómo vivo',en?'How I organize my life':'Mi ritmo',lives),
          SizedBox(height:8),
          _rhythmTile(context,Icons.people_outline,
            en?'How I Relate':'Cómo me relaciono',en?'How I make room for someone':'Mis conexiones',relates),
          SizedBox(height:12),
          FittedProfileProgressV29(
            rhythm:rhythm,startingPreference:startingPreference,
            onChooseStarting:onChooseStarting,onConfigure:onConfigure,
            showCompletion:false),
        ],
      );
      return wide?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(flex:6,child:identity),SizedBox(width:16),
        Expanded(flex:5,child:rhythmCards),
      ]):Column(children:[identity,SizedBox(height:20),rhythmCards]);
    });
  }

  Widget _rhythmTile(BuildContext context,IconData icon,String title,
      String subtitle,List<String> lines){
    final theme=Theme.of(context);
    final accent=icon==Icons.directions_run_outlined?FitDateColors.aqua:
      icon==Icons.nights_stay_outlined?FitDateColors.apricot:FitDateColors.lilac;
    return Container(
      padding:EdgeInsets.symmetric(horizontal:16,vertical:17),
      decoration:BoxDecoration(
        gradient:LinearGradient(colors:[
          accent.withValues(alpha:.13),Color(0xFF182830)],
          begin:Alignment.topLeft,end:Alignment.bottomRight),
        borderRadius:BorderRadius.circular(20),
        border:Border.all(color:accent.withValues(alpha:.31)),
      ),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(width:45,height:45,
          decoration:BoxDecoration(shape:BoxShape.circle,
            color:accent.withValues(alpha:.15),
            border:Border.all(color:accent.withValues(alpha:.30))),
          child:Icon(icon,color:accent,size:23)),
        SizedBox(width:13),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text(title,style:theme.textTheme.titleMedium?.copyWith(
              fontWeight:FontWeight.w800,color:FitDateColors.pearl)),
            Text(subtitle,style:theme.textTheme.bodySmall?.copyWith(
              color:Color(0xFFB3C3B9))),
            SizedBox(height:7),
            Wrap(spacing:5,runSpacing:5,children:[
              for(final line in lines)
                Container(
                  constraints:BoxConstraints(maxWidth:255),
                  padding:EdgeInsets.symmetric(horizontal:8,vertical:4),
                  decoration:BoxDecoration(
                    color:accent.withValues(alpha:.10),
                    border:Border.all(color:accent.withValues(alpha:.20)),
                    borderRadius:BorderRadius.circular(11)),
                  child:Text(line,maxLines:1,overflow:TextOverflow.ellipsis,
                    style:theme.textTheme.labelSmall),
                ),
            ]),
          ])),
      ]),
    );
  }
}
