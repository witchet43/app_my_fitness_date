import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FitIaAdminRepository{
  Future<Map<String,dynamic>> load(String pillar);
  Future<void> saveQuestion(Map<String,dynamic> value);
  Future<void> saveDepth(String pillar,int ma,int mt,int sa,int st);
}
class SupabaseFitIaAdminRepository implements FitIaAdminRepository{
  const SupabaseFitIaAdminRepository(this.client);
  final SupabaseClient client;
  @override
  Future<Map<String,dynamic>> load(String pillar)async{
    final data=await client.rpc('fit_ia_admin_list_v2',
      params:{'p_pillar':pillar});
    return Map<String,dynamic>.from(data as Map);
  }
  @override
  Future<void> saveQuestion(Map<String,dynamic> q)async{
    final result=await client.rpc('fit_ia_admin_save_question_v2',params:{
      'p_id':q['id'],'p_topic':q['topic'],
      'p_prompt_es':q['prompt_es'],'p_prompt_en':q['prompt_en'],
      'p_choices_es':q['choices_es'],'p_choices_en':q['choices_en'],
      'p_enabled':q['enabled'],
    });
    if(result is! Map||result['saved']!=true)throw StateError('not_saved');
  }
  @override
  Future<void> saveDepth(String pillar,int ma,int mt,int sa,int st)async{
    final result=await client.rpc('fit_ia_admin_save_depth_v2',params:{
      'p_pillar':pillar,'p_medium_answers':ma,'p_medium_topics':mt,
      'p_strong_answers':sa,'p_strong_topics':st,
    });
    if(result is! Map||result['saved']!=true)throw StateError('not_saved');
  }
}
class FitIaAdminPage extends StatefulWidget{
  const FitIaAdminPage({super.key,required this.repository});
  final FitIaAdminRepository repository;
  @override
  State<FitIaAdminPage> createState()=>_FitIaAdminPageState();
}
class _FitIaAdminPageState extends State<FitIaAdminPage>{
  static const keys=['move','live','relate'];
  static const names=['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
  final filter=TextEditingController();
  final ma=TextEditingController(),mt=TextEditingController();
  final sa=TextEditingController(),st=TextEditingController();
  int selected=0;
  bool loading=true,editingRules=false,saving=false;
  String? issue;
  Map<String,dynamic> rule={};
  List<Map<String,dynamic>> questions=[];
  String get pillar=>keys[selected];

  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){
    filter.dispose();ma.dispose();mt.dispose();sa.dispose();st.dispose();
    super.dispose();
  }
  void _notice(String value){
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(value)));
  }
  Future<void> _load()async{
    final target=pillar;
    setState((){loading=true;issue=null;});
    try{
      final data=await widget.repository.load(target);
      if(!mounted||target!=pillar)return;
      final items=data['questions'];
      final r=data['rule'];
      setState((){
        questions=items is List?items.whereType<Map>().map(
          (q)=>Map<String,dynamic>.from(q)).toList():[];
        rule=r is Map?Map<String,dynamic>.from(r):{};
        ma.text=(rule['medium_answers']??4).toString();
        mt.text=(rule['medium_topics']??3).toString();
        sa.text=(rule['strong_answers']??10).toString();
        st.text=(rule['strong_topics']??6).toString();
        loading=false;editingRules=false;
      });
    }catch(_){
      if(mounted)setState((){
        loading=false;issue='No pudimos abrir el catálogo. '
          'Comprueba el rol administrador y el segundo factor (MFA).';
      });
    }
  }
  Future<void> _pillar(int value)async{
    if(selected==value)return;
    setState((){
      selected=value;filter.clear();questions=[];editingRules=false;
    });
    await _load();
  }
  Widget _num(String name,TextEditingController c)=>SizedBox(width:165,
    child:TextField(controller:c,keyboardType:TextInputType.number,
      decoration:InputDecoration(labelText:name)));
  Future<void> _saveRules()async{
    final a=int.tryParse(ma.text),b=int.tryParse(mt.text);
    final c=int.tryParse(sa.text),d=int.tryParse(st.text);
    if(a==null||b==null||c==null||d==null||
       a<1||a>50||b<1||b>9||c<=a||c>100||d<=b||d>10){
      _notice('Indica criterios progresivos: Medio debe ser menor a Fuerte '
        'en respuestas y variedad de temas.');return;
    }
    setState(()=>saving=true);
    try{
      await widget.repository.saveDepth(pillar,a,b,c,d);
      if(mounted){await _load();_notice('Criterios de profundidad actualizados.');}
    }catch(_){_notice('No se pudieron guardar los criterios. Verifica MFA.');}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Future<void> _edit(Map<String,dynamic> q)async{
    final topic=TextEditingController(text:q['topic']?.toString()??'');
    final es=TextEditingController(text:q['prompt_es']?.toString()??'');
    final en=TextEditingController(text:q['prompt_en']?.toString()??'');
    final esOptions=(q['choices_es'] as List).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
    final enOptions=(q['choices_en'] as List).map((x)=>Map<String,dynamic>.from(x as Map)).toList();
    final optEs=List.generate(4,(i)=>TextEditingController(text:esOptions[i]['label'].toString()));
    final optEn=List.generate(4,(i)=>TextEditingController(text:enOptions[i]['label'].toString()));
    var enabled=q['enabled']==true;
    var submitting=false;
    final saved=await showDialog<bool>(context:context,builder:(context)=>
      StatefulBuilder(builder:(context,update)=>AlertDialog(
        title:Text('Editar pregunta '+q['id'].toString()),
        content:ConstrainedBox(
          constraints:BoxConstraints(maxWidth:680,
            maxHeight:MediaQuery.sizeOf(context).height*.72),
          child:SingleChildScrollView(
            child:Column(mainAxisSize:MainAxisSize.min,
              crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                const Text('Las ediciones se aplican a nuevas preguntas; '
                  'las respuestas anteriores quedan conservadas.'),
                const SizedBox(height:12),
                TextField(controller:topic,decoration:const InputDecoration(
                  labelText:'Tema (letras minúsculas y guiones bajos)')),
                const SizedBox(height:10),
                TextField(controller:es,maxLines:2,maxLength:250,
                  decoration:const InputDecoration(labelText:'Pregunta en español')),
                TextField(controller:en,maxLines:2,maxLength:250,
                  decoration:const InputDecoration(labelText:'Question in English')),
                const Divider(),
                for(var i=0;i<4;i++)Padding(
                  padding:const EdgeInsets.only(top:10),
                  child:Row(children:[
                    Expanded(child:TextField(controller:optEs[i],
                      decoration:InputDecoration(
                        labelText:'Opción '+(i+1).toString()+' ES'))),
                    const SizedBox(width:12),
                    Expanded(child:TextField(controller:optEn[i],
                      decoration:InputDecoration(
                        labelText:'Option '+(i+1).toString()+' EN'))),
                  ]),
                ),
                SwitchListTile(title:const Text('Pregunta activa'),
                  subtitle:const Text('Desactivar no borra respuestas anteriores.'),
                  value:enabled,onChanged:(v)=>update(()=>enabled=v)),
              ]),
          ),
        ),
        actions:[
          TextButton(onPressed:submitting?null:()=>Navigator.pop(context,false),
            child:const Text('Cancelar')),
          FilledButton(
            key:const Key('fit-ia-admin-save-question'),
            onPressed:submitting?null:()async{
              update(()=>submitting=true);
              try{
                await widget.repository.saveQuestion({
                  ...q,'topic':topic.text.trim(),
                  'prompt_es':es.text.trim(),'prompt_en':en.text.trim(),
                  'enabled':enabled,
                  'choices_es':List.generate(4,(i)=>{
                    'key':'opt_'+(i+1).toString(),
                    'label':optEs[i].text.trim(),
                  }),
                  'choices_en':List.generate(4,(i)=>{
                    'key':'opt_'+(i+1).toString(),
                    'label':optEn[i].text.trim(),
                  }),
                });
                if(context.mounted)Navigator.pop(context,true);
              }catch(_){
                if(context.mounted){
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:Text('No se pudo guardar. Revisa las cuatro '
                      'opciones, traducciones y permisos MFA.')));
                  update(()=>submitting=false);
                }
              }
            },
            child:Text(submitting?'Guardando…':'Guardar pregunta')),
        ],
      )));
    WidgetsBinding.instance.addPostFrameCallback((_){
      topic.dispose();es.dispose();en.dispose();
      for(final c in [...optEs,...optEn]){c.dispose();}
    });
    if(saved==true&&mounted){
      await _load();_notice('Pregunta actualizada.');
    }
  }
  @override
  Widget build(BuildContext context){
    final query=filter.text.trim().toLowerCase();
    final visible=questions.where((q)=>query.isEmpty||
      [q['id'],q['topic'],q['prompt_es'],q['prompt_en']]
      .any((value)=>value.toString().toLowerCase().contains(query))).toList();
    return Padding(key:const Key('fit-ia-admin-page'),
      padding:const EdgeInsets.all(16),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text('Administrar Fit-IA',
          style:Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:5),
        const Text('Bancos de preguntas y criterios por pilar. '
          'Solo administración verificada con MFA.'),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,
          child:Row(children:[
            for(var i=0;i<3;i++)Padding(
              padding:const EdgeInsets.only(right:8),
              child:ChoiceChip(key:Key('fit-ia-admin-pillar-'+i.toString()),
                label:Text(names[i]),selected:selected==i,
                onSelected:(_)=>_pillar(i))),
          ])),
        const SizedBox(height:12),
        if(loading)const LinearProgressIndicator(minHeight:2),
        if(issue!=null)Card(child:ListTile(
          title:Text(issue!),trailing:TextButton(onPressed:_load,
            child:const Text('Reintentar')))),
        if(!loading&&issue==null)...[
          Card(child:Padding(padding:const EdgeInsets.all(14),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                const Icon(Icons.tune_outlined),
                const SizedBox(width:8),
                Expanded(child:Text('Nivel de conocimiento · '+names[selected],
                  style:Theme.of(context).textTheme.titleMedium)),
                TextButton(
                  key:const Key('fit-ia-admin-configure-depth'),
                  onPressed:()=>setState(()=>editingRules=!editingRules),
                  child:Text(editingRules?'Cerrar':'Configurar')),
              ]),
              Text('Medio: '+(rule['medium_answers']??4).toString()+
                ' respuestas / '+(rule['medium_topics']??3).toString()+
                ' temas · Fuerte: '+(rule['strong_answers']??10).toString()+
                ' respuestas / '+(rule['strong_topics']??6).toString()+' temas'),
              if(editingRules)...[
                const SizedBox(height:10),
                Wrap(spacing:10,runSpacing:10,children:[
                  _num('Medio · respuestas',ma),_num('Medio · temas',mt),
                  _num('Fuerte · respuestas',sa),_num('Fuerte · temas',st),
                ]),
                const SizedBox(height:10),
                FilledButton.icon(
                  key:const Key('fit-ia-admin-save-depth'),
                  onPressed:saving?null:_saveRules,
                  icon:const Icon(Icons.save_outlined),
                  label:const Text('Guardar criterios')),
              ],
            ]),
          )),
          const SizedBox(height:9),
          TextField(key:const Key('fit-ia-admin-search'),controller:filter,
            onChanged:(_)=>setState((){}),
            decoration:const InputDecoration(prefixIcon:Icon(Icons.search),
              hintText:'Buscar por tema, palabra o identificador')),
          const SizedBox(height:7),
          Text(visible.length.toString()+' de '+
            questions.length.toString()+' preguntas',
            style:Theme.of(context).textTheme.labelMedium),
          const SizedBox(height:5),
          Expanded(child:ListView.builder(
            key:const Key('fit-ia-admin-question-list'),
            itemCount:visible.length,
            itemBuilder:(ctx,index){
              final q=visible[index];
              return Card(child:ListTile(
                key:Key('fit-ia-admin-question-'+q['id'].toString()),
                title:Text(q['prompt_es'].toString(),maxLines:2,
                  overflow:TextOverflow.ellipsis),
                subtitle:Text(q['id'].toString()+' · '+q['topic'].toString()+
                  (q['enabled']==true?' · Activa':' · Desactivada')),
                leading:Icon(q['enabled']==true?
                  Icons.check_circle_outline:Icons.visibility_off_outlined),
                trailing:IconButton(
                  key:Key('fit-ia-admin-edit-'+q['id'].toString()),
                  onPressed:()=>_edit(q),tooltip:'Editar',
                  icon:const Icon(Icons.edit_outlined)),
                onTap:()=>_edit(q)));
            },
          )),
        ],
      ]),
    );
  }
}
