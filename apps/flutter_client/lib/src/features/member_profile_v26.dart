import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import 'dating_v27.dart';
import '../widgets/mfd_branding.dart';
import '../theme/fitness_date_theme.dart';

List<String> _tokens(String text) => text.split(',')
    .map((x) => x.trim()).where((x) => x.isNotEmpty).toSet().toList();
String _list(dynamic value) => value is List ? value.join(', ') : '';

/// Full self-profile editor. Only the owner can call the Gateway endpoints.
class ProfileEditorV26 extends StatefulWidget {
  const ProfileEditorV26({super.key, required this.initial,
    required this.onSave, this.onCancel});
  final Map<String,dynamic>? initial;
  final Future<void> Function(Map<String,dynamic>) onSave;
  final VoidCallback? onCancel;
  @override
  State<ProfileEditorV26> createState() => _ProfileEditorV26State();
}

class _ProfileEditorV26State extends State<ProfileEditorV26> {
  final form = GlobalKey<FormState>();
  late final Map<String,TextEditingController> fields;
  late String frequency;
  late String intent;
  late String visibility;
  String? warning;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initial ?? {};
    const scalar = ['display_name','date_of_birth','city','headline',
      'about_me','occupation'];
    const lists = ['languages','hobbies','life_values','sports',
      'fitness_goals','achievements'];
    fields = {
      for(final k in scalar) k: TextEditingController(text:(data[k] ?? '').toString()),
      for(final k in lists) k: TextEditingController(text:_list(data[k])),
    };
    final prompts = data['prompts'] is List ? data['prompts'] as List : [];
    for (var i=0;i<3;i++) {
      final prompt = i<prompts.length && prompts[i] is Map
        ? prompts[i] as Map : <String,dynamic>{};
      fields['q$i'] = TextEditingController(
          text:(prompt['question'] ?? '').toString());
      fields['a$i'] = TextEditingController(
          text:(prompt['answer'] ?? '').toString());
    }
    frequency = (data['training_frequency'] ?? 'flexible').toString();
    intent = (data['dating_intent'] ?? 'unknown').toString();
    visibility = (data['social_visibility'] ?? 'private').toString();
  }

  @override
  void dispose() {
    for (final c in fields.values) { c.dispose(); }
    super.dispose();
  }

  Widget input(String field, String label,{int lines=1,bool required=false,
     int? maxLength,String? hint}) => Padding(
    padding:const EdgeInsets.only(bottom:12),
    child:TextFormField(
      key:Key('profile-$field'),controller:fields[field],
      maxLines:lines,maxLength:maxLength,
      decoration:InputDecoration(labelText:label,hintText:hint,
        alignLabelWithHint:lines>1),
      validator:required?(s)=>s==null||s.trim().length<2
          ?'Completa este campo':null:null,
    ));

  Widget heading(String title, IconData icon, Color color) =>
    Padding(padding:const EdgeInsets.fromLTRB(0,18,0,12),
      child:Row(children:[
        Icon(icon,color:color),const SizedBox(width:10),
        Flexible(child:Text(title,style:const TextStyle(
          fontSize:21,fontWeight:FontWeight.w900))),
      ]));

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final dob=fields['date_of_birth']!.text.trim();
    if(!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)){
      setState(()=>warning='Escribe la fecha AAAA-MM-DD');
      return;
    }
    final prompts=<Map<String,String>>[];
    for(var i=0;i<3;i++){
      final q=fields['q$i']!.text.trim();
      final a=fields['a$i']!.text.trim();
      if(q.isNotEmpty&&a.isNotEmpty)prompts.add({'question':q,'answer':a});
    }
    const scalar=['display_name','date_of_birth','city','headline',
      'about_me','occupation'];
    const lists=['languages','hobbies','life_values','sports',
      'fitness_goals','achievements'];
    final profile=<String,dynamic>{
      for(final k in scalar) k:fields[k]!.text.trim(),
      for(final k in lists) k:_tokens(fields[k]!.text),
      'prompts':prompts,
      'training_frequency':frequency,
      'dating_intent':intent,
      'social_visibility':visibility,
      'onboarding_complete':true,
    };
    setState((){saving=true;warning=null;});
    try { await widget.onSave(profile); }
    catch (_) {
      if(mounted)setState(()=>warning='No se guardó. Revisa los campos.');
    } finally {
      if(mounted)setState(()=>saving=false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(key:form,
    child:ListView(padding:const EdgeInsets.all(22),children:[
      const Text('Mi perfil 360°',key:Key('v26-profile-editor'),
        style:TextStyle(fontSize:31,fontWeight:FontWeight.w900)),
      const SizedBox(height:9),
      const Text('Quién eres como persona y cómo disfrutas el movimiento. '
        'Los datos están privados por defecto.',
        style:TextStyle(color:FitDateColors.muted)),
      heading('Mi historia personal',Icons.favorite_border,FitDateColors.coral),
      input('display_name','Nombre visible',required:true,maxLength:60),
      input('date_of_birth','Nacimiento privado · AAAA-MM-DD',
        required:true,hint:'1995-06-15'),
      const Text('La fecha no se publica y no constituye una verificación '
        'independiente de mayoría de edad.',
        style:TextStyle(color:FitDateColors.muted,fontSize:12)),
      const SizedBox(height:10),
      input('city','Ciudad general',required:true,maxLength:100),
      input('headline','Una frase que te describa',maxLength:160),
      input('about_me','Sobre mí',lines:4,maxLength:1200),
      input('occupation','Profesión (opcional)',maxLength:100),
      input('languages','Idiomas separados por coma',hint:'Español, Inglés'),
      input('hobbies','Gustos fuera del gym',
        hint:'Café, viajes, música, naturaleza'),
      input('life_values','Valores y prioridades',
        hint:'Familia, honestidad, curiosidad'),
      heading('Mi mundo fitness',Icons.directions_run,FitDateColors.lime),
      input('sports','Mis disciplinas',hint:'Running, fuerza, yoga, ciclismo'),
      DropdownButtonFormField<String>(
        initialValue:frequency,decoration:const InputDecoration(
          labelText:'Frecuencia de entrenamiento'),
        items:const [
          DropdownMenuItem(value:'starting',child:Text('Estoy empezando')),
          DropdownMenuItem(value:'one_to_two',child:Text('1–2 días')),
          DropdownMenuItem(value:'three_to_four',child:Text('3–4 días')),
          DropdownMenuItem(value:'five_plus',child:Text('5 o más días')),
          DropdownMenuItem(value:'flexible',child:Text('Flexible')),
        ],
        onChanged:(v)=>setState(()=>frequency=v??'flexible')),
      const SizedBox(height:13),
      input('fitness_goals','Objetivos deportivos',
        hint:'Mi primer 10K, más fuerza, movilidad'),
      input('achievements','Logros personales',
        hint:'Terminé mi primer 21K, carrera de montaña'),
      heading('Conversación y afinidad',Icons.auto_awesome,FitDateColors.lilac),
      for(var i=0;i<3;i++)...[
        input('q$i','Pregunta ${i + 1}',maxLength:110,
          hint:'Mi plan favorito de fin de semana es...'),
        input('a$i','Mi respuesta',lines:2,maxLength:280),
      ],
      DropdownButtonFormField<String>(
        initialValue:intent,decoration:const InputDecoration(
          labelText:'Tipo de conexión (privado)'),
        items:const [
          DropdownMenuItem(value:'unknown',child:Text('Prefiero decidir después')),
          DropdownMenuItem(value:'relationship',child:Text('Relación estable')),
          DropdownMenuItem(value:'companionship',child:Text('Compañía o amistad')),
          DropdownMenuItem(value:'open_to_explore',child:Text('Explorar con respeto')),
        ],
        onChanged:(v)=>setState(()=>intent=v??'unknown')),
      heading('Privacidad',Icons.shield_outlined,FitDateColors.lime),
      DropdownButtonFormField<String>(
        initialValue:visibility,decoration:const InputDecoration(
          labelText:'Preferencia social futura'),
        items:const [
          DropdownMenuItem(value:'private',child:Text('Solo yo')),
          DropdownMenuItem(value:'members',child:Text('Miembros, al habilitarse')),
        ],
        onChanged:(v)=>setState(()=>visibility=v??'private')),
      const SizedBox(height:10),
      const Text('Guardar esta preferencia NO publica tu perfil ni '
        'activa FitDating. Los gimnasios, studios y horarios siguen privados.',
        style:TextStyle(color:FitDateColors.muted,fontSize:12)),
      if(warning!=null)Padding(padding:const EdgeInsets.all(10),
        child:Text(warning!,style:const TextStyle(color:Colors.redAccent))),
      const SizedBox(height:16),
      FilledButton.icon(
        key:const Key('v26-save-profile'),onPressed:saving?null:save,
        icon:const Icon(Icons.save_outlined),
        label:Text(saving?'Guardando...':'Guardar mi perfil')),
      if(widget.onCancel!=null)TextButton(
        onPressed:widget.onCancel,child:const Text('Cancelar')),
    ]));

}

/// Owner-only home; no real dating/discovery feed until independent gates pass.
class MemberProfileHomeV26 extends StatefulWidget {
  const MemberProfileHomeV26({super.key,required this.profile,
    required this.api,required this.onEdit,required this.onLogout});
  final Map<String,dynamic> profile;
  final MemberV26Api api;
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  @override
  State<MemberProfileHomeV26> createState()=>_MemberProfileHomeV26State();
}

class _MemberProfileHomeV26State extends State<MemberProfileHomeV26> {
  List<Map<String,dynamic>> photos=[];
  List<Map<String,dynamic>> places=[];
  String? problem;
  bool loading=true;
  @override
  void initState(){super.initState(); reload();}
  Future<void> reload() async {
    setState((){loading=true;problem=null;});
    try {
      final result=await Future.wait([
        widget.api.loadPlaces(),widget.api.loadPhotos()]);
      if(mounted)setState((){places=result[0];photos=result[1];});
    } catch (_) {
      if(mounted)setState(()=>problem='No se pudieron cargar los datos privados.');
    } finally {if(mounted)setState(()=>loading=false);}
  }

  Future<void> addPlace() async {
    final name=TextEditingController();
    final city=TextEditingController();
    final zone=TextEditingController();
    var kind='gym';
    final result=await showDialog<Map<String,String>>(context:context,
      builder:(dialog)=>StatefulBuilder(builder:(dialog,setDialog)=>
        AlertDialog(title:const Text('Mi lugar de entrenamiento'),
          content:SingleChildScrollView(child:Column(
            mainAxisSize:MainAxisSize.min,children:[
              DropdownButtonFormField<String>(initialValue:kind,
                decoration:const InputDecoration(labelText:'Tipo'),
                items:const [
                  DropdownMenuItem(value:'gym',child:Text('Gimnasio')),
                  DropdownMenuItem(value:'studio',child:Text('Studio')),
                  DropdownMenuItem(value:'running_club',child:Text('Club de running')),
                  DropdownMenuItem(value:'park',child:Text('Parque')),
                  DropdownMenuItem(value:'box',child:Text('Box')),
                  DropdownMenuItem(value:'other',child:Text('Otro')),
                ],
                onChanged:(v)=>setDialog(()=>kind=v??'gym')),
              const SizedBox(height:10),
              TextField(controller:name,onChanged:(_)=>setDialog((){}),
                decoration:const InputDecoration(labelText:'Nombre')),
              const SizedBox(height:10),
              TextField(controller:city,onChanged:(_)=>setDialog((){}),
                decoration:const InputDecoration(labelText:'Ciudad')),
              const SizedBox(height:10),
              TextField(controller:zone,
                decoration:const InputDecoration(
                  labelText:'Zona general (opcional)')),
              const SizedBox(height:10),
              const Text('El gimnasio y los horarios no se compartirán.',
                style:TextStyle(fontSize:12)),
            ])),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog),
              child:const Text('Cancelar')),
            FilledButton(
              onPressed:name.text.trim().length<2||city.text.trim().length<2
                ?null:()=>Navigator.pop(dialog,{
                  'venue_kind':kind,'place_name':name.text.trim(),
                  'city':city.text.trim(),'general_zone':zone.text.trim()}),
              child:const Text('Guardar')),
          ])));
    name.dispose();city.dispose();zone.dispose();
    if(result==null)return;
    try{await widget.api.addPlace(result);await reload();}
    catch(_){if(mounted)setState(()=>problem='No se pudo guardar el lugar.');}
  }

  Widget section(String title,IconData icon,Color color,Widget child)=>
    Card(child:Padding(padding:const EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(icon,color:color),const SizedBox(width:9),
          Expanded(child:Text(title,style:const TextStyle(
            fontWeight:FontWeight.w900,fontSize:19)))]),
        const SizedBox(height:12),child,
      ])));
  Widget tags(dynamic value) {
    final items=value is List?value:[];
    return items.isEmpty
      ?const Text('Aún sin información',
        style:TextStyle(color:FitDateColors.muted))
      :Wrap(spacing:7,runSpacing:6,
        children:items.map<Widget>((x)=>Chip(label:Text(x.toString()))).toList());
  }
  Widget photoTile(Map<String,dynamic> photo)=>SizedBox(width:140,
    child:Card(child:Padding(padding:const EdgeInsets.all(9),
      child:Column(children:[
        SizedBox(height:110,
          child:FutureBuilder<Uint8List>(
            future:widget.api.photoContent(photo['id'].toString()),
            builder:(context,snapshot)=>snapshot.hasData
              ?Image.memory(snapshot.data!,fit:BoxFit.cover)
              :const Center(child:Icon(Icons.image_outlined)))),
        Text((photo['moderation_state']??'pending').toString(),
          style:const TextStyle(color:FitDateColors.muted,fontSize:11)),
        IconButton(tooltip:'Eliminar mi foto',
          icon:const Icon(Icons.delete_outline),
          onPressed:()async{
            try{await widget.api.removePhoto(photo['id'].toString());await reload();}
            catch(_){if(mounted)setState(()=>problem='No se pudo eliminar.');}
          }),
      ]))));

  @override
  Widget build(BuildContext context) {
    final p=widget.profile;
    return Scaffold(
      appBar:AppBar(title:const Text('My Fitness Date'),
        actions:[
          IconButton(tooltip:'Editar',onPressed:widget.onEdit,
            icon:const Icon(Icons.edit_outlined)),
          IconButton(tooltip:'Cerrar sesión',onPressed:widget.onLogout,
            icon:const Icon(Icons.logout)),
        ]),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:980),
        child:ListView(padding:const EdgeInsets.all(16),children:[
          Container(padding:const EdgeInsets.all(22),
            decoration:BoxDecoration(
              borderRadius:BorderRadius.circular(24),
              gradient:const LinearGradient(colors:[
                Color(0xFF38233D),Color(0xFF1B3029)])),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const MfdBranding(full:false,width:80),
              const SizedBox(height:12),
              const Text('MI PERFIL · PRIVADO',style:TextStyle(
                color:FitDateColors.lime,letterSpacing:2,fontSize:11)),
              const SizedBox(height:10),
              Text((p['display_name']??'').toString(),
                key:const Key('v26-member-name'),
                style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900)),
              Text((p['city']??'').toString(),style:const TextStyle(
                color:FitDateColors.muted)),
              const SizedBox(height:10),
              Text((p['headline']??'').toString()),
            ])),
          section('Yo como persona',Icons.favorite,FitDateColors.coral,
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text((p['about_me']??'').toString()),
              const SizedBox(height:12),tags(p['hobbies']),
              const SizedBox(height:12),
              Text('Valores: ${_list(p['life_values'])}'),
              for(final answer in (p['prompts'] is List?p['prompts'] as List:[]))
                if(answer is Map)
                  ListTile(title:Text((answer['question']??'').toString()),
                    subtitle:Text((answer['answer']??'').toString())),
            ])),
          section('Mi lado deportivo',Icons.directions_run,FitDateColors.lime,
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              tags(p['sports']),const SizedBox(height:8),
              const Text('Mis objetivos',style:TextStyle(fontWeight:FontWeight.bold)),
              tags(p['fitness_goals']),const SizedBox(height:10),
              const Text('Mis logros',style:TextStyle(fontWeight:FontWeight.bold)),
              tags(p['achievements']),
            ])),
          section('Fotografías privadas',Icons.photo_library_outlined,
            FitDateColors.lilac,Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Hasta ocho fotos. Se eliminan metadatos y '
                  'no se muestran a otras personas sin aprobación.',
                  style:TextStyle(color:FitDateColors.muted,fontSize:12)),
                const SizedBox(height:12),
                const Text('Carga de fotos suspendida hasta completar la sanitización y moderación del servicio.',
                  style:TextStyle(color:FitDateColors.muted,fontSize:12)),
                if(loading)const LinearProgressIndicator(),
                Wrap(spacing:8,runSpacing:8,
                  children:photos.map(photoTile).toList()),
            ])),
          section('Gimnasios, studios y zonas privadas',
            Icons.shield_outlined,FitDateColors.lime,Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Solo tú ves estos lugares. Nunca mostramos '
                  'ubicaciones exactas ni horarios de asistencia.',
                  style:TextStyle(color:FitDateColors.muted,fontSize:12)),
                const SizedBox(height:12),
                FilledButton.icon(onPressed:addPlace,
                  icon:const Icon(Icons.add_location_alt_outlined),
                  label:const Text('Añadir lugar privado')),
                for(final place in places)
                  ListTile(
                    title:Text((place['place_name']??'').toString()),
                    subtitle:Text((place['city']??'').toString()),
                    trailing:IconButton(
                      icon:const Icon(Icons.delete_outline),
                      onPressed:()async{
                        try{await widget.api.removePlace(place['id'].toString());await reload();}
                        catch(_){if(mounted)setState(()=>problem='No se pudo eliminar.');}
                      },
                    )),
            ])),
          section('FitDating y seguridad',Icons.verified_user_outlined,
            FitDateColors.coral,
            Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              const Text('Revisa tu elegibilidad, registra el consentimiento separado y consulta personas compatibles cuando se apruebe tu verificación de edad.'),
              const SizedBox(height:12),
              FilledButton.icon(
                key:const Key('fitdating-open'),
                onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                  builder:(_)=>DatingV27(api:widget.api))),
                icon:const Icon(Icons.favorite_outline),
                label:const Text('Explorar FitDating')),
            ])),
          if(problem!=null)Text(problem!,
            style:const TextStyle(color:Colors.redAccent)),
        ]),
      )),
    );
  }
}
