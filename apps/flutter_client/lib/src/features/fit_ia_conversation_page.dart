import 'dart:async';
import 'package:flutter/material.dart';
import '../core/fit_ia_repository.dart';
import '../core/fitted_locale.dart';
import 'private_strava_evidence_card.dart';

/// Private, resumable conversations. Answers persist before a new question
/// is displayed; they never enable discovery or share a personal profile.
class FitIaConversationPage extends StatefulWidget {
  const FitIaConversationPage({super.key,required this.repository,
    this.initialPillar=0,this.ownerId='' }):assert(initialPillar>=0&&initialPillar<3);
  final FitIaRepository repository;
  final int initialPillar;
  final String ownerId;
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

  Future<void> _showMyApplications() async {
    if(current==0 && widget.ownerId.isNotEmpty){
      await showModalBottomSheet<void>(
        context:context,
        isScrollControlled:true,
        showDragHandle:true,
        builder:(sheet)=>SafeArea(child:FractionallySizedBox(
          heightFactor:.85,
          child:ListView(padding:const EdgeInsets.all(16),children:[
            PrivateStravaEvidenceCard(ownerId:widget.ownerId),
          ]),
        )),
      );
    }
  }

  Widget _tabs(){
    final colors=Theme.of(context).colorScheme;
    const icons=[Icons.directions_run_outlined,Icons.wb_sunny_outlined,
      Icons.people_outline];
    return SingleChildScrollView(
      scrollDirection:Axis.horizontal,
      child:Row(children:[
        for(var i=0;i<3;i++)Padding(
          padding:const EdgeInsets.only(right:9),
          child:ChoiceChip(
            key:Key('fit-ia-pillar-'+i.toString()),
            selected:current==i,
            avatar:Icon(icons[i],size:17,color:current==i
              ?colors.onSecondaryContainer:colors.onSurfaceVariant),
            label:Text(en?FitIaDepth.labelsEn[i]:FitIaDepth.labelsEs[i]),
            onSelected:(_)=>_switch(i),
            shape:RoundedRectangleBorder(
              borderRadius:BorderRadius.circular(13)),
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

        ]),
    );
  }
  List<Map<String,dynamic>> get answerHistory{
    final raw=insights?['answers'];
    return raw is List
      ?raw.whereType<Map>().map((q)=>Map<String,dynamic>.from(q)).toList()
      :<Map<String,dynamic>>[];
  }

  Widget _formList(){
    if(formLoading)return const Center(child:CircularProgressIndicator());
    if(formQuestions.isEmpty)return Center(child:Padding(
      padding:const EdgeInsets.all(20),
      child:Text(tr('Ya contestaste todas las preguntas disponibles '
        'de este pilar. Puedes continuar en otro.',
        'You have answered all available questions in this pillar.'))));
    return ListView.builder(
      key:const Key('fit-ia-traditional-form'),
      padding:const EdgeInsets.all(15),
      itemCount:formQuestions.length,
      itemBuilder:(ctx,index){
        final q=formQuestions[index];
        final id=q['id'].toString();
        final raw=q[en?'choices_en':'choices_es'];
        final options=raw is List?raw.whereType<Map>().map(
          (e)=>Map<String,dynamic>.from(e)).toList():<Map<String,dynamic>>[];
        return Card(child:Padding(
          padding:const EdgeInsets.all(15),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((index+1).toString().padLeft(2,'0')+'  ·  '+
              (q[en?'en':'es']??'').toString(),
              style:Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:11),
            Wrap(spacing:8,runSpacing:8,children:[
              for(final opt in options)ChoiceChip(
                key:Key('fit-ia-form-'+id+'-'+opt['key'].toString()),
                selected:formDraft[id]==opt['key'],
                label:Text(opt['label']?.toString()??''),
                onSelected:formSaving?null:(v)=>setState((){
                  if(v){formDraft[id]=opt['key'].toString();}
                  else{formDraft.remove(id);}
                }),
              ),
            ]),
          ]),
        ));
      },
    );
  }

  Widget _conversation(){
    if(loading)return const Center(child:CircularProgressIndicator());
    if(state==null)return Center(child:Column(
      mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.wifi_off_outlined,size:37),
        const SizedBox(height:12),
        Text(tr('No pudimos iniciar la conversación',
          'Unable to start the conversation')),
        const SizedBox(height:9),
        FilledButton(onPressed:_load,child:Text(tr('Reintentar','Retry'))),
      ]));
    return ListView(
      key:const Key('fit-ia-chat-history'),
      controller:scroll,
      padding:const EdgeInsets.fromLTRB(18,22,18,24),
      children:[
        if(messages.isEmpty)
          Align(alignment:Alignment.centerLeft,child:Card(
            child:Padding(padding:const EdgeInsets.all(17),
              child:Text(tr('¡Hola! Soy Fit-IA. Me gustaría conocer '
                'cómo te expresas en este aspecto de tu vida.',
                'Hello! I’m Fit-IA. Let’s explore this part of your life.'))))),
        for(final m in messages)_bubble(m),
        if(question==null&&messages.isNotEmpty)
          Text(tr('Hemos recorrido las preguntas disponibles de este pilar.',
            'We have explored the questions available in this pillar.')),
      ],
    );
  }

  Widget _modeSelector(){
    return SegmentedButton<bool>(
      key:const Key('fit-ia-mode-selector'),
      segments:[
        ButtonSegment<bool>(value:false,
          label:Text(tr('Conversación','Conversation')),
          icon:const Icon(Icons.forum_outlined,size:18)),
        ButtonSegment<bool>(value:true,
          label:Text(tr('Formulario','Form')),
          icon:const Icon(Icons.list_alt_outlined,size:18)),
      ],
      selected:{formMode},showSelectedIcon:false,
      onSelectionChanged:(v)=>_setMode(v.first),
    );
  }

  Widget _leftPane(){
    final theme=Theme.of(context);
    return Card(
      margin:EdgeInsets.zero,clipBehavior:Clip.antiAlias,
      child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(18,16,18,14),
          child:LayoutBuilder(builder:(context,limits){
            final heading=Row(children:[
              CircleAvatar(
                radius:22,
                backgroundColor:theme.colorScheme.primaryContainer,
                child:Icon(Icons.auto_awesome_rounded,
                  color:theme.colorScheme.onPrimaryContainer)),
              const SizedBox(width:12),
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('Fit-IA',style:theme.textTheme.titleLarge?.copyWith(
                    fontWeight:FontWeight.w800)),
                  Text(en?FitIaDepth.labelsEn[current]:FitIaDepth.labelsEs[current],
                    style:theme.textTheme.bodySmall),
                ]),
              ),
            ]);
            return limits.maxWidth<540
              ?Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                  heading,const SizedBox(height:13),
                  _modeSelector(),
                ])
              :Row(children:[
                  Expanded(child:heading),
                  Flexible(child:_modeSelector()),
                ]);
          }),
        ),
        const Divider(height:1),
        if(error!=null)
          MaterialBanner(
            leading:const Icon(Icons.info_outline),
            content:Text(error!),
            actions:[
              TextButton(
                onPressed:formMode?_loadForm:_load,
                child:Text(tr('Reintentar','Retry'))),
            ],
          ),
        if(notice!=null)Padding(
          padding:const EdgeInsets.symmetric(horizontal:15,vertical:7),
          child:Text(notice!,style:theme.textTheme.bodySmall)),
        Expanded(child:formMode?_formList():_conversation()),
        if(!formMode&&!loading&&question!=null)_choices(),
        if(formMode)
          Padding(padding:const EdgeInsets.all(12),
            child:Row(children:[
              Expanded(child:Text(
                tr('Responde las que desees','Answer the ones you prefer'),
                style:theme.textTheme.bodySmall)),
              FilledButton.icon(
                key:const Key('fit-ia-save-form'),
                onPressed:formSaving||formDraft.isEmpty?null:_submitForm,
                icon:const Icon(Icons.save_outlined,size:18),
                label:Text(tr('Guardar','Save')+' ('+
                  formDraft.length.toString()+')')),
            ]),
          ),
        Padding(padding:const EdgeInsets.fromLTRB(13,5,13,9),
          child:Wrap(alignment:WrapAlignment.spaceBetween,
            spacing:6,runSpacing:4,children:[
            TextButton.icon(
              key:const Key('fit-ia-pause'),
              onPressed:()async{
                if(!await _allowDiscard()||!mounted)return;
                Navigator.pop(context);
              },
              icon:const Icon(Icons.pause_circle_outline),
              label:Text(tr('Continuar después','Continue later'))),
            if(!aiEnabled)
              TextButton.icon(
                key:const Key('fit-ia-enable-ai'),
                onPressed:consentBusy?null:_consent,
                icon:const Icon(Icons.auto_awesome_outlined,size:16),
                label:Text(tr('Activar IA','Enable AI'))),
          ]),
        ),
      ]),
    );
  }

  Widget _rightPane(){
    final theme=Theme.of(context),colors=theme.colorScheme;
    final raw=insights?['brief'];
    final brief=raw is Map?Map<String,dynamic>.from(raw):<String,dynamic>{};
    final sentence=(brief[en?'en':'es']??'').toString().trim();
    final items=answerHistory;
    return ListView(
      key:const Key('fit-ia-insights-panel'),
      padding:EdgeInsets.zero,children:[
        Card(margin:const EdgeInsets.only(bottom:12),
          child:Padding(padding:const EdgeInsets.all(17),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Icon(Icons.auto_stories_outlined,color:colors.primary),
                const SizedBox(width:9),
                Expanded(child:Text(tr('Resumen ejecutivo',
                  'Executive summary'),
                  style:theme.textTheme.titleMedium?.copyWith(
                    fontWeight:FontWeight.w800))),
              ]),
              const SizedBox(height:13),
              Text(sentence.isEmpty
                ?tr('Tu resumen irá tomando forma conforme respondas.',
                  'Your summary will take shape as you answer.')
                :sentence,
                key:const Key('fit-ia-executive-summary'),
                style:theme.textTheme.bodyLarge?.copyWith(height:1.45)),
              const SizedBox(height:11),
              if(aiEnabled)
                TextButton.icon(
                  key:const Key('fit-ia-refresh-summary'),
                  onPressed:summaryBusy?null:()=>_refreshSummary(),
                  icon:const Icon(Icons.auto_awesome_outlined,size:18),
                  label:Text(tr('Actualizar historia completa',
                    'Refresh full story'))),
            ]),
          ),
        ),
        Card(margin:const EdgeInsets.only(bottom:12),
          child:Padding(padding:const EdgeInsets.all(17),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(tr('Nivel de conocimiento','Profile depth'),
                style:theme.textTheme.titleMedium?.copyWith(
                  fontWeight:FontWeight.w800)),
              const SizedBox(height:10),
              Wrap(spacing:10,crossAxisAlignment:WrapCrossAlignment.center,
                children:[
                  Chip(
                    key:const Key('fit-ia-strength'),
                    label:Text(FitIaDepth.label(level,en)),
                    avatar:const Icon(Icons.layers_outlined,size:17)),
                  Text(tr('Respuestas: ','Answers: ')+
                    FitIaDepth.answered(overview,pillar).toString()),
                  Text(tr('Temas: ','Topics: ')+
                    ((overview?[pillar] is Map)
                      ?(overview![pillar] as Map)['topics']?.toString()??'0'
                      :'0')),
                ]),
              const SizedBox(height:6),
              Text(FitIaDepth.message(level,en),
                style:theme.textTheme.bodySmall),
            ]),
          ),
        ),
        Card(
          child:Padding(padding:const EdgeInsets.all(17),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                const Icon(Icons.fact_check_outlined,size:21),
                const SizedBox(width:9),
                Expanded(child:Text(tr('Lo que he aprendido',
                  'What I’ve learned'),
                  style:theme.textTheme.titleMedium?.copyWith(
                    fontWeight:FontWeight.w800))),
                Text(items.length.toString(),
                  style:theme.textTheme.labelSmall),
              ]),
              const SizedBox(height:10),
              if(items.isEmpty)
                Text(tr('Aquí aparecerán tus preguntas y respuestas.',
                  'Your questions and answers will appear here.'),
                  style:theme.textTheme.bodySmall),
              for(final entry in items.take(30))...[
                Text((entry[en?'question_en':'question_es']??'').toString(),
                  style:theme.textTheme.bodySmall?.copyWith(
                    fontWeight:FontWeight.w600)),
                const SizedBox(height:4),
                Text((entry[en?'answer_en':'answer_es']??'').toString(),
                  style:theme.textTheme.bodyMedium?.copyWith(
                    color:colors.primary)),
                const Divider(height:23),
              ],
            ]),
          ),
        ),
      ],
    );
  }
  void _showMobileInsights(){
    showModalBottomSheet<void>(
      context:context,isScrollControlled:true,showDragHandle:true,
      builder:(ctx)=>SafeArea(
        child:SizedBox(height:MediaQuery.sizeOf(ctx).height*.78,
          child:Padding(padding:const EdgeInsets.symmetric(horizontal:13),
            child:_rightPane()))),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      key:const Key('fit-ia-conversation-page'),
      appBar:AppBar(
        title:const Text('Fit-IA'),
        actions:[
          if(current==0 && widget.ownerId.isNotEmpty)
            IconButton(
              key:const Key('fit-ia-view-private-apps'),
              tooltip:tr('Mis aplicaciones deportivas',
                'My sports apps'),
              onPressed:_showMyApplications,
              icon:const Icon(Icons.insights_outlined)),
          IconButton(key:const Key('fit-ia-view-story'),
            tooltip:tr('Mi historia','My story'),
            onPressed:_story,
            icon:const Icon(Icons.auto_stories_outlined)),
          PopupMenuButton<String>(
            tooltip:tr('Privacidad y configuración',
              'Privacy and settings'),
            onSelected:(v){
              if(v=='consent')unawaited(_consent());
              if(v=='delete')unawaited(_delete());
            },
            itemBuilder:(_)=>[
              PopupMenuItem(value:'consent',
                child:Text(aiEnabled?tr('Desactivar IA en mi cuenta',
                  'Disable account AI'):tr('Activar IA en mi cuenta',
                  'Enable account AI'))),
              PopupMenuItem(value:'delete',child:Text(tr(
                'Eliminar mis conversaciones','Delete my conversations'))),
            ],
          ),
        ],
      ),
      body:SafeArea(child:LayoutBuilder(
        builder:(context,limits){
          final desktop=limits.maxWidth>=1040;
          return Center(child:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:1500),
            child:Padding(
              padding:const EdgeInsets.all(14),
              child:Column(children:[
                Align(alignment:Alignment.centerLeft,
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      Text(tr('Conócete con Fit-IA','Get to know yourself with Fit-IA'),
                        style:Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight:FontWeight.w800)),
                      const SizedBox(height:9),
                      _tabs(),
                    ])),
                const SizedBox(height:13),
                Expanded(child:desktop
                  ?Row(children:[
                    Expanded(flex:7,child:_leftPane()),
                    const SizedBox(width:14),
                    Expanded(flex:4,child:_rightPane()),
                  ])
                  :Column(children:[
                    Expanded(child:_leftPane()),
                    Padding(
                      padding:const EdgeInsets.only(top:7),
                      child:OutlinedButton.icon(
                        key:const Key('fit-ia-mobile-insights'),
                        onPressed:_showMobileInsights,
                        icon:const Icon(Icons.insights_outlined),
                        label:Text(tr('Ver resumen y respuestas',
                          'View summary and answers'))),
                    ),
                  ]),
                ),
              ]),
            ),
          ));
        },
      )),
    );
  }
}
