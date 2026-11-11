import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/member_v26_api.dart';
import 'features/member_profile_v26.dart';
import 'features/public_entry_shell.dart';
import 'theme/fitness_date_theme.dart';

/// V26 sign-in gate: no member screen is reachable without remote validation
/// of the Supabase Auth session plus accepted legal terms and an owner profile.
/// Romantic discovery is separately disabled until external age/consent gates.
class MemberV26App extends StatefulWidget {
  const MemberV26App({super.key,required this.auth,required this.api,
    required this.termsUrl,required this.privacyUrl,
    required this.redirectUrl,required this.termsVersion,
    required this.privacyVersion});
  final SupabaseClient auth;
  final MemberV26Api api;
  final String termsUrl;
  final String privacyUrl;
  final String redirectUrl;
  final String termsVersion;
  final String privacyVersion;
  @override
  State<MemberV26App> createState()=>_MemberV26AppState();
}

class _MemberV26AppState extends State<MemberV26App> {
  late final StreamSubscription<AuthState> sub;
  bool loading=true;
  bool verified=false;
  bool legalAccepted=false;
  bool editing=false;
  bool busy=false;
  String? failure;
  Map<String,dynamic>? profile;

  @override
  void initState(){
    super.initState();
    sub=widget.auth.auth.onAuthStateChange.listen((_){
      if(mounted) unawaited(refresh());
    });
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if(mounted)setState((){loading=true;failure=null;});
    try{
      final session=widget.auth.auth.currentSession;
      if(session==null){
        if(mounted){setState((){
          verified=false; legalAccepted=false;
          profile=null;editing=false;loading=false;
        });}
        return;
      }
      // Do not trust a locally stored session as identity until remote Auth
      // verifies it. Provider account is not independently age-verified.
      final response=await widget.auth.auth.getUser();
      if(response.user==null || response.user!.emailConfirmedAt==null){
        throw const MemberApiException('Se requiere un correo verificado.');
      }
      final records=await widget.api.loadConsents();
      final terms=records.any((r)=>r['consent_kind']=='terms' &&
          r['document_version']==widget.termsVersion);
      final privacy=records.any((r)=>r['consent_kind']=='privacy' &&
          r['document_version']==widget.privacyVersion);
      final own=terms && privacy ? await widget.api.loadProfile() : null;
      if(mounted){setState((){
        verified=true;legalAccepted=terms&&privacy;
        profile=own;
        loading=false;
      });}
    }catch(_){
      // Fail closed; backend down or unverified means no member app.
      if(mounted){setState((){
        verified=false;legalAccepted=false;
        profile=null;loading=false;
        failure='No fue posible validar tu sesión de manera segura.';
      });}
    }
  }

  Future<void> google() async {
    try{
      await widget.auth.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:widget.redirectUrl,
      );
    }catch(_){
      if(mounted)setState(()=>failure='No fue posible iniciar sesión con Google.');
    }
  }

  Future<void> email({required bool register}) async {
    final email=TextEditingController();
    final password=TextEditingController();
    String? error;
    bool submitting=false;
    await showDialog<void>(context:context,builder:(ctx)=>
      StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
        title:Text(register?'Crear cuenta con correo':'Iniciar sesión'),
        content:SingleChildScrollView(child:Column(
          mainAxisSize:MainAxisSize.min,children:[
            TextField(controller:email,keyboardType:TextInputType.emailAddress,
              autofillHints:const [AutofillHints.email],
              decoration:const InputDecoration(labelText:'Correo electrónico')),
            const SizedBox(height:12),
            TextField(controller:password,obscureText:true,
              decoration:const InputDecoration(labelText:'Contraseña')),
            if(error!=null)Padding(padding:const EdgeInsets.only(top:10),
              child:Text(error!,style:const TextStyle(color:Colors.redAccent))),
          ])),
        actions:[
          TextButton(onPressed:submitting?null:()=>Navigator.pop(ctx),
            child:const Text('Cancelar')),
          FilledButton(onPressed:submitting?null:()async{
            if(!email.text.contains('@') || password.text.length<10){
              setDialog(()=>error='Correo válido y contraseña de 10 caracteres como mínimo.');
              return;
            }
            setDialog((){submitting=true;error=null;});
            try{
              if(register){
                await widget.auth.auth.signUp(email:email.text.trim(),
                  password:password.text,
                  emailRedirectTo:widget.redirectUrl);
              }else{
                await widget.auth.auth.signInWithPassword(
                  email:email.text.trim(),password:password.text);
              }
              if(ctx.mounted)Navigator.pop(ctx);
              if(mounted && register) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:Text('Revisa tu correo y confirma la cuenta para continuar.')));
              }
              await refresh();
            }catch(_){
              if(ctx.mounted)setDialog(()=>error=
                  'No fue posible completar la solicitud. Comprueba los datos.');
            }finally{
              if(ctx.mounted)setDialog(()=>submitting=false);
            }
          },child:Text(register?'Registrarme':'Entrar')),
        ],
      )));
    email.dispose();password.dispose();
  }

  Future<void> acceptLegal() async {
    setState(()=>busy=true);
    try{
      await widget.api.acceptConsent('terms',widget.termsVersion);
      await widget.api.acceptConsent('privacy',widget.privacyVersion);
      await refresh();
    }catch(_){
      if(mounted)setState(()=>failure='No pudimos registrar tu consentimiento.');
    }finally{if(mounted)setState(()=>busy=false);}
  }

  Future<void> saveProfile(Map<String,dynamic> data) async {
    final next=await widget.api.saveProfile(data);
    if(mounted)setState((){profile=next;editing=false;failure=null;});
  }

  Future<void> logout() async {
    await widget.auth.auth.signOut();
    await refresh();
  }

  @override
  void dispose(){
    sub.cancel();
    super.dispose();
  }

  Widget _legal() => _LegalGate(
    termsUrl:widget.termsUrl,privacyUrl:widget.privacyUrl,
    submitting:busy,onAccept:acceptLegal,onLogout:logout);

  @override
  Widget build(BuildContext context){
    Widget body;
    if(loading){
      body=const Scaffold(body:Center(child:CircularProgressIndicator()));
    }else if(widget.auth.auth.currentSession==null){
      body=PublicEntryShell(
        onGoogle:google,
        onEmailRegister:()=>email(register:true),
        onEmailSignIn:()=>email(register:false),
        termsUrl:widget.termsUrl,
        privacyUrl:widget.privacyUrl,
      );
    }else if(!verified){
      body=Scaffold(body:Center(child:Padding(
        padding:const EdgeInsets.all(24),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Icon(Icons.shield_outlined,size:48),
          const SizedBox(height:15),
          const Text('Tu acceso está protegido',
            style:TextStyle(fontWeight:FontWeight.w900,fontSize:23)),
          const SizedBox(height:10),
          Text(failure??'Necesitamos validar tu cuenta.',
            textAlign:TextAlign.center),
          const SizedBox(height:12),
          FilledButton(onPressed:refresh,child:const Text('Reintentar')),
          TextButton(onPressed:logout,child:const Text('Cerrar sesión')),
        ]))));
    }else if(!legalAccepted){
      body=_legal();
    }else if(profile==null || profile!['onboarding_complete']!=true || editing){
      body=Scaffold(
        appBar:AppBar(title:const Text('Completa tu perfil'),
          actions:[
            IconButton(onPressed:logout,tooltip:'Cerrar sesión',
              icon:const Icon(Icons.logout)),
          ]),
        body:ProfileEditorV26(
          initial:profile,onSave:saveProfile,
          onCancel:profile==null?null:()=>setState(()=>editing=false)),
      );
    }else{
      body=MemberProfileHomeV26(
        profile:profile!,api:widget.api,
        onEdit:()=>setState(()=>editing=true),
        onLogout:logout,
      );
    }
    return MaterialApp(title:'My Fitness Date',
      debugShowCheckedModeBanner:false,
      theme:FitDateTheme.dark(),
      home:body);
  }
}

class _LegalGate extends StatefulWidget {
  const _LegalGate({required this.termsUrl,required this.privacyUrl,
    required this.submitting,required this.onAccept,required this.onLogout});
  final String termsUrl;
  final String privacyUrl;
  final bool submitting;
  final VoidCallback onAccept;
  final VoidCallback onLogout;
  @override
  State<_LegalGate> createState()=>_LegalGateState();
}
class _LegalGateState extends State<_LegalGate> {
  bool terms=false;
  bool privacy=false;
  bool adult=false;
  Future<void> open(String url) async {
    final uri=Uri.tryParse(url);
    if(uri!=null && uri.scheme=='https') {
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Tu privacidad primero')),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:520),
      child:ListView(padding:const EdgeInsets.all(22),children:[
        const Icon(Icons.verified_user_outlined,
          size:55,color:FitDateColors.lime),
        const SizedBox(height:16),
        const Text('Antes de crear tu perfil',
          style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        const Text('Tu perfil comienza privado. FitDating requiere '
          'verificación independiente y consentimiento posterior.',
          style:TextStyle(color:FitDateColors.muted)),
        TextButton(onPressed:()=>open(widget.termsUrl),
          child:const Text('Leer Términos de uso')),
        TextButton(onPressed:()=>open(widget.privacyUrl),
          child:const Text('Leer Aviso de privacidad')),
        CheckboxListTile(
          title:const Text('He leído y acepto los Términos'),
          value:terms,onChanged:(v)=>setState(()=>terms=v??false)),
        CheckboxListTile(
          title:const Text('He leído el Aviso de privacidad'),
          value:privacy,onChanged:(v)=>setState(()=>privacy=v??false)),
        CheckboxListTile(
          title:const Text('Declaro ser mayor de 18 años'),
          subtitle:const Text('La declaración no sustituye '
            'la verificación externa de edad.'),
          value:adult,onChanged:(v)=>setState(()=>adult=v??false)),
        FilledButton(
          key:const Key('v26-accept-legal'),
          onPressed:terms&&privacy&&adult&&!widget.submitting
            ?widget.onAccept:null,
          child:Text(widget.submitting?'Guardando...':'Continuar')),
        TextButton(onPressed:widget.onLogout,
          child:const Text('Salir de mi cuenta')),
      ]),
    )));
}
