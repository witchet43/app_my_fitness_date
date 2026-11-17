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
    this.onSelectPillar,
  });

  final String titleEs, titleEn, subtitleEs, subtitleEn;
  final bool compact, showPillars;
  /// Routes to the corresponding private lifestyle setup when supplied.
  /// Public/unauthenticated hero has no profile access.
  final ValueChanged<int>? onSelectPillar;

  @override
  Widget build(BuildContext context) {
    final en = FittedLocaleScope.languageOf(context) == 'en';
    return LayoutBuilder(builder: (context, bounds) {
      final isWide = bounds.maxWidth >= 650;
      return Container(
        key: Key('fitted-rhythm-hero'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FitDateColors.aqua.withValues(alpha: .32)),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF17274A), Color(0xFF181D3E), Color(0xFF282143)],
          ),
          boxShadow: [BoxShadow(
            color: FitDateColors.aqua.withValues(alpha: .09),
            blurRadius: 32, offset: Offset(0, 16),
          )],
        ),
        child: Stack(children: [
          Positioned.fill(child:FittedRhythmLines()),
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
                    padding:EdgeInsets.symmetric(horizontal:12,vertical:8),
                    child:Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 18, height: 3,
                      decoration: BoxDecoration(color: FitDateColors.aqua,
                        borderRadius: BorderRadius.circular(3))),
                    SizedBox(width: 9),
                    Flexible(child:Text(
                      en ? 'LIFESTYLE COMPATIBILITY' : 'AFINIDAD DE ESTILO DE VIDA',
                      maxLines:2,softWrap:true,
                      style: TextStyle(color: FitDateColors.aqua,
                        letterSpacing: 1.1, fontSize: 10, fontWeight: FontWeight.w800))),
                  ])),
                  SizedBox(height: 17),
                  Text(en ? titleEn : titleEs,
                    style: TextStyle(fontFamily: 'Georgia',
                      fontSize: compact ? (isWide ? 30 : 27) : (isWide ? 43 : 33),
                      height: 1.13, letterSpacing: -.7,
                      color: FitDateColors.pearl, fontWeight: FontWeight.w700)),
                  SizedBox(height: 10),
                  Text(en ? subtitleEn : subtitleEs,
                    style: TextStyle(color: FitDateColors.muted,
                      fontSize: 14, height: 1.55)),
                  if (showPillars) ...[
                    SizedBox(height: compact ? 15 : 22),
                    Wrap(spacing: 8, runSpacing: 9, children: [
                      _PillarPill(
                        key:Key('hero-pillar-move'),
                        icon:Icons.directions_run_rounded,
                        text:en?'How I Move':'Cómo me muevo',
                        color:FitDateColors.aqua,
                        onTap:onSelectPillar==null?null:()=>onSelectPillar!(0)),
                      _PillarPill(
                        key:Key('hero-pillar-live'),
                        icon:Icons.wb_twilight_outlined,
                        text:en?'How I Live':'Cómo vivo',
                        color:FitDateColors.apricot,
                        onTap:onSelectPillar==null?null:()=>onSelectPillar!(1)),
                      _PillarPill(
                        key:Key('hero-pillar-relate'),
                        icon:Icons.connect_without_contact_outlined,
                        text:en?'How I Relate':'Cómo me relaciono',
                        color:FitDateColors.lilac,
                        onTap:onSelectPillar==null?null:()=>onSelectPillar!(2)),
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
  const _PillarPill({
    super.key,required this.icon,required this.text,
    required this.color,this.onTap,
  });
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button:onTap!=null,
    enabled:onTap!=null,
    child:Material(
      color:Colors.transparent,
      child:InkWell(
        borderRadius:BorderRadius.circular(100),
        onTap:onTap,
        child:Container(
    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: FitDateColors.inkDeep.withValues(alpha: .7),
      border: Border.all(color: color.withValues(alpha: .38)),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      SizedBox(width: 7),
      Text(text, style: TextStyle(color: FitDateColors.pearl,
        fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
      ),
    ),
    ),
  );
}
