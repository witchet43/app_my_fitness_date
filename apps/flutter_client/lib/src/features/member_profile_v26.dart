import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import 'dating_v27.dart';
import 'rhythm_concept_lab_b10.dart';
import 'fitted_profile_story_v28.dart';
import '../core/fitted_profile_insights_v29.dart';
import 'fitted_gym_shield_v28.dart';
import 'fitted_affinity_home_v16.dart';
import 'fitted_immersive_home_b17.dart';
import 'fitted_age_verification_b14.dart';
import 'activities_b1.dart';
import 'my_activities_b2.dart';
import '../widgets/mfd_branding.dart';
import 'community_b4.dart';
import '../theme/fitness_date_theme.dart';
import '../core/live_brand.dart';
import '../core/fitted_locale.dart';
import '../widgets/fitted_rhythm_hero.dart';

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
      decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,label),
        hintText:hint==null?null:FittedLocaleScope.translate(context,hint),
        alignLabelWithHint:lines>1),
      validator:required?(s)=>s==null||s.trim().length<2
          ?'Completa este campo':null:null,
    ));

  Widget heading(String title, IconData icon, Color color) {
    final number = title == 'Mi historia personal' ? '01'
      : title == 'Mi mundo fitness' ? '02' : '03';
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 26, 0, 13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [
            color.withValues(alpha: .16),
            FitDateColors.surface.withValues(alpha: .98),
          ]),
          border: Border.all(color: color.withValues(alpha: .32)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FITTED / $number', style: TextStyle(
                fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800,
                color: color)),
              const SizedBox(height: 3),
              FittedText(title, style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700)),
            ],
          )),
          Icon(Icons.arrow_outward_rounded, size: 18,
            color: color.withValues(alpha: .65)),
        ]),
      ),
    );
  }

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
    child:ListView(padding:const EdgeInsets.symmetric(horizontal:20,vertical:22),children:[
      const FittedRhythmHero(
        titleEs:'Lo que te mueve, te conecta.',
        titleEn:'What moves you, connects you.',
        subtitleEs:'Construye un perfil que hable de tu energía, tus valores y el espacio que quieres compartir con alguien.',
        subtitleEn:'Build a profile shaped by your energy, values and the space you want to share with someone.',
        compact:true,
      ),
      const SizedBox(height:23),
      const FittedText('Mi perfil 360°',key:Key('v26-profile-editor'),
        style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      const FittedText('Tu historia va más allá del entrenamiento. Tú decides qué compartir; tus datos son privados por defecto.',
        style:TextStyle(color:FitDateColors.muted,height:1.5)),
      const SizedBox(height:9),
      const FittedText('MOVE  /  LIVE  /  RELATE',
        style:TextStyle(fontSize:10,letterSpacing:2,
          fontWeight:FontWeight.w800,color:FitDateColors.aqua)),
      heading('Mi historia personal',Icons.favorite_border,FitDateColors.coral),
      input('display_name','Nombre visible',required:true,maxLength:60),
      input('date_of_birth','Nacimiento privado · AAAA-MM-DD',
        required:true,hint:'1995-06-15'),
      const FittedText('La fecha no se publica y no constituye una verificación '
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
        initialValue:frequency,decoration:InputDecoration(
          labelText:FittedLocaleScope.translate(context,'Frecuencia de entrenamiento')),
        items:const [
          DropdownMenuItem(value:'starting',child:FittedText('Estoy empezando')),
          DropdownMenuItem(value:'one_to_two',child:FittedText('1–2 días')),
          DropdownMenuItem(value:'three_to_four',child:FittedText('3–4 días')),
          DropdownMenuItem(value:'five_plus',child:FittedText('5 o más días')),
          DropdownMenuItem(value:'flexible',child:FittedText('Flexible')),
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
        initialValue:intent,decoration:InputDecoration(
          labelText:FittedLocaleScope.translate(context,'Tipo de conexión (privado)')),
        items:const [
          DropdownMenuItem(value:'unknown',child:FittedText('Prefiero decidir después')),
          DropdownMenuItem(value:'relationship',child:FittedText('Relación estable')),
          DropdownMenuItem(value:'companionship',child:FittedText('Compañía o amistad')),
          DropdownMenuItem(value:'open_to_explore',child:FittedText('Explorar con respeto')),
        ],
        onChanged:(v)=>setState(()=>intent=v??'unknown')),
      heading('Privacidad',Icons.shield_outlined,FitDateColors.lime),
      DropdownButtonFormField<String>(
        initialValue:visibility,decoration:InputDecoration(
          labelText:FittedLocaleScope.translate(context,'Preferencia social futura')),
        items:const [
          DropdownMenuItem(value:'private',child:FittedText('Solo yo')),
          DropdownMenuItem(value:'members',child:FittedText('Miembros, al habilitarse')),
        ],
        onChanged:(v)=>setState(()=>visibility=v??'private')),
      const SizedBox(height:10),
      const FittedText('Guardar esta preferencia NO publica tu perfil ni '
        'activa FitDating. Los gimnasios, studios y horarios siguen privados.',
        style:TextStyle(color:FitDateColors.muted,fontSize:12)),
      if(warning!=null)Padding(padding:const EdgeInsets.all(10),
        child:FittedText(warning!,style:const TextStyle(color:Colors.redAccent))),
      const SizedBox(height:16),
      FilledButton.icon(
        key:const Key('v26-save-profile'),onPressed:saving?null:save,
        icon:const Icon(Icons.save_outlined),
        label:FittedText(saving?'Guardando...':'Guardar mi perfil')),
      if(widget.onCancel!=null)TextButton(
        onPressed:widget.onCancel,child:const FittedText('Cancelar')),
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
  late final Future<bool> lifestyleConsent;
  bool consentGrantedInSession=false;
  int selectedArea = 0; // 0 = Inicio, 1 = Mi perfil
  List<Map<String,dynamic>> photos=[];
  List<Map<String,dynamic>> places=[];
  Map<String,dynamic>? lifestyle;
  String? startingRhythm;
  String? problem;
  bool loading=true;
  @override
  void initState(){
    super.initState();
    final hint=widget.api.auth.auth.currentUser?.userMetadata?['fitted_starting_rhythm'];
    if(FittedProfileInsights.segments.contains(hint)){
      startingRhythm=hint as String;
    }
    lifestyleConsent=widget.api.loadConsents().then((records)=>records.any(
      (r)=>r['consent_kind']=='dating' &&
        r['document_version']=='dating-v1')).catchError((Object _)=>false);
    reload();
  }
  Future<void> reload() async {
    setState((){loading=true;problem=null;});
    try {
      final result=await Future.wait([
        widget.api.loadPlaces(),widget.api.loadPhotos()]);
      if(mounted)setState((){places=result[0];photos=result[1];});
      // Private rhythm answers are fetched ONLY with separate dating consent.
      final consent=consentGrantedInSession || await lifestyleConsent;
      if(consent){
        try{
          final saved=await widget.api.loadRhythmB11();
          if(mounted)setState(()=>lifestyle=saved);
        }catch(_){if(mounted)setState(()=>lifestyle=null);}
      } else if(mounted){setState(()=>lifestyle=null);}
    } catch (_) {
      if(mounted)setState(()=>problem='No se pudieron cargar los datos privados.');
    } finally {if(mounted)setState(()=>loading=false);}
  }

  Future<void> setStartingRhythm(String? value) async {
    if(value!=null&&!FittedProfileInsights.segments.contains(value))return;
    try{
      await widget.api.auth.auth.updateUser(UserAttributes(
        data:{'fitted_starting_rhythm':value},
      ));
      if(mounted)setState(()=>startingRhythm=value);
    }catch(_){
      if(mounted)ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content:Text(FittedLocaleScope.t(context,
          'No se pudo guardar tu selección inicial.',
          'Could not save your starting preference.'))));
    }
  }

  Future<void> configurePillars([int initialPillar=0]) async {
    var consent=consentGrantedInSession || await lifestyleConsent;
    if(!mounted)return;
    if(!consent){
      final approved=await showDialog<bool>(context:context,
        builder:(dialog)=>AlertDialog(
          title:Text(FittedLocaleScope.t(context,
            'Tu estilo de vida es privado',
            'Your lifestyle is private')),
          content:Text(FittedLocaleScope.t(context,
            'Para guardar tus tres pilares, acepta el consentimiento '
            'independiente de FitDating. Tus respuestas permanecen privadas '
            'y no activan el descubrimiento ni los mensajes automáticamente.',
            'To save your three pillars, accept the separate FitDating '
            'consent. Your answers stay private and do not automatically '
            'enable discovery or messages.')),
          actions:[
            TextButton(
              onPressed:()=>Navigator.of(dialog).pop(false),
              child:Text(FittedLocaleScope.t(context,'Ahora no','Not now'))),
            FilledButton(
              key:const Key('pillars-consent-confirm'),
              onPressed:()=>Navigator.of(dialog).pop(true),
              child:Text(FittedLocaleScope.t(context,
                'Acepto y continúo','I agree and continue'))),
          ],
        ),
      );
      if(!mounted||approved!=true)return;
      try{
        await widget.api.acceptDating();
        consentGrantedInSession=true;
        consent=true;
      }catch(_){
        if(mounted)ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content:Text(FittedLocaleScope.t(context,
            'No se pudo guardar tu consentimiento. Intenta de nuevo.',
            'Could not save your consent. Try again.'))));
        return;
      }
    }
    if(!mounted)return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>RhythmConceptLabB10(
        repository:widget.api,canSave:consent,
        profileMode:true,initialPillar:initialPillar)));
    if(mounted)await reload();
  }

  Future<void> configureShield() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>FittedGymShieldV28(
        api:widget.api,onAddPlace:addPlace)));
    if(mounted)await reload();
  }

  Future<void> addPlace() async {
    final name=TextEditingController();
    final city=TextEditingController();
    final zone=TextEditingController();
    var kind='gym';
    final result=await showDialog<Map<String,String>>(context:context,
      builder:(dialog)=>StatefulBuilder(builder:(dialog,setDialog)=>
        AlertDialog(title:const FittedText('Mi lugar de entrenamiento'),
          content:SingleChildScrollView(child:Column(
            mainAxisSize:MainAxisSize.min,children:[
              DropdownButtonFormField<String>(initialValue:kind,
                decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Tipo')),
                items:const [
                  DropdownMenuItem(value:'gym',child:FittedText('Gimnasio')),
                  DropdownMenuItem(value:'studio',child:FittedText('Studio')),
                  DropdownMenuItem(value:'running_club',child:FittedText('Club de running')),
                  DropdownMenuItem(value:'park',child:FittedText('Parque')),
                  DropdownMenuItem(value:'box',child:FittedText('Box')),
                  DropdownMenuItem(value:'other',child:FittedText('Otro')),
                ],
                onChanged:(v)=>setDialog(()=>kind=v??'gym')),
              const SizedBox(height:10),
              TextField(controller:name,onChanged:(_)=>setDialog((){}),
                decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Nombre'))),
              const SizedBox(height:10),
              TextField(controller:city,onChanged:(_)=>setDialog((){}),
                decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Ciudad'))),
              const SizedBox(height:10),
              TextField(controller:zone,
                decoration:InputDecoration(
                  labelText:FittedLocaleScope.translate(context,'Zona general (opcional)'))),
              const SizedBox(height:10),
              const FittedText('El gimnasio y los horarios no se compartirán.',
                style:TextStyle(fontSize:12)),
            ])),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog),
              child:const FittedText('Cancelar')),
            FilledButton(
              onPressed:name.text.trim().length<2||city.text.trim().length<2
                ?null:()=>Navigator.pop(dialog,{
                  'venue_kind':kind,'place_name':name.text.trim(),
                  'city':city.text.trim(),'general_zone':zone.text.trim()}),
              child:const FittedText('Guardar')),
          ])));
    name.dispose();city.dispose();zone.dispose();
    if(result==null)return;
    try{await widget.api.addPlace(result);await reload();}
    catch(_){if(mounted)setState(()=>problem='No se pudo guardar el lugar.');}
  }

  Future<void> uploadMainPhoto() async {
    try{
      final picked=await FilePicker.pickFile(
        type:FileType.custom,allowedExtensions:['jpg','jpeg','png']);
      if(picked==null)return;
      final bytes=await picked.readAsBytes();
      final name=picked.name.toLowerCase();
      final kind=name.endsWith('.png')?'image/png':'image/jpeg';
      if(bytes.isEmpty||bytes.length>6*1024*1024){
        throw const MemberApiException('La foto debe pesar menos de 6 MB.');
      }
      final existing=photos.where((p)=>p['position']==0).toList();
      if(existing.isNotEmpty){
        if(!mounted)return;
        final confirm=await showDialog<bool>(context:context,builder:(ctx)=>
          AlertDialog(
            title:Text(FittedLocaleScope.t(context,
              'Cambiar foto de perfil','Replace profile photo')),
            content:Text(FittedLocaleScope.t(context,
              'La foto anterior se eliminará. La nueva permanecerá privada '
              'hasta que un administrador la revise.',
              'Your previous photo will be deleted. The new one remains '
              'private until a moderator approves it.')),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(ctx,false),
                child:const Text('Cancelar')),
              FilledButton(onPressed:()=>Navigator.pop(ctx,true),
                child:const Text('Continuar')),
            ]));
        if(confirm!=true)return;
        await widget.api.removePhoto(existing.first['id'].toString());
      }
      await widget.api.uploadPhoto(bytes,kind);
      await reload();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(FittedLocaleScope.t(context,
          'Foto guardada en privado. Pendiente de moderación.',
          'Photo stored privately and awaiting moderation.'))));
    }catch(_){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(FittedLocaleScope.t(context,
          'No fue posible guardar la foto. Usa JPG o PNG.',
          'Unable to save photo. Please use JPG or PNG.'))));
    }
  }

  void openFittedDiscovery(){
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>DatingV27(api:widget.api))).then((_){
        if(mounted)reload();
      });
  }
  void openAgeReview(){
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>FittedAgeVerificationB14(api:widget.api))).then((_){
        if(mounted)reload();
      });
  }

  Widget section(String title,IconData icon,Color color,Widget child)=>
    Card(child:Padding(padding:const EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(icon,color:color),const SizedBox(width:9),
          Expanded(child:FittedText(title,style:const TextStyle(
            fontWeight:FontWeight.w900,fontSize:19)))]),
        const SizedBox(height:12),child,
      ])));
  Widget tags(dynamic value) {
    final items=value is List?value:[];
    return items.isEmpty
      ?const FittedText('Aún sin información',
        style:TextStyle(color:FitDateColors.muted))
      :Wrap(spacing:7,runSpacing:6,
        children:items.map<Widget>((x)=>Chip(label:FittedText(x.toString()))).toList());
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
        FittedText((photo['moderation_state']??'pending').toString(),
          style:const TextStyle(color:FitDateColors.muted,fontSize:11)),
        IconButton(tooltip:FittedLocaleScope.translate(context,'Eliminar mi foto'),
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
      appBar:AppBar(
        titleSpacing:12,
        title:Row(
          mainAxisSize:MainAxisSize.min,
          children:[
            const MfdBranding(full:false,width:38),
            const SizedBox(width:11),
            Flexible(child:Text(
              LiveBrandScope.of(context).name,
              key:const Key('fitted-member-header-name'),
              maxLines:1,overflow:TextOverflow.ellipsis,
              style:const TextStyle(
                fontSize:20,fontWeight:FontWeight.w800,
                letterSpacing:.2),
            )),
          ],
        ),
        actions:[
          if(MediaQuery.sizeOf(context).width>=950)...[
            TextButton.icon(onPressed:()=>setState(()=>selectedArea=0),
              icon:const Icon(Icons.home_outlined,size:18),
              label:Text(FittedLocaleScope.t(context,'Inicio','Home'))),
            TextButton.icon(onPressed:openFittedDiscovery,
              icon:const Icon(Icons.people_outline,size:18),
              label:Text(FittedLocaleScope.t(context,'Buscar fits','Find fits'))),
            TextButton.icon(onPressed:()=>setState(()=>selectedArea=1),
              icon:const Icon(Icons.person_outline,size:18),
              label:Text(FittedLocaleScope.t(context,'Mi perfil','My profile'))),
            TextButton.icon(onPressed:widget.onEdit,
              icon:const Icon(Icons.settings_outlined,size:18),
              label:Text(FittedLocaleScope.t(context,'Configuración','Settings'))),
          ],
          const FittedLanguageSelector(),
          PopupMenuButton<String>(
            tooltip:FittedLocaleScope.t(context,'Cuenta','Account'),
            icon:const Icon(Icons.account_circle_outlined),
            onSelected:(value) {
              if(value=='profile')setState(()=>selectedArea=1);
              if(value=='edit')widget.onEdit();
              if(value=='activities')Navigator.of(context).push(
                MaterialPageRoute<void>(builder:(_)=>
                  ActivitiesB1(api:widget.api)));
              if(value=='reservations')Navigator.of(context).push(
                MaterialPageRoute<void>(builder:(_)=>
                  MyActivitiesB2(api:widget.api)));
              if(value=='logout')widget.onLogout();
            },
            itemBuilder:(_)=>[
              PopupMenuItem(value:'profile',
                child:Text(FittedLocaleScope.t(context,'Mi perfil','My profile'))),
              PopupMenuItem(value:'edit',
                child:Text(FittedLocaleScope.t(context,'Editar perfil','Edit profile'))),
              PopupMenuItem(value:'activities',
                child:Text(FittedLocaleScope.t(context,'Actividades (opcional)','Activities (optional)'))),
              PopupMenuItem(value:'reservations',
                child:Text(FittedLocaleScope.t(context,'Mis reservas','My reservations'))),
              const PopupMenuDivider(),
              PopupMenuItem(value:'logout',
                child:Text(FittedLocaleScope.t(context,'Cerrar sesión','Sign out'))),
            ],
          ),
        ]),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:1440),
        child:ListView(padding:const EdgeInsets.all(16),children:[
          if(MediaQuery.sizeOf(context).width<950)SegmentedButton<int>(
            key:const Key('fitted-home-navigation'),
            showSelectedIcon:false,
            segments:[
              ButtonSegment(value:0,icon:const Icon(Icons.home_outlined),
                label:Text(FittedLocaleScope.t(context,'Inicio','Home'))),
              ButtonSegment(value:1,icon:const Icon(Icons.person_outline),
                label:Text(FittedLocaleScope.t(context,'Mi perfil','My profile'))),
            ],
            selected:{selectedArea},
            onSelectionChanged:(value)=>setState(()=>selectedArea=value.first),
          ),
          const SizedBox(height:18),
          if(selectedArea==0)...[
            FittedImmersiveHomeB17(
              api:widget.api,profile:p,rhythm:lifestyle,photos:photos,
              onConfigurePillar:configurePillars,
              onEditProfile:widget.onEdit,
              onUploadPhoto:uploadMainPhoto,
              onDiscover:openFittedDiscovery,
              onVerifyAge:openAgeReview,
            ),
            const SizedBox(height:17),
            Row(children:[
              Expanded(child:OutlinedButton.icon(
                key:const Key('b4-member-community'),
                onPressed:()=>Navigator.of(context).push(
                  MaterialPageRoute<void>(builder:(_)=>
                    CommunityB4(api:widget.api))),
                icon:const Icon(Icons.groups_outlined),
                label:Text(FittedLocaleScope.t(context,
                  'Explorar comunidad','Explore community')))),
              const SizedBox(width:12),
              Expanded(child:OutlinedButton.icon(
                key:const Key('b17-edit-profile-shortcut'),
                onPressed:widget.onEdit,
                icon:const Icon(Icons.person_outline),
                label:Text(FittedLocaleScope.t(context,
                  'Editar mi perfil','Edit my profile')))),
            ]),
          ]else...[
            Row(children:[
              Expanded(child:Text(FittedLocaleScope.t(context,
                'Mi perfil privado','My private profile'),
                style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800))),
              IconButton(
                tooltip:FittedLocaleScope.t(context,'Editar','Edit'),
                onPressed:widget.onEdit,icon:const Icon(Icons.edit_outlined)),
            ]),
            const SizedBox(height:12),
          KeyedSubtree(
            key:const Key('fitted-profile-three-pillars-card'),
            child:FittedProfileStoryV28(
              profile:p,rhythm:lifestyle,
              startingPreference:startingRhythm,
              onChooseStarting:setStartingRhythm,
              onConfigure:()=>configurePillars(),
              onEditIdentity:widget.onEdit,
            ),
          ),

          if((lifestyle!=null &&
                (lifestyle!['challenge']??'').toString().trim().isNotEmpty) ||
              (p['achievements'] is List &&
                (p['achievements'] as List).isNotEmpty))
            section(FittedLocaleScope.t(context,
                'Mis retos y logros','My challenges and milestones'),
              Icons.flag_outlined,FitDateColors.lime,
              Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                if(lifestyle!=null &&
                    (lifestyle!['challenge']??'').toString().trim().isNotEmpty)
                  ListTile(
                    contentPadding:EdgeInsets.zero,
                    leading:const Icon(Icons.track_changes_outlined),
                    title:Text(FittedLocaleScope.t(context,
                      'En lo que estoy trabajando','What I am working on')),
                    subtitle:Text(lifestyle!['challenge'].toString())),
                if(p['achievements'] is List &&
                    (p['achievements'] as List).isNotEmpty)
                  tags(p['achievements']),
              ])),
          section('Gym Shield',Icons.shield_outlined,
            FitDateColors.lime,
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(FittedLocaleScope.t(context,
                'Protege dónde y cuándo entrenas. Decide si aceptas '
                'personas de tu mismo gimnasio o de horarios compartidos, '
                'sin publicar tu rutina.',
                'Protect when and where you train. Choose whether to '
                'allow people from your gym or overlapping times, '
                'without publishing your schedule.')),
              const SizedBox(height:12),
              Wrap(spacing:7,runSpacing:7,children:[
                for(final place in places.take(3))
                  Chip(avatar:const Icon(Icons.lock_outline,size:16),
                    label:Text((place['place_name']??'').toString())),
              ]),
              if(places.isEmpty)
                Text(FittedLocaleScope.t(context,
                  'Añade tus lugares y ventanas generales para personalizar '
                  'la protección.',
                  'Add places and broad time windows to customize protection.')),
              const SizedBox(height:13),
              FilledButton.icon(
                key:const Key('fitted-open-gym-shield'),
                onPressed:configureShield,
                icon:const Icon(Icons.admin_panel_settings_outlined),
                label:Text(FittedLocaleScope.t(context,
                  'Configurar Gym Shield','Configure Gym Shield'))),
            ])),
          if(photos.isNotEmpty)section(FittedLocaleScope.t(context,'Fotografías privadas','Private photos'),Icons.photo_library_outlined,
            FitDateColors.lilac,Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(FittedLocaleScope.t(context,
                  'Tus fotos permanecen privadas hasta su aprobación.',
                  'Your photos remain private until approved.'),
                  style:const TextStyle(color:FitDateColors.muted,fontSize:12)),
                const SizedBox(height:12),
                if(loading)const LinearProgressIndicator(),
                Wrap(spacing:8,runSpacing:8,
                  children:photos.map(photoTile).toList()),
            ])),
          section(FittedLocaleScope.t(context,'Compatibilidad y seguridad',
              'Compatibility and safety'),Icons.verified_user_outlined,
            FitDateColors.lime,
            Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(FittedLocaleScope.t(context,
                'Consulta las protecciones de tu cuenta. Las funciones de citas se habilitarán después de las verificaciones de seguridad.',
                'Review your account protections. Dating features will open after safety checks.' )),
              const SizedBox(height:12),
              FilledButton.icon(
                key:const Key('fitdating-open'),
                onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                  builder:(_)=>DatingV27(api:widget.api))),
                icon:const Icon(Icons.favorite_outline),
                label:const FittedText('Explorar FitDating')),
            ])),
          ],
          if(problem!=null)FittedText(problem!,
            style:const TextStyle(color:Colors.redAccent)),
        ]),
      )),
    );
  }
}
