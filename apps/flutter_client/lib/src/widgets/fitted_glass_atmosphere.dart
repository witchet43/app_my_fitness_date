import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/fitness_date_theme.dart';

/// Ambient brand geometry: paths and concentric loops, not a static rectangle.
/// Decorative only, mouse/touch transparent and reduced motion by default.
class FittedRhythmLines extends StatelessWidget {
  const FittedRhythmLines({super.key, this.density = 1});
  final double density;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child:ExcludeSemantics(child:CustomPaint(
      key:const Key('fitted-rhythm-lines'),
      painter:_RhythmPainter(density),
      size:Size.infinite,
    )),
  );
}

class _RhythmPainter extends CustomPainter {
  const _RhythmPainter(this.density);
  final double density;

  @override
  void paint(Canvas canvas, Size size) {
    if(size.isEmpty) return;
    final w=size.width,h=size.height;
    final paint=Paint()..style=PaintingStyle.stroke
      ..strokeCap=StrokeCap.round;
    final center=Offset(w*.93,h*.14);
    final limit=density.clamp(.3,1.8);
    for(var i=0;i<5;i++){
      paint.color=(i.isEven?FitDateColors.aqua:FitDateColors.lilac)
        .withValues(alpha:.14-(i*.014));
      paint.strokeWidth=i==0?1.8:.9;
      final radius=(h*.23)+(i*h*.065);
      canvas.drawArc(Rect.fromCircle(center:center,radius:radius),
        -.25,3.75,false,paint);
    }
    for(var i=0;i<3;i++){
      final origin=h*(.38+i*.23);
      final path=Path()
        ..moveTo(-w*.06,origin)
        ..cubicTo(w*.17,origin-h*.31*limit,
          w*.37,origin+h*.26*limit,w*.58,origin-h*.03)
        ..cubicTo(w*.73,origin-h*.26*limit,
          w*.83,origin+h*.07,w*1.1,origin-h*.24);
      paint.color=(i==1?FitDateColors.apricot:FitDateColors.aqua)
        .withValues(alpha:i==1?.22:.14);
      paint.strokeWidth=i==1?1.65:1.0;
      canvas.drawPath(path,paint);
    }
    for(var i=0;i<6;i++){
      final x=w*(.10+i*.155),y=h*(.18+(i%3)*.23);
      canvas.drawCircle(Offset(x,y),i.isEven?2.5:1.6,
        Paint()..color=FitDateColors.pearl.withValues(alpha:.30));
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter old) =>
    old.density!=density;
}

/// Transparent glass accent; semantic labels belong to the caller content.
/// Backdrop is bounded by a rounded clip for predictable GPU costs.
class FittedGlassPanel extends StatelessWidget {
  const FittedGlassPanel({super.key,required this.child,
    this.padding=const EdgeInsets.all(14),this.radius=20,this.blur=8});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius,blur;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius:BorderRadius.circular(radius),
    child:BackdropFilter(
      filter:ImageFilter.blur(sigmaX:blur,sigmaY:blur),
      child:Container(
        key:const Key('fitted-glass-panel'),
        padding:padding,
        decoration:BoxDecoration(
          gradient:LinearGradient(
            begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:[
              FitDateColors.pearl.withValues(alpha:.15),
              FitDateColors.aqua.withValues(alpha:.035),
            ],
          ),
          border:Border.all(color:FitDateColors.pearl.withValues(alpha:.24)),
          borderRadius:BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color:FitDateColors.inkDeep.withValues(alpha:.10),
              blurRadius:18,offset:const Offset(0,9)),
          ],
        ),
        child:child,
      ),
    ),
  );
}
