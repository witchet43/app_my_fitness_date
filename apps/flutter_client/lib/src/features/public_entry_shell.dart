import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/live_brand.dart';
import '../core/fitted_locale.dart';
import '../widgets/mfd_branding.dart';
import '../theme/fitness_date_theme.dart';

/// Exact editorial composition approved for the Fitted public cover.
/// The approved source contains the original young couple and mint ribbon.
/// Photography, story, sign-in and legal links remain one accessible panel;
/// no raster text or fake sign-in hotspots are used.
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
  static const _silver = Color(0xFFBCCCD4);
  static const _approvedArtwork =
    'assets/branding/fitted_approved_cover_reference.png';

  bool get legalConfigured =>
    widget.termsUrl.startsWith('https://') &&
    widget.privacyUrl.startsWith('https://');

  Future<void> openPolicy(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'https') {
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    }
  }

  Widget _approvedPair() => LayoutBuilder(builder:(context,box) {
    // Crop the exact approved reference in source-image pixels; keep the
    // real couple, hair silhouette and motion ribbon, not the baked-in UI.
    const sourceWidth=1672.0;
    const sourceHeight=941.0;
    const cropLeft=746.0;
    const cropTop=33.0;
    const cropWidth=916.0;
    const cropHeight=559.0;
    final scale=math.max(box.maxWidth/cropWidth,
      box.maxHeight/cropHeight);
    return Stack(fit:StackFit.expand,children:[
      Positioned(
        left:-cropLeft*scale,top:-cropTop*scale,
        width:sourceWidth*scale,height:sourceHeight*scale,
        child:Image.asset(_approvedArtwork,fit:BoxFit.fill,
          key:const Key('landing-approved-image-source')),
      ),
    ]);
  });

  Widget _photo(LiveBrandSettings brand,bool wide) {
    final candidate=brand.media[wide?'cover_desktop':'cover_mobile'];
    final custom=candidate!=null && LiveBrandSettings.safeAssetUrl(candidate);
    Widget image = custom
      ? Image.network(candidate,fit:BoxFit.cover,
          errorBuilder:(_,__,___)=>_approvedPair())
      : _approvedPair();
    image=ClipRect(child:image);
    // The source image softly disappears into the shared slate background,
    // so no rectangular image container interrupts the floating portrait.
    if(wide) {
      image=ShaderMask(
        blendMode:BlendMode.dstIn,
        shaderCallback:(bounds)=>const LinearGradient(
          begin:Alignment.centerLeft,end:Alignment.centerRight,
          stops:[0,.16,.38,1],
          colors:[Colors.transparent,Colors.black54,Colors.black,Colors.black],
        ).createShader(bounds),
        child:ShaderMask(
          blendMode:BlendMode.dstIn,
          shaderCallback:(bounds)=>const LinearGradient(
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
            stops:[0,.77,1],
            colors:[Colors.black,Colors.black,Colors.transparent],
          ).createShader(bounds),
          child:image,
        ),
      );
    }
    return Semantics(
      label:FittedLocaleScope.t(context,
        'Pareja joven corriendo al aire libre, portada aprobada de Fitted',
        'Young adults running outdoors, approved Fitted cover'),
      image:true,
      child:KeyedSubtree(
        key:const Key('landing-editorial-photo'),child:image));
  }

  Widget _chip(IconData icon,String es,String en,
      LiveBrandSettings brand,double scale) =>
    Container(
      padding:EdgeInsets.symmetric(
        horizontal:14*scale,vertical:10*scale),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(42),
        color:const Color(0xFF0B2830).withValues(alpha:.70),
        border:Border.all(color:_silver.withValues(alpha:.56),
          width:1.05),
      ),
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        Icon(icon,color:_silver,size:24*scale),
        SizedBox(width:9*scale),
        Text(FittedLocaleScope.t(context,es,en),
          style:TextStyle(color:FitDateColors.pearl,
            fontWeight:FontWeight.w800,fontSize:16.5*scale)),
      ]),
    );

  Widget _message(LiveBrandSettings brand,double scale,bool wide) {
    final title=FittedTranslations.translate(
      brand.title,FittedLocaleScope.languageOf(context));
    final rawDescription=FittedTranslations.translate(
      brand.description,FittedLocaleScope.languageOf(context));
    final description=rawDescription==
      'Entrenamiento, bienestar y un estilo de vida activo. Conecta con personas que comparten tus intereses, valores y pasión por el movimiento.'
      ?'Entrenamiento, bienestar y un estilo de vida activo.\n'
       'Conecta con personas que comparten tus intereses,\n'
       'valores y pasión por el movimiento.'
      :rawDescription;
    final titleStyle=TextStyle(
      color:FitDateColors.pearl,fontFamily:brand.font,
      fontSize:wide?70*scale:37,fontWeight:FontWeight.w800,
      letterSpacing:wide?-2.1*scale:-.9,
      height:1.04,
    );
    Widget headline;
    if(title=='Conexiones que trascienden.') {
      headline=Text.rich(TextSpan(children:[
        const TextSpan(text:'Conexiones que\n'),
        TextSpan(text:'trascienden.',style:const TextStyle(color:_silver)),
      ]),key:const Key('landing-headline'),style:titleStyle);
    } else if(title=='Connections that go further.') {
      headline=Text.rich(TextSpan(children:[
        const TextSpan(text:'Connections that\n'),
        TextSpan(text:'go further.',style:const TextStyle(color:_silver)),
      ]),key:const Key('landing-headline'),style:titleStyle);
    } else {
      headline=Text(title,key:const Key('landing-headline'),style:titleStyle);
    }
    return Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      mainAxisSize:MainAxisSize.min,
      children:[
        Text(FittedLocaleScope.t(context,
          'PERSONAS EN MOVIMIENTO','PEOPLE IN MOTION'),
          style:TextStyle(color:_silver,fontSize:19*scale,
            letterSpacing:1.4*scale,fontWeight:FontWeight.w800)),
        SizedBox(height:17*scale),
        Container(width:68*scale,height:6*scale,
          decoration:BoxDecoration(color:_silver.withValues(alpha:.92),
            borderRadius:BorderRadius.circular(5))),
        SizedBox(height:28*scale),
        headline,
        SizedBox(height:19*scale),
        Text(description,key:const Key('landing-brand-description'),
          style:TextStyle(color:FitDateColors.pearl,
            height:1.37,fontSize:20.6*scale,fontWeight:FontWeight.w500)),
        SizedBox(height:19*scale),
        Wrap(spacing:14*scale,runSpacing:10*scale,children:[
          _chip(Icons.directions_run_rounded,
            'Cómo me muevo','How I Move',brand,scale),
          _chip(Icons.spa_outlined,
            'Cómo vivo','How I Live',brand,scale),
          _chip(Icons.groups,
            'Cómo me relaciono','How I Relate',brand,scale),
        ]),
      ],
    );
  }

  Widget _googleSymbol(double scale)=>ShaderMask(
    blendMode:BlendMode.srcIn,
    shaderCallback:(bounds)=>const LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,
      stops:[0,.30,.55,.78,1],
      colors:[
        Color(0xFF4285F4),Color(0xFFEA4335),
        Color(0xFFFBBC05),Color(0xFF34A853),Color(0xFF4285F4)
      ]).createShader(bounds),
    child:Text('G',style:TextStyle(
      color:Colors.white,fontWeight:FontWeight.w900,
      fontFamily:'Arial',fontSize:27*scale)));

  Widget _authButtons(bool wide,LiveBrandSettings brand,double scale) {
    final action=register
      ?widget.onEmailRegister??widget.onEmail
      :widget.onEmailSignIn??widget.onEmail;
    final labelStyle=TextStyle(
      fontWeight:FontWeight.w700,fontSize:19.2*scale);
    final height=66*scale;
    final google=OutlinedButton.icon(
      key:const Key('google-signin-entry'),
      onPressed:legalConfigured?widget.onGoogle:null,
      style:OutlinedButton.styleFrom(
        minimumSize:Size(0,height),
        padding:EdgeInsets.symmetric(horizontal:10*scale),
        foregroundColor:FitDateColors.pearl,
        textStyle:labelStyle,
        side:BorderSide(color:_silver.withValues(alpha:.72),
          width:1.2),
        shape:const StadiumBorder(),
        backgroundColor:const Color(0xFF0D2A32).withValues(alpha:.62),
      ),
      icon:_googleSymbol(scale),
      label:Text(FittedLocaleScope.t(context,
        'Continuar con Google','Continue with Google')),
    );
    final apple=OutlinedButton.icon(
      key:const Key('apple-signin-entry'),
      onPressed:legalConfigured?widget.onApple:null,
      style:OutlinedButton.styleFrom(
        minimumSize:Size(0,height),
        padding:EdgeInsets.symmetric(horizontal:10*scale),
        foregroundColor:FitDateColors.pearl,
        textStyle:labelStyle,
        side:BorderSide(color:_silver.withValues(alpha:.72),
          width:1.2),
        shape:const StadiumBorder(),
        backgroundColor:const Color(0xFF0D2A32).withValues(alpha:.62),
      ),
      icon:Icon(Icons.apple,size:28*scale),
      label:Text(FittedLocaleScope.t(context,
        'Continuar con Apple','Continue with Apple')),
    );
    final email=FilledButton.icon(
      key:const Key('email-entry'),
      onPressed:legalConfigured?action:null,
      style:FilledButton.styleFrom(
        minimumSize:Size(0,height),
        padding:EdgeInsets.symmetric(horizontal:10*scale),
        textStyle:labelStyle,
        shape:const StadiumBorder(),
        backgroundColor:brand.primaryColor,
        foregroundColor:brand.backgroundColor,
      ),
      icon:Icon(Icons.mail_outline_rounded,size:25*scale),
      label:Text(register
        ?FittedLocaleScope.t(context,
          'Crear cuenta con correo','Create account with email')
        :FittedLocaleScope.t(context,
          'Entrar con correo','Sign in with email')),
    );
    if(!wide) {
      return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        google,const SizedBox(height:9),
        apple,const SizedBox(height:9),email,
      ]);
    }
    return Row(children:[
      Expanded(child:google),SizedBox(width:18*scale),
      Expanded(child:apple),SizedBox(width:18*scale),
      Expanded(child:email),
    ]);
  }

  Widget _promise(IconData icon,String es,String en,
      LiveBrandSettings brand,double scale) =>
    Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:_silver,size:28*scale),
      SizedBox(width:12*scale),
      Text(FittedLocaleScope.t(context,es,en),
        style:TextStyle(color:FitDateColors.pearl,
          fontSize:18.5*scale)),
    ]);

  Widget _access(bool wide,LiveBrandSettings brand,double scale,
      double panelWidth) => KeyedSubtree(
    key:const Key('landing-access'),
    child:Padding(
      padding:EdgeInsets.fromLTRB(
        wide?panelWidth*.111:21,
        wide?0:18,
        wide?panelWidth*.111:21,
        wide?30*scale:23),
      child:Column(mainAxisSize:MainAxisSize.min,children:[
        _authButtons(wide,brand,scale),
        SizedBox(height:16*scale),
        Row(children:[
          Expanded(child:Divider(color:FitDateColors.pearl.withValues(alpha:.7),
            thickness:.8)),
          SizedBox(width:14*scale),
          Flexible(child:TextButton(
            key:const Key('switch-entry-mode'),
            onPressed:()=>setState(()=>register=!register),
            child:Text.rich(
              TextSpan(children:[
                TextSpan(text:register
                  ?FittedLocaleScope.t(context,'¿Ya tienes cuenta? ',
                    'Already have an account? ')
                  :FittedLocaleScope.t(context,'¿Aún no tienes cuenta? ',
                    'New here? ')),
                TextSpan(text:register
                  ?FittedLocaleScope.t(context,'Inicia sesión','Sign in')
                  :FittedLocaleScope.t(context,'Regístrate','Sign up'),
                  style:TextStyle(color:brand.primaryColor,
                    decoration:TextDecoration.underline,
                    decorationColor:brand.primaryColor,
                    fontWeight:FontWeight.w800)),
              ]),maxLines:1,
              style:TextStyle(color:FitDateColors.pearl,
                fontSize:17.2*scale,fontWeight:FontWeight.w500)),
          )),
          SizedBox(width:14*scale),
          Expanded(child:Divider(color:FitDateColors.pearl.withValues(alpha:.7),
            thickness:.8)),
        ]),
        SizedBox(height:16*scale),
        Wrap(alignment:WrapAlignment.center,
          crossAxisAlignment:WrapCrossAlignment.center,
          spacing:30*scale,runSpacing:12*scale,
          children:[
            _promise(Icons.groups_rounded,
              'Personas auténticas','Authentic people',brand,scale),
            if(wide) Text('|',style:TextStyle(
              color:FitDateColors.pearl,fontSize:18*scale)),
            _promise(Icons.auto_awesome_rounded,
              'Afinidad real','Meaningful affinity',brand,scale),
            if(wide) Text('|',style:TextStyle(
              color:FitDateColors.pearl,fontSize:18*scale)),
            _promise(Icons.shield_outlined,
              'Protección','Protection',brand,scale),
          ]),
        SizedBox(height:14*scale),
        Wrap(alignment:WrapAlignment.center,
          crossAxisAlignment:WrapCrossAlignment.center,
          spacing:wide?21*scale:1,runSpacing:4,
          children:[
          TextButton(
            onPressed:legalConfigured
              ?()=>openPolicy(widget.termsUrl):null,
            child:Text(FittedLocaleScope.t(context,'Términos','Terms'),
              style:TextStyle(color:FitDateColors.pearl,
                fontSize:17.5*scale))),
          Text('|',style:TextStyle(
            color:FitDateColors.pearl,fontSize:17*scale)),
          TextButton(
            onPressed:legalConfigured
              ?()=>openPolicy(widget.privacyUrl):null,
            child:Text(FittedLocaleScope.t(context,'Privacidad','Privacy'),
              style:TextStyle(color:FitDateColors.pearl,
                fontSize:17.5*scale))),
        ]),
      ]),
    ));

  Widget _hero(LiveBrandSettings brand,bool wide,double panelWidth) {
    final scale=(panelWidth/1616).clamp(.73,1.09).toDouble();
    // Intrinsic height follows translated/wrapping copy; no blank spacer
    // between the three lifestyle pillars and working sign-in controls.
    return Stack(
      key:const Key('landing-hero'),
      clipBehavior:Clip.none,
      children:[
        Container(
          width:panelWidth,
          decoration:BoxDecoration(
            borderRadius:BorderRadius.circular(53*scale),
            border:Border.all(color:_silver.withValues(alpha:.63),
              width:1.25),
            gradient:LinearGradient(
              begin:Alignment.topLeft,end:Alignment.bottomRight,
              colors:[brand.backgroundColor,
                const Color(0xFF13343E),const Color(0xFF12303A)])),
          clipBehavior:Clip.antiAlias,
          child:Stack(children:[
            Positioned.fill(child:IgnorePointer(child:CustomPaint(
              painter:_FittedApprovedWaves(brand.primaryColor)))),
            Column(children:[
              if(wide)
                Padding(
                  padding:EdgeInsets.fromLTRB(
                    panelWidth*.067,59*scale,panelWidth*.48,32*scale),
                  child:Align(alignment:Alignment.topLeft,
                    child:_message(brand,scale,true)),
                )
              else ...[
                SizedBox(height:265,width:double.infinity,
                  child:_photo(brand,false)),
                Padding(
                  padding:const EdgeInsets.fromLTRB(21,22,20,18),
                  child:_message(brand, .75,false)),
              ],
              _access(wide,brand,scale,panelWidth),
            ]),
          ]),
        ),
        if(wide)
          Positioned(
            right:0,top:-46*scale,
            width:panelWidth*.557,height:557*scale,
            child:IgnorePointer(child:_photo(brand,true)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand=LiveBrandScope.of(context);
    final width=MediaQuery.sizeOf(context).width;
    final wide=width>=1120;
    return Scaffold(
      backgroundColor:brand.backgroundColor,
      appBar:AppBar(
        toolbarHeight:62,
        backgroundColor:brand.backgroundColor,
        titleSpacing:wide?31:15,
        title:Row(mainAxisSize:MainAxisSize.min,children:[
          const MfdBranding(full:false,width:44),
          const SizedBox(width:10),
          Flexible(child:Text(brand.name,maxLines:1,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:27.5,
              color:FitDateColors.pearl,fontWeight:FontWeight.w800))),
        ]),
        actions:[const Padding(padding:EdgeInsets.only(right:16),
          child:Center(child:FittedLanguageSelector()))],
      ),
      body:SafeArea(child:LayoutBuilder(builder:(context,box) {
        final panelWidth=math.min(box.maxWidth-(wide?52:24),1680.0);
        return ListView(
          clipBehavior:Clip.none,
          padding:EdgeInsets.symmetric(
            horizontal:wide?26:12,vertical:wide?17:11),
          children:[Center(child:_hero(brand,wide,panelWidth)),
            const SizedBox(height:40)],
        );
      })),
    );
  }
}

/// Teal editorial swoops: background-only. Text and buttons remain real UI.
class _FittedApprovedWaves extends CustomPainter {
  const _FittedApprovedWaves(this.mint);
  final Color mint;

  @override
  void paint(Canvas canvas,Size size) {
    final w=size.width,h=size.height;
    final silver=Color.lerp(mint,const Color(0xFFACBEC8),.9)!;
    final graphite=Color.lerp(mint,const Color(0xFF4D6977),.9)!;
    final left=Path()
      ..moveTo(0,h*.675)
      ..cubicTo(w*.06,h*.726,w*.16,h*.87,w*.245,h)
      ..lineTo(0,h)..close();
    canvas.drawPath(left,Paint()..shader=LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[silver.withValues(alpha:.58),
        graphite.withValues(alpha:.30),
        graphite.withValues(alpha:.04)],
    ).createShader(Rect.fromLTWH(0,h*.64,w*.25,h*.4)));

    final right=Path()
      ..moveTo(w*.765,h)
      ..cubicTo(w*.87,h*.95,w*.965,h*.79,w,h*.655)
      ..lineTo(w,h)..close();
    canvas.drawPath(right,Paint()..shader=LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[graphite.withValues(alpha:.16),
        silver.withValues(alpha:.47),silver.withValues(alpha:.68)],
    ).createShader(Rect.fromLTWH(w*.74,h*.65,w*.26,h*.36)));
  }

  @override
  bool shouldRepaint(covariant _FittedApprovedWaves oldDelegate) =>
    oldDelegate.mint!=mint;
}
