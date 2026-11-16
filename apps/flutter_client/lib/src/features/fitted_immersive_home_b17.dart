import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../core/fitted_profile_insights_v29.dart';
import '../core/member_v26_api.dart';
import '../theme/fitness_date_theme.dart';
import '../widgets/fitted_glass_atmosphere.dart';

/// B17: the TWO screenshot-inspired panels are the actual signed-in home.
/// No fictional candidates, percentage, approved photo or match may enter UI.
class FittedImmersiveHomeB17 extends StatefulWidget {
  const FittedImmersiveHomeB17({
    super.key,required this.api,required this.profile,required this.rhythm,
    required this.photos,required this.onConfigurePillar,
    required this.onEditProfile,required this.onUploadPhoto,
    required this.onDiscover,required this.onVerifyAge,
  });
  final MemberV26Api api;
  final Map<String,dynamic> profile;
  final Map<String,dynamic>? rhythm;
  final List<Map<String,dynamic>> photos;
  final ValueChanged<int> onConfigurePillar;
  final VoidCallback onEditProfile,onUploadPhoto,onDiscover,onVerifyAge;
  @override
  State<FittedImmersiveHomeB17> createState()=>_FittedImmersiveHomeB17State();
}

class _FittedImmersiveHomeB17State extends State<FittedImmersiveHomeB17>{
  Map<String,dynamic> summary={},dating={};
  List<Map<String,dynamic>> candidates=[];
  Map<String,Map<String,dynamic>> candidateCards={};
  final Map<String,Future<Uint8List>> photoRequests={};
  final Map<String,Future<Map<String,dynamic>>> scores={};
  Future<Uint8List>? ownerPhoto;
  int page=0;
  bool busy=false,loading=true,aiAvailable=false;
  String? notice;
  bool get english=>FittedLocaleScope.languageOf(context)=='en';
  String t(String es,String en)=>english?en:es;
  List<int> get progress=>FittedProfileInsights.pillarProgress(widget.rhythm);
  int get total=>FittedProfileInsights.overallProgress(widget.rhythm);

  @override
  void initState(){super.initState();_refreshOwnPhoto();reload();}
  @override
  void didUpdateWidget(covariant FittedImmersiveHomeB17 old){
    super.didUpdateWidget(old);
    if(old.photos!=widget.photos)_refreshOwnPhoto();
    if(old.rhythm!=widget.rhythm ||old.profile!=widget.profile){
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted)reload();
      });
    }
  }
  void _refreshOwnPhoto(){
    final photos=widget.photos.where((v)=>v['position']==0).toList();
    if(photos.isNotEmpty){
      ownerPhoto=widget.api.photoContent(photos.first['id'].toString());
    }else{ownerPhoto=null;}
  }
  Future<void> reload()async{
    if(!mounted)return;
    setState((){loading=true;notice=null;});
    try{
      final results=await Future.wait<dynamic>([
        widget.api.mySummaryB17().catchError((Object _)=><String,dynamic>{}),
        widget.api.datingStatus().catchError((Object _)=><String,dynamic>{}),
        widget.api.summaryAiCapabilityB17().catchError((Object _)=><String,dynamic>{}),
      ]);
      final state=Map<String,dynamic>.from(results[1] as Map);
      List<Map<String,dynamic>> found=[];
      Map<String,Map<String,dynamic>> cards={};
      if(state['enabled']==true){
        try{
          found=await widget.api.discoverB11();
          for(final candidate in found.take(10)){
            final id=(candidate['user_id']??'').toString();
            if(id.isEmpty)continue;
            try{
              final detail=await widget.api.candidateCardB17(id);
              if(detail['visible']==true)cards[id]=detail;
            }catch(_){/* No cross-member details without valid authorization. */}
          }
        }catch(_){
          if(mounted)setState(()=>notice=t(
            'No se pudieron actualizar los fits. Tus datos siguen privados.',
            'Could not refresh fits. Your information stays private.'));
        }
      }
      if(mounted)setState((){
        summary=Map<String,dynamic>.from(results[0] as Map);
        dating=state;aiAvailable=(results[2] as Map)['available']==true;
        candidates=found.where((x)=>cards.containsKey(x['user_id']?.toString())).toList();
        candidateCards=cards;page=0;
        photoRequests.clear();scores.clear();
      });
    }catch(_){
      if(mounted)setState(()=>notice=t('No se pudieron actualizar los datos.',
        'Unable to refresh data.'));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> optInAi() async{
    if(busy)return;
    final agreed=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:Text(t('Mi resumen de perfil','My profile summary')),
        content:Text(t(
          'Acepto que mis intereses, valores y respuestas generales se procesen '
          'mediante el proveedor de IA configurado para redactar un resumen '
          'en español e inglés. No se compartirán mis gimnasios, rutas, '
          'horarios, correo ni fecha de nacimiento. También autorizo mostrar '
          'el resumen a miembros verificados cuando mi perfil esté visible.',
          'I agree to share my general interests, values and lifestyle '
          'answers with the configured AI provider to draft bilingual '
          'profile summaries. Gym, routes, schedules, email and birth date '
          'are excluded. I also agree to show the summary to eligible '
          'verified members when my profile is visible.')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text(t('Cancelar','Cancel'))),
          FilledButton(
            key:const Key('b17-summary-optin-confirm'),
            onPressed:()=>Navigator.pop(ctx,true),
            child:Text(t('Aceptar y generar','Accept and generate'))),
        ],
      ));
    if(agreed!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      await widget.api.setSummaryConsentB17(ai:true,share:true);
      final result=await widget.api.regenerateSummaryB17();
      await reload();
      if(mounted)setState(()=>notice=result['status']=='ai_updated'
        ?t('Tu resumen con IA se actualizó.','Your AI summary was refreshed.')
        :t('Tu resumen básico está actualizado. La generación con IA '
            'depende de tener el proveedor configurado.',
            'Your base summary is current. AI generation requires '
            'an available provider.'));
    }catch(_){if(mounted)setState(()=>notice=t(
      'No fue posible activar el resumen. Inténtalo de nuevo.',
      'Could not activate the summary. Please retry.'));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> revokeShare() async{
    if(busy)return;
    setState(()=>busy=true);
    try{
      await widget.api.setSummaryConsentB17(ai:false,share:false);
      await reload();
    }catch(_){if(mounted)setState(()=>notice=t(
      'No se pudo retirar la autorización.','Could not withdraw permission.'));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> expressInterest(String id)async{
    if(busy)return;
    final agreed=await showDialog<bool>(context:context,builder:(ctx)=>
      AlertDialog(
        title:Text(t('¿Te interesa esta persona?','Interested in this member?')),
        content:Text(t('Solo habrá match si ambas personas muestran interés.',
          'A match only happens after mutual interest.')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text(t('Cancelar','Cancel'))),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text(t('Mostrar interés','Show interest'))),
        ],
      ));
    if(agreed!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      final result=await widget.api.likeB11(id);
      if(mounted)setState(()=>notice=result=='matched'
        ?t('¡Interés mutuo confirmado!','Mutual interest confirmed!')
        :t('Interés privado registrado.','Private interest saved.'));
      await reload();
    }catch(_){if(mounted)setState(()=>notice=t(
      'No fue posible registrar el interés.',
      'Unable to record your interest.'));}
    finally{if(mounted)setState(()=>busy=false);}
  }

  BoxDecoration _panel({bool secondary=false})=>BoxDecoration(
    borderRadius:BorderRadius.circular(29),
    border:Border.all(color:secondary
      ?const Color(0xFF9476E6).withValues(alpha:.65)
      :const Color(0xFF6EB5E2).withValues(alpha:.55),width:1.2),
    gradient:LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:secondary
        ?const [Color(0xFF1A254F),Color(0xFF1E2147),Color(0xFF2C2151)]
        :const [Color(0xFF15264D),Color(0xFF1B234B),Color(0xFF2B2149)]),
    boxShadow:[BoxShadow(
      color:FitDateColors.pulseViolet.withValues(alpha:.1),
      blurRadius:22,offset:const Offset(0,9))],
  );

  Widget _pill(int index){
    final en=english;
    const icons=[Icons.directions_run_rounded,
      Icons.wb_twilight_outlined,Icons.connect_without_contact_outlined];
    final labels=en
      ?const ['How I Move','How I Live','How I Relate']
      :const ['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
    final accents=[FitDateColors.aqua,
      FitDateColors.apricot,FitDateColors.lilac];
    return Material(color:Colors.transparent,
      child:InkWell(
        key:Key('b17-pillar-'+index.toString()),
        onTap:()=>widget.onConfigurePillar(index),
        borderRadius:BorderRadius.circular(22),
        child:Padding(
          padding:const EdgeInsets.symmetric(vertical:7,horizontal:3),
          child:Row(children:[
            Container(
              width:190,
              padding:const EdgeInsets.symmetric(
                vertical:13,horizontal:13),
              decoration:BoxDecoration(
                borderRadius:BorderRadius.circular(23),
                color:const Color(0xFF0F1938).withValues(alpha:.8),
                border:Border.all(color:accents[index].withValues(alpha:.7)),
              ),
              child:Row(children:[
                Icon(icons[index],color:accents[index],size:21),
                const SizedBox(width:12),
                Expanded(child:Text(labels[index],
                  style:const TextStyle(
                    fontWeight:FontWeight.w700,fontSize:14))),
              ]),
            ),
            const SizedBox(width:14),
            Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.end,children:[
                Text(progress[index].toString()+'%',
                  key:Key('b17-progress-'+index.toString()),
                  style:const TextStyle(fontWeight:FontWeight.w700)),
                const SizedBox(height:7),
                ClipRRect(borderRadius:BorderRadius.circular(20),
                  child:LinearProgressIndicator(
                    value:progress[index]/100,minHeight:8,
                    color:accents[index],
                    backgroundColor:const Color(0xFF414667))),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  Widget _storyCard(){
    final text=(summary[english?'summary_en':'summary_es']??'').toString();
    final isAI=summary['mode']=='ai';
    final shared=summary['share_consented']==true;
    return Container(
      key:const Key('b17-ai-story'),
      constraints:const BoxConstraints(minHeight:215),
      padding:const EdgeInsets.all(19),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(23),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.66)),
        gradient:LinearGradient(
          colors:[const Color(0xFF272852).withValues(alpha:.94),
            const Color(0xFF322A5C).withValues(alpha:.94)]),
        boxShadow:[BoxShadow(color:FitDateColors.lilac.withValues(alpha:.09),
          blurRadius:18)],
      ),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          const Icon(Icons.auto_awesome,color:FitDateColors.lilac),
          const SizedBox(width:10),
          Expanded(child:Text(t('Tu perfil, en resumen','Your story, in brief'),
            style:const TextStyle(
              fontWeight:FontWeight.w800,fontSize:18))),
          Container(
            padding:const EdgeInsets.symmetric(horizontal:9,vertical:3),
            decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),
              border:Border.all(color:FitDateColors.lilac)),
            child:Text(isAI?'IA':t('PERFIL','PROFILE'),
              style:const TextStyle(
                fontWeight:FontWeight.bold,fontSize:11,
                color:FitDateColors.lilac))),
        ]),
        const SizedBox(height:12),
        Text(text.isNotEmpty?text:t(
          'Completa tus tres pilares para crear tu historia. '
          'No se inventarán intereses ni logros.',
          'Complete your lifestyle pillars to build your story. '
          'No interests or achievements are invented.'),
          key:const Key('b17-summary-copy'),
          style:const TextStyle(fontSize:15.5,height:1.58,
            fontStyle:FontStyle.italic,color:FitDateColors.pearl)),
        const SizedBox(height:13),
        if(!shared)
          SizedBox(width:double.infinity,
            child:TextButton(
              key:const Key('b17-summary-ai-consent'),
              onPressed:busy?null:optInAi,
              child:Row(children:[
                const Icon(Icons.auto_awesome_outlined,size:17),
                const SizedBox(width:8),
                Expanded(child:Text(
                  aiAvailable?t('Generar con IA y compartir',
                    'Generate with AI and share')
                  :t('Configurar resumen y privacidad',
                    'Set up summary and privacy'),
                  maxLines:2,overflow:TextOverflow.ellipsis)),
              ]),
            ),
          ),
        if(shared)
          Row(children:[
            const Icon(Icons.verified_user_outlined,
              size:15,color:FitDateColors.aqua),
            const SizedBox(width:5),
            Expanded(child:Text(t(
              'Visible solo para miembros elegibles si habilitas tu perfil.',
              'Visible to eligible members only if your profile is enabled.'),
              style:const TextStyle(fontSize:11,
                color:FitDateColors.muted))),
            IconButton(
              key:const Key('b17-revoke-summary'),
              tooltip:t('Dejar de compartir','Stop sharing'),
              icon:const Icon(Icons.visibility_off_outlined,size:19),
              onPressed:busy?null:revokeShare),
          ]),
      ]),
    );
  }

  Widget _portrait(){
    final hasPhoto=ownerPhoto!=null;
    final pending=widget.photos.any((x)=>x['position']==0 &&
      x['moderation_state']!='approved');
    return Container(
      key:const Key('b17-my-photo'),
      constraints:const BoxConstraints(minHeight:230),
      height:253,
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(24),
        border:Border.all(color:FitDateColors.aqua.withValues(alpha:.55)),
        color:const Color(0xFF27264C)),
      child:ClipRRect(borderRadius:BorderRadius.circular(23),
        child:Stack(fit:StackFit.expand,children:[
          if(hasPhoto)
            FutureBuilder<Uint8List>(
              future:ownerPhoto,builder:(ctx,snapshot)=>
                snapshot.hasData
                  ?Image.memory(snapshot.data!,fit:BoxFit.cover)
                  :const Center(child:Icon(Icons.person_outline,
                    size:78,color:FitDateColors.lilac)))
          else const Center(child:Icon(Icons.person_outline,
            size:78,color:FitDateColors.lilac)),
          Positioned(bottom:0,left:0,right:0,
            child:Container(
              padding:const EdgeInsets.all(10),
              decoration:BoxDecoration(gradient:LinearGradient(
                begin:Alignment.topCenter,end:Alignment.bottomCenter,
                colors:[Colors.transparent,
                  const Color(0xFF0C1230).withValues(alpha:.98)])),
              child:TextButton.icon(
                onPressed:widget.onUploadPhoto,
                icon:const Icon(Icons.camera_alt_outlined,size:19),
                label:Text(hasPhoto
                  ?(pending?t('Foto pendiente','Photo pending')
                    :t('Tu foto de perfil','Your profile photo'))
                  :t('Añadir mi foto','Add my photo'),
                  maxLines:2),
              )),
          ),
        ])),
    );
  }

  Widget _heroPanel(BoxConstraints size){
    final wide=size.maxWidth>=1070;
    final medium=size.maxWidth>=740;
    final user=widget.profile['display_name']?.toString().trim()??'';
    final first=user.isEmpty?'':user.split(' ').first;
    final title=t('Hola','Hello')+(first.isEmpty?'':', '+first)+
      t('. Sigue tu ritmo.','. Follow your rhythm.');
    final titleStyle=TextStyle(fontSize:wide?33:26,
      fontWeight:FontWeight.w800,color:FitDateColors.pearl);
    return Container(
      key:const Key('fitted-member-dashboard'),
      decoration:_panel(),
      clipBehavior:Clip.antiAlias,
      child:Stack(children:[
        const Positioned.fill(child:IgnorePointer(
          child:Opacity(opacity:.35,child:FittedRhythmLines()))),
        Padding(padding:EdgeInsets.all(wide?26:18),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(
              padding:const EdgeInsets.symmetric(
                horizontal:15,vertical:9),
              decoration:BoxDecoration(
                borderRadius:BorderRadius.circular(22),
                border:Border.all(color:FitDateColors.aqua.withValues(alpha:.35)),
                color:FitDateColors.aqua.withValues(alpha:.09)),
              child:Row(mainAxisSize:MainAxisSize.min,children:[
                Container(width:26,height:3,
                  decoration:BoxDecoration(color:FitDateColors.aqua,
                    borderRadius:BorderRadius.circular(4))),
                const SizedBox(width:12),
                Text(t('AFINIDAD DE ESTILO DE VIDA',
                      'LIFESTYLE AFFINITY'),
                  style:const TextStyle(color:FitDateColors.aqua,
                    fontSize:11,fontWeight:FontWeight.bold,
                    letterSpacing:1.3)),
              ])),
            const SizedBox(height:15),
            Text(title,style:titleStyle),
            const SizedBox(height:7),
            Text(t(
              'Conoce personas que comparten tu forma de vivir. '
              'La afinidad empieza en tu ritmo, tus valores y tus intenciones.',
              'Meet people who share your lifestyle. '
              'Affinity starts with your rhythm, values and intentions.'),
              style:TextStyle(fontSize:wide?16:14.5,
                color:FitDateColors.muted,height:1.5)),
            const SizedBox(height:22),
            if(wide)
              Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(flex:38,child:Column(
                  children:[for(var i=0;i<3;i++)_pill(i)])),
                const SizedBox(width:22),
                Expanded(flex:37,child:_storyCard()),
                const SizedBox(width:20),
                Expanded(flex:25,child:_portrait()),
              ])
            else if(medium)
              Column(children:[
                Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Expanded(child:Column(children:[
                    for(var i=0;i<3;i++)_pill(i)])),
                  const SizedBox(width:15),
                  SizedBox(width:235,child:_portrait()),
                ]),
                const SizedBox(height:15),
                _storyCard(),
              ])
            else Column(children:[
              for(var i=0;i<3;i++)_pill(i),
              const SizedBox(height:12),
              _storyCard(),
              const SizedBox(height:14),
              _portrait(),
            ]),
            const SizedBox(height:16),
            const Divider(color:Color(0xFF484E78)),
            const SizedBox(height:4),
            Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Icon(Icons.info_outline,size:17,
                color:FitDateColors.muted),
              const SizedBox(width:10),
              Expanded(child:Text(t(
                'Este es el resumen de tu perfil que podrán ver personas '
                'elegibles con tu permiso. Se actualiza al guardar cambios.',
                'This is the summary eligible people can see with your '
                'permission. It updates when you save profile changes.'),
                style:const TextStyle(
                  color:FitDateColors.muted,fontSize:12.5,height:1.5))),
            ]),
          ]),
        ),
      ]),
    );
  }

  List<({String title,String subtitle,bool ok,VoidCallback act})> get checks{
    final prof=widget.profile['onboarding_complete']==true &&total>=75;
    final age=dating['age_verified']==true;
    final prefs=dating['participation_requested']==true;
    final consent=dating['dating_consent']==true;
    final ready=dating['enabled']==true;
    return [
      (title:t('Completar perfil','Complete profile'),
        subtitle:t('Tu estilo de vida y afinidad.',
          'Your lifestyle and compatibility.'),ok:prof,
        act:()=>widget.onConfigurePillar(
          progress.indexWhere((v)=>v<100)<0?0:progress.indexWhere((v)=>v<100))),
      (title:t('Verificar mayoría de edad e identidad',
        'Verify age and identity'),
        subtitle:t('Una revisión documental humana y privada.',
          'A private, human document review.'),ok:age,
        act:widget.onVerifyAge),
      (title:t('Configurar preferencias','Set preferences'),
        subtitle:t('Define qué buscas en una conexión.',
          'Define what matters in a connection.'),ok:prefs,
        act:widget.onDiscover),
      (title:t('Aceptar privacidad y seguridad',
        'Accept privacy and safety'),
        subtitle:t('Tu consentimiento es independiente y revocable.',
          'Separate, revocable consent.'),ok:consent,
        act:widget.onDiscover),
      (title:t('Activar perfil y verificación del servicio',
        'Activate profile and service eligibility'),
        subtitle:t('El sistema valida tus requisitos y moderación.',
          'The service checks your eligibility and moderation.'),
        ok:ready,act:widget.onDiscover),
    ];
  }

  Widget _checklist(){
    final entries=checks;
    final done=entries.where((e)=>e.ok).length;
    return Container(
      key:const Key('b17-dating-checklist'),
      padding:const EdgeInsets.all(18),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(23),
        border:Border.all(color:FitDateColors.lilac.withValues(alpha:.52)),
        gradient:const LinearGradient(colors:[
          Color(0xFF263156),Color(0xFF30264F)])),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Text(t('Preparación para hacer match',
              'Getting ready to match'),
            style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold))),
          SizedBox(width:39,height:39,child:Stack(
            alignment:Alignment.center,children:[
              CircularProgressIndicator(
                value:done/entries.length,strokeWidth:4,
                color:FitDateColors.lilac,
                backgroundColor:FitDateColors.outline),
              Text((done*100~/entries.length).toString(),
                style:const TextStyle(
                  fontSize:11,fontWeight:FontWeight.bold)),
            ])),
        ]),
        const SizedBox(height:15),
        for(var i=0;i<entries.length;i++)...[
          const Divider(height:1,color:Color(0xFF4A4E76)),
          Material(color:Colors.transparent,child:InkWell(
            key:Key('b17-readiness-'+i.toString()),
            borderRadius:BorderRadius.circular(10),
            onTap:entries[i].ok?null:entries[i].act,
            child:Padding(
              padding:const EdgeInsets.symmetric(vertical:11),
              child:Row(children:[
                Icon(entries[i].ok?Icons.check_circle:
                  Icons.radio_button_unchecked,
                  color:entries[i].ok?FitDateColors.aqua:
                    FitDateColors.lilac,size:22),
                const SizedBox(width:13),
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(entries[i].title,style:const TextStyle(
                      fontSize:13,fontWeight:FontWeight.w700)),
                    const SizedBox(height:3),
                    Text(entries[i].subtitle,
                      style:const TextStyle(fontSize:11.5,
                        color:FitDateColors.muted)),
                  ])),
                const SizedBox(width:9),
                Icon(entries[i].ok?Icons.check:
                  Icons.chevron_right,
                  color:entries[i].ok?FitDateColors.aqua:
                    FitDateColors.pearl,size:19),
              ]),
            ),
          )),
        ],
      ]),
    );
  }

  Future<Uint8List>? photoOf(String id,String key){
    if(key.isEmpty)return null;
    return photoRequests.putIfAbsent(id,
      ()=>widget.api.approvedCandidatePhotoB17(key));
  }
  Widget _fitCard(Map<String,dynamic> person){
    final id=(person['user_id']??'').toString();
    final data=candidateCards[id]??{};
    final summaryText=(data[english?'summary_en':'summary_es']??'').toString();
    final photoKey=(data['photo_key']??'').toString();
    final avatar=photoOf(id,photoKey);
    final name=(person['display_name']??'').toString();
    return Container(
      key:Key('b17-real-fit-'+id),
      padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(19),
        color:const Color(0xFF2C2B57),
        border:Border.all(
          color:FitDateColors.lilac.withValues(alpha:.52))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          ClipRRect(borderRadius:BorderRadius.circular(13),
            child:SizedBox(width:88,height:118,
              child:avatar==null?const ColoredBox(
                color:Color(0xFF37345A),
                child:Icon(Icons.person_outline,size:40))
              :FutureBuilder<Uint8List>(future:avatar,builder:(ctx,snapshot)=>
                snapshot.hasData
                  ?Image.memory(snapshot.data!,fit:BoxFit.cover)
                  :const ColoredBox(color:Color(0xFF37345A),
                    child:Icon(Icons.person_outline,size:40))))),
          const SizedBox(width:11),
          Expanded(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Flexible(child:Text(name,maxLines:1,
                  overflow:TextOverflow.ellipsis,
                  style:const TextStyle(
                    fontSize:16,fontWeight:FontWeight.bold))),
                const SizedBox(width:5),
                const Icon(Icons.verified_user_outlined,size:16,
                  color:FitDateColors.aqua),
              ]),
              const SizedBox(height:5),
              Text(summaryText.isNotEmpty?summaryText:
                t('Comparte tu ritmo y descubre una conexión real.',
                  'Explore a real connection at your pace.'),
                maxLines:5,overflow:TextOverflow.ellipsis,
                style:const TextStyle(
                  color:FitDateColors.muted,fontSize:11.5,height:1.4)),
            ],
          )),
        ]),
        const SizedBox(height:10),
        FutureBuilder<Map<String,dynamic>>(
          future:scores.putIfAbsent(id,
            ()=>widget.api.compatibilityB11(id)),
          builder:(ctx,snapshot){
            final data=snapshot.data;
            if(!snapshot.hasData||data?['available']!=true||
              data?['percent'] is! num){
              return Text(t('Afinidad por descubrir',
                'Explore your affinity'),
                style:const TextStyle(fontSize:11,
                  color:FitDateColors.aqua));
            }
            return Text(t('Ritmo afín · ','Rhythm fit · ')+
              (data!['percent'] as num).round().toString()+'%',
              style:const TextStyle(
                fontWeight:FontWeight.bold,fontSize:11.5,
                color:FitDateColors.aqua));
          }),
        const SizedBox(height:7),
        Align(alignment:Alignment.centerRight,
          child:TextButton.icon(
            key:Key('b17-like-'+id),onPressed:busy?null:()=>expressInterest(id),
            icon:const Icon(Icons.favorite_border,size:16),
            label:Text(t('Me interesa','Interested')))),
      ]),
    );
  }

  Widget _candidateView(double width){
    final pageSize=width>=630?2:1;
    final count=candidates.length;
    if(loading)return const Center(child:CircularProgressIndicator());
    if(dating['enabled']!=true)return _emptyFitView(locked:true);
    if(count==0)return _emptyFitView(locked:false);
    final pages=(count/pageSize).ceil();
    final selected=page.clamp(0,pages-1);
    final start=selected*pageSize;
    final visible=candidates.skip(start).take(pageSize).toList();
    return Column(children:[
      Row(children:[
        IconButton(
          key:const Key('b17-fit-prev'),
          tooltip:t('Anterior','Previous'),
          onPressed:pages<=1?null:()=>setState(()=>
            page=(selected-1+pages)%pages),
          icon:const Icon(Icons.chevron_left,color:FitDateColors.lilac)),
        Expanded(child:Row(children:[
          for(var i=0;i<visible.length;i++)...[
            if(i>0)const SizedBox(width:10),
            Expanded(child:_fitCard(visible[i])),
          ],
        ])),
        IconButton(
          key:const Key('b17-fit-next'),
          tooltip:t('Siguiente','Next'),
          onPressed:pages<=1?null:()=>setState(()=>page=(selected+1)%pages),
          icon:const Icon(Icons.chevron_right,color:FitDateColors.lilac)),
      ]),
      const SizedBox(height:12),
      Wrap(spacing:7,children:[
        for(var i=0;i<pages;i++)
          AnimatedContainer(
            duration:const Duration(milliseconds:160),
            width:i==selected?12:8,height:8,
            decoration:BoxDecoration(
              shape:BoxShape.circle,
              color:i==selected?FitDateColors.lilac:FitDateColors.outline)),
      ]),
    ]);
  }
  Widget _emptyFitView({required bool locked}){
    return Container(
      key:const Key('b17-fits-empty-real'),
      constraints:const BoxConstraints(minHeight:217),
      padding:const EdgeInsets.symmetric(vertical:23,horizontal:19),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(21),
        color:const Color(0xFF181C40).withValues(alpha:.65),
        border:Border.all(
          color:FitDateColors.outline.withValues(alpha:.7))),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        const Icon(Icons.people_alt_outlined,size:45,
          color:FitDateColors.lilac),
        const SizedBox(height:14),
        Text(t(locked?'Completa los requisitos para ver tus fits':
           'Aún no hay personas compatibles autorizadas',
           locked?'Finish the checklist to see your fits':
           'No eligible compatible members yet'),
          textAlign:TextAlign.center,
          style:const TextStyle(
            fontSize:15,fontWeight:FontWeight.bold)),
        const SizedBox(height:7),
        Text(t(locked
          ?'Aquí aparecerán perfiles reales después de verificar tu '
            'cuenta y activar tus preferencias.'
          :'Mostraremos perfiles reales cuando haya miembros elegibles '
            'que correspondan a tu búsqueda.',
          locked
          ?'Real profiles appear here only after verification '
            'and activating your preferences.'
          :'Real profiles will appear when eligible people '
            'match your search preferences.'),
          textAlign:TextAlign.center,
          style:const TextStyle(
            fontSize:12,color:FitDateColors.muted,height:1.5)),
      ]),
    );
  }

  Widget _matchesPanel(BoxConstraints constraints){
    final wide=constraints.maxWidth>=1010;
    return Container(
      key:const Key('b17-fits-panel'),
      decoration:_panel(secondary:true),
      padding:EdgeInsets.all(wide?26:18),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Container(
            width:53,height:53,
            decoration:BoxDecoration(
              color:FitDateColors.lilac.withValues(alpha:.17),
              borderRadius:BorderRadius.circular(16)),
            child:const Icon(Icons.people_alt_outlined,
              color:FitDateColors.lilac,size:27)),
          const SizedBox(width:14),
          Expanded(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(t('Tus próximos fits','Your next fits'),
                style:const TextStyle(
                  fontSize:25,fontWeight:FontWeight.w800)),
              const SizedBox(height:4),
              Text(t(
                'Completa los pasos, activa tu perfil y empieza a conocer '
                'personas compatibles contigo.',
                'Complete the steps, activate your profile and meet '
                'people compatible with you.'),
                style:const TextStyle(fontSize:12.5,
                  color:FitDateColors.muted,height:1.45)),
            ]),
          ),
        ]),
        const SizedBox(height:20),
        if(wide) Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(flex:39,child:_checklist()),
          const SizedBox(width:23),
          Container(width:1,height:330,color:FitDateColors.outline),
          const SizedBox(width:23),
          Expanded(flex:61,child:_fitViewPart(constraints.maxWidth*.48)),
        ])
        else Column(children:[
          _checklist(),const SizedBox(height:19),
          _fitViewPart(constraints.maxWidth),
        ]),
        if(notice!=null)Padding(
          padding:const EdgeInsets.only(top:12),
          child:Text(notice!,key:const Key('b17-home-notice'),
            style:const TextStyle(color:FitDateColors.muted))),
      ]),
    );
  }

  Widget _fitViewPart(double width)=>Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        const Icon(Icons.groups_outlined,
          color:FitDateColors.lilac,size:24),
        const SizedBox(width:9),
        Expanded(child:Text(t('Así se verán tus fits','Your compatible people'),
          style:const TextStyle(fontSize:17,
            fontWeight:FontWeight.w800))),
        if(dating['enabled']!=true) Container(
          padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),
            border:Border.all(color:FitDateColors.lilac)),
          child:Text(t('SIN ACTIVAR','NOT ACTIVE'),
            style:const TextStyle(
              fontSize:10,color:FitDateColors.lilac))),
      ]),
      const SizedBox(height:4),
      Text(t(
        'Solo mostramos personas elegibles y fotos aprobadas.',
        'Only eligible people and approved photos are displayed.'),
        style:const TextStyle(
          color:FitDateColors.muted,fontSize:12.5)),
      const SizedBox(height:14),
      _candidateView(width),
      const SizedBox(height:14),
      Center(child:FilledButton.icon(
        key:const Key('b17-discover-fits'),
        onPressed:widget.onDiscover,
        icon:const Icon(Icons.explore_outlined),
        label:Text(t('Descubrir conexiones','Discover connections')))),
    ],
  );

  @override
  Widget build(BuildContext context)=>Column(children:[
    LayoutBuilder(builder:(ctx,limits)=>_heroPanel(limits)),
    const SizedBox(height:17),
    LayoutBuilder(builder:(ctx,limits)=>_matchesPanel(limits)),
  ]);
}
