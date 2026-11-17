import 'dart:async';
import 'package:flutter/material.dart';
import '../core/fit_ia_repository.dart';
import '../core/fitted_locale.dart';

/// Private, resumable conversations. Answers persist before a new question
/// is displayed; they never enable discovery or share a personal profile.
class FitIaConversationPage extends StatefulWidget {
  const FitIaConversationPage({super.key,required this.repository,
    this.initialPillar=0}):assert(initialPillar>=0&&initialPillar<3);
  final FitIaRepository repository;
  final int initialPillar;
  @override
  State<FitIaConversationPage> createState()=>_FitIaConversationPageState();
}
class _FitIaConversationPageState extends State<FitIaConversationPage>{
  late int current;
  Map<String,dynamic>? state,overview,insights;
  List<Map<String,dynamic>> formQuestions=[];
  final Map<String,String> formDraft={};
  bool formMode=false,formLoading=false,formSaving=false;
  final scroll=ScrollController();
  bool loading=true,sending=false,summaryBusy=false,consentBusy=false;
  String? error,notice;
  bool get en=>FittedLocaleScope.languageOf(context)=='en';
  String tr(String es,String enText)=>en?enText:es;
  String get pillar=>FitIaDepth.keys[current];
  bool get aiEnabled=>state?['ai_enabled']==true;
  bool get realAi=>state?['conversation_mode']=='ai';
  Map<String,dynamic>? get question {
    final q=state?['question'];
    return q is Map?Map<String,dynamic>.from(q):null;
  }
  List<Map<String,dynamic>> get messages{
    final all=state?['messages'];
    return all is List?all.whereType<Map>().map(
      (m)=>Map<String,dynamic>.from(m)).toList():[];
  }
  String get level{
    final d=state?['depth'];
    return d is Map&&FitIaDepth.levels.contains(d['level'])
      ?d['level'].toString():FitIaDepth.level(overview,pillar);
  }
  Map<String,dynamic>? get summary{
    final s=state?['summary']??overview?['summary'];
    return s is Map?Map<String,dynamic>.from(s):null;
  }
  int get totalAnswers=>FitIaDepth.keys.fold<int>(0,
    (sum,k)=>sum+FitIaDepth.answered(overview,k));

  @override
  void initState(){super.initState();current=widget.initialPillar;_load();}
  @override
  void dispose(){scroll.dispose();super.dispose();}
  void _scrollBottom(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(mounted&&scroll.hasClients){
        unawaited(scroll.animateTo(scroll.position.maxScrollExtent,
          duration:const Duration(milliseconds:220),curve:Curves.easeOut));
      }
    });
  }
  Future<void> _load()async{
    final selected=pillar;
    setState((){loading=true;error=null;});
    try{
      // The active question is the critical request. Optional insights must
      // not prevent a chat from opening when the secondary RPC is unavailable.
      final session=await widget.repository.fitIaState(selected);
      if(!mounted||selected!=pillar)return;
      setState((){state=session;loading=false;});
      unawaited(_refreshInsights());
      _scrollBottom();
    }catch(_){
      if(mounted&&selected==pillar)setState((){
        loading=false;
        error=tr('No pudimos abrir la conversación. '
          'Tus respuestas anteriores están guardadas.',
          'Could not open the conversation. Your previous answers are saved.');
      });
    }
  }
  Future<void> _switch(int index)async{
    if(index==current||sending||loading||formSaving)return;
    if(!await _allowDiscard())return;
    setState((){
      current=index;state=null;overview=null;insights=null;
      formQuestions=[];formDraft.clear();notice=null;
    });
    await _load();
    if(formMode)await _loadForm();
  }
  Future<bool> _allowDiscard()async{
    if(formDraft.isEmpty)return true;
    return await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(tr('Respuestas sin guardar','Unsaved answers')),
      content:Text(tr('Guarda el formulario o descarta estas selecciones.',
        'Save the form or discard your selections.')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),
          child:Text(tr('Seguir aquí','Stay here'))),
        TextButton(onPressed:()=>Navigator.pop(ctx,true),
          child:Text(tr('Descartar selecciones','Discard selections'))),
      ],
    ))??false;
  }
  Future<void> _refreshInsights()async{
    final target=pillar;
    try{
      final result=await Future.wait([
        widget.repository.fitIaOverview(),
        widget.repository.fitIaInsights(target),
      ]);
      if(mounted&&target==pillar)setState((){
        overview=result[0];insights=result[1];
      });
    }catch(_){
      // A question remains usable if analytics are temporarily unavailable.
    }
  }
  Future<void> _loadForm()async{
    final target=pillar;
    setState(()=>formLoading=true);
    try{
      final data=await widget.repository.fitIaForm(target);
      if(!mounted||target!=pillar)return;
      final items=data['questions'];
      setState((){
        formQuestions=items is List
          ?items.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList()
          :[];
        formDraft.clear();formLoading=false;error=null;
      });
    }catch(_){
      if(mounted&&target==pillar)setState((){
        formLoading=false;
        error=tr('No se pudo cargar el formulario. Inténtalo de nuevo.',
          'Could not load the form. Please try again.');
      });
    }
  }
  Future<void> _setMode(bool useForm)async{
    if(formMode==useForm||sending||formSaving)return;
    if(!await _allowDiscard())return;
    setState((){
      formMode=useForm;formDraft.clear();error=null;
    });
    if(useForm)await _loadForm();
  }
  Future<void> _submitForm()async{
    if(formSaving||formDraft.isEmpty)return;
    final target=pillar;
    setState(()=>formSaving=true);
    try{
      final items=formDraft.entries.map((e)=><String,String>{
        'question_id':e.key,'choice_key':e.value,
      }).toList();
      await widget.repository.fitIaSubmitForm(target,items);
      if(!mounted||target!=pillar)return;
      formDraft.clear();
      await _load();
      if(mounted&&target==pillar)await _loadForm();
      if(mounted)setState(()=>notice=tr('Respuestas guardadas.',
        'Answers saved.'));
    }catch(_){
      if(mounted)setState(()=>error=tr(
        'No se pudieron guardar las respuestas. '
        'Conservamos tus selecciones para que puedas reintentar.',
        'Unable to save. Your choices are kept for another attempt.'));
    }finally{if(mounted)setState(()=>formSaving=false);}
  }
  Future<void> _answer(String key)async{
    final q=question;
    if(sending||q==null||loading)return;
    setState(()=>sending=true);
    try{
      final response=await widget.repository.fitIaAnswer(
        pillar,q['id'].toString(),key,locale:en?'en':'es');
      if(!mounted)return;
      setState((){
        state=response;error=null;
      });
      // An overview refresh must never make a successfully saved answer
      // appear to fail or get submitted twice after a network hiccup.
      try{
        final result=await widget.repository.fitIaOverview();
        if(mounted)setState(()=>overview=result);
      }catch(_){/* The answered question is already durably persisted. */}
      _scrollBottom();
      unawaited(_refreshInsights());
      if(aiEnabled&&totalAnswers>=5&&
        (totalAnswers==5||(totalAnswers-5)%3==0)){
        unawaited(_refreshSummary(silent:true));
      }
    }catch(_){
      if(mounted)setState(()=>error=tr(
        'No se guardó tu respuesta. Puedes intentarlo otra vez.',
        'The answer could not be saved. Please try again.'));
    }finally{if(mounted)setState(()=>sending=false);}
  }
  Future<void> _refreshSummary({bool silent=false})async{
    if(summaryBusy||!aiEnabled)return;
    setState((){
      summaryBusy=true;if(!silent)notice=null;
    });
    try{
      final result=await widget.repository.fitIaGenerateSummary();
      if(!mounted)return;
      if(result['status']=='saved'){
        final updated=await widget.repository.fitIaOverview();
        if(mounted)setState((){
          overview=updated;
          state={...?state,'summary':updated['summary']};
          notice=tr('Tu historia se actualizó con IA.',
            'Your story was updated with AI.');
        });
      }else if(!silent){
        setState(()=>notice=result['status']=='rate_limited'
          ?tr('Ya actualizamos tu historia hace poco. '
            'Puedes seguir conversando.',
            'Your story was updated recently. Keep chatting.')
          :result['status']=='more_information_needed'
          ?tr('Aún necesito conocer algunas facetas más de ti.',
            'I need a few more details about you.')
          :tr('El resumen no está disponible ahora; tus respuestas están guardadas.',
            'The story is unavailable right now; your answers are saved.'));
      }
    }catch(_){
      if(mounted&&!silent)setState(()=>notice=tr(
        'No pudimos actualizar tu historia. No se perdieron respuestas.',
        'Could not update your story. Your answers were not lost.'));
    }finally{if(mounted)setState(()=>summaryBusy=false);}
  }
  Future<void> _consent()async{
    if(consentBusy)return;
    if(!aiEnabled){
      final allowed=await showDialog<bool>(context:context,
        builder:(dialog)=>AlertDialog(
          title:const Text('Activar IA en toda mi cuenta'),
          content:Text(tr('Esta decisión habilita todas las herramientas de IA '
            'de tu cuenta, incluidos Fit-IA y los resúmenes privados. '
            'Se pueden procesar respuestas y datos seleccionados del '
            'perfil mediante OpenAI, nunca documentos de identidad, '
            'gimnasios u horarios exactos. No publica contenido '
            'automáticamente. Puedes apagarla en Configuración.',
            'This choice enables AI across your entire account, '
            'including Fit-IA and private stories. Selected profile '
            'details and answers may be processed by OpenAI, never '
            'identity documents, gyms or exact schedules. '
            'Nothing is shared automatically. Disable it in Settings.')),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog,false),
              child:Text(tr('Ahora no','Not now'))),
            FilledButton(key:const Key('fit-ia-confirm-consent'),
              onPressed:()=>Navigator.pop(dialog,true),
              child:Text(tr('Acepto activar IA','Enable AI with consent'))),
          ],
        ));
      if(allowed!=true||!mounted)return;
    }
    setState(()=>consentBusy=true);
    try{
      await widget.repository.fitIaConsent(!aiEnabled);
      if(mounted)await _load();
    }catch(_){
      if(mounted)setState(()=>error=tr('No se pudo cambiar el consentimiento.',
        'Could not change consent.'));
    }finally{if(mounted)setState(()=>consentBusy=false);}
  }
  Future<void> _delete()async{
    final allowed=await showDialog<bool>(context:context,
      builder:(dialog)=>AlertDialog(
        title:Text(tr('Eliminar mis conversaciones',
          'Delete my conversations')),
        content:Text(tr('Se eliminarán todas las respuestas, mensajes '
          'y resúmenes de Fit-IA en los tres pilares. '
          'Esta acción es irreversible.',
          'All Fit-IA answers, messages and summaries in the three pillars '
          'will be permanently removed. This cannot be undone.')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),
            child:Text(tr('Cancelar','Cancel'))),
          FilledButton(key:const Key('fit-ia-confirm-delete'),
            onPressed:()=>Navigator.pop(dialog,true),
            child:Text(tr('Eliminar todo','Delete all'))),
        ],
      ));
    if(allowed!=true||!mounted)return;
    try{
      await widget.repository.fitIaDeleteMyData();
      if(mounted)await _load();
    }catch(_){
      if(mounted)setState(()=>error=tr('No se pudieron borrar tus respuestas.',
        'Unable to delete your answers.'));
    }
  }
  Future<void> _story()async{
    final text=(summary?[en?'summary_en':'summary_es']??'').toString().trim();
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(
      title:Text(tr('Mi historia con Fit-IA','My Fit-IA story')),
      content:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),
        child:SingleChildScrollView(child:Text(text.isEmpty
          ?tr('Estamos conociéndote. Comparte algunas respuestas '
            'en los tres pilares para crear tu historia personal.',
            'We are getting to know you. Share answers across all '
            'three pillars to create your story.'):text))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dialog),
          child:Text(tr('Cerrar','Close'))),
        if(aiEnabled)FilledButton(
          onPressed:(){
            Navigator.pop(dialog);
            unawaited(_refreshSummary());
          },
          child:Text(tr('Actualizar historia','Refresh story'))),
      ],
    ));
  }

  Widget _tabs(){
    final colors=Theme.of(context).colorScheme;
    const icons=[Icons.directions_run_outlined,Icons.wb_sunny_outlined,
      Icons.people_outline];
    return SingleChildScrollView(scrollDirection:Axis.horizontal,
      child:Row(children:[
        for(var i=0;i<3;i++)
          Padding(padding:const EdgeInsets.only(right:9),
            child:Material(
              color:i==current?colors.primaryContainer:
                colors.surfaceContainerHighest,
              borderRadius:BorderRadius.circular(16),
              child:InkWell(
                key:Key('fit-ia-pillar-$i'),
                onTap:()=>_switch(i),
                borderRadius:BorderRadius.circular(16),
                child:Container(
                  width:157,padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(
                    borderRadius:BorderRadius.circular(16),
                    border:Border.all(color:i==current?colors.primary:
                      colors.outline.withValues(alpha:.25))),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      Icon(icons[i],size:22),
                      const SizedBox(height:8),
                      Text(en?FitIaDepth.labelsEn[i]:FitIaDepth.labelsEs[i],
                        maxLines:1,overflow:TextOverflow.ellipsis,
                        style:const TextStyle(fontWeight:FontWeight.w700)),
                      const SizedBox(height:5),
                      Text(FitIaDepth.label(i==current?level:
                        FitIaDepth.level(overview,FitIaDepth.keys[i]),en),
                        style:Theme.of(context).textTheme.labelSmall),
                    ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
  Widget _bubble(Map<String,dynamic> m){
    final own=m['kind']=='answer';
    final comment=(m['comment']??'').toString().trim();
    final value=(m[own?(en?'answer_en':'answer_es'):(en?'en':'es')]
      ??'').toString();
    final theme=Theme.of(context),colors=theme.colorScheme;
    return Align(alignment:own?Alignment.centerRight:Alignment.centerLeft,
      child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:560),
        child:Container(
          margin:const EdgeInsets.only(bottom:12),
          padding:const EdgeInsets.symmetric(horizontal:16,vertical:13),
          decoration:BoxDecoration(
            color:own?colors.primaryContainer:colors.surfaceContainerHigh,
            borderRadius:BorderRadius.circular(17),
            border:Border.all(color:colors.outline.withValues(alpha:.2))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(mainAxisSize:MainAxisSize.min,children:[
              Icon(own?Icons.person_outline:Icons.auto_awesome,
                size:15,color:colors.primary),
              const SizedBox(width:7),
              Text(own?tr('Tú','You'):'Fit-IA',
                style:theme.textTheme.labelMedium?.copyWith(
                  color:colors.primary,fontWeight:FontWeight.w800)),
            ]),
            if(comment.isNotEmpty)...[
              const SizedBox(height:8),
              Text(comment,style:theme.textTheme.bodyMedium),
            ],
            if(value.isNotEmpty)...[
              SizedBox(height:comment.isEmpty?7:10),
              Text(value,style:theme.textTheme.bodyLarge?.copyWith(
                height:1.4,fontWeight:own?FontWeight.w700:FontWeight.w500)),
            ],
          ]),
        ),
      ),
    );
  }
  Widget _choices(){
    final q=question;
    if(q==null)return const SizedBox.shrink();
    final raw=q[en?'choices_en':'choices_es'];
    final options=raw is List?raw.whereType<Map>().map(
      (m)=>Map<String,dynamic>.from(m)).toList():<Map<String,dynamic>>[];
    return Container(
      key:const Key('fit-ia-answer-options'),
      decoration:BoxDecoration(
        color:Theme.of(context).colorScheme.surface,
        border:Border(top:BorderSide(color:Theme.of(context)
          .colorScheme.outline.withValues(alpha:.18)))),
      padding:const EdgeInsets.all(16),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,
        mainAxisSize:MainAxisSize.min,children:[
          Text(tr('Elige lo que más encaje contigo:',
            'Choose what fits you best:'),
            style:Theme.of(context).textTheme.labelMedium),
          const SizedBox(height:9),
          Wrap(spacing:8,runSpacing:8,children:[
            for(final option in options)
              OutlinedButton(
                key:Key('fit-ia-option-'+option['key'].toString()),
                onPressed:sending?null:
                  ()=>_answer(option['key'].toString()),
                child:Text(option['label']?.toString()??''),
              ),
          ]),
          if(sending)...[
            const SizedBox(height:7),
            const LinearProgressIndicator(minHeight:2),
          ],
          const SizedBox(height:8),
          Text(tr('Cada respuesta se guarda. Puedes pausar cuando quieras.',
            'Every answer is saved. Pause whenever you like.'),
            style:Theme.of(context).textTheme.bodySmall),
        ]),
    );
  }
  @override
  Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Scaffold(
      key:const Key('fit-ia-conversation-page'),
      appBar:AppBar(
        title:const Text('Fit-IA'),
        actions:[
          IconButton(key:const Key('fit-ia-view-story'),
            tooltip:tr('Mi historia','My story'),
            onPressed:_story,
            icon:const Icon(Icons.auto_stories_outlined)),
          PopupMenuButton<String>(
            tooltip:tr('Privacidad','Privacy'),
            onSelected:(v){
              if(v=='consent')unawaited(_consent());
              if(v=='delete')unawaited(_delete());
            },
            itemBuilder:(_)=>[
              PopupMenuItem(value:'consent',
                child:Text(aiEnabled?tr('Desactivar IA en toda la cuenta',
                  'Disable AI for my account'):tr('Activar IA en mi cuenta','Enable AI for my account'))),
              PopupMenuItem(value:'delete',child:Text(tr(
                'Eliminar mis conversaciones','Delete my conversations'))),
            ],
          ),
        ],
      ),
      body:SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:900),
        child:Column(children:[
          Padding(padding:const EdgeInsets.fromLTRB(16,12,16,9),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(tr('Conócete conversando','Get to know yourself through chat'),
                style:Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight:FontWeight.w800)),
              const SizedBox(height:7),
              Text(tr('Sin formularios ni porcentajes. '
                'No necesitas responder las 100 preguntas.',
                'No forms or percentages. You do not need all 100 answers.'),
                style:Theme.of(context).textTheme.bodySmall),
              const SizedBox(height:13),
              _tabs(),
              const SizedBox(height:12),
              Row(children:[
                const Icon(Icons.shield_outlined,size:16),
                const SizedBox(width:7),
                Expanded(child:Text(realAi?tr(
                  'IA activa con consentimiento · Respuestas privadas',
                  'AI enabled with consent · Private answers'):
                  tr('Modo guiado privado · IA externa desactivada',
                    'Private guided mode · External AI disabled'),
                  style:Theme.of(context).textTheme.bodySmall)),
                Text(FitIaDepth.label(level,en),
                  key:const Key('fit-ia-strength'),
                  style:TextStyle(color:colors.primary,
                    fontWeight:FontWeight.w800)),
              ]),
              const SizedBox(height:4),
              Text(FitIaDepth.message(level,en),
                style:Theme.of(context).textTheme.bodySmall),
              if(!aiEnabled)TextButton.icon(
                key:const Key('fit-ia-enable-ai'),
                onPressed:consentBusy?null:_consent,
                icon:const Icon(Icons.auto_awesome_outlined,size:18),
                label:Text(tr('Activar IA en mi cuenta',
                  'Enable AI for my account'))),
            ]),
          ),
          if(error!=null)MaterialBanner(
            content:Text(error!),leading:const Icon(Icons.info_outline),
            actions:[TextButton(onPressed:_load,
              child:Text(tr('Reintentar','Retry')))],
          ),
          if(notice!=null)Padding(
            padding:const EdgeInsets.symmetric(horizontal:15),
            child:Text(notice!,style:Theme.of(context).textTheme.bodySmall)),
          Expanded(child:loading
            ?const Center(child:CircularProgressIndicator())
            :ListView(
              key:const Key('fit-ia-chat-history'),
              controller:scroll,padding:const EdgeInsets.all(16),
              children:[
                for(final m in messages)_bubble(m),
                if(messages.isEmpty)
                  Text(tr('Fit-IA prepara tu primera pregunta…',
                    'Fit-IA is preparing your first question…')),
                if(question==null&&messages.isNotEmpty)
                  Text(tr('Ya exploramos las preguntas de este pilar.',
                    'We have covered this pillar’s question bank.')),
              ],
            )),
          if(!loading&&question!=null)_choices(),
          Padding(padding:const EdgeInsets.fromLTRB(16,7,16,10),
            child:Row(children:[
              TextButton.icon(
                key:const Key('fit-ia-pause'),
                onPressed:()=>Navigator.pop(context),
                icon:const Icon(Icons.pause_circle_outline),
                label:Text(tr('Continuar después','Continue later'))),
              const Spacer(),
              if(aiEnabled)TextButton.icon(
                key:const Key('fit-ia-refresh-summary'),
                onPressed:summaryBusy?null:()=>_refreshSummary(),
                icon:const Icon(Icons.auto_stories_outlined),
                label:Text(tr('Mi resumen','My summary'))),
            ]),
          ),
        ]),
      ))),
    );
  }
}
