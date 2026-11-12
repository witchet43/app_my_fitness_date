import 'package:flutter/material.dart';
import '../core/live_brand.dart';

/// Reusable global logo on marketing, administration and member routes.
/// Only approved public-bucket assets are ever rendered on anonymous screens.
class MfdBranding extends StatelessWidget {
  const MfdBranding({
    super.key,
    this.full = true,
    this.width = 240,
  });

  final bool full;
  final double width;

  static const _catalog = <IconData>[
    Icons.favorite_outline,
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
    final isNetwork = LiveBrandSettings.safeAssetUrl(brand.logo);
    Widget image;
    if (isNetwork) {
      image = Image.network(
        brand.logo,
        key: const Key('mfd-public-logo-network'),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder:(context,error,stackTrace)=>Icon(
          Icons.favorite_outline,color:brand.primaryColor,size:32),
      );
    } else if (index != null && index > 0 && index < _catalog.length) {
      image = FittedBox(child:Icon(
        _catalog[index], color:brand.primaryColor, size:64,
      ));
    } else {
      image = Image.asset(
        full ? 'assets/branding/mfd_logo_full.webp'
             : 'assets/branding/mfd_icon.webp',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder:(context,error,stackTrace)=>Icon(
          Icons.favorite_outline,color:brand.primaryColor,size:32),
      );
    }
    return Semantics(
      label:'Logotipo ${brand.name}',
      image:true,
      child:Container(
        key:Key(full ? 'mfd-brand-full' : 'mfd-brand-icon'),
        width:width,
        height:full ? null : width,
        constraints:BoxConstraints(minHeight:full ? 75 : 0),
        padding:const EdgeInsets.all(5),
        decoration:BoxDecoration(
          color:Colors.white,
          borderRadius:BorderRadius.circular(full ? 18 : 14),
        ),
        child:image,
      ),
    );
  }
}
