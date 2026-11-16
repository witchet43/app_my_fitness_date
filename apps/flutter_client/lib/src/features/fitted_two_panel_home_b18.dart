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
    required this.photo,required this.summaryBusy,
    this.profileVisibleToMembers=false,
  });
  final String name;
  final Map<String,dynamic>? rhythm,summary;
  final ValueChanged<int> onPillar;
  final VoidCallback onEdit,onSummaryConsent;
  final Future<Uint8List>? photo;
  final bool summaryBusy,profileVisibleToMembers;

  Widget _heading(BuildContext context, bool en) => Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(
        padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),
        decoration:BoxDecoration(
          color:FitDateColors.aqua.withValues(alpha:.09),
          borderRadius:BorderRadius.circular(40),
          border:Border.all(color:FitDateColors.aqua.withValues(alpha:.30))),
        child:Text(en?'LIFESTYLE COMPATIBILITY':'AFINIDAD DE ESTILO DE VIDA',
          style:const TextStyle(color:FitDateColors.aqua,fontSize:11,
            fontWeight:FontWeight.w800,letterSpacing:1.15)),
      ),
      const SizedBox(height:16),
      Text(en?'Hello, $name. Find your rhythm.':'Hola, $name. Sigue tu ritmo.',
        key:const Key('b18-main-greeting'),
        maxLines:2,overflow:TextOverflow.ellipsis,
        style:Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight:FontWeight.w800,color:FitDateColors.pearl,
          height:1.13,fontSize:32)),
      const SizedBox(height:7),
      Text(en?'Meet people whose values and lifestyle align with yours.':
        'Conoce personas que comparten tu ritmo, tus valores y tus intenciones.',
        style:Theme.of(context).textTheme.bodyLarge?.copyWith(
          color:FitDateColors.muted)),
    ],
  );

  Widget _pillars(BuildContext context,bool en){
    final progress=FittedProfileInsights.pillarProgress(rhythm);
    final titles=en?const ['How I Move','How I Live','How I Relate']:
      const ['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
    const symbols=[Icons.directions_run_rounded,Icons.wb_twilight_outlined,
      Icons.connect_without_contact_outlined];
    const colors=[FitDateColors.aqua,FitDateColors.apricot,FitDateColors.lilac];
    return Column(mainAxisSize:MainAxisSize.min,children:[
      for(var i=0;i<3;i++)...[
        InkWell(
          key:Key('b18-pillar-$i'),onTap:()=>onPillar(i),
          borderRadius:BorderRadius.circular(18),
          child:Padding(padding:const EdgeInsets.symmetric(vertical:8),
            child:Row(children:[
              SizedBox(width:190,
                child:Container(padding:const EdgeInsets.symmetric(
                  horizontal:10,vertical:11),
                  decoration:BoxDecoration(
                    color:FitDateColors.inkDeep.withValues(alpha:.58),
                    borderRadius:BorderRadius.circular(32),
                    border:Border.all(color:colors[i].withValues(alpha:.5))),
                  child:Row(children:[
                    Icon(symbols[i],color:colors[i],size:20),
                    const SizedBox(width:8),
                    Expanded(child:Text(titles[i],maxLines:1,
                      overflow:TextOverflow.ellipsis,
                      style:const TextStyle(fontWeight:FontWeight.w700))),
                  ]))),
              const SizedBox(width:12),
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.end,children:[
                  Text('${progress[i]}%',
                    style:const TextStyle(fontWeight:FontWeight.w700)),
                  const SizedBox(height:5),
                  ClipRRect(borderRadius:BorderRadius.circular(6),
                    child:LinearProgressIndicator(
                      key:Key('b18-pillar-progress-$i'),
                      minHeight:6,value:progress[i]/100,
                      backgroundColor:FitDateColors.pearl.withValues(alpha:.15),
                      color:colors[i])),
                ])),
              const SizedBox(width:5),
            ]))),
        if(i<2)Divider(color:FitDateColors.pearl.withValues(alpha:.10)),
      ],
    ]);
  }

  Widget _summary(BuildContext context,bool en){
    final s=summary??const <String,dynamic>{};
    final consent=s['ai_consented']==true;
    final publish=s['share_consented']==true && profileVisibleToMembers;
    final mode=(s['mode']??'editorial').toString();
    final value=(s[en?'summary_en':'summary_es']??'').toString().trim();
    return FittedGlassPanel(
      radius:23,blur:8,padding:const EdgeInsets.all(17),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          const Icon(Icons.auto_awesome,color:FitDateColors.lilac,size:23),
          const SizedBox(width:8),
          Expanded(child:Text(en?'Your profile, in a nutshell':
            'Tu perfil, en resumen',
            style:Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight:FontWeight.w800))),
          Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:3),
            decoration:BoxDecoration(
              borderRadius:BorderRadius.circular(20),
              border:Border.all(color:FitDateColors.lilac)),
            child:Text(mode=='ai'?'IA':'Perfil',
              style:const TextStyle(fontSize:10,color:FitDateColors.lilac))),
        ]),
        const SizedBox(height:12),
        if(summaryBusy)const LinearProgressIndicator(minHeight:2),
        Text(value.isNotEmpty?value:
          (en?'Complete your profile to create your personal story.':
              'Completa tu perfil para construir tu historia personal.'),
          key:const Key('b18-profile-summary'),
          maxLines:8,overflow:TextOverflow.ellipsis,
          style:Theme.of(context).textTheme.bodyLarge?.copyWith(
            height:1.53,fontStyle:FontStyle.italic)),
        const SizedBox(height:9),
        Text(publish?(en?'Visible to verified members.':
          'Visible para miembros verificados.'):
          (en?'Private until you choose to share.':
          'Privado hasta que autorices compartirlo y actives la visibilidad para miembros.'),
          style:Theme.of(context).textTheme.bodySmall?.copyWith(
            color:FitDateColors.muted)),
        const SizedBox(height:7),
        TextButton.icon(
          key:const Key('b18-summary-consent'),
          onPressed:summaryBusy?null:onSummaryConsent,
          icon:const Icon(Icons.auto_awesome_outlined,size:18),
          label:Text(consent?(en?'Manage AI and sharing':
            'Gestionar IA y visibilidad'):(en?'Enable AI summary':
              'Activar resumen con IA')),
        ),
      ]),
    );
  }

  Widget _portrait(BuildContext context,bool en) => InkWell(
    key:const Key('b18-owner-portrait'),
    onTap:onEdit,borderRadius:BorderRadius.circular(23),
    child:Container(
      height:240,width:200,
      clipBehavior:Clip.antiAlias,
      decoration:BoxDecoration(
        gradient:const LinearGradient(colors:[
          Color(0xFF29375E),Color(0xFF321F52)]),
        borderRadius:BorderRadius.circular(23),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.55))),
      child:Stack(fit:StackFit.expand,children:[
        if(photo==null)
          const Center(child:Icon(Icons.person_outline_rounded,
            color:FitDateColors.lilac,size:78))
        else FutureBuilder<Uint8List>(
          future:photo,
          builder:(context,snap)=>snap.hasData&&snap.data!.isNotEmpty
            ?Image.memory(snap.data!,fit:BoxFit.cover,
              gaplessPlayback:true)
            :const Center(child:Icon(Icons.person_outline_rounded,
                color:FitDateColors.lilac,size:78)),
        ),
        Align(alignment:Alignment.bottomCenter,child:Container(
          width:double.infinity,padding:const EdgeInsets.all(11),
          decoration:BoxDecoration(
            color:FitDateColors.inkDeep.withValues(alpha:.83),
            borderRadius:const BorderRadius.only(
              bottomLeft:Radius.circular(21),
              bottomRight:Radius.circular(21))),
          child:Row(children:[
            const Icon(Icons.camera_alt_outlined,size:21),
            const SizedBox(width:8),
            Expanded(child:Text(en?'My profile photo':
              'Mi foto de perfil',style:const TextStyle(
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
      final wide=box.maxWidth>=880;
      final middle=box.maxWidth>=590;
      return Container(
        key:const Key('b18-unified-identity-panel'),
        clipBehavior:Clip.antiAlias,
        decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(28),
          border:Border.all(color:FitDateColors.aqua.withValues(alpha:.4)),
          gradient:const LinearGradient(
            colors:[Color(0xFF162A4B),Color(0xFF191D40),Color(0xFF292046)])),
        child:Stack(children:[
          const Positioned.fill(child:FittedRhythmLines(density:.8)),
          Padding(padding:EdgeInsets.all(wide?24:16),
            child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              _heading(context,en),
              const SizedBox(height:21),
              if(wide) Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(flex:40,child:_pillars(context,en)),
                const SizedBox(width:20),
                Expanded(flex:40,child:_summary(context,en)),
                const SizedBox(width:15),
                SizedBox(width:165,child:_portrait(context,en)),
              ]) else if(middle) Column(children:[
                Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Expanded(child:_pillars(context,en)),
                  const SizedBox(width:14),
                  SizedBox(width:155,child:_portrait(context,en)),
                ]),
                const SizedBox(height:12),_summary(context,en),
              ]) else Column(children:[
                _pillars(context,en),const SizedBox(height:12),
                Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Expanded(child:_summary(context,en)),
                  const SizedBox(width:9),
                  SizedBox(width:115,child:_portrait(context,en)),
                ]),
              ]),
              const SizedBox(height:12),
              Divider(color:FitDateColors.pearl.withValues(alpha:.2)),
              Row(children:[
                const Icon(Icons.info_outline,color:FitDateColors.aqua,size:17),
                const SizedBox(width:9),
                Expanded(child:Text(en
                  ?'Your story refreshes when you save your profile. Only shared information is visible to other members.'
                  :'Tu historia se actualiza al guardar. Solo la información autorizada será visible para otras personas.',
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
        title:const Text('¿Te interesa conocer a esta persona?'),
        content:const Text('Solo existirá un match cuando ambos acepten.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Expresar interés')),
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
      key:Key('b18-fit-$id'),margin:const EdgeInsets.all(3),
      child:Padding(padding:const EdgeInsets.all(14),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            CircleAvatar(radius:28,
              backgroundColor:FitDateColors.surfaceRaised,
              child:const Icon(Icons.person_outline,color:FitDateColors.lilac)),
            const SizedBox(width:11),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text((person['display_name']??'').toString(),
                  maxLines:1,overflow:TextOverflow.ellipsis,
                  style:Theme.of(context).textTheme.titleMedium),
                Text((person['city']??'').toString(),
                  style:Theme.of(context).textTheme.bodySmall),
              ])),
          ]),
          const SizedBox(height:10),
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
                      :const SizedBox.shrink()),
                  const SizedBox(height:7),
                  Text(bio,maxLines:4,overflow:TextOverflow.ellipsis,
                    style:Theme.of(context).textTheme.bodySmall),
                ]);
            }),
          const SizedBox(height:9),
          FutureBuilder<Map<String,dynamic>>(
            future:widget.api.compatibilityB11(id),
            builder:(context,score){
              final result=score.data;
              final percent=result?['percent'];
              if(result?['available']!=true || percent is! num){
                return const SizedBox.shrink();
              }
              return Container(
                padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
                decoration:BoxDecoration(
                  border:Border.all(color:FitDateColors.aqua),
                  borderRadius:BorderRadius.circular(20)),
                child:Text(en?'Lifestyle affinity · ${percent.round()}%':
                  'Ritmo afín · ${percent.round()}%',
                  style:const TextStyle(fontSize:12,
                    fontWeight:FontWeight.w700,color:FitDateColors.aqua)),
              );
            }),
          const Spacer(),
          Align(alignment:Alignment.centerRight,
            child:TextButton.icon(
              onPressed:busy==null?()=>like(person):null,
              icon:const Icon(Icons.favorite_border),
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
      key:const Key('b18-fits-matching-panel'),
      padding:const EdgeInsets.all(19),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(28),
        gradient:const LinearGradient(colors:[
          Color(0xFF20254B),Color(0xFF23204A),Color(0xFF30214F)]),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.52))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(children:[
          Container(padding:const EdgeInsets.all(11),
            decoration:BoxDecoration(
              color:FitDateColors.lilac.withValues(alpha:.17),
              borderRadius:BorderRadius.circular(16)),
            child:const Icon(Icons.favorite_border,color:FitDateColors.lilac,size:28)),
          const SizedBox(width:13),
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
            icon:const Icon(Icons.refresh)),
        ]),
        const SizedBox(height:16),
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
              const SizedBox(height:10),
              LinearProgressIndicator(
                value:complete/setup.length,minHeight:7,
                backgroundColor:FitDateColors.pearl.withValues(alpha:.12),
                color:FitDateColors.lilac),
              const SizedBox(height:9),
              for(var i=0;i<setup.length;i++)
                ListTile(
                  key:Key('b18-readiness-$i'),
                  dense:true,contentPadding:EdgeInsets.zero,
                  leading:Icon(setup[i].ok?Icons.check_circle:
                    Icons.radio_button_unchecked,
                    color:setup[i].ok?FitDateColors.aqua:FitDateColors.lilac),
                  title:Text(en?setup[i].en:setup[i].es,
                    style:const TextStyle(fontWeight:FontWeight.w600)),
                  subtitle:Text(en?setup[i].descEn:setup[i].descEs),
                  trailing:setup[i].ok?const Icon(Icons.check,size:18,
                    color:FitDateColors.aqua):
                    const Icon(Icons.chevron_right),
                  onTap:setup[i].onTap,
                ),
            ]);
          final right=Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text(en?'These are your fits':'Así se verán tus fits',
              style:Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight:FontWeight.w700)),
            const SizedBox(height:5),
            Text(canBrowse?(en?'Real members who passed safety checks.':
              'Perfiles reales con verificaciones de seguridad.'):(en
              ?'Matches will appear after every requirement is complete.':
              'Aquí aparecerán personas afines cuando completes los requisitos.'),
              style:Theme.of(context).textTheme.bodySmall),
            const SizedBox(height:13),
            if(loading)const LinearProgressIndicator(),
            if(problem!=null)Text(problem!,
              style:const TextStyle(color:Colors.orangeAccent)),
            if(!canBrowse)
              Container(height:176,alignment:Alignment.center,
                decoration:BoxDecoration(
                  borderRadius:BorderRadius.circular(17),
                  color:FitDateColors.inkDeep.withValues(alpha:.4),
                  border:Border.all(color:FitDateColors.outline)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  const Icon(Icons.lock_person_outlined,size:42,
                    color:FitDateColors.lilac),
                  const SizedBox(height:10),
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
                  key:const Key('b18-fit-previous'),
                  onPressed:cursor>0?()=>setState(()=>cursor--):null,
                  tooltip:en?'Previous':'Anterior',
                  icon:const Icon(Icons.chevron_left)),
                Expanded(child:SizedBox(height:320,child:Row(children:[
                  _candidate(context,candidates[cursor]),
                  if(wide&&cursor+1<candidates.length)
                    _candidate(context,candidates[cursor+1]),
                ]))),
                IconButton(
                  key:const Key('b18-fit-next'),
                  onPressed:cursor<candidates.length-1
                    ?()=>setState(()=>cursor++):null,
                  tooltip:en?'Next':'Siguiente',
                  icon:const Icon(Icons.chevron_right)),
              ]),
            const SizedBox(height:14),
            FilledButton.icon(
              key:const Key('b18-find-fits-cta'),
              onPressed:canBrowse?refresh:widget.onPrepare,
              icon:Icon(canBrowse?Icons.explore_outlined:Icons.tune),
              label:Text(canBrowse?(en?'Explore more fits':'Buscar más fits'):
                (en?'Complete steps to connect':'Completar pasos para conectar')),
            ),
          ]);
          if(wide)return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Expanded(flex:45,child:checklist),
            Container(width:1,margin:const EdgeInsets.symmetric(horizontal:19),
              color:FitDateColors.outline),
            Expanded(flex:55,child:right),
          ]);
          return Column(children:[
            checklist,const Divider(height:25),right]);
        }),
      ]),
    );
  }
}
