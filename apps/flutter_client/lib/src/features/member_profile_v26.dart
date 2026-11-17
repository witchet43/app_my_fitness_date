import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import 'dating_v27.dart';
import 'rhythm_concept_lab_b10.dart';
import 'fit_ia_conversation_page.dart';
import '../core/fit_ia_repository.dart';
import 'fitted_profile_story_v28.dart';
import '../core/fitted_profile_insights_v29.dart';
import 'fitted_gym_shield_v28.dart';
import 'fitted_two_panel_home_b18.dart';
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
    padding:EdgeInsets.only(bottom:12),
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
      padding: EdgeInsets.fromLTRB(0, 26, 0, 13),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
          SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FITTED / $number', style: TextStyle(
                fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w800,
                color: color)),
              SizedBox(height: 3),
              FittedText(title, style: TextStyle(
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
    child:ListView(padding:EdgeInsets.symmetric(horizontal:20,vertical:22),children:[
      FittedRhythmHero(
        titleEs:'Lo que te mueve, te conecta.',
        titleEn:'What moves you, connects you.',
        subtitleEs:'Construye un perfil que hable de tu energía, tus valores y el espacio que quieres compartir con alguien.',
        subtitleEn:'Build a profile shaped by your energy, values and the space you want to share with someone.',
        compact:true,
      ),
      SizedBox(height:23),
      FittedText('Mi perfil 360°',key:Key('v26-profile-editor'),
        style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
      SizedBox(height:8),
      FittedText('Tu historia va más allá del entrenamiento. Tú decides qué compartir; tus datos son privados por defecto.',
        style:TextStyle(color:FitDateColors.muted,height:1.5)),
      SizedBox(height:9),
      FittedText('MOVE  /  LIVE  /  RELATE',
        style:TextStyle(fontSize:10,letterSpacing:2,
          fontWeight:FontWeight.w800,color:FitDateColors.aqua)),
      heading('Mi historia personal',Icons.favorite_border,FitDateColors.coral),
      input('display_name','Nombre visible',required:true,maxLength:60),
      input('date_of_birth','Nacimiento privado · AAAA-MM-DD',
        required:true,hint:'1995-06-15'),
      FittedText('La fecha no se publica y no constituye una verificación '
        'independiente de mayoría de edad.',
        style:TextStyle(color:FitDateColors.muted,fontSize:12)),
      SizedBox(height:10),
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
      SizedBox(height:13),
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
      SizedBox(height:10),
      FittedText('Guardar esta preferencia NO publica tu perfil ni '
        'activa FitDating. Los gimnasios, studios y horarios siguen privados.',
        style:TextStyle(color:FitDateColors.muted,fontSize:12)),
      if(warning!=null)Padding(padding:EdgeInsets.all(10),
        child:FittedText(warning!,style:TextStyle(color:Colors.redAccent))),
      SizedBox(height:16),
      FilledButton.icon(
        key:Key('v26-save-profile'),onPressed:saving?null:save,
        icon:Icon(Icons.save_outlined),
        label:FittedText(saving?'Guardando...':'Guardar mi perfil')),
      if(widget.onCancel!=null)TextButton(
        onPressed:widget.onCancel,child:FittedText('Cancelar')),
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
  Map<String,dynamic>? summary;
  Map<String,dynamic>? matchStatus;
  Map<String,dynamic>? fitIaOverview;
  Future<Uint8List>? profilePortrait;
  bool summaryBusy=false;
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
      if(mounted)setState((){
        places=result[0];photos=result[1];
        final featured=result[1].where((photo)=>
          photo['position']==0 || photo['position']=='0').toList();
        final pick=featured.isNotEmpty?featured.first:
          (result[1].isNotEmpty?result[1].first:null);
        profilePortrait=pick==null?null:
          widget.api.photoContent(pick['id'].toString());
      });
      try{
        final current=await Future.wait<Map<String,dynamic>>([
          widget.api.myFittedSummaryB18(),
          widget.api.datingStatus(),
          widget.api.fitIaOverview().catchError((Object _) =>
            <String,dynamic>{}),
        ]);
        if(mounted)setState((){
          fitIaOverview=current[2];
          matchStatus=current[1];
          summary=current[0];
          // Fit-IA summaries remain private. They are displayed only when
          // the owner separately approved AI use; public candidate profiles
          // still follow the existing sharing consent and publication gate.
          final ia=current[2];
          final story=ia['summary'];
          if(ia['ai_enabled']==true && story is Map &&
             (story['summary_es']??'').toString().trim().isNotEmpty){
            summary={
              ...current[0],
              'summary_es':story['summary_es'],
              'summary_en':story['summary_en'],
              'ai_consented':true,
              'mode':'ai',
            };
          }
        });
      }catch(_){if(mounted)setState(()=>matchStatus=null);}

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

  /// Member-authored biography: stored as their words, never submitted to AI.
  /// Both the UI and the SQL RPC reject edits while AI mode is enabled.
  Future<void> editManualStoryB19() async {
    if(summary?['ai_consented']==true || !mounted)return;
    final en=FittedLocaleScope.languageOf(context)=='en';
    final locale=en?'en':'es';
    final original=(summary?[en?'manual_summary_en':'manual_summary_es']??'')
      .toString();
    final controller=TextEditingController(text:original);
    try{
      final text=await showDialog<String>(context:context,
        builder:(dialog)=>StatefulBuilder(
          builder:(dialog,update)=>AlertDialog(
            title:Row(children:[
              Icon(Icons.edit_outlined,color:FitDateColors.lilac),
              SizedBox(width:8),
              Expanded(child:Text(en?'Write my story':'Escribir mi historia')),
            ]),
            content:SizedBox(width:590,child:SingleChildScrollView(
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                Text(en
                  ?'Write what you want another Fitted member to know about '
                    'your lifestyle, values and what you are looking for. '
                    'Your words are never sent to an AI model.'
                  :'Describe con tus palabras tu estilo de vida, tus valores '
                    'y lo que buscas. Este texto no se envía a ningún modelo de IA.'),
                SizedBox(height:13),
                TextField(
                  key:Key('b19-manual-story-field'),
                  controller:controller,minLines:7,maxLines:13,
                  maxLength:1600,
                  onChanged:(_)=>update((){}),
                  decoration:InputDecoration(
                    labelText:en?'My story':'Mi historia personal',
                    hintText:en
                      ?'I enjoy... I value... I am interested in meeting...'
                      :'Disfruto... Valoro... Me gustaría conocer...',
                    border:OutlineInputBorder(),
                    helperText:en?'80–1600 characters.':
                      'Entre 80 y 1600 caracteres.')),
                SizedBox(height:8),
                Text(en
                  ?'Sharing requires separate authorization and a profile '
                    'visible to eligible members.'
                  :'Compartirlo requiere autorización independiente y '
                    'visibilidad habilitada para miembros elegibles.',
                  style:Theme.of(dialog).textTheme.bodySmall),
              ]),
            )),
            actions:[
              TextButton(onPressed:()=>Navigator.of(dialog).pop(),
                child:Text(en?'Cancel':'Cancelar')),
              FilledButton.icon(
                key:Key('b19-save-manual-story'),
                onPressed:controller.text.trim().length>=80 &&
                  controller.text.trim().length<=1600
                    ?()=>Navigator.of(dialog).pop(controller.text.trim())
                    :null,
                icon:Icon(Icons.check),
                label:Text(en?'Save my story':'Guardar mi historia'),
              ),
            ],
          )));
      if(text==null||!mounted)return;
      setState(()=>summaryBusy=true);
      try{
        final result=await widget.api.saveManualStoryB19(
          text:text,locale:locale);
        if(result!='saved'){
          throw MemberApiException(result=='ai_active'
            ?'La IA está activa. Desactívala antes de editar.'
            :'El texto no pudo guardarse. Evita datos de contacto.');
        }
        await reload();
      }catch(_){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:Text(en
            ?'Could not save your story. Check length and contact details.'
            :'No pudimos guardar tu historia. Revisa la extensión y evita datos de contacto.')));
      }finally{if(mounted)setState(()=>summaryBusy=false);}
    }finally{controller.dispose();}
  }

  Future<void> configureSummaryB18() async {
    final en=FittedLocaleScope.languageOf(context)=='en';
    var ai=summary?['ai_consented']==true;
    var share=summary?['share_consented']==true;
    final decision=await showDialog<(bool,bool)>(context:context,
      builder:(dialog)=>StatefulBuilder(builder:(dialog,update)=>AlertDialog(
        title:Text(en?'AI story & privacy':'Mi historia con IA y privacidad'),
        content:SizedBox(width:440,child:Column(
          mainAxisSize:MainAxisSize.min,children:[
            Text(en
              ?'With your permission, AI can summarize your interests, goals, '
                'values and all three lifestyle pillars in a longer personal '
                'story. IDs, photos, gyms, exact schedules and contacts are excluded. '
                'When AI is off, your own written text stays unchanged.'
              :'Con tu permiso, la IA puede integrar intereses, objetivos, '
                'valores y los tres pilares en una descripción más completa. '
                'No se envían documentos, fotos, gimnasios, horarios exactos '
                'ni contactos. Con IA apagada, conservarás tu texto manual.'),
            CheckboxListTile(
              key:Key('b18-ai-consent'),
              value:ai,onChanged:(v)=>update(()=>ai=v??false),
              title:Text(en?'Allow AI to write my story':
                'Permitir que IA redacte mi resumen')),
            CheckboxListTile(
              key:Key('b18-share-consent'),
              value:share,onChanged:(v)=>update(()=>share=v??false),
              title:Text(en?'Share my approved story with eligible members':
                'Mostrar mi resumen a miembros verificados')),
            Text(en?'You can change these permissions any time.':
              'Puedes cambiar estos permisos cuando quieras.',
              style:Theme.of(dialog).textTheme.bodySmall),
          ])),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog),
            child:Text(en?'Cancel':'Cancelar')),
          FilledButton(
            key:Key('b18-summary-consent-save'),
            onPressed:()=>Navigator.pop(dialog,(ai,share)),
            child:Text(en?'Save preferences':'Guardar preferencias')),
        ],
      )));
    if(decision==null||!mounted)return;
    setState(()=>summaryBusy=true);
    try{
      final state=await widget.api.fittedSummaryConsentB18(
        ai:decision.$1,share:decision.$2);
      if(state!='updated')throw MemberApiException('Not saved');
      if(decision.$1)await widget.api.refreshFittedAiSummaryB18();
      await reload();
    }catch(_){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(en?'Could not save AI preferences.':
          'No se pudieron guardar las preferencias de IA.')));
    }finally{if(mounted)setState(()=>summaryBusy=false);}
  }

  Future<void> openFitdatingB18() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>DatingV27(api:widget.api)));
    if(mounted)await reload();
  }
  Future<void> openAgeVerificationB18() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>FittedAgeVerificationB14(api:widget.api)));
    if(mounted)await reload();
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

  /// Three pillars now use Fit-IA's own private conversation consent.
  /// Dating/discovery remains a separate, explicitly consented operation.
  Future<void> configurePillars([int initialPillar=0])async{
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder:(_)=>FitIaConversationPage(
        repository:widget.api,initialPillar:initialPillar)));
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
        AlertDialog(title:FittedText('Mi lugar de entrenamiento'),
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
              SizedBox(height:10),
              TextField(controller:name,onChanged:(_)=>setDialog((){}),
                decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Nombre'))),
              SizedBox(height:10),
              TextField(controller:city,onChanged:(_)=>setDialog((){}),
                decoration:InputDecoration(labelText:FittedLocaleScope.translate(context,'Ciudad'))),
              SizedBox(height:10),
              TextField(controller:zone,
                decoration:InputDecoration(
                  labelText:FittedLocaleScope.translate(context,'Zona general (opcional)'))),
              SizedBox(height:10),
              FittedText('El gimnasio y los horarios no se compartirán.',
                style:TextStyle(fontSize:12)),
            ])),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog),
              child:FittedText('Cancelar')),
            FilledButton(
              onPressed:name.text.trim().length<2||city.text.trim().length<2
                ?null:()=>Navigator.pop(dialog,{
                  'venue_kind':kind,'place_name':name.text.trim(),
                  'city':city.text.trim(),'general_zone':zone.text.trim()}),
              child:FittedText('Guardar')),
          ])));
    name.dispose();city.dispose();zone.dispose();
    if(result==null)return;
    try{await widget.api.addPlace(result);await reload();}
    catch(_){if(mounted)setState(()=>problem='No se pudo guardar el lugar.');}
  }

  Widget section(String title,IconData icon,Color color,Widget child)=>
    Card(child:Padding(padding:EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(icon,color:color),SizedBox(width:9),
          Expanded(child:FittedText(title,style:TextStyle(
            fontWeight:FontWeight.w900,fontSize:19)))]),
        SizedBox(height:12),child,
      ])));
  Widget tags(dynamic value) {
    final items=value is List?value:[];
    return items.isEmpty
      ?FittedText('Aún sin información',
        style:TextStyle(color:FitDateColors.muted))
      :Wrap(spacing:7,runSpacing:6,
        children:items.map<Widget>((x)=>Chip(label:FittedText(x.toString()))).toList());
  }
  Widget photoTile(Map<String,dynamic> photo)=>SizedBox(width:140,
    child:Card(child:Padding(padding:EdgeInsets.all(9),
      child:Column(children:[
        SizedBox(height:110,
          child:FutureBuilder<Uint8List>(
            future:widget.api.photoContent(photo['id'].toString()),
            builder:(context,snapshot)=>snapshot.hasData
              ?Image.memory(snapshot.data!,fit:BoxFit.cover)
              :Center(child:Icon(Icons.image_outlined)))),
        FittedText((photo['moderation_state']??'pending').toString(),
          style:TextStyle(color:FitDateColors.muted,fontSize:11)),
        IconButton(tooltip:FittedLocaleScope.translate(context,'Eliminar mi foto'),
          icon:Icon(Icons.delete_outline),
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
            MfdBranding(full:false,width:38),
            SizedBox(width:11),
            Flexible(child:Text(
              LiveBrandScope.of(context).name,
              key:Key('fitted-member-header-name'),
              maxLines:1,overflow:TextOverflow.ellipsis,
              style:TextStyle(
                fontSize:20,fontWeight:FontWeight.w800,
                letterSpacing:.2),
            )),
          ],
        ),
        actions:[
          if(MediaQuery.sizeOf(context).width>=1020)...[
            TextButton.icon(
              onPressed:()=>setState(()=>selectedArea=0),
              icon:Icon(Icons.home_outlined,size:19),
              label:Text(FittedLocaleScope.t(context,'Inicio','Home'))),
            TextButton.icon(
              key:Key('b18-header-fits'),
              onPressed:openFitdatingB18,
              icon:Icon(Icons.people_alt_outlined,size:19),
              label:Text(FittedLocaleScope.t(context,'Buscar fits','Find fits'))),
            TextButton.icon(
              onPressed:()=>setState(()=>selectedArea=1),
              icon:Icon(Icons.person_outline,size:19),
              label:Text(FittedLocaleScope.t(context,'Mi perfil','My profile'))),
            TextButton.icon(
              onPressed:widget.onEdit,
              icon:Icon(Icons.settings_outlined,size:19),
              label:Text(FittedLocaleScope.t(context,
                'Configuración','Settings'))),
          ],
          FittedLanguageSelector(),
          PopupMenuButton<String>(
            tooltip:FittedLocaleScope.t(context,'Cuenta','Account'),
            icon:Icon(Icons.account_circle_outlined),
            onSelected:(value) {
              if(value=='profile')setState(()=>selectedArea=1);
              if(value=='edit')widget.onEdit();
              if(value=='community')Navigator.of(context).push(
                MaterialPageRoute<void>(builder:(_)=>CommunityB4(api:widget.api)));
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
              PopupMenuItem(value:'community',
                child:Text(FittedLocaleScope.t(context,'Comunidad','Community'))),
              PopupMenuItem(value:'activities',
                child:Text(FittedLocaleScope.t(context,'Actividades (opcional)','Activities (optional)'))),
              PopupMenuItem(value:'reservations',
                child:Text(FittedLocaleScope.t(context,'Mis reservas','My reservations'))),
              PopupMenuDivider(),
              PopupMenuItem(value:'logout',
                child:Text(FittedLocaleScope.t(context,'Cerrar sesión','Sign out'))),
            ],
          ),
        ]),
      body:Center(child:ConstrainedBox(
        constraints:BoxConstraints(maxWidth:980),
        child:ListView(padding:EdgeInsets.all(16),children:[
          if(MediaQuery.sizeOf(context).width<1020)SegmentedButton<int>(
            key:Key('fitted-home-navigation'),
            showSelectedIcon:false,
            segments:[
              ButtonSegment(value:0,icon:Icon(Icons.home_outlined),
                label:Text(FittedLocaleScope.t(context,'Inicio','Home'))),
              ButtonSegment(value:1,icon:Icon(Icons.person_outline),
                label:Text(FittedLocaleScope.t(context,'Mi perfil','My profile'))),
            ],
            selected:{selectedArea},
            onSelectionChanged:(value)=>setState(()=>selectedArea=value.first),
          ),
          SizedBox(height:18),
          if(selectedArea==0)...[
            FittedIdentityPanelB18(
              name:(p['display_name']??'').toString().trim().split(' ').first,
              rhythm:lifestyle,summary:summary,
              fitIaOverview:fitIaOverview,
              photo:profilePortrait,summaryBusy:summaryBusy,
              profileVisibleToMembers:p['social_visibility']=='members',
              onPillar:(index)=>configurePillars(index),
              onEdit:widget.onEdit,
              onSummaryConsent:configureSummaryB18,
              onManualEdit:editManualStoryB19,
            ),
            SizedBox(height:16),
            FittedFitsPanelB18(
              api:widget.api,
              pillarProgress:FittedProfileInsights.pillarProgress(lifestyle),
              fitIaOverview:fitIaOverview,
              status:matchStatus,
              onPrepare:openFitdatingB18,
              onVerifyAge:openAgeVerificationB18,
            ),
          ]else...[
            Row(children:[
              Expanded(child:Text(FittedLocaleScope.t(context,
                'Mi perfil privado','My private profile'),
                style:TextStyle(fontSize:24,fontWeight:FontWeight.w800))),
              IconButton(
                tooltip:FittedLocaleScope.t(context,'Editar','Edit'),
                onPressed:widget.onEdit,icon:Icon(Icons.edit_outlined)),
            ]),
            SizedBox(height:12),
          KeyedSubtree(
            key:Key('fitted-profile-three-pillars-card'),
            child:FittedProfileStoryV28(
              profile:p,rhythm:lifestyle,
              fitIaOverview:fitIaOverview,
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
                    leading:Icon(Icons.track_changes_outlined),
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
              SizedBox(height:12),
              Wrap(spacing:7,runSpacing:7,children:[
                for(final place in places.take(3))
                  Chip(avatar:Icon(Icons.lock_outline,size:16),
                    label:Text((place['place_name']??'').toString())),
              ]),
              if(places.isEmpty)
                Text(FittedLocaleScope.t(context,
                  'Añade tus lugares y ventanas generales para personalizar '
                  'la protección.',
                  'Add places and broad time windows to customize protection.')),
              SizedBox(height:13),
              FilledButton.icon(
                key:Key('fitted-open-gym-shield'),
                onPressed:configureShield,
                icon:Icon(Icons.admin_panel_settings_outlined),
                label:Text(FittedLocaleScope.t(context,
                  'Configurar Gym Shield','Configure Gym Shield'))),
            ])),
          if(photos.isNotEmpty)section(FittedLocaleScope.t(context,'Fotografías privadas','Private photos'),Icons.photo_library_outlined,
            FitDateColors.lilac,Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(FittedLocaleScope.t(context,
                  'Tus fotos permanecen privadas hasta su aprobación.',
                  'Your photos remain private until approved.'),
                  style:TextStyle(color:FitDateColors.muted,fontSize:12)),
                SizedBox(height:12),
                if(loading)LinearProgressIndicator(),
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
              SizedBox(height:12),
              FilledButton.icon(
                key:Key('fitdating-open'),
                onPressed:()=>Navigator.of(context).push(MaterialPageRoute<void>(
                  builder:(_)=>DatingV27(api:widget.api))),
                icon:Icon(Icons.favorite_outline),
                label:FittedText('Explorar FitDating')),
            ])),
          ],
          if(problem!=null)FittedText(problem!,
            style:TextStyle(color:Colors.redAccent)),
        ]),
      )),
    );
  }
}
