import 'package:flutter/material.dart';

/// Compact Fit-IA athletic robot mascot. Theme-aware charcoal / silver
/// with the active brand accent. Vector geometry keeps it sharp at any size.
class FitIaMascot extends StatelessWidget{
  const FitIaMascot({super.key,this.size=56});
  final double size;
  @override
  Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Semantics(
      label:'Fit-IA, asistente deportivo',
      image:true,
      child:SizedBox(
        width:size,height:size,
        child:CustomPaint(painter:_FitIaMascotPainter(
          colors.primary,colors.onSurface,colors.surface)),
      ),
    );
  }
}
class _FitIaMascotPainter extends CustomPainter{
  const _FitIaMascotPainter(this.accent,this.ink,this.surface);
  final Color accent,ink,surface;
  @override
  void paint(Canvas canvas,Size size){
    canvas.save();
    canvas.scale(size.width/100,size.height/100);
    final silver=Color.lerp(surface,ink,.27)!;
    final shell=Color.lerp(surface,ink,.13)!;
    final dark=Color.lerp(ink,surface,.12)!;
    Paint line(Color color,double width)=>Paint()
      ..color=color..style=PaintingStyle.stroke
      ..strokeWidth=width..strokeCap=StrokeCap.round
      ..strokeJoin=StrokeJoin.round;
    Paint fill(Color color)=>Paint()..color=color;

    // A soft pair of orbital streaks suggests continuous movement.
    final orbit=Path()
      ..moveTo(8,63)..cubicTo(21,44,66,76,94,46);
    canvas.drawPath(orbit,line(accent.withValues(alpha:.55),4));
    final trail=Path()..moveTo(11,76)..cubicTo(26,83,47,84,67,72);
    canvas.drawPath(trail,line(silver.withValues(alpha:.85),2.5));

    // Dynamic stride with a forward knee, backward shin and rounded shoes.
    canvas.drawPath(Path()..moveTo(43,64)..lineTo(64,75)
      ..lineTo(79,88),line(dark,11));
    canvas.drawPath(Path()..moveTo(47,63)..lineTo(32,78)
      ..lineTo(18,83),line(dark,10));
    canvas.drawPath(Path()..moveTo(43,64)..lineTo(64,75)
      ..lineTo(79,88),line(silver,6.3));
    canvas.drawPath(Path()..moveTo(47,63)..lineTo(32,78)
      ..lineTo(18,83),line(shell,6.2));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(72,86,19,8),const Radius.circular(5)),
      fill(silver));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(8,80,18,8),const Radius.circular(5)),
      fill(silver));

    // Torso bends slightly forward, arms pump in opposite directions.
    canvas.drawOval(const Rect.fromLTWH(33,43,34,27),fill(dark));
    canvas.drawOval(const Rect.fromLTWH(37,46,25,20),fill(silver));
    canvas.drawPath(Path()..moveTo(44,49)..lineTo(25,60)
      ..lineTo(16,52),line(dark,11));
    canvas.drawPath(Path()..moveTo(44,49)..lineTo(25,60)
      ..lineTo(16,52),line(silver,7));
    canvas.drawPath(Path()..moveTo(58,50)..lineTo(74,55)
      ..lineTo(82,42),line(dark,12));
    canvas.drawPath(Path()..moveTo(58,50)..lineTo(74,55)
      ..lineTo(82,42),line(silver,7));
    canvas.drawCircle(const Offset(83,41),5.5,fill(silver));
    canvas.drawCircle(const Offset(16,52),5,fill(silver));

    // Helmet, dark visor and friendly smiling eye arcs.
    canvas.drawOval(const Rect.fromLTWH(30,12,45,41),fill(silver));
    canvas.drawOval(const Rect.fromLTWH(33,15,40,34),fill(shell));
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(38,24,33,20),const Radius.circular(10)),fill(dark));
    canvas.drawCircle(const Offset(35,32),6.2,fill(dark));
    canvas.drawCircle(const Offset(35,32),3.6,fill(accent));
    canvas.drawPath(Path()..moveTo(44,33)
      ..quadraticBezierTo(48,27,52,33),line(accent,2.6));
    canvas.drawPath(Path()..moveTo(58,33)
      ..quadraticBezierTo(62,28,66,33),line(accent,2.6));
    canvas.drawPath(Path()..moveTo(53,38)
      ..quadraticBezierTo(58,42,63,38),line(silver,2));
    canvas.drawPath(Path()..moveTo(43,56)
      ..quadraticBezierTo(50,55,58,53),line(accent,3.2));
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _FitIaMascotPainter old)=>
    old.accent!=accent||old.ink!=ink||old.surface!=surface;
}
