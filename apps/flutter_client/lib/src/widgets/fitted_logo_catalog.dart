import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector collection, independent of fonts, assets or platform.
/// Index 0 deliberately retains the approved silver Motion F. The remaining
/// 20 concepts are distinct visual metaphors for movement and connection.
abstract final class FittedLogoCatalog {
  static const names = <String>[
    'F · Plata','Órbita','Nexo','Impulso','Cima','Pulso',
    'Amanecer','Trama','Cometa','Compás','Infinito',
    'Cadencia','Vértice','Convergencia','Flujo','Chispa',
    'Enlace','Ruta','Equilibrio','Expansión','Brote',
  ];
  static const descriptions = <String>[
    'Monograma original plateado con dos trazos dinámicos',
    'Trayectoria circular alrededor de un punto común',
    'Dos vínculos abiertos que se encuentran',
    'Tres trazos ascendentes con energía',
    'Silueta de dos cumbres en movimiento',
    'Ritmo continuo que une dos lados',
    'Sol emergente sobre un horizonte limpio',
    'Conexiones geométricas entre cuatro extremos',
    'Movimiento curvo con origen luminoso',
    'Puntos cardinales y decisión',
    'Conexión continua en dos direcciones',
    'Tres compases de movimiento',
    'Dos triángulos que avanzan',
    'Rutas convergentes hacia un objetivo',
    'Ondas ligeras en sincronía',
    'Destello minimalista de cuatro puntas',
    'Anillos enlazados sin corazón',
    'Ruta ascendente entre tres nodos',
    'Dos mitades en armonía',
    'Radios de energía que se expanden',
    'Crecimiento orgánico y bienestar',
  ];
  static const count = 21;
}

/// Uses its own vectors; 0 is painted by FittedMintMark in MfdBranding.
class FittedLogoGlyph extends StatelessWidget {
  const FittedLogoGlyph({
    super.key,required this.index,required this.size,
    required this.primary,required this.accent,
  });
  final int index;
  final double size;
  final Color primary,accent;

  @override
  Widget build(BuildContext context) => Semantics(
    label:FittedLogoCatalog.names[index.clamp(0,20)],
    image:true,
    child:SizedBox.square(
      dimension:size,
      child:CustomPaint(
        painter:_SymbolPainter(index,primary,accent),
      ),
    ),
  );
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter(this.index,this.primary,this.accent);
  final int index;
  final Color primary,accent;
  @override
  void paint(Canvas canvas,Size size) {
    canvas.save();
    canvas.scale(size.width/100,size.height/100);
    final stroke=Paint()..color=primary..style=PaintingStyle.stroke
      ..strokeWidth=6..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    final fine=Paint()..color=accent..style=PaintingStyle.stroke
      ..strokeWidth=4.5..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
    final solid=Paint()..color=accent..style=PaintingStyle.fill;
    final center=const Offset(50,50);
    void line(double x,double y,double x2,double y2,[Paint? p]) =>
      canvas.drawLine(Offset(x,y),Offset(x2,y2),p??stroke);
    void circle(double x,double y,double radius,[Paint? p]) =>
      canvas.drawCircle(Offset(x,y),radius,p??stroke);
    void path(List<Offset> dots,[Paint? p,bool close=false]){
      final d=Path()..moveTo(dots.first.dx,dots.first.dy);
      for(final point in dots.skip(1)){d.lineTo(point.dx,point.dy);}
      if(close)d.close();
      canvas.drawPath(d,p??stroke);
    }
    void arc(double x,double y,double radius,double start,double sweep,[Paint? p])=>
      canvas.drawArc(Rect.fromCircle(center:Offset(x,y),radius:radius),
        start,sweep,false,p??stroke);
    void dot(double x,double y,[double radius=4])=>circle(x,y,radius,solid);
    switch(index){
      case 1: // Orbit: tilted ellipse and a satellite.
        canvas.save();canvas.translate(50,50);canvas.rotate(-.38);
        canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:75,height:44),stroke);
        canvas.restore();arc(50,50,18,1.25,4.6,fine);dot(85,34,5);break;
      case 2: // Nexo: two open interlocking links.
        arc(35,46,20,-2.35,4.7);
        arc(65,54,20,.8,4.7,fine);
        line(40,54,60,46);break;
      case 3: // Impulse: three curved speed strokes.
        for(var i=0;i<3;i++){
          final y=30+i*20.0;
          final p=Path()..moveTo(20,y+9)
            ..cubicTo(39,y+7,49,y-12,79,y-14);
          canvas.drawPath(p,i==1?stroke:fine);
        }dot(79,17,5);break;
      case 4: // Cima.
        path([Offset(12,76),Offset(40,27),Offset(61,62),Offset(73,46),Offset(89,76)]);
        path([Offset(31,76),Offset(54,42),Offset(77,76)],fine);
        break;
      case 5: // Pulse.
        path([Offset(11,50),Offset(28,50),Offset(38,36),Offset(49,73),
          Offset(60,27),Offset(69,50),Offset(89,50)]);
        dot(11,50,3.5);dot(89,50,3.5);break;
      case 6: // Sunrise.
        line(13,69,87,69);arc(50,68,27,math.pi,math.pi);
        for(var a=0;a<5;a++){final ang=math.pi*1.1+a*math.pi*.2;
          line(50+38*math.cos(ang),68+38*math.sin(ang),
            50+44*math.cos(ang),68+44*math.sin(ang),fine);}
        break;
      case 7: // Mesh: crossed connections.
        for(final a in [Offset(23,28),Offset(77,28),Offset(23,73),Offset(77,73)])
          circle(a.dx,a.dy,7,a.dx==23?stroke:fine);
        line(23,28,77,73);line(77,28,23,73,fine);
        line(23,28,77,28,fine);line(23,73,77,73);break;
      case 8: // Comet.
        final p=Path()..moveTo(16,75)..cubicTo(36,72,41,47,74,29);
        canvas.drawPath(p,stroke);
        path([Offset(54,27),Offset(77,27),Offset(77,49)],fine);
        dot(81,24,5);break;
      case 9: // Compass.
        path([Offset(50,10),Offset(78,50),Offset(50,90),Offset(22,50)],stroke,true);
        path([Offset(50,26),Offset(61,50),Offset(50,73),Offset(39,50)],fine,true);
        dot(50,50);break;
      case 10: // Infinity.
        final p=Path()..moveTo(50,50)
          ..cubicTo(33,22,13,31,14,51)
          ..cubicTo(16,73,39,72,50,50)
          ..cubicTo(66,22,90,30,86,51)
          ..cubicTo(82,73,65,74,50,50);
        canvas.drawPath(p,stroke);dot(50,50,4);break;
      case 11: // Cadence.
        for(var i=0;i<3;i++){
          final x=26+i*24.0;
          line(x,70,x,34-i*8.0,i==1?stroke:fine);
          dot(x,30-i*8.0,4);
        }
        line(18,79,85,79,fine);break;
      case 12: // Vertex.
        path([Offset(12,71),Offset(37,25),Offset(63,71)],stroke,true);
        path([Offset(40,77),Offset(65,31),Offset(90,77)],fine,true);
        break;
      case 13: // Convergence: three trajectories.
        for(final y in [23.0,50.0,77.0]){
          final p=Path()..moveTo(16,y)
            ..quadraticBezierTo(52,y,74,50);
          canvas.drawPath(p,y==50?stroke:fine);
        }
        path([Offset(66,38),Offset(79,50),Offset(66,62)]);break;
      case 14: // Flow.
        for(var i=0;i<3;i++){
          final y=29+i*21.0;
          final p=Path()..moveTo(10,y)
            ..cubicTo(35,y-22,60,y+22,90,y);
          canvas.drawPath(p,i==1?stroke:fine);
        }break;
      case 15: // Spark.
        path([Offset(50,8),Offset(59,40),Offset(92,50),Offset(59,60),
          Offset(50,92),Offset(41,60),Offset(8,50),Offset(41,40)],stroke,true);
        dot(50,50,6);break;
      case 16: // Link: two diagonally interlocked rings.
        arc(38,44,23,.6,5.2,stroke);arc(62,56,23,3.7,5.2,fine);
        line(42,56,58,44);break;
      case 17: // Route: curved route with endpoints.
        final p=Path()..moveTo(20,78)
          ..cubicTo(10,47,68,62,56,31)
          ..quadraticBezierTo(51,18,80,19);
        canvas.drawPath(p,stroke);
        dot(20,78,6);dot(56,31,5);dot(80,19,6);break;
      case 18: // Balance.
        arc(50,51,35,math.pi*.56,math.pi*.90);
        arc(50,51,35,-math.pi*.44,math.pi*.90,fine);
        line(50,20,50,80);circle(50,50,7);break;
      case 19: // Expansion.
        for(var i=0;i<8;i++){
          final angle=i*math.pi/4.0;
          line(50+19*math.cos(angle),50+19*math.sin(angle),
            50+39*math.cos(angle),50+39*math.sin(angle),i.isEven?stroke:fine);
        }
        circle(50,50,8);break;
      case 20: // Sprout: two leaves, a stem.
        final p=Path()..moveTo(50,84)..quadraticBezierTo(53,57,50,41);
        canvas.drawPath(p,stroke);
        final left=Path()..moveTo(49,57)
          ..quadraticBezierTo(16,55,24,26)
          ..quadraticBezierTo(47,27,49,57);
        final right=Path()..moveTo(51,44)
          ..quadraticBezierTo(51,17,81,17)
          ..quadraticBezierTo(79,39,51,44);
        canvas.drawPath(left,stroke);canvas.drawPath(right,fine);break;
      default: // Invalid state has a neutral, non-interactive fallback.
        circle(center.dx,center.dy,20);break;
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _SymbolPainter old)=>
    old.index!=index||old.primary!=primary||old.accent!=accent;
}
