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
  final _accessKey = GlobalKey();
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

  Widget _compactPromise(IconData icon,String es,String en) =>
    Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:gold,size:17),
      const SizedBox(width:7),
      Text(FittedLocaleScope.t(context,es,en),
        style:const TextStyle(color:sage,fontSize:12)),
    ]);

  // Editorial photograph is a real landing asset, not a placeholder card.
  // A configured administrator cover takes precedence over the licensed default.
  static const _editorialPhoto =
    'https://images.unsplash.com/photo-1758520705254-1e9d913d78ea'
    '?auto=format&fit=crop&w=1400&q=82';

  Widget _hero(LiveBrandSettings brand,bool wide) {
    final cover=brand.media[wide?'cover_desktop':'cover_mobile'];
    final photo=cover!=null && cover.startsWith('https://')
        ?cover:_editorialPhoto;
    final message=Padding(
      padding:EdgeInsets.all(wide?38:23),
      child:Column(
        mainAxisAlignment:MainAxisAlignment.center,
        crossAxisAlignment:CrossAxisAlignment.start,
        mainAxisSize:MainAxisSize.min,
        children:[
          Text(FittedLocaleScope.t(context,
            'CONEXIONES QUE VAN CONTIGO','CONNECTIONS THAT MOVE WITH YOU'),
            style:const TextStyle(color:Color(0xFFB6F266),
              fontSize:11,letterSpacing:1.3,fontWeight:FontWeight.w800)),
          const SizedBox(height:20),
          Text(FittedTranslations.translate(
              brand.title,FittedLocaleScope.languageOf(context)),
            key:const Key('landing-headline'),
            style:TextStyle(color:ivory,fontFamily:brand.font,
              fontSize:wide?39:30,fontWeight:FontWeight.w700,
              height:1.17)),
          const SizedBox(height:14),
          Text(FittedTranslations.translate(
              brand.description,FittedLocaleScope.languageOf(context)),
            key:const Key('landing-brand-description'),
            style:const TextStyle(color:Color(0xFFE1E8E0),
              height:1.5,fontSize:15)),
          const SizedBox(height:23),
          FilledButton.icon(
            key:const Key('landing-create-profile'),
            onPressed:(){
              setState(()=>register=true);
              WidgetsBinding.instance.addPostFrameCallback((_){
                final target=_accessKey.currentContext;
                if(target!=null)Scrollable.ensureVisible(target,
                  duration:const Duration(milliseconds:350),
                  curve:Curves.easeInOut);
              });
            },
            style:FilledButton.styleFrom(
              backgroundColor:const Color(0xFFB6F266),
              foregroundColor:navy,
              minimumSize:const Size(0,50)),
            icon:const Icon(Icons.arrow_forward),
            label:Text(FittedLocaleScope.t(context,
              'Crear mi perfil','Create my profile'))),
        ],
      ),
    );
    final picture=ClipRRect(
      borderRadius:BorderRadius.circular(22),
      child:Image.network(
        photo,
        key:const Key('landing-editorial-photo'),
        fit:BoxFit.cover,
        width:double.infinity,
        height:wide?430:260,
        semanticLabel:FittedLocaleScope.t(context,
          'Dos personas activas compartiendo un momento al aire libre',
          'Two active people sharing a moment outdoors'),
        errorBuilder:(_,__,___)=>const DecoratedBox(
          decoration:BoxDecoration(color:Color(0xFF293D3C)),
          child:SizedBox(height:260,child:Center(
            child:Icon(Icons.landscape_outlined,color:gold,size:48))),
        ),
      ),
    );
    return Container(
      key:const Key('landing-hero'),
      padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(28),
        color:const Color(0xFF172D29)),
      child:wide
        ?Row(children:[
            Expanded(flex:1,child:message),
            Expanded(flex:1,child:picture),
          ])
        :Column(children:[
            picture,
            message,
          ]),
    );
  }

  Widget _access(bool wide) {
    final action=register
      ?widget.onEmailRegister??widget.onEmail
      :widget.onEmailSignIn??widget.onEmail;
    return Container(
      key:_accessKey,
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
            style:TextStyle(
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
              _hero(brand,wide),
              const SizedBox(height:20),
              ConstrainedBox(
                constraints:const BoxConstraints(maxWidth:570),
                child:_access(wide)),

              const SizedBox(height:18),
              Wrap(
                alignment:WrapAlignment.center,
                spacing:20,runSpacing:12,
                children:[
                  _compactPromise(Icons.people_outline,
                    'Personas auténticas','Authentic people'),
                  _compactPromise(Icons.auto_awesome_outlined,
                    'Afinidad real','Meaningful affinity'),
                  _compactPromise(Icons.shield_outlined,
                    'Privacidad','Privacy'),
                ]),
              
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
      ),
    );
  }
}
