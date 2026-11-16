import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/live_brand.dart';
import '../core/fitted_locale.dart';
import '../widgets/mfd_branding.dart';
import '../theme/fitness_date_theme.dart';

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
  static const navy = FitDateColors.inkDeep;
  static const gold = FitDateColors.apricot;
  static const ivory = FitDateColors.pearl;
  static const sage = FitDateColors.muted;

  bool get legalConfigured =>
    widget.termsUrl.startsWith('https://') &&
    widget.privacyUrl.startsWith('https://');

  Future<void> openPolicy(String raw) async {
    final uri=Uri.tryParse(raw);
    if(uri!=null && uri.scheme=='https') {
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    }
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
    'https://images.pexels.com/photos/8795582/pexels-photo-8795582.jpeg'
    '?auto=compress&cs=tinysrgb&w=1400';

  Widget _hero(LiveBrandSettings brand,bool wide) {
    final cover=brand.media[wide?'cover_desktop':'cover_mobile'];
    final photo=cover!=null && cover.startsWith('https://')
        ?cover:_editorialPhoto;
    final message=Padding(
      padding:EdgeInsets.all(wide?38:16),
      child:Column(
        mainAxisAlignment:MainAxisAlignment.center,
        crossAxisAlignment:CrossAxisAlignment.start,
        mainAxisSize:MainAxisSize.min,
        children:[
          Text(FittedLocaleScope.t(context,
            'PERSONAS EN MOVIMIENTO','PEOPLE IN MOTION'),
            style:const TextStyle(color:FitDateColors.aqua,
              fontSize:11,letterSpacing:1.8,fontWeight:FontWeight.w800)),
          const SizedBox(height:14),
          Container(width:42,height:3,decoration:BoxDecoration(
            color:FitDateColors.apricot,borderRadius:BorderRadius.circular(3))),
          const SizedBox(height:17),
          Text(FittedTranslations.translate(
              brand.title,FittedLocaleScope.languageOf(context)),
            key:const Key('landing-headline'),
            style:TextStyle(color:ivory,fontFamily:brand.font,
              fontSize:wide?46:34,fontWeight:FontWeight.w700,
              height:1.14,letterSpacing:-.9)),
          const SizedBox(height:14),
          Text(FittedTranslations.translate(
              brand.description,FittedLocaleScope.languageOf(context)),
            key:const Key('landing-brand-description'),
            style:const TextStyle(color:Color(0xFFE1E8E0),
              height:1.5,fontSize:15)),
          const SizedBox(height:19),
          Wrap(spacing:8,runSpacing:8,children:[
            _heroPill(Icons.directions_run_rounded,'How I Move'),
            _heroPill(Icons.wb_twilight_outlined,'How I Live'),
            _heroPill(Icons.connect_without_contact_outlined,'How I Relate'),
          ]),
          const SizedBox(height:24),
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
              backgroundColor:FitDateColors.aqua,
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
      child:SizedBox(
        height:wide?460:245,
        width:double.infinity,
        child:Stack(fit:StackFit.expand,children:[
          Image.network(
            photo,
            key:const Key('landing-editorial-photo'),
            fit:BoxFit.cover,
            semanticLabel:FittedLocaleScope.t(context,
              'Dos personas activas compartiendo un momento al aire libre',
              'Two active people sharing a moment outdoors'),
            errorBuilder:(_,__,___)=>const ColoredBox(
              color:Color(0xFF294A4A),child:Center(
                child:Icon(Icons.landscape_outlined,color:gold,size:48))),
          ),
          const DecoratedBox(decoration:BoxDecoration(
            gradient:LinearGradient(begin:Alignment.topCenter,
              end:Alignment.bottomCenter,
              colors:[Colors.transparent,Color(0xCC0F1821)],
              stops:[.4,1]))),
          Positioned(left:20,right:20,bottom:21,child:Row(children:[
            Container(width:33,height:33,
              decoration:BoxDecoration(shape:BoxShape.circle,
                color:FitDateColors.aqua.withValues(alpha:.17),
                border:Border.all(color:FitDateColors.aqua)),
              child:const Icon(Icons.graphic_eq_rounded,color:FitDateColors.aqua,size:18)),
            const SizedBox(width:10),
            Expanded(child:Text(FittedLocaleScope.t(context,
              'BUENA ENERGÍA · CONEXIONES CON SENTIDO',
              'GOOD ENERGY · MEANINGFUL CONNECTIONS'),
              style:const TextStyle(color:ivory,fontSize:10,
                letterSpacing:1.1,fontWeight:FontWeight.w800))),
          ])),
        ]),
      ),
    );
    return Container(
      key:const Key('landing-hero'),
      padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(30),
        gradient:const LinearGradient(
          colors:[Color(0xFF173B41),Color(0xFF192936),Color(0xFF26283B)],
          begin:Alignment.topLeft,end:Alignment.bottomRight),
        border:Border.all(color:FitDateColors.aqua.withValues(alpha:.24))),
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

  Widget _heroPill(IconData icon,String label) => Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),
    decoration:BoxDecoration(
      color:FitDateColors.inkDeep.withValues(alpha:.48),
      borderRadius:BorderRadius.circular(50),
      border:Border.all(color:FitDateColors.aqua.withValues(alpha:.3))),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:FitDateColors.aqua,size:14),
      const SizedBox(width:7),
      Text(label,style:const TextStyle(color:ivory,fontSize:11,
        fontWeight:FontWeight.w700)),
    ]),
  );

  Widget _access(bool wide) {
    final action=register
      ?widget.onEmailRegister??widget.onEmail
      :widget.onEmailSignIn??widget.onEmail;
    return KeyedSubtree(
      key:const Key('landing-access'),
      child:Container(
      key:_accessKey,
      padding:EdgeInsets.all(wide?28:21),
      decoration:BoxDecoration(
        color:FitDateColors.surface,
        borderRadius:BorderRadius.circular(25),
        border:Border.all(color:FitDateColors.aqua.withValues(alpha:.28))),
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
      ),
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
                    'Protección','Protection'),
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
