import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/live_brand.dart';
import '../core/fitted_locale.dart';
import '../widgets/mfd_branding.dart';
import '../theme/fitness_date_theme.dart';

/// One responsive public panel: story, photography, authentication and legal.
/// The administrator's live brand continues to control copy, colors and cover.
/// Registration consent remains part of the existing registration flow.
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

  bool get legalConfigured =>
    widget.termsUrl.startsWith('https://') &&
    widget.privacyUrl.startsWith('https://');

  Future<void> openPolicy(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'https') {
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    }
  }

  static const _editorialPhoto =
    'https://images.pexels.com/photos/8497645/pexels-photo-8497645.jpeg'
    '?auto=compress&cs=tinysrgb&w=1600';

  Widget _heroPill(IconData icon,String label,LiveBrandSettings brand) =>
    Container(
      padding:const EdgeInsets.symmetric(horizontal:11,vertical:9),
      decoration:BoxDecoration(
        color:brand.backgroundColor.withValues(alpha:.75),
        borderRadius:BorderRadius.circular(36),
        border:Border.all(color:brand.accentColor.withValues(alpha:.56)),
      ),
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        Icon(icon,color:brand.primaryColor,size:17),
        const SizedBox(width:8),
        Text(label,style:const TextStyle(
          color:FitDateColors.pearl,fontSize:12,fontWeight:FontWeight.w700)),
      ]),
    );

  Widget _message(LiveBrandSettings brand,bool wide) {
    final title=FittedTranslations.translate(
      brand.title,FittedLocaleScope.languageOf(context));
    final description=FittedTranslations.translate(
      brand.description,FittedLocaleScope.languageOf(context));
    final baseStyle=TextStyle(
      color:FitDateColors.pearl,fontFamily:brand.font,
      fontSize:wide?52:34,fontWeight:FontWeight.w800,
      height:1.11,letterSpacing:-1.3);
    return Column(
      mainAxisSize:MainAxisSize.min,
      crossAxisAlignment:CrossAxisAlignment.start,
      children:[
        Text(FittedLocaleScope.t(context,
          'PERSONAS EN MOVIMIENTO','PEOPLE IN MOTION'),
          style:TextStyle(color:brand.primaryColor,fontSize:12,
            letterSpacing:2.0,fontWeight:FontWeight.w800)),
        const SizedBox(height:12),
        Container(width:44,height:4,decoration:BoxDecoration(
          color:brand.primaryColor,borderRadius:BorderRadius.circular(3))),
        const SizedBox(height:17),
        if(title.contains('trascienden.'))
          RichText(key:const Key('landing-headline'),
            text:TextSpan(style:baseStyle,children:[
              TextSpan(text:title.split('trascienden.').first),
              TextSpan(text:'trascienden.',
                style:TextStyle(color:brand.primaryColor)),
            ]))
        else Text(title,key:const Key('landing-headline'),style:baseStyle),
        const SizedBox(height:17),
        Text(description,key:const Key('landing-brand-description'),
          style:const TextStyle(color:FitDateColors.pearl,
            fontSize:15.5,height:1.48)),
        const SizedBox(height:20),
        Wrap(spacing:9,runSpacing:9,children:[
          _heroPill(Icons.directions_run_rounded,
            FittedLocaleScope.t(context,'Cómo me muevo','How I Move'),brand),
          _heroPill(Icons.spa_outlined,
            FittedLocaleScope.t(context,'Cómo vivo','How I Live'),brand),
          _heroPill(Icons.groups_outlined,
            FittedLocaleScope.t(context,
              'Cómo me relaciono','How I Relate'),brand),
        ]),
      ],
    );
  }

  Widget _photo(String url,LiveBrandSettings brand) => Stack(
    fit:StackFit.expand,children:[
      Image.network(
        url,key:const Key('landing-editorial-photo'),
        fit:BoxFit.cover,alignment:Alignment.center,
        semanticLabel:FittedLocaleScope.t(context,
          'Dos adultos jóvenes corriendo juntos al aire libre',
          'Two young adults running together outdoors'),
        errorBuilder:(_,__,___)=>const ColoredBox(
          color:FitDateColors.surfaceRaised,child:Center(
            child:Icon(Icons.directions_run,color:FitDateColors.aqua,size:64))),
      ),
      Positioned(right:0,bottom:22,child:Container(
        width:130,height:2,
        decoration:BoxDecoration(color:brand.primaryColor.withValues(alpha:.8),
          borderRadius:BorderRadius.circular(2)))),
    ],
  );

  Widget _hero(LiveBrandSettings brand,bool wide,double availableWidth) {
    final raw=brand.media[wide?'cover_desktop':'cover_mobile'];
    final photo=raw!=null && LiveBrandSettings.safeAssetUrl(raw)
      ?raw:_editorialPhoto;
    final surface=brand.backgroundColor;
    return Container(
      key:const Key('landing-hero'),
      clipBehavior:Clip.antiAlias,
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(34),
        border:Border.all(color:brand.primaryColor.withValues(alpha:.65)),
        gradient:LinearGradient(
          begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:[surface,FitDateColors.surfaceRaised,surface])),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        if(wide) SizedBox(
          height:465,
          child:Stack(fit:StackFit.expand,children:[
            Positioned.fill(left:availableWidth*.40,
              child:_photo(photo,brand)),
            Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(
              gradient:LinearGradient(
                begin:Alignment.centerLeft,end:Alignment.centerRight,
                stops:const [0,.34,.69,1],
                colors:[surface,surface,
                  surface.withValues(alpha:.85),Colors.transparent])))),
            Positioned(left:54,top:43,width:availableWidth*.49,
              child:_message(brand,true)),
          ]),
        ) else ...[
          SizedBox(height:220,width:double.infinity,
            child:_photo(photo,brand)),
          Padding(padding:const EdgeInsets.fromLTRB(21,21,21,10),
            child:_message(brand,false)),
        ],
        _access(wide,brand),
      ]),
    );
  }

  Widget _authButtons(bool wide,LiveBrandSettings brand) {
    final action=register
      ?widget.onEmailRegister??widget.onEmail
      :widget.onEmailSignIn??widget.onEmail;
    final google=OutlinedButton.icon(
      key:const Key('google-signin-entry'),
      onPressed:legalConfigured?widget.onGoogle:null,
      style:OutlinedButton.styleFrom(
        foregroundColor:FitDateColors.pearl,
        side:BorderSide(color:brand.primaryColor.withValues(alpha:.65)),
        minimumSize:const Size(0,51)),
      icon:const Icon(Icons.account_circle_outlined),
      label:Text(FittedLocaleScope.t(context,
        'Continuar con Google','Continue with Google')));
    final apple=OutlinedButton.icon(
      key:const Key('apple-signin-entry'),
      onPressed:legalConfigured?widget.onApple:null,
      style:OutlinedButton.styleFrom(
        foregroundColor:FitDateColors.pearl,
        side:BorderSide(color:brand.primaryColor.withValues(alpha:.65)),
        minimumSize:const Size(0,51)),
      icon:const Icon(Icons.apple),
      label:Text(FittedLocaleScope.t(context,
        'Continuar con Apple','Continue with Apple')));
    final email=FilledButton.icon(
      key:const Key('email-entry'),
      onPressed:legalConfigured?action:null,
      style:FilledButton.styleFrom(
        backgroundColor:brand.primaryColor,
        foregroundColor:brand.backgroundColor,
        minimumSize:const Size(0,51)),
      icon:const Icon(Icons.mail_outline),
      label:Text(register
        ?FittedLocaleScope.t(context,
          'Crear cuenta con correo','Create account with email')
        :FittedLocaleScope.t(context,
          'Entrar con correo','Sign in with email')));
    return wide
      ?Row(children:[
          Expanded(child:google),const SizedBox(width:14),
          Expanded(child:apple),const SizedBox(width:14),
          Expanded(child:email),
        ])
      :Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          google,const SizedBox(height:9),
          apple,const SizedBox(height:9),email,
        ]);
  }

  Widget _compactPromise(IconData icon,String es,String en,
      LiveBrandSettings brand) =>
    Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:brand.primaryColor,size:20),
      const SizedBox(width:9),
      Text(FittedLocaleScope.t(context,es,en),
        style:const TextStyle(color:FitDateColors.muted,fontSize:13)),
    ]);

  Widget _access(bool wide,LiveBrandSettings brand) => KeyedSubtree(
    key:const Key('landing-access'),
    child:Padding(
      padding:EdgeInsets.fromLTRB(wide?65:19,wide?8:18,
        wide?65:19,wide?22:24),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        Padding(
          padding:const EdgeInsets.only(bottom:13),
          child:Wrap(alignment:WrapAlignment.center,
            crossAxisAlignment:WrapCrossAlignment.center,
            spacing:15,runSpacing:6,children:[
              Text(FittedLocaleScope.t(context,
                'TU ESPACIO EN FITTED','YOUR FITTED SPACE'),
                style:TextStyle(color:brand.primaryColor,
                  fontSize:10,letterSpacing:1.6,
                  fontWeight:FontWeight.w800)),
              Text(register
                ?FittedLocaleScope.t(context,'Comienza aquí','Start here')
                :FittedLocaleScope.t(context,'Bienvenido','Welcome'),
                style:const TextStyle(color:FitDateColors.pearl,
                  fontSize:15,fontWeight:FontWeight.w700)),
              Text(register
                ?FittedLocaleScope.t(context,
                  'Crea tu cuenta y empieza tu perfil.',
                  'Create your account and begin your profile.')
                :FittedLocaleScope.t(context,
                  'Entra y continúa donde lo dejaste.',
                  'Sign in and pick up where you left off.'),
                style:const TextStyle(color:FitDateColors.muted,
                  fontSize:12)),
            ]),
        ),
        _authButtons(wide,brand),
        const SizedBox(height:14),
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
            style:TextStyle(color:brand.primaryColor,
              fontWeight:FontWeight.w600))),
        const SizedBox(height:13),
        Wrap(
          alignment:WrapAlignment.center,
          spacing:wide?30:18,runSpacing:12,
          children:[
            _compactPromise(Icons.people_outline,
              'Personas auténticas','Authentic people',brand),
            _compactPromise(Icons.auto_awesome_outlined,
              'Afinidad real','Meaningful affinity',brand),
            _compactPromise(Icons.shield_outlined,
              'Protección','Protection',brand),
          ]),
        const SizedBox(height:11),
        Wrap(
          alignment:WrapAlignment.center,
          spacing:15,
          children:[
            TextButton(
              onPressed:legalConfigured
                ?()=>openPolicy(widget.termsUrl):null,
              child:Text(FittedLocaleScope.t(context,'Términos','Terms'),
                style:const TextStyle(color:FitDateColors.pearl))),
            TextButton(
              onPressed:legalConfigured
                ?()=>openPolicy(widget.privacyUrl):null,
              child:Text(FittedLocaleScope.t(context,
                'Privacidad','Privacy'),
                style:const TextStyle(color:FitDateColors.pearl))),
          ]),
      ]),
    ));

  @override
  Widget build(BuildContext context) {
    final brand=LiveBrandScope.of(context);
    final width=MediaQuery.sizeOf(context).width;
    final wide=width>=920;
    return Scaffold(
      backgroundColor:brand.backgroundColor,
      appBar:AppBar(
        backgroundColor:brand.backgroundColor,
        titleSpacing:wide?32:15,
        title:Row(mainAxisSize:MainAxisSize.min,children:[
          const MfdBranding(full:false,width:42),
          const SizedBox(width:11),
          Flexible(child:Text(brand.name,maxLines:1,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:22,color:FitDateColors.pearl,
              fontWeight:FontWeight.w800))),
        ]),
        actions:[const Padding(padding:EdgeInsets.only(right:16),
          child:Center(child:FittedLanguageSelector()))],
      ),
      body:SafeArea(child:LayoutBuilder(builder:(context,box) {
        final panelWidth=(box.maxWidth-(wide?56:28)).clamp(0.0,1500.0).toDouble();
        return ListView(
          padding:EdgeInsets.symmetric(
            horizontal:wide?28:14,vertical:wide?16:10),
          children:[Center(child:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:1500),
            child:_hero(brand,wide,panelWidth))),
            const SizedBox(height:20),
          ],
        );
      })),
    );
  }
}
