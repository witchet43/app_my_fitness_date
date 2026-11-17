import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/fitted_profile_insights_v29.dart';
import '../core/member_v26_api.dart';
import '../theme/fitness_date_theme.dart';
import '../widgets/fitted_glass_atmosphere.dart';

/// Published B18 design: the illustration is a layout reference, never a
/// source for fictitious user pictures, people or AI biographies.
class FittedIdentityPanelB18 extends StatelessWidget {
  const FittedIdentityPanelB18({
    super.key,required this.name,required this.rhythm,
    required this.summary,required this.onPillar,
    required this.onEdit,required this.onSummaryConsent,
    this.onManualEdit,
    required this.photo,required this.summaryBusy,
    this.profileVisibleToMembers=false,
  });
  final String name;
  final Map<String,dynamic>? rhythm,summary;
  final ValueChanged<int> onPillar;
  final VoidCallback onEdit,onSummaryConsent;
  final VoidCallback? onManualEdit;
  final Future<Uint8List>? photo;
  final bool summaryBusy,profileVisibleToMembers;

  Widget _heading(BuildContext context, bool en) => Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(
        padding:EdgeInsets.symmetric(horizontal:14,vertical:9),
        decoration:BoxDecoration(
          color:FitDateColors.aqua.withValues(alpha:.09),
          borderRadius:BorderRadius.circular(40),
          border:Border.all(color:FitDateColors.aqua.withValues(alpha:.30))),
        child:Text(en?'LIFESTYLE COMPATIBILITY':'AFINIDAD DE ESTILO DE VIDA',
          style:TextStyle(color:FitDateColors.aqua,fontSize:11,
            fontWeight:FontWeight.w800,letterSpacing:1.15)),
      ),
      SizedBox(height:16),
      Text(en?'Hello, $name. Find your rhythm.':'Hola, $name. Sigue tu ritmo.',
        key:Key('b18-main-greeting'),
        maxLines:2,overflow:TextOverflow.ellipsis,
        style:Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight:FontWeight.w800,color:FitDateColors.pearl,
          height:1.13,fontSize:32)),
      SizedBox(height:7),
      Text(en?'Meet people whose values and lifestyle align with yours.':
        'Conoce personas que comparten tu ritmo, tus valores y tus intenciones.',
        style:Theme.of(context).textTheme.bodyLarge?.copyWith(
          color:FitDateColors.muted)),
    ],
  );

  /// Quiet three-pillar progress navigation at the upper-right of the hero.
  Widget _pillars(BuildContext context,bool en){
    final progress=FittedProfileInsights.pillarProgress(rhythm);
    final names=en?const ['How I Move','How I Live','How I Relate']:
      const ['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
    const icons=[Icons.directions_run_rounded,Icons.wb_twilight_outlined,
      Icons.connect_without_contact_outlined];
    final colors = [FitDateColors.aqua,FitDateColors.apricot,FitDateColors.lilac];
    return Container(
      key:Key('b19-compact-pillars'),
      width:292,
      padding:EdgeInsets.symmetric(horizontal:12,vertical:10),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(18),
        color:FitDateColors.inkDeep.withValues(alpha:.34),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.22))),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        for(var i=0;i<3;i++)...[
          InkWell(
            key:Key('b18-pillar-$i'),
            onTap:()=>onPillar(i),
            borderRadius:BorderRadius.circular(10),
            child:Padding(
              padding:EdgeInsets.symmetric(vertical:7),
              child:Row(children:[
                Icon(icons[i],size:16,color:colors[i]),
                SizedBox(width:8),
                Expanded(child:Text(names[i],maxLines:1,
                  overflow:TextOverflow.ellipsis,
                  style:TextStyle(fontSize:12.5,
                    color:FitDateColors.pearl,fontWeight:FontWeight.w600))),
                SizedBox(width:6),
                SizedBox(width:58,
                  child:LinearProgressIndicator(
                    key:Key('b18-pillar-progress-$i'),
                    value:progress[i]/100,
                    minHeight:4,
                    borderRadius:BorderRadius.circular(5),
                    color:colors[i],
                    backgroundColor:FitDateColors.pearl.withValues(alpha:.13))),
                SizedBox(width:6),
                SizedBox(width:34,child:Text('${progress[i]}%',
                  textAlign:TextAlign.right,
                  style:TextStyle(fontSize:11,color:colors[i],
                    fontWeight:FontWeight.w700))),
              ]),
            )),
        ],
      ]),
    );
  }

  /// The hero is a personal editorial story, not a truncated short caption.
  Widget _summary(BuildContext context,bool en){
    final s=summary??const <String,dynamic>{};
    final aiEnabled=s['ai_consented']==true;
    final published=s['share_consented']==true && profileVisibleToMembers;
    final actualAi=aiEnabled && s['mode']=='ai';
    final value=(s[en?'summary_en':'summary_es']??'').toString().trim();
    final empty= value.isEmpty;
    return FittedGlassPanel(
      radius:23,blur:8,padding:EdgeInsets.all(22),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Icon(Icons.auto_stories_outlined,color:FitDateColors.lilac,size:24),
          SizedBox(width:10),
          Expanded(child:Text(en?'Your rhythm, in words':'Tu ritmo, en palabras',
            key:Key('b19-story-title'),
            style:Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight:FontWeight.w800))),
          Container(
            padding:EdgeInsets.symmetric(horizontal:9,vertical:4),
            decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),
              border:Border.all(color:FitDateColors.lilac.withValues(alpha:.65))),
            child:Text(actualAi?'IA':aiEnabled
              ?(en?'Editorial':'Editorial')
              :(en?'Written by you':'Tu historia'),
              style:TextStyle(fontSize:11,color:FitDateColors.lilac,
                fontWeight:FontWeight.w700))),
          if(!aiEnabled)...[
            SizedBox(width:5),
            IconButton(
              key:Key('b19-edit-manual-story'),
              tooltip:en?'Edit my story':'Editar mi historia',
              onPressed:summaryBusy?null:onManualEdit,
              icon:Icon(Icons.edit_outlined,
                color:FitDateColors.lilac,size:22)),
          ],
        ]),
        SizedBox(height:19),
        if(summaryBusy)LinearProgressIndicator(minHeight:3),
        Text(empty?(aiEnabled
            ?(en?'Complete your lifestyle profile to build your story.':
              'Completa tu perfil para construir tu historia con IA.')
            :(en?'Write your personal introduction in your own words.':
              'Escribe tu historia con tus propias palabras.'))
          :value,
          key:Key('b18-profile-summary'),
          style:Theme.of(context).textTheme.bodyLarge?.copyWith(
            height:1.64,fontSize:17.5,
            fontWeight:FontWeight.w400,
            color:empty?FitDateColors.muted:FitDateColors.pearl)),
        SizedBox(height:19),
        Divider(color:FitDateColors.pearl.withValues(alpha:.15)),
        Text(published
            ?(en?'Visible to eligible verified members.':
                'Visible para miembros elegibles y verificados.')
            :(en?'Private until you authorize sharing and member visibility.':
              'Privado hasta que autorices compartirlo y actives la visibilidad para miembros.'),
          style:Theme.of(context).textTheme.bodySmall?.copyWith(
            color:FitDateColors.muted)),
        SizedBox(height:7),
        TextButton.icon(
          key:Key('b18-summary-consent'),
          onPressed:summaryBusy?null:onSummaryConsent,
          icon:Icon(aiEnabled?Icons.auto_awesome_outlined:
            Icons.verified_user_outlined,size:18),
          label:Text(aiEnabled?(en?'Manage AI and visibility':
              'Gestionar IA y visibilidad'):
              (en?'Privacy and visibility':
                'Privacidad y visibilidad')),
        ),
      ]),
    );
  }

  Widget _portrait(BuildContext context,bool en) => InkWell(
    key:Key('b18-owner-portrait'),
    onTap:onEdit,borderRadius:BorderRadius.circular(23),
    child:Container(
      height:240,width:200,
      clipBehavior:Clip.antiAlias,
      decoration:BoxDecoration(
        gradient:LinearGradient(colors:[
          Color(0xFF29375E),Color(0xFF321F52)]),
        borderRadius:BorderRadius.circular(23),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.55))),
      child:Stack(fit:StackFit.expand,children:[
        if(photo==null)
          Center(child:Icon(Icons.person_outline_rounded,
            color:FitDateColors.lilac,size:78))
        else FutureBuilder<Uint8List>(
          future:photo,
          builder:(context,snap)=>snap.hasData&&snap.data!.isNotEmpty
            ?Image.memory(snap.data!,fit:BoxFit.cover,
              gaplessPlayback:true)
            :Center(child:Icon(Icons.person_outline_rounded,
                color:FitDateColors.lilac,size:78)),
        ),
        Align(alignment:Alignment.bottomCenter,child:Container(
          width:double.infinity,padding:EdgeInsets.all(11),
          decoration:BoxDecoration(
            color:FitDateColors.inkDeep.withValues(alpha:.83),
            borderRadius:BorderRadius.only(
              bottomLeft:Radius.circular(21),
              bottomRight:Radius.circular(21))),
          child:Row(children:[
            Icon(Icons.camera_alt_outlined,size:21),
            SizedBox(width:8),
            Expanded(child:Text(en?'My profile photo':
              'Mi foto de perfil',style:TextStyle(
                fontSize:12,fontWeight:FontWeight.w700))),
          ]),
        )),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context){
    final en=FittedLocaleScope.languageOf(context)=='en';
    return LayoutBuilder(builder:(context,box){
      final wide=box.maxWidth>=900;
      final medium=box.maxWidth>=600;
      return Container(
        key:Key('b18-unified-identity-panel'),
        clipBehavior:Clip.antiAlias,
        decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(28),
          border:Border.all(color:FitDateColors.aqua.withValues(alpha:.4)),
          gradient:LinearGradient(
            colors:[Color(0xFF162A4B),Color(0xFF191D40),Color(0xFF292046)])),
        child:Stack(children:[
          Positioned.fill(child:FittedRhythmLines(density:.8)),
          Padding(
            padding:EdgeInsets.all(wide?25:17),
            child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              if(wide) Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(child:_heading(context,en)),
                SizedBox(width:18),
                _pillars(context,en),
              ]) else Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                _heading(context,en),
                SizedBox(height:14),
                Align(alignment:Alignment.centerRight,child:_pillars(context,en)),
              ]),
              SizedBox(height:22),
              if(wide) Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(flex:75,child:ConstrainedBox(
                  constraints:BoxConstraints(minHeight:290),
                  child:_summary(context,en))),
                SizedBox(width:17),
                SizedBox(width:200,child:_portrait(context,en)),
              ]) else if(medium)
                Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Expanded(child:_summary(context,en)),
                  SizedBox(width:12),
                  SizedBox(width:150,child:_portrait(context,en)),
                ])
              else Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                _summary(context,en),
                SizedBox(height:15),
                Align(alignment:Alignment.centerRight,
                  child:SizedBox(width:175,child:_portrait(context,en))),
              ]),
              SizedBox(height:16),
              Divider(color:FitDateColors.pearl.withValues(alpha:.18)),
              Row(children:[
                Icon(Icons.info_outline,color:FitDateColors.aqua,size:17),
                SizedBox(width:9),
                Expanded(child:Text(en
                  ?'Your story stays yours: AI updates only with your consent; manual text changes only when you edit it.'
                  :'Tu historia te pertenece: la IA se actualiza solo con tu autorización; el texto manual cambia únicamente cuando tú lo editas.',
                  style:Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:FitDateColors.muted))),
              ]),
            ]),
          ),
        ]),
      );
    });
  }
}

/// A matching feed only uses verified server-returned candidates. The
/// illustrative people from a design mockup are never rendered as users.
class FittedFitsPanelB18 extends StatefulWidget {
  const FittedFitsPanelB18({super.key,required this.api,
    required this.pillarProgress,required this.status,
    required this.onPrepare,required this.onVerifyAge});
  final MemberV26Api api;
  final List<int> pillarProgress;
  final Map<String,dynamic>? status;
  final VoidCallback onPrepare,onVerifyAge;
  @override
  State<FittedFitsPanelB18> createState()=>_FittedFitsPanelB18State();
}
class _FittedFitsPanelB18State extends State<FittedFitsPanelB18>{
  bool loading=false;
  String? problem,busy;
  List<Map<String,dynamic>> candidates=[];
  int cursor=0;
  @override
  void initState(){super.initState();refresh();}
  @override
  void didUpdateWidget(covariant FittedFitsPanelB18 old){
    super.didUpdateWidget(old);
    if(old.status?['enabled']!=widget.status?['enabled']){
      refresh();
    }
  }
  Future<void> refresh()async{
    if(!mounted)return;
    if(widget.status?['enabled']!=true){
      setState((){candidates=[];cursor=0;loading=false;});return;
    }
    setState((){loading=true;problem=null;});
    try{
      final values=await widget.api.discoverB11();
      if(mounted)setState((){candidates=values;cursor=0;});
    }catch(_){
      if(mounted)setState((){
        candidates=[];problem='No se pudo comprobar el acceso a los perfiles.';
      });
    }finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> like(Map<String,dynamic> person)async{
    final id=(person['user_id']??'').toString();
    if(id.isEmpty||busy!=null)return;
    final confirm=await showDialog<bool>(context:context,builder:(ctx)=>
      AlertDialog(
        title:Text('¿Te interesa conocer a esta persona?'),
        content:Text('Solo existirá un match cuando ambos acepten.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text('Expresar interés')),
        ],
      ));
    if(confirm!=true||!mounted)return;
    setState(()=>busy=id);
    try{
      final state=await widget.api.likeB11(id);
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(
          state=='matched'?'¡Interés mutuo confirmado!':
          'Tu interés se registró de forma privada.')));
        await refresh();
      }
    }catch(_){if(mounted)setState(()=>
      problem='No se pudo registrar el interés.');}
    finally{if(mounted)setState(()=>busy=null);}
  }
  Widget _candidate(BuildContext context,Map<String,dynamic> person){
    final id=(person['user_id']??'').toString();
    final en=FittedLocaleScope.languageOf(context)=='en';
    return Expanded(child:Card(
      key:Key('b18-fit-$id'),margin:EdgeInsets.all(3),
      child:Padding(padding:EdgeInsets.all(14),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            CircleAvatar(radius:28,
              backgroundColor:FitDateColors.surfaceRaised,
              child:Icon(Icons.person_outline,color:FitDateColors.lilac)),
            SizedBox(width:11),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text((person['display_name']??'').toString(),
                  maxLines:1,overflow:TextOverflow.ellipsis,
                  style:Theme.of(context).textTheme.titleMedium),
                Text((person['city']??'').toString(),
                  style:Theme.of(context).textTheme.bodySmall),
              ])),
          ]),
          SizedBox(height:10),
          FutureBuilder<Map<String,dynamic>>(
            future:widget.api.candidateShowcaseB18(id),
            builder:(context,s){
              if(!s.hasData||s.data?['available']!=true){
                return Text(en?'Private biography':
                  'Presentación privada',
                  style:Theme.of(context).textTheme.bodySmall);
              }
              final key=(s.data?['photo_key']??'').toString();
              final bio=(s.data?[en?'summary_en':'summary_es']??'').toString();
              return Column(crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  if(key.isNotEmpty)FutureBuilder<Uint8List>(
                    future:widget.api.candidatePhotoB18(key),
                    builder:(context,photo)=>photo.hasData
                      ?ClipRRect(borderRadius:BorderRadius.circular(12),
                        child:Image.memory(photo.data!,height:115,
                          width:double.infinity,fit:BoxFit.cover))
                      :SizedBox.shrink()),
                  SizedBox(height:7),
                  Text(bio,maxLines:4,overflow:TextOverflow.ellipsis,
                    style:Theme.of(context).textTheme.bodySmall),
                ]);
            }),
          SizedBox(height:9),
          FutureBuilder<Map<String,dynamic>>(
            future:widget.api.compatibilityB11(id),
            builder:(context,score){
              final result=score.data;
              final percent=result?['percent'];
              if(result?['available']!=true || percent is! num){
                return SizedBox.shrink();
              }
              return Container(
                padding:EdgeInsets.symmetric(horizontal:10,vertical:6),
                decoration:BoxDecoration(
                  border:Border.all(color:FitDateColors.aqua),
                  borderRadius:BorderRadius.circular(20)),
                child:Text(en?'Lifestyle affinity · ${percent.round()}%':
                  'Ritmo afín · ${percent.round()}%',
                  style:TextStyle(fontSize:12,
                    fontWeight:FontWeight.w700,color:FitDateColors.aqua)),
              );
            }),
          Spacer(),
          Align(alignment:Alignment.centerRight,
            child:TextButton.icon(
              onPressed:busy==null?()=>like(person):null,
              icon:Icon(Icons.explore_outlined),
              label:Text(en?'Interested':'Me interesa'))),
        ]),
      ),
    ));
  }
  @override
  Widget build(BuildContext context){
    final en=FittedLocaleScope.languageOf(context)=='en';
    final p=widget.pillarProgress;
    final data=widget.status??const <String,dynamic>{};
    final setup=<({String es,String en,String descEs,String descEn,bool ok,VoidCallback onTap})>[
      (es:'Completar los tres pilares',en:'Complete your three pillars',
        descEs:'Tu ritmo, hábitos y relaciones.',descEn:'Your lifestyle and values.',
        ok:p.every((x)=>x>=100),onTap:widget.onPrepare),
      (es:'Verificar mayoría de edad',en:'Verify legal age',
        descEs:'Revisión humana de identificación.',descEn:'Human ID review.',
        ok:data['age_verified']==true,onTap:widget.onVerifyAge),
      (es:'Definir preferencias',en:'Set matching preferences',
        descEs:'Decide qué tipo de conexión buscas.',descEn:'Choose your connection.',
        ok:data['participation_requested']==true,onTap:widget.onPrepare),
      (es:'Aceptar privacidad y consentimiento',en:'Accept privacy and consent',
        descEs:'Tus datos siguen protegidos.',descEn:'Your information stays protected.',
        ok:data['dating_consent']==true,onTap:widget.onPrepare),
      (es:'Apertura segura de Fitted',en:'Safety release approval',
        descEs:'Operación y moderación verificadas.',descEn:'Verified safety operations.',
        ok:data['discovery_release_ready']==true,onTap:widget.onPrepare),
    ];
    final complete=setup.where((x)=>x.ok).length;
    final canBrowse=data['enabled']==true && complete==setup.length;
    return Container(
      key:Key('b18-fits-matching-panel'),
      padding:EdgeInsets.all(19),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(28),
        gradient:LinearGradient(colors:[
          Color(0xFF20254B),Color(0xFF23204A),Color(0xFF30214F)]),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.52))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(children:[
          Container(padding:EdgeInsets.all(11),
            decoration:BoxDecoration(
              color:FitDateColors.lilac.withValues(alpha:.17),
              borderRadius:BorderRadius.circular(16)),
            child:Icon(Icons.hub_outlined,color:FitDateColors.lilac,size:28)),
          SizedBox(width:13),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text(en?'Your next fits':'Tus próximos fits',
                style:Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight:FontWeight.w800)),
              Text(en?'Prepare your profile to find genuine connections.':
                'Completa tus pasos y conoce personas que comparten tu ritmo.',
                style:Theme.of(context).textTheme.bodySmall),
            ])),
          IconButton(onPressed:loading?null:refresh,
            tooltip:en?'Refresh fits':'Actualizar fits',
            icon:Icon(Icons.refresh)),
        ]),
        SizedBox(height:16),
        LayoutBuilder(builder:(context,widths){
          final wide=widths.maxWidth>=770;
          final checklist=Column(crossAxisAlignment:CrossAxisAlignment.stretch,
            children:[
              Row(children:[
                Expanded(child:Text(en?'Ready to make a match':
                    'Preparación para hacer match',
                  style:Theme.of(context).textTheme.titleMedium)),
                Text('$complete/${setup.length}',
                  style:Theme.of(context).textTheme.titleLarge?.copyWith(
                    color:FitDateColors.lilac)),
              ]),
              SizedBox(height:10),
              LinearProgressIndicator(
                value:complete/setup.length,minHeight:7,
                backgroundColor:FitDateColors.pearl.withValues(alpha:.12),
                color:FitDateColors.lilac),
              SizedBox(height:9),
              for(var i=0;i<setup.length;i++)
                ListTile(
                  key:Key('b18-readiness-$i'),
                  dense:true,contentPadding:EdgeInsets.zero,
                  leading:Icon(setup[i].ok?Icons.check_circle:
                    Icons.radio_button_unchecked,
                    color:setup[i].ok?FitDateColors.aqua:FitDateColors.lilac),
                  title:Text(en?setup[i].en:setup[i].es,
                    style:TextStyle(fontWeight:FontWeight.w600)),
                  subtitle:Text(en?setup[i].descEn:setup[i].descEs),
                  trailing:setup[i].ok?Icon(Icons.check,size:18,
                    color:FitDateColors.aqua):
                    Icon(Icons.chevron_right),
                  onTap:setup[i].onTap,
                ),
            ]);
          final right=Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text(en?'These are your fits':'Así se verán tus fits',
              style:Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight:FontWeight.w700)),
            SizedBox(height:5),
            Text(canBrowse?(en?'Real members who passed safety checks.':
              'Perfiles reales con verificaciones de seguridad.'):(en
              ?'Matches will appear after every requirement is complete.':
              'Aquí aparecerán personas afines cuando completes los requisitos.'),
              style:Theme.of(context).textTheme.bodySmall),
            SizedBox(height:13),
            if(loading)LinearProgressIndicator(),
            if(problem!=null)Text(problem!,
              style:TextStyle(color:Colors.orangeAccent)),
            if(!canBrowse)
              Container(height:176,alignment:Alignment.center,
                decoration:BoxDecoration(
                  borderRadius:BorderRadius.circular(17),
                  color:FitDateColors.inkDeep.withValues(alpha:.4),
                  border:Border.all(color:FitDateColors.outline)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Icon(Icons.lock_person_outlined,size:42,
                    color:FitDateColors.lilac),
                  SizedBox(height:10),
                  Text(en?'Your safe connections start here':
                    'Tus conexiones seguras empiezan aquí',
                    textAlign:TextAlign.center),
                ]))
            else if(candidates.isEmpty&&!loading)
              Container(height:176,alignment:Alignment.center,
                child:Text(en?'No verified members available yet.':
                  'Todavía no hay perfiles reales y verificados disponibles.',
                  textAlign:TextAlign.center))
            else if(candidates.isNotEmpty)
              Row(children:[
                IconButton(
                  key:Key('b18-fit-previous'),
                  onPressed:cursor>0?()=>setState(()=>cursor--):null,
                  tooltip:en?'Previous':'Anterior',
                  icon:Icon(Icons.chevron_left)),
                Expanded(child:SizedBox(height:320,child:Row(children:[
                  _candidate(context,candidates[cursor]),
                  if(wide&&cursor+1<candidates.length)
                    _candidate(context,candidates[cursor+1]),
                ]))),
                IconButton(
                  key:Key('b18-fit-next'),
                  onPressed:cursor<candidates.length-1
                    ?()=>setState(()=>cursor++):null,
                  tooltip:en?'Next':'Siguiente',
                  icon:Icon(Icons.chevron_right)),
              ]),
            SizedBox(height:14),
            FilledButton.icon(
              key:Key('b18-find-fits-cta'),
              onPressed:canBrowse?refresh:widget.onPrepare,
              icon:Icon(canBrowse?Icons.explore_outlined:Icons.tune),
              label:Text(canBrowse?(en?'Explore more fits':'Buscar más fits'):
                (en?'Complete steps to connect':'Completar pasos para conectar')),
            ),
          ]);
          if(wide)return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Expanded(flex:45,child:checklist),
            Container(width:1,margin:EdgeInsets.symmetric(horizontal:19),
              color:FitDateColors.outline),
            Expanded(flex:55,child:right),
          ]);
          return Column(children:[
            checklist,Divider(height:25),right]);
        }),
      ]),
    );
  }
}
