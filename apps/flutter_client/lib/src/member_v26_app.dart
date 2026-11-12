import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/member_v26_api.dart';
import 'core/brand_admin_repository.dart';
import 'core/account_role.dart';
import 'core/auth_refresh_policy.dart';
import 'core/password_recovery.dart';
import 'features/brand_admin_home.dart';
import 'features/brand_admin_mfa.dart';
import 'features/password_recovery_screen.dart';
import 'features/member_profile_v26.dart';
import 'features/public_entry_shell.dart';
import 'theme/fitness_date_theme.dart';
import 'widgets/mfd_branding.dart';

/// V26 sign-in gate: no member screen is reachable without remote validation
/// of the Supabase Auth session plus accepted legal terms and an owner profile.
/// Romantic discovery is separately disabled until external age/consent gates.
class MemberV26App extends StatefulWidget {
  const MemberV26App({super.key,required this.auth,required this.api,
    required this.termsUrl,required this.privacyUrl,
    required this.redirectUrl,required this.termsVersion,
    required this.privacyVersion,this.googleEnabled=false});
  final SupabaseClient auth;
  final MemberV26Api api;
  final String termsUrl;
  final String privacyUrl;
  final String redirectUrl;
  final bool googleEnabled;
  final String termsVersion;
  final String privacyVersion;
  @override
  State<MemberV26App> createState()=>_MemberV26AppState();
}

class _MemberV26AppState extends State<MemberV26App> {
  // The root State builds MaterialApp and is NOT itself beneath a Navigator.
  // Its dialogs and notifications must use the material app's own keys.
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final StreamSubscription<AuthState> sub;
  bool loading=true;
  bool verified=false;
  bool brandAdministrator=false;
  bool adminMfaVerified=false;
  bool passwordRecoveryRequested=false;
  bool legalAccepted=false;
  bool editing=false;
  bool busy=false;
  String? failure;
  Map<String,dynamic>? profile;
  bool _refreshRunning = false;
  bool _refreshPending = false;
  String? _validatedUserId;

  @override
  void initState(){
    super.initState();
    // Supabase can handle the PKCE callback before this widget subscribes.
    // Keep an explicit URL marker as well as the passwordRecovery event.
    passwordRecoveryRequested = Uri.base.path == '/recover/';
    sub=widget.auth.auth.onAuthStateChange.listen((event){
      if(event.event==AuthChangeEvent.passwordRecovery){
        passwordRecoveryRequested=true;
      }
      // Supabase can emit tokenRefreshed during validation/MFA. Revalidating
      // on every token refresh repeatedly replaced the MFA enrollment UI.
      // Challenge verification calls refresh() explicitly after AAL2.
      if(shouldRefreshIdentityForAuthEvent(event.event)){
        if(mounted) unawaited(refresh());
      }
    },onError:(Object _, StackTrace __){
      if(mounted)setState((){
        loading=false;verified=false;
        failure='No fue posible verificar la sesión. Reintenta.';
      });
    });
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_refreshRunning) {
      _refreshPending = true;
      return;
    }
    _refreshRunning = true;
    try {
      do {
        _refreshPending = false;
        await _refreshOnce();
      } while (_refreshPending && mounted);
    } finally {
      _refreshRunning = false;
    }
  }

  Future<void> _refreshOnce() async {
    final session = widget.auth.auth.currentSession;
    // Do not unmount the MFA widget on refreshes for the same user: its
    // in-memory TOTP secret must survive until enrollment is verified.
    // Do block the UI on an actual account switch / first validation.
    if (mounted && (loading || _validatedUserId != session?.user.id)) {
      setState(() {loading = true; failure = null;});
    }
    try{
      if(session==null){
        _validatedUserId = null;
        if(mounted){setState((){
          verified=false; legalAccepted=false;
          brandAdministrator=false;adminMfaVerified=false;
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
      // Recovery never routes to an administrator panel or member data.
      // Auth enforces the token; this only shows its password form.
      if(passwordRecoveryRequested){
        _validatedUserId = response.user!.id;
        if(mounted)setState((){
          verified=true;brandAdministrator=false;adminMfaVerified=false;
          legalAccepted=false;profile=null;editing=false;loading=false;
        });
        return;
      }
      // Resolve privilege before sending anyone into the member onboarding
      // or privacy flow. The database is authoritative, never user metadata
      // or an email match. A failed role check blocks access altogether.
      final adminResult=await widget.auth.rpc('brand_admin_status');
      if(adminResult is! bool){
        throw const MemberApiException('No fue posible verificar el rol.');
      }
      if(adminResult){
        // AAL2 is verified SERVER-SIDE on each request, not a UI flag.
        final allow=await widget.auth.rpc('brand_admin_session');
        _validatedUserId = response.user!.id;
        if(mounted){setState((){
          verified=true;brandAdministrator=true;
          adminMfaVerified=allow==true;
          legalAccepted=false;profile=null;editing=false;loading=false;
        });}
        return;
      }
      final records=await widget.api.loadConsents();
      final terms=records.any((r)=>r['consent_kind']=='terms' &&
          r['document_version']==widget.termsVersion);
      final privacy=records.any((r)=>r['consent_kind']=='privacy' &&
          r['document_version']==widget.privacyVersion);
      final own=terms && privacy ? await widget.api.loadProfile() : null;
      _validatedUserId = response.user!.id;
      if(mounted){setState((){
        verified=true;brandAdministrator=false;adminMfaVerified=false;
        legalAccepted=terms&&privacy;
        profile=own;
        loading=false;
      });}
    }catch(_){
      // Fail closed; backend down or unverified means no member app.
      _validatedUserId = null;
      if(mounted){setState((){
        verified=false;legalAccepted=false;
        brandAdministrator=false;adminMfaVerified=false;
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
    // showDialog needs a descendant of MaterialApp. Passing this State's
    // context (above MaterialApp) made 'Acceso con correo' appear inert.
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      email.dispose();
      password.dispose();
      return;
    }
    await showDialog<void>(context:dialogContext,builder:(ctx)=>
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
          if(!register) TextButton(
            key:const Key('request-password-recovery'),
            onPressed:submitting?null:()async{
              final address=email.text.trim();
              if(!address.contains('@')){
                setDialog(()=>error='Introduce tu correo para continuar.');
                return;
              }
              setDialog((){submitting=true;error=null;});
              try{
                await widget.auth.auth.resetPasswordForEmail(
                  address,
                  redirectTo:passwordRecoveryRedirect(widget.redirectUrl),
                );
                if(ctx.mounted)Navigator.pop(ctx);
                if(mounted) _messengerKey.currentState?.showSnackBar(
                  const SnackBar(content:Text(
                    'Si el correo está registrado, recibirás un enlace '
                    'para crear una contraseña.')),
                );
              }catch(_){
                if(ctx.mounted)setDialog(()=>error=
                  'No fue posible enviar el enlace. Reintenta más tarde.');
              }finally{
                if(ctx.mounted)setDialog(()=>submitting=false);
              }
            },
            child:const Text('Crear o recuperar mi contraseña'),
          ),
          FilledButton(onPressed:submitting?null:()async{
            // Never reject a valid existing password based on the
            // registration policy. Apply the stronger rule to new accounts.
            if(!email.text.trim().contains('@') ||
                (register ? password.text.length<12 : password.text.isEmpty)){
              setDialog(()=>error=register
                ? 'Correo válido y contraseña de 12 caracteres como mínimo.'
                : 'Introduce tu correo y tu contraseña.');
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
                _messengerKey.currentState?.showSnackBar(const SnackBar(
                  content:Text('Revisa tu correo y confirma la cuenta para continuar.')));
              }
              await refresh();
            }catch(_){
              if(ctx.mounted) {
                setDialog(()=>error=
                  'No fue posible completar la solicitud. Comprueba los datos.');
              }
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
        onGoogle:widget.googleEnabled?google:null,
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
    }else if(passwordRecoveryRequested){
      body=PasswordRecoveryScreen(
        client:widget.auth,
        onFinished:()async{
          passwordRecoveryRequested=false;
          await logout();
        },
      );
    }else if(brandAdministrator){
      final destination=resolveAccountSpace(
        hasSession:true,remoteIdentityVerified:verified,
        roleCheckSucceeded:true,brandAdministrator:true,
        mfaAal2:adminMfaVerified);
      if(destination==AccountSpace.administrator){
        body=BrandAdminHome(
          repository:BrandAdminRepository(widget.auth),
          email:widget.auth.auth.currentUser?.email??'',
          onSignOut:logout,
        );
      }else{
        body=BrandAdminMfaGate(
          client:widget.auth,onVerified:refresh,onSignOut:logout);
      }
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
      navigatorKey:_navigatorKey,
      scaffoldMessengerKey:_messengerKey,
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
        const MfdBranding(full:true,width:220),
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
