import 'package:flutter/material.dart';
import '../core/live_brand.dart';
import '../theme/fitness_date_theme.dart';
import 'fitted_logo_catalog.dart';


/* Shared translucent silver F. The two flowing strokes evoke motion and
 * connection without visual clutter or reliance on a remote asset. */
class FittedMintMark extends StatelessWidget {
  const FittedMintMark({super.key,this.size=48});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width:size,height:size,child:CustomPaint(painter:_FittedMintPainter()));
}
class _FittedMintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas,Size size) {
    canvas.save();
    canvas.scale(size.width/200,size.height/200);
    final top=Path()
      ..moveTo(43,53)
      ..cubicTo(60,23,85,30,120,30)
      ..cubicTo(148,30,173,31,179,29)
      ..cubicTo(175,52,151,66,124,66)
      ..cubicTo(100,66,77,60,63,86)
      ..cubicTo(47,95,36,107,26,121)
      ..cubicTo(28,91,32,71,43,53)
      ..close();
    final lower=Path()
      ..moveTo(28,113)
      ..cubicTo(51,88,61,80,94,80)
      ..cubicTo(118,78,128,76,137,72)
      ..cubicTo(128,93,114,108,94,110)
      ..cubicTo(75,109,69,113,61,129)
      ..cubicTo(45,165,21,174,14,158)
      ..cubicTo(9,142,13,130,28,113)
      ..close();
    canvas.drawPath(top,Paint()..shader=LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[Color(0xE8F2F6F7),Color(0xBFA9B9C1),Color(0x906F8792)],
    ).createShader(Rect.fromLTWH(14,22,168,146)));
    canvas.drawPath(lower,Paint()..shader=LinearGradient(
      begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[Color(0xD9CDD9DF),Color(0xA67D929D),Color(0x85516674)],
    ).createShader(Rect.fromLTWH(12,68,140,112)));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}

/// Silver Motion F: one mark on welcome, member screens and admin. Brand Lab custom
/// uploaded logos remain supported and can override this canonical default.
class MfdBranding extends StatelessWidget {
  const MfdBranding({
    super.key,
    this.full = true,
    this.width = 240,
  });
  final bool full;
  final double width;


  @override
  Widget build(BuildContext context) {
    final brand = LiveBrandScope.of(context);
    final index = brand.logo.startsWith('catalog:')
        ? int.tryParse(brand.logo.substring(8)) : null;
    final networkLogo = LiveBrandSettings.safeAssetUrl(brand.logo);
    // catalog:0 = brand-owned icon; user-uploaded logo wins.
    final bundledMark = !networkLogo && (index == null || index == 0);
    Widget image;
    if (networkLogo) {
      image = Image.network(
        brand.logo,
        key:Key('mfd-public-logo-network'),
        fit:BoxFit.contain,
        filterQuality:FilterQuality.high,
        errorBuilder:(context,error,stackTrace)=>Icon(
          Icons.auto_awesome,color:Color(0xFFB5C5CE),size:32),
      );
    } else if (index != null && index > 0 && index < FittedLogoCatalog.count) {
      image = LayoutBuilder(builder:(_,box)=>FittedLogoGlyph(
        index:index,size:box.biggest.shortestSide,
        primary:brand.primaryColor,accent:brand.accentColor));
    } else {
      image = LayoutBuilder(
        builder:(_,box)=>FittedMintMark(
          key:Key('fitted-motion-f-mark'),
          size:box.biggest.shortestSide),
      );
    }
    final markSize = full ? 63.0 : width;
    final mark = Container(
      key:Key(full ? 'mfd-brand-full' : 'mfd-brand-icon'),
      width:markSize,
      height:markSize,
      padding:EdgeInsets.all(bundledMark ? 0 : 5),
      decoration:BoxDecoration(
        color:bundledMark ? Colors.transparent : brand.backgroundColor,
        border:bundledMark ? null : Border.all(
          color:brand.primaryColor.withValues(alpha:.4)),
        borderRadius:BorderRadius.circular(full ? 19 : 14),
      ),
      child:ClipRRect(
        borderRadius:BorderRadius.circular(full ? 18 : 13),
        child:image,
      ),
    );
    return Semantics(
      label:'Logotipo ${brand.name}',
      image:true,
      child:full
        ? SizedBox(width:width,child:Row(
            mainAxisSize:MainAxisSize.min,
            children:[
              mark,
              SizedBox(width:12),
              Flexible(child:Column(
                mainAxisSize:MainAxisSize.min,
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(brand.name.toUpperCase(),
                    key:Key('fitted-motion-wordmark'),
                    maxLines:1,overflow:TextOverflow.ellipsis,
                    style:TextStyle(
                      fontSize:23,fontWeight:FontWeight.w800,
                      letterSpacing:2.5,color:FitDateColors.pearl)),
                  SizedBox(height:2),
                  Text('RITMO · CONEXIÓN',
                    maxLines:1,overflow:TextOverflow.ellipsis,
                    style:TextStyle(fontSize:8.5,letterSpacing:1.2,
                      color:FitDateColors.lilac,
                      fontWeight:FontWeight.w700)),
                ],
              )),
            ],
          ))
        :mark,
    );
  }
}
