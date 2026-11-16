import 'package:flutter/material.dart';
import '../core/fitted_locale.dart';
import '../theme/fitness_date_theme.dart';
import 'fitted_glass_atmosphere.dart';

/// Brand-safe, presentational hero shared by onboarding and profile.
/// No user profiling, API calls, behavioral inference or feature gating here.
class FittedRhythmHero extends StatelessWidget {
  const FittedRhythmHero({
    super.key,
    required this.titleEs,
    required this.titleEn,
    required this.subtitleEs,
    required this.subtitleEn,
    this.compact = false,
    this.showPillars = true,
  });

  final String titleEs, titleEn, subtitleEs, subtitleEn;
  final bool compact, showPillars;

  @override
  Widget build(BuildContext context) {
    final en = FittedLocaleScope.languageOf(context) == 'en';
    return LayoutBuilder(builder: (context, bounds) {
      final isWide = bounds.maxWidth >= 650;
      return Container(
        key: const Key('fitted-rhythm-hero'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FitDateColors.aqua.withValues(alpha: .32)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF173D45), Color(0xFF182932), Color(0xFF252839)],
          ),
          boxShadow: [BoxShadow(
            color: FitDateColors.aqua.withValues(alpha: .09),
            blurRadius: 32, offset: const Offset(0, 16),
          )],
        ),
        child: Stack(children: [
          const Positioned.fill(child:FittedRhythmLines()),
          Positioned(
            top: compact ? -80 : -95, right: isWide ? -35 : -120,
            child: ExcludeSemantics(child: Container(
              width: compact ? 235 : 330, height: compact ? 235 : 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: FitDateColors.aqua.withValues(alpha: .22), width: 1.5),
                gradient: RadialGradient(colors: [
                  FitDateColors.aqua.withValues(alpha: .16),
                  FitDateColors.aqua.withValues(alpha: .025),
                  Colors.transparent,
                ]),
              ),
              child: Center(child: Container(
                width: compact ? 126 : 185, height: compact ? 126 : 185,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: FitDateColors.apricot.withValues(alpha: .38))),
                child: Center(child: Icon(Icons.graphic_eq_rounded,
                  size: compact ? 58 : 82,
                  color: FitDateColors.aqua.withValues(alpha: .22))),
              )),
            )),
          ),
          Padding(
            padding: EdgeInsets.all(isWide ? (compact ? 24 : 34) : 22),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 570 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedGlassPanel(
                    blur:6,radius:50,
                    padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
                    child:Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 18, height: 3,
                      decoration: BoxDecoration(color: FitDateColors.aqua,
                        borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 9),
                    Text(en ? 'LIFESTYLE COMPATIBILITY' : 'AFINIDAD DE ESTILO DE VIDA',
                      style: const TextStyle(color: FitDateColors.aqua,
                        letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.w800)),
                  ])),
                  const SizedBox(height: 17),
                  Text(en ? titleEn : titleEs,
                    style: TextStyle(fontFamily: 'Georgia',
                      fontSize: compact ? (isWide ? 30 : 27) : (isWide ? 43 : 33),
                      height: 1.13, letterSpacing: -.7,
                      color: FitDateColors.pearl, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(en ? subtitleEn : subtitleEs,
                    style: const TextStyle(color: FitDateColors.muted,
                      fontSize: 14, height: 1.55)),
                  if (showPillars) ...[
                    SizedBox(height: compact ? 15 : 22),
                    Wrap(spacing: 8, runSpacing: 9, children: [
                      _PillarPill(icon: Icons.directions_run_rounded,
                        text: 'How I Move', color: FitDateColors.aqua),
                      _PillarPill(icon: Icons.wb_twilight_outlined,
                        text: 'How I Live', color: FitDateColors.apricot),
                      _PillarPill(icon: Icons.connect_without_contact_outlined,
                        text: 'How I Relate', color: FitDateColors.lilac),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class _PillarPill extends StatelessWidget {
  const _PillarPill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1921).withValues(alpha: .5),
      border: Border.all(color: color.withValues(alpha: .38)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 7),
      Text(text, style: const TextStyle(color: FitDateColors.pearl,
        fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}
