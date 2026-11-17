import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/fit_ia_repository.dart';
import '../core/fitted_locale.dart';
import '../core/live_brand.dart';
import '../widgets/fit_ia_mascot.dart';

/// Fit-IA v3 is AI-only. Curated questions are model guidance, never a
/// mandatory fixed questionnaire. Text is durably stored before AI inference.
class FitIaNaturalChatPage extends StatefulWidget{
  const FitIaNaturalChatPage({super.key,required this.repository,
    this.initialPillar=0}):assert(initialPillar>=0&&initialPillar<3);
  final FitIaRepository repository;
  final int initialPillar;
  @override
  State<FitIaNaturalChatPage> createState()=>_FitIaNaturalChatPageState();
}
class _FitIaNaturalChatPageState extends State<FitIaNaturalChatPage>{
  final editor=TextEditingController();
  final scroll=ScrollController();
  final drafts=<String,String>{};
  late int active;
  Map<String,dynamic>? data,insights;
  final older=<Map<String,dynamic>>[];
  bool olderHasMore=false,olderLoading=false;
  bool loading=true,sending=false,busyConsent=false;
  String? issue,notice,pendingPreview;
  static const keys=['move','live','relate'];
  static const icons=[Icons.directions_run_outlined,
    Icons.spa_outlined,Icons.people_outline];
  bool get english=>FittedLocaleScope.languageOf(context)=='en';
  String get assistantName=>LiveBrandScope.of(context).assistantName;
  String tr(String es,String en)=>english?en:es;
  String get pillar=>keys[active];
  bool get enabled=>data?['ai_enabled']==true;
  bool get providerUnavailable=>data?['status']=='provider_unavailable';
  bool get awaiting=>data?['needs_response']==true;
  bool get unavailable=>data?['status']=='ai_unavailable';
  List<Map<String,dynamic>> get history{
    final raw=data?['messages'];
    final recent=raw is List?raw.whereType<Map>()
      .map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
    return [...older,...recent];
  }
  bool get hasEarlier=>older.isEmpty
    ?(data?['has_more']==true):olderHasMore;
  List<String> get options{
    final raw=data?['quick_options'];
    if(!enabled||awaiting||raw is! List)return <String>[];
    return raw.whereType<String>().take(4).toList();
  }
  Map<String,dynamic> get depth{
    final raw=data?['depth'];
    return raw is Map?Map<String,dynamic>.from(raw):{};
  }
  Map<String,dynamic> get brief{
    final raw=data?['brief'];
    return raw is Map?Map<String,dynamic>.from(raw):{};
  }
  List<Map<String,dynamic>> get answers{
    final raw=insights?['answers'];
    return raw is List?raw.whereType<Map>()
      .map((x)=>Map<String,dynamic>.from(x)).toList():[];
  }
  @override
  void initState(){super.initState();active=widget.initialPillar;_load();}
  @override
  void dispose(){editor.dispose();scroll.dispose();super.dispose();}
  void _scrollBottom(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(mounted&&scroll.hasClients){
        unawaited(scroll.animateTo(scroll.position.maxScrollExtent,
          duration:const Duration(milliseconds:240),
          curve:Curves.easeOut));
      }
    });
  }
  Future<void> _load()async{
    final selected=pillar;
    setState((){loading=true;issue=null;});
    try{
      var result=await widget.repository.fitIaChatState(selected,
        locale:english?'en':'es');
      // A member's existing account-wide opt-in is sufficient. Repair the
      // legacy per-pillar flag without another permission dialog.
      if(result['ai_enabled']!=true && widget.repository is FitIaAccountConsentSync){
        final synced=await (widget.repository as FitIaAccountConsentSync)
          .fitIaSyncAccountConsent();
        if(synced){
          result=await widget.repository.fitIaChatState(selected,
            locale:english?'en':'es');
        }
      }
      if(!mounted||pillar!=selected)return;
      setState((){
        data=result;loading=false;
        older.clear();olderHasMore=false;
      });
      _scrollBottom();
      unawaited(_refreshInsights());
    }catch(_){
      if(mounted&&pillar==selected)setState((){
        loading=false;issue=tr(
          'No pudimos recuperar la charla. '
          'Tu historial guardado está a salvo.',
          'Could not load the chat. Your saved history is safe.');
      });
    }
  }
  Future<void> _refreshInsights()async{
    final selected=pillar;
    try{
      final details=await widget.repository.fitIaInsights(selected);
      if(mounted&&selected==pillar)setState(()=>insights=details);
    }catch(_){/* A sidebar failure must not block the conversation. */}
  }
  Future<void> _loadEarlier()async{
    if(olderLoading||!hasEarlier||history.isEmpty)return;
    final oldest=history.first['id'];
    if(oldest is! int)return;
    final key=pillar,oldMax=scroll.hasClients?scroll.position.maxScrollExtent:0.0;
    final oldOffset=scroll.hasClients?scroll.offset:0.0;
    setState(()=>olderLoading=true);
    try{
      final result=await widget.repository.fitIaChatOlder(key,oldest);
      if(!mounted||pillar!=key)return;
      final raw=result['messages'];
      final previous=raw is List?raw.whereType<Map>()
        .map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
      setState((){
        older.insertAll(0,previous);
        olderHasMore=result['has_more']==true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_){
        if(mounted&&scroll.hasClients){
          final added=scroll.position.maxScrollExtent-oldMax;
          scroll.jumpTo((oldOffset+added).clamp(
            0.0,scroll.position.maxScrollExtent));
        }
      });
    }catch(_){
      if(mounted)setState(()=>issue=tr(
        'No pudimos cargar los mensajes anteriores.',
        'Unable to load older messages.'));
    }finally{if(mounted)setState(()=>olderLoading=false);}
  }
  Future<void> _switch(int index)async{
    if(index==active||sending||loading)return;
    drafts[pillar]=editor.text;
    setState((){active=index;data=null;insights=null;notice=null;});
    editor.text=drafts[pillar]??'';
    await _load();
  }
  String _uuid(){
    final b=List<int>.generate(16,(_)=>Random.secure().nextInt(256));
    b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;
    final s=b.map((x)=>x.toRadixString(16).padLeft(2,'0')).join();
    return s.substring(0,8)+'-'+s.substring(8,12)+'-'+
      s.substring(12,16)+'-'+s.substring(16,20)+'-'+s.substring(20);
  }
  Future<void> _send([String? suggested])async{
    final value=(suggested??editor.text).trim();
    if(!enabled||loading||sending||awaiting||
      value.isEmpty||value.length>1500)return;
    final key=pillar;
    setState((){
      sending=true;issue=null;notice=null;pendingPreview=value;
    });
    try{
      final result=await widget.repository.fitIaChatSend(
        key,value,_uuid(),locale:english?'en':'es');
      if(!mounted||key!=pillar)return;
      setState((){
        data=result;pendingPreview=null;
        if(suggested==null)editor.clear();
        if(result['status']=='ai_unavailable'){
          notice=tr('Guardé tu mensaje. Puedes recuperar '
            'la respuesta de Fit-IA sin enviarlo otra vez.',
            'Your message is saved. Recover Fit-IA’s response '
            'without resending it.');
        }
      });
      drafts[key]=editor.text;
      _scrollBottom();unawaited(_refreshInsights());
    }catch(_){
      if(mounted&&key==pillar)setState((){
        pendingPreview=null;
        if(suggested!=null)editor.text=value;
        issue=tr(
          'No se confirmó el envío. Recarga la conversación '
          'antes de intentar enviarlo otra vez.',
          'Send not confirmed. Reload the conversation '
          'before sending anything again.');
      });
    }finally{if(mounted)setState(()=>sending=false);}
  }
  Future<void> _retry()async{
    if(sending||loading||!enabled)return;
    final key=pillar;
    setState((){sending=true;issue=null;notice=null;});
    try{
      final reply=await widget.repository.fitIaChatRetry(key,
        locale:english?'en':'es');
      if(!mounted||pillar!=key)return;
      setState((){
        data=reply;
        if(reply['status']=='ai_unavailable'){
          notice=tr('El asistente aún no responde; tu texto permanece guardado.',
            'The assistant is still unavailable; your text remains saved.');
        }
      });
      _scrollBottom();unawaited(_refreshInsights());
    }catch(_){
      if(mounted)setState(()=>issue=tr(
        'No fue posible recuperar la respuesta. Reintenta.',
        'Could not recover the reply. Please retry.'));
    }finally{if(mounted)setState(()=>sending=false);}
  }
  Future<void> _disable()async{
    if(busyConsent)return;
    setState(()=>busyConsent=true);
    try{
      await widget.repository.fitIaConsent(false);
      if(mounted)await _load();
    }catch(_){
      if(mounted)setState(()=>issue=tr('No pudimos cambiar el permiso de IA.',
        'Could not change the AI permission.'));
    }finally{if(mounted)setState(()=>busyConsent=false);}
  }
  Future<void> _erase()async{
    final confirmed=await showDialog<bool>(context:context,
      builder:(dialog)=>AlertDialog(
        title:Text(tr('Eliminar mis conversaciones','Delete my chats')),
        content:Text(tr('Se borrará el historial privado y el resumen '
          'de los tres pilares. No se puede deshacer.',
          'All private messages and summaries from three pillars '
          'will be permanently removed. This cannot be undone.')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),
            child:Text(tr('Cancelar','Cancel'))),
          FilledButton(key:const Key('fit-ia-confirm-delete'),
            onPressed:()=>Navigator.pop(dialog,true),
            child:Text(tr('Eliminar todo','Delete all'))),
        ],
      ));
    if(confirmed!=true||!mounted)return;
    try{
      await widget.repository.fitIaDeleteMyData();
      drafts.clear();editor.clear();
      if(mounted)await _load();
    }catch(_){
      if(mounted)setState(()=>issue=tr('No pudimos borrar el historial.',
        'Could not delete chat history.'));
    }
  }
  Widget _tabs(){
    return SingleChildScrollView(scrollDirection:Axis.horizontal,
      child:Row(children:[
        for(var i=0;i<3;i++)Padding(
          padding:const EdgeInsets.only(right:8),
          child:ChoiceChip(
            key:Key('fit-ia-pillar-$i'),
            selected:active==i,
            avatar:Icon(icons[i],size:18),
            label:Text(english?FitIaDepth.labelsEn[i]:FitIaDepth.labelsEs[i]),
            onSelected:(_)=>_switch(i),
            shape:RoundedRectangleBorder(
              borderRadius:BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }
  Widget _bubble(Map<String,dynamic> item){
    final own=item['role']=='user';
    final theme=Theme.of(context);
    final value=(english?item['text_en']:item['text'])??
      item['text']??'';
    return Align(alignment:own?Alignment.centerRight:Alignment.centerLeft,
      child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:505),
        child:Padding(padding:const EdgeInsets.only(bottom:13),
          child:Row(
            crossAxisAlignment:CrossAxisAlignment.end,
            mainAxisSize:MainAxisSize.min,
            children:[
              if(!own)...[
                const FitIaMascot(size:33),
                const SizedBox(width:7),
              ],
              Flexible(child:Container(
                decoration:BoxDecoration(
                  color:own?theme.colorScheme.primaryContainer:
                    theme.colorScheme.surfaceContainerHigh,
                  borderRadius:BorderRadius.only(
                    topLeft:const Radius.circular(17),
                    topRight:const Radius.circular(17),
                    bottomLeft:Radius.circular(own?17:5),
                    bottomRight:Radius.circular(own?5:17)),
                  border:Border.all(color:theme.colorScheme.outline
                    .withValues(alpha:.15)),
                ),
                padding:const EdgeInsets.all(13),
                child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(own?tr('Tú','You'):assistantName,
                      style:theme.textTheme.labelSmall?.copyWith(
                        color:theme.colorScheme.primary,
                        fontWeight:FontWeight.w800)),
                    const SizedBox(height:5),
                    Text(value.toString(),
                      style:theme.textTheme.bodyLarge?.copyWith(height:1.43)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
  Widget _history(){
    if(loading)return const Center(child:CircularProgressIndicator());
    if(data==null)return Center(child:FilledButton.icon(
      onPressed:_load,icon:const Icon(Icons.refresh),
      label:Text(tr('Reintentar','Retry'))));
    return ListView(
      key:const Key('fit-ia-chat-history'),
      controller:scroll,padding:const EdgeInsets.all(15),
      children:[
        if(hasEarlier)Center(child:TextButton.icon(
          key:const Key('fit-ia-load-earlier'),
          onPressed:olderLoading?null:_loadEarlier,
          icon:const Icon(Icons.history_outlined),
          label:Text(tr('Mostrar mensajes anteriores',
            'Load earlier messages')))),
        for(final entry in history)_bubble(entry),
        if(pendingPreview!=null)
          _bubble({'role':'user','text':pendingPreview}),
        if(sending)
          Padding(padding:const EdgeInsets.all(12),
            child:Row(mainAxisSize:MainAxisSize.min,children:[
              const FitIaMascot(size:27),
              const SizedBox(width:8),
              Text(tr('$assistantName está pensando…','$assistantName is thinking…')),
              const SizedBox(width:9),
              const SizedBox(width:14,height:14,
                child:CircularProgressIndicator(strokeWidth:2)),
            ])),
        if(awaiting&&!sending&&enabled)
          OutlinedButton.icon(
            key:const Key('fit-ia-retry'),
            onPressed:_retry,
            icon:const Icon(Icons.refresh_outlined),
            label:Text(tr('Recuperar respuesta pendiente',
              'Recover pending reply'))),
      ],
    );
  }
  Widget _composer(){
    final theme=Theme.of(context);
    if(!enabled){
      return Padding(padding:const EdgeInsets.all(16),
        child:Column(mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text(providerUnavailable
              ?tr('El servicio de IA no está disponible',
                'The AI service is unavailable')
              :tr('Conversación con IA no disponible',
                'AI conversation unavailable'),
              style:theme.textTheme.titleMedium),
            const SizedBox(height:8),
            Text(providerUnavailable
              ?tr('Tu autorización ya está registrada. El servidor de IA '
                'necesita ser configurado por el administrador. Recargar '
                'no resolverá el problema hasta restaurar el servicio.',
                'Your AI permission is recorded. The administrator must '
                'restore the AI provider. Reloading will not fix this '
                'until the service is available.')
              :tr('Comprueba en Cuenta → Configuración que autorizaste '
                'la IA durante el registro. Si ya la autorizaste, recarga.',
                'Check your account settings for the AI choice made during '
                'registration. If already enabled, reload.'),
              style:theme.textTheme.bodySmall),
            const SizedBox(height:11),
            OutlinedButton.icon(
              key:const Key('fit-ia-reload-consent'),
              onPressed:loading||providerUnavailable?null:_load,
              icon:const Icon(Icons.refresh_outlined),
              label:Text(tr('Recargar conversación','Reload chat'))),
          ]),
      );
    }
    return Container(
      padding:const EdgeInsets.fromLTRB(13,12,13,14),
      decoration:BoxDecoration(
        color:theme.colorScheme.surface,
        border:Border(top:BorderSide(
          color:theme.colorScheme.outline.withValues(alpha:.16)))),
      child:Column(mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          if(options.isNotEmpty)...[
            Text(tr('Responde rápido o escribe a tu manera',
              'Reply quickly or in your own words'),
              style:theme.textTheme.bodySmall),
            const SizedBox(height:8),
            Wrap(spacing:7,runSpacing:7,children:[
              for(var i=0;i<options.length;i++)
                ActionChip(
                  key:Key('fit-ia-quick-option-$i'),
                  onPressed:sending||awaiting?null:()=>_send(options[i]),
                  avatar:const Icon(Icons.bolt_outlined,size:17),
                  label:Text(options[i])),
            ]),
            const SizedBox(height:10),
          ],
          Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
            Expanded(child:TextField(
              key:const Key('fit-ia-message-input'),
              controller:editor,enabled:!sending&&!awaiting,
              minLines:1,maxLines:3,maxLength:1500,
              textInputAction:TextInputAction.send,
              onSubmitted:(_)=>_send(),
              decoration:InputDecoration(
                hintText:tr('Escribe lo que de verdad piensas…',
                  'Say what you really think…'),
                counterText:'',
                border:OutlineInputBorder(
                  borderRadius:BorderRadius.circular(15)),
                contentPadding:const EdgeInsets.symmetric(
                  horizontal:13,vertical:12))),
            ),
            const SizedBox(width:8),
            IconButton.filled(
              key:const Key('fit-ia-send'),
              tooltip:tr('Enviar','Send'),
              onPressed:sending||awaiting?null:()=>_send(),
              icon:const Icon(Icons.arrow_upward_rounded)),
          ]),
        ]),
    );
  }
  Widget _leftPane(){
    final theme=Theme.of(context);
    return Card(margin:EdgeInsets.zero,clipBehavior:Clip.antiAlias,
      child:Column(children:[
        Padding(padding:const EdgeInsets.all(14),
          child:Row(children:[
            const FitIaMascot(size:54),const SizedBox(width:12),
            Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(assistantName,style:theme.textTheme.titleLarge?.copyWith(
                  fontWeight:FontWeight.w800)),
                Text(english?FitIaDepth.labelsEn[active]:
                  FitIaDepth.labelsEs[active],
                  style:theme.textTheme.bodySmall),
              ]),
            ),
            Icon(Icons.lock_outline,size:19,color:theme.colorScheme.outline),
          ]),
        ),
        const Divider(height:1),
        if(issue!=null)MaterialBanner(
          content:Text(issue!),leading:const Icon(Icons.info_outline),
          actions:[TextButton(onPressed:_load,
            child:Text(tr('Recargar','Reload')))]),
        if(notice!=null)Padding(
          padding:const EdgeInsets.all(9),
          child:Text(notice!,style:theme.textTheme.bodySmall)),
        Expanded(child:_history()),
        _composer(),
        Align(alignment:Alignment.centerLeft,
          child:Padding(padding:const EdgeInsets.only(left:8,bottom:5),
            child:TextButton.icon(
              key:const Key('fit-ia-pause'),
              onPressed:()=>Navigator.maybePop(context),
              icon:const Icon(Icons.pause_circle_outline,size:18),
              label:Text(tr('Continuar después','Continue later'))))),
      ]),
    );
  }
  Widget _rightPane(){
    final theme=Theme.of(context);
    final value=(brief[english?'en':'es']??'').toString().trim();
    final items=answers;
    final current=depth;
    return ListView(key:const Key('fit-ia-insights-panel'),
      padding:EdgeInsets.zero,children:[
        Card(margin:const EdgeInsets.only(bottom:12),
          child:Padding(padding:const EdgeInsets.all(18),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                const Icon(Icons.auto_stories_outlined,size:22),
                const SizedBox(width:9),
                Expanded(child:Text(tr('Tu resumen en construcción',
                  'Your evolving summary'),
                  style:theme.textTheme.titleMedium?.copyWith(
                    fontWeight:FontWeight.w800))),
              ]),
              const SizedBox(height:12),
              Text(value.isEmpty?tr(
                'Conforme conversemos, reuniré aquí '
                'lo que has compartido, sin inventar detalles.',
                'As we chat, I’ll gather the details you have '
                'shared here, without inventing anything.'):value,
                key:const Key('fit-ia-executive-summary'),
                style:theme.textTheme.bodyLarge?.copyWith(height:1.43)),
            ]),
          )),
        Card(margin:const EdgeInsets.only(bottom:12),
          child:Padding(padding:const EdgeInsets.all(18),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(tr('Profundidad de este pilar','Pillar depth'),
                style:theme.textTheme.titleMedium?.copyWith(
                  fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              Wrap(spacing:8,runSpacing:7,children:[
                Chip(key:const Key('fit-ia-strength'),
                  avatar:const Icon(Icons.layers_outlined,size:16),
                  label:Text(FitIaDepth.label(
                    current['level']?.toString()??'weak',english))),
                Text(tr('Respuestas útiles: ','Useful answers: ')+
                  (current['answered']??0).toString()),
                Text(tr('Temas: ','Topics: ')+
                  (current['topics']??0).toString()),
              ]),
              const SizedBox(height:8),
              Text(FitIaDepth.message(
                current['level']?.toString()??'weak',english),
                style:theme.textTheme.bodySmall),
            ]),
          )),
        Card(child:Padding(padding:const EdgeInsets.all(18),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(tr('Lo que hemos conversado','What we’ve discussed'),
              style:theme.textTheme.titleMedium?.copyWith(
                fontWeight:FontWeight.w800)),
            const SizedBox(height:11),
            if(items.isEmpty)
              Text(tr('Aquí aparecerán tus respuestas.',
                'Your answers will appear here.'),
                style:theme.textTheme.bodySmall),
            for(final entry in items.take(35))...[
              Text((entry[english?'question_en':'question_es']??'')
                .toString(),
                style:theme.textTheme.bodySmall?.copyWith(
                  fontWeight:FontWeight.w600)),
              const SizedBox(height:4),
              Text((entry[english?'answer_en':'answer_es']??'')
                .toString(),
                style:theme.textTheme.bodyMedium?.copyWith(
                  color:theme.colorScheme.primary)),
              const Divider(height:22),
            ],
          ]),
        )),
      ],
    );
  }
  void _openMobileInsights(){
    showModalBottomSheet<void>(context:context,
      isScrollControlled:true,showDragHandle:true,
      builder:(ctx)=>SafeArea(child:SizedBox(
        height:MediaQuery.sizeOf(ctx).height*.75,
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:12),
          child:_rightPane()))));
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      key:const Key('fit-ia-natural-conversation-page'),
      appBar:AppBar(
        title:Text(assistantName),
        actions:[
          PopupMenuButton<String>(
            tooltip:tr('Privacidad','Privacy'),
            onSelected:(action){
              if(action=='disable')unawaited(_disable());
              if(action=='delete')unawaited(_erase());
            },
            itemBuilder:(_)=>[
              if(enabled)PopupMenuItem(value:'disable',
                child:Text(tr('Desactivar IA de mi cuenta',
                  'Disable account AI'))),
              PopupMenuItem(value:'delete',
                child:Text(tr('Eliminar mis conversaciones',
                  'Delete my chats'))),
            ],
          ),
        ],
      ),
      body:SafeArea(child:LayoutBuilder(builder:(ctx,limits){
        final wide=limits.maxWidth>=990;
        return Center(child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:1440),
          child:Padding(padding:const EdgeInsets.all(13),
            child:Column(children:[
              Align(alignment:Alignment.centerLeft,
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    Text(tr('Tu espacio con $assistantName',
                      'Your space with $assistantName'),
                      style:Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight:FontWeight.w800)),
                    const SizedBox(height:9),
                    _tabs(),
                  ]),
              ),
              const SizedBox(height:12),
              Expanded(child:wide?Row(children:[
                Expanded(flex:5,child:_leftPane()),
                const SizedBox(width:13),
                Expanded(flex:6,child:_rightPane()),
              ]):Column(children:[
                Expanded(child:_leftPane()),
                OutlinedButton.icon(
                  key:const Key('fit-ia-mobile-insights'),
                  onPressed:_openMobileInsights,
                  icon:const Icon(Icons.insights_outlined),
                  label:Text(tr('Ver resumen e historial',
                    'View summary and history'))),
              ])),
            ]),
          ),
        ));
      })),
    );
  }
}
