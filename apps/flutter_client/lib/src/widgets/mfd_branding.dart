import 'package:flutter/material.dart';

/// Original My Fitness Date artwork provided by the product owner.
/// White backing is intentional: supplied raster logo has a white background.
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
    return Semantics(
      label: full ? 'Logotipo My Fitness Date' : 'Ícono My Fitness Date',
      image: true,
      child: Container(
        key: Key(full ? 'mfd-brand-full' : 'mfd-brand-icon'),
        width: width,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(full ? 18 : 14),
        ),
        child: Image.asset(
          full
              ? 'assets/branding/mfd_logo_full.webp'
              : 'assets/branding/mfd_icon.webp',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.favorite_outline,
            color: Color(0xFFFF4F73),
            size: 30,
          ),
        ),
      ),
    );
  }
}
