import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/live_brand.dart';
import '../core/fitted_locale.dart';
import '../widgets/mfd_branding.dart';

/// One canonical public entry: one brand, one clear proposition, one auth
/// card. Legal consent is collected only by the registration flow.
class PublicEntryShell extends StatefulWidget {
  const PublicEntryShell({
    super.key,
    this.onGoogle,
    this.onApple,
    this.onEmail,
    this.onEmailRegister,
    this.onEmailSignIn,
    this.termsUrl = '',
    this.privacyUrl = '',
  });
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onEmail;
  final VoidCallback? onEmailRegister;
  final VoidCallback? onEmailSignIn;
  final String termsUrl;
  final String privacyUrl;

  @override
  State<PublicEntryShell> createState() => _PublicEntryShellState();
}

class _PublicEntryShellState extends State<PublicEntryShell> {
  bool register = false;
  static const navy = Color(0xFF101B21);
  static const gold = Color(0xFFD5BE8A);
  static const ivory = Color(0xFFF4F0E8);
  static const sage = Color(0xFFB9CBC1);

  bool get legalConfigured =>
    widget.termsUrl.startsWith('https://') &&
    widget.privacyUrl.startsWith('https://');

  Future<void> openPolicy(String raw) async {
    final uri=Uri.tryParse(raw);
    if(uri!=null && uri.scheme=='https') {
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    }
  }

  Widget _benefit(IconData icon,String esTitle,String enTitle,
      String esCopy,String enCopy,{required bool compact}) {
    return Padding(
      padding:EdgeInsets.symmetric(vertical:compact?7:11),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(
          width:38,height:38,
          decoration:BoxDecoration(
            color:const Color(0xFF293D3C),
            borderRadius:BorderRadius.circular(11)),
          child:Icon(icon,color:gold,size:20)),
        const SizedBox(width:12),
        Expanded(child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(FittedLocaleScope.t(context,esTitle,enTitle),
              style:const TextStyle(color:ivory,fontWeight:FontWeight.w700,
                fontSize:14)),
            const SizedBox(height:3),
            Text(FittedLocaleScope.t(context,esCopy,enCopy),
              style:const TextStyle(color:sage,fontSize:12,height:1.45)),
          ])),
      ]),
    );
  }

  Widget _hero(LiveBrandSettings brand,bool wide) {
    final cover=brand.media[wide?'cover_desktop':'cover_mobile'];
    return Container(
      key:const Key('landing-hero'),
      padding:EdgeInsets.symmetric(
        horizontal:wide?38:22,vertical:wide?35:25),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(22),
        border:Border.all(color:gold.withValues(alpha:.18)),
        gradient:const LinearGradient(
          begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:[Color(0xFF243A3A),navy,Color(0xFF26392E)]),
        image:cover==null?null:DecorationImage(
          image:NetworkImage(cover),fit:BoxFit.cover,
          colorFilter:ColorFilter.mode(
            navy.withValues(alpha:.78),BlendMode.darken)),
      ),
      child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,
        mainAxisSize:MainAxisSize.min,children:[
          Row(mainAxisSize:MainAxisSize.min,children:[
            Container(width:21,height:1.5,color:gold),
            const SizedBox(width:10),
            Flexible(child:Text(FittedLocaleScope.t(context,
              'PERSONAS EN MOVIMIENTO','PEOPLE IN MOTION'),
              style:const TextStyle(color:gold,
                letterSpacing:1.7,fontSize:10,fontWeight:FontWeight.w800))),
          ]),
          SizedBox(height:wide?21:15),
          Text(FittedTranslations.translate(
              brand.title,FittedLocaleScope.languageOf(context)),
            key:const Key('landing-headline'),
            style:TextStyle(
              color:ivory,fontFamily:brand.font,
              fontWeight:FontWeight.w600,
              height:1.13,fontSize:wide?39:31)),
          const SizedBox(height:13),
          Text(FittedTranslations.translate(
              brand.description,FittedLocaleScope.languageOf(context)),
            key:const Key('landing-brand-description'),
            style:const TextStyle(color:Color(0xFFE1E8E0),
              height:1.55,fontSize:14)),
          SizedBox(height:wide?21:13),
          if(wide)...[
            const Divider(color:Color(0xFF425751)),
            const SizedBox(height:5),
            _benefit(Icons.compare_arrows_outlined,
              'Compatibilidad, no deportes idénticos',
              'Compatibility, not identical sports',
              'Los hábitos compartidos importan más que la disciplina.',
              'Shared habits matter more than identical sports.',
              compact:false),
            _benefit(Icons.shield_outlined,
              'Tus espacios siguen siendo tuyos',
              'Keep your spaces your own',
              'Gym Shield protege lugares y rutinas privadas.',
              'Gym Shield protects private venues and routines.',
              compact:false),
          ]else
            Row(mainAxisSize:MainAxisSize.min,children:[
              const Icon(Icons.shield_outlined,color:gold,size:17),
              const SizedBox(width:8),
              Flexible(child:Text(FittedLocaleScope.t(context,
                'Conexiones con intención y privacidad',
                'Intentional connections with privacy'),
                style:const TextStyle(color:sage,fontSize:12))),
            ]),
        ]),
    );
  }

  Widget _access(bool wide) {
    final action=register
      ?widget.onEmailRegister??widget.onEmail
      :widget.onEmailSignIn??widget.onEmail;
    return Container(
      key:const Key('landing-access'),
      padding:EdgeInsets.all(wide?28:21),
      decoration:BoxDecoration(
        color:const Color(0xFF19272C),
        borderRadius:BorderRadius.circular(22),
        border:Border.all(color:gold.withValues(alpha:.3))),
      child:Column(
        crossAxisAlignment:CrossAxisAlignment.stretch,
        mainAxisSize:MainAxisSize.min,children:[
          Text(FittedLocaleScope.t(context,
              'TU ESPACIO EN FITTED','YOUR FITTED SPACE'),
            style:const TextStyle(fontSize:10,
              letterSpacing:1.8,color:gold,fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          Text(register
            ?FittedLocaleScope.t(context,'Comienza aquí','Start here')
            :FittedLocaleScope.t(context,'Bienvenido','Welcome'),
            style:const TextStyle(
              fontFamily:'Georgia',fontSize:wide?29:27,color:ivory)),
          const SizedBox(height:7),
          Text(register
            ?FittedLocaleScope.t(context,
              'Crea tu cuenta y empieza a construir tu perfil.',
              'Create an account and start building your profile.')
            :FittedLocaleScope.t(context,
              'Entra y continúa donde lo dejaste.',
              'Sign in and pick up where you left off.'),
            style:const TextStyle(color:sage,fontSize:13,height:1.45)),
          const SizedBox(height:21),
          OutlinedButton.icon(
            key:const Key('google-signin-entry'),
            onPressed:legalConfigured?widget.onGoogle:null,
            style:OutlinedButton.styleFrom(
              minimumSize:const Size(0,48)),
            icon:const Icon(Icons.account_circle_outlined),
            label:Text(FittedLocaleScope.t(context,
              'Continuar con Google','Continue with Google'))),
          const SizedBox(height:9),
          OutlinedButton.icon(
            key:const Key('apple-signin-entry'),
            onPressed:legalConfigured?widget.onApple:null,
            style:OutlinedButton.styleFrom(
              minimumSize:const Size(0,48)),
            icon:const Icon(Icons.apple),
            label:Text(FittedLocaleScope.t(context,
              'Continuar con Apple','Continue with Apple'))),
          const SizedBox(height:9),
          FilledButton.icon(
            key:const Key('email-entry'),
            onPressed:legalConfigured?action:null,
            style:FilledButton.styleFrom(
              backgroundColor:gold,foregroundColor:navy,
              minimumSize:const Size(0,52)),
            icon:const Icon(Icons.mail_outline),
            label:Text(register
              ?FittedLocaleScope.t(context,
                'Crear cuenta con correo','Create account with email')
              :FittedLocaleScope.t(context,
                'Entrar con correo','Sign in with email'))),
          const SizedBox(height:9),
          TextButton(
            key:const Key('switch-entry-mode'),
            onPressed:()=>setState(()=>register=!register),
            child:Text(register
              ?FittedLocaleScope.t(context,
                '¿Ya tienes cuenta? Inicia sesión',
                'Already have an account? Sign in')
              :FittedLocaleScope.t(context,
                '¿Aún no tienes cuenta? Regístrate',
                'New here? Sign up'),
              style:const TextStyle(color:gold))),
          const Divider(color:Color(0xFF425150),height:24),
          Center(child:Wrap(
            alignment:WrapAlignment.center,spacing:19,runSpacing:0,
            children:[
              TextButton(
                onPressed:legalConfigured
                  ?()=>openPolicy(widget.termsUrl):null,
                child:Text(FittedLocaleScope.t(context,
                  'Términos','Terms'),
                  style:const TextStyle(color:ivory))),
              TextButton(
                onPressed:legalConfigured
                  ?()=>openPolicy(widget.privacyUrl):null,
                child:Text(FittedLocaleScope.t(context,
                  'Privacidad','Privacy'),
                  style:const TextStyle(color:ivory))),
            ])),
        ]),
    );
  }

  @override
  Widget build(BuildContext context){
    final brand=LiveBrandScope.of(context);
    final width=MediaQuery.sizeOf(context).width;
    final wide=width>=900;
    return Scaffold(
      backgroundColor:navy,
      appBar:AppBar(
        backgroundColor:navy,
        titleSpacing:wide?32:16,
        title:Row(mainAxisSize:MainAxisSize.min,children:[
          const MfdBranding(full:false,width:38),
          const SizedBox(width:11),
          Flexible(child:Text(brand.name,maxLines:1,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:19,color:ivory,
              fontWeight:FontWeight.w700))),
        ]),
        actions:[
          const Padding(
            padding:EdgeInsets.only(right:16),
            child:Center(child:FittedLanguageSelector())),
        ]),
      body:SafeArea(child:ListView(
        padding:EdgeInsets.symmetric(
          horizontal:wide?28:14,vertical:wide?22:12),
        children:[
          Center(child:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:1180),
            child:Column(children:[
              if(wide)
                Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Expanded(flex:6,child:_hero(brand,true)),
                  const SizedBox(width:18),
                  Expanded(flex:5,child:_access(true)),
                ])
              else ...[
                _hero(brand,false),
                const SizedBox(height:12),
                _access(false),
              ],
              const SizedBox(height:21),
              if(wide)
                Row(children:[
                  Expanded(child:_benefit(
                    Icons.auto_awesome_outlined,
                    'Estilo de vida antes que etiquetas',
                    'Lifestyle before labels',
                    'Conoce el ritmo de alguien, no una biografía genérica.',
                    'Understand someone’s rhythm, not a generic biography.',
                    compact:true)),
                  const SizedBox(width:19),
                  Expanded(child:_benefit(
                    Icons.people_outline,
                    'Movimiento con intención',
                    'Move with intention',
                    'Conexiones entre personas con hábitos compatibles.',
                    'Connections between people with compatible habits.',
                    compact:true)),
                ])
              else
                _benefit(
                  Icons.compare_arrows_outlined,
                  'Compatibilidad más allá del deporte',
                  'Compatibility beyond sport',
                  'Tus hábitos importan más que entrenar lo mismo.',
                  'Your lifestyle matters more than the same workout.',
                  compact:true),
              const Divider(color:Color(0xFF425150),height:26),
              Padding(padding:const EdgeInsets.only(bottom:14),
                child:Text(FittedLocaleScope.t(context,
                  'Las funciones de citas se habilitarán cuando concluyan '
                  'las verificaciones de seguridad.',
                  'Dating features will open once the safety checks are complete.'),
                  textAlign:TextAlign.center,
                  style:const TextStyle(color:sage,fontSize:11.5,height:1.5))),
            ]),
          )),
        ]),
      )),
    );
  }
}
