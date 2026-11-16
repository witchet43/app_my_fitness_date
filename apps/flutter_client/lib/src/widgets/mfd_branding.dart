import 'package:flutter/material.dart';
import '../core/live_brand.dart';
import '../theme/fitness_date_theme.dart';

/// Motion F: one mark on welcome, member screens and admin. Brand Lab custom
/// uploaded logos remain supported and can override this canonical default.
class MfdBranding extends StatelessWidget {
  const MfdBranding({
    super.key,
    this.full = true,
    this.width = 240,
  });
  final bool full;
  final double width;
  static const _catalog = <IconData>[
    Icons.diamond_outlined,
    Icons.graphic_eq,
    Icons.landscape_outlined,
    Icons.hub_outlined,
    Icons.multiline_chart,
    Icons.explore_outlined,
    Icons.timeline,
    Icons.waves_outlined,
    Icons.diamond_outlined,
    Icons.auto_graph_outlined,
  ];

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
        key:const Key('mfd-public-logo-network'),
        fit:BoxFit.contain,
        filterQuality:FilterQuality.high,
        errorBuilder:(context,error,stackTrace)=>Icon(
          Icons.auto_awesome,color:brand.primaryColor,size:32),
      );
    } else if (index != null && index > 0 && index < _catalog.length) {
      image = FittedBox(child:Icon(_catalog[index],
        color:brand.primaryColor,size:64));
    } else {
      image = Image.asset(
        'assets/branding/mfd_icon.webp',
        key:const Key('fitted-motion-f-mark'),
        fit:BoxFit.contain,
        filterQuality:FilterQuality.high,
        errorBuilder:(context,error,stackTrace)=>Icon(
          Icons.auto_awesome,color:brand.primaryColor,size:32),
      );
    }
    final markSize = full && bundledMark ? 63.0 : width;
    final mark = Container(
      key:Key(full ? 'mfd-brand-full' : 'mfd-brand-icon'),
      width:markSize,
      height:markSize,
      padding:EdgeInsets.all(bundledMark ? 1 : 5),
      decoration:BoxDecoration(
        color:bundledMark ? FitDateColors.inkDeep : brand.backgroundColor,
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
      child:full && bundledMark
        ? SizedBox(width:width,child:Row(
            mainAxisSize:MainAxisSize.min,
            children:[
              mark,
              const SizedBox(width:12),
              Flexible(child:Column(
                mainAxisSize:MainAxisSize.min,
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(brand.name.toUpperCase(),
                    key:const Key('fitted-motion-wordmark'),
                    maxLines:1,overflow:TextOverflow.ellipsis,
                    style:const TextStyle(
                      fontSize:23,fontWeight:FontWeight.w800,
                      letterSpacing:2.5,color:FitDateColors.pearl)),
                  const SizedBox(height:2),
                  const Text('RITMO · CONEXIÓN',
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
