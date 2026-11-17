import 'package:flutter/material.dart';

/// Branded athlete/connection vector collection. 0 preserves the silver
/// monogram; 1..20 depict exercise, companionship, momentum and wellbeing.
/// Paths are absolute SVG-style M/L/Q/C/Z (no remote assets).
abstract final class FittedLogoCatalog {
  static const names=<String>[
    'F · Plata',
    'Zancada compartida',
    'Fuerza en pareja',
    'Ciclismo en dúo',
    'Meta compartida',
    'Kilómetros juntos',
    'Relevo',
    'Pulso activo',
    'Entrenamos juntos',
    'Pista de conexión',
    'Paso a paso',
    'Senderismo en pareja',
    'Cumbre en equipo',
    'Yoga en pareja',
    'Tenis social',
    'Ruta de encuentros',
    'Gimnasio en equipo',
    'Ritmo de carrera',
    'Entrenamiento funcional',
    'Fitness & afinidad',
    'Movimiento contigo',
  ];
  static const descriptions=<String>[
    'Monograma de movimiento original, sin clichés románticos',
    'Dos personas corriendo al mismo ritmo',
    'Dos deportistas sostienen una barra juntos',
    'Dos personas pedaleando y compartiendo ruta',
    'Dos corredores alcanzan una meta juntos',
    'Dos trayectorias de carrera que avanzan hacia el mismo destino',
    'Una conexión auténtica representada por el pase del testigo',
    'Energía de dos personas conectadas por un ritmo saludable',
    'Dos personas activas unidas por una mancuerna',
    'Carriles deportivos que se acercan como una conexión real',
    'Un par de huellas avanza en la misma dirección',
    'Dos caminantes compartiendo el recorrido',
    'Dos personas conquistan una montaña juntas',
    'Dos personas en equilibrio, bienestar y conexión',
    'Dos raquetas y una pelota: entrenamiento y afinidad',
    'Dos caminos que se unen en un punto de llegada',
    'Fuerza, constancia y compañerismo en el gimnasio',
    'Dos corredores sincronizan su frecuencia de movimiento',
    'Dos atletas completan un circuito funcional',
    'Dos siluetas activas conectadas por metas compartidas',
    'Dos figuras avanzan y forman una trayectoria conjunta',
  ];
  static const primaryPaths=<String>[
    '',
    'M 25 30 C 25 27.2 27.2 25 30 25 C 32.8 25 35 27.2 35 30 C 35 32.8 32.8 35 30 35 C 27.2 35 25 32.8 25 30 Z M 30 37 L 34 52 L 22 68 M 34 52 L 46 63 M 30 40 L 16 49 M 30 40 L 44 33 M 64 26 C 64 23.2 66.2 21 69 21 C 71.8 21 74 23.2 74 26 C 74 28.8 71.8 31 69 31 C 66.2 31 64 28.8 64 26 Z M 69 33 L 65 48 L 76 64 M 65 48 L 53 59 M 69 36 L 84 45 M 69 36 L 55 29',
    'M 26 40 C 26 37.2 28.2 35 31 35 C 33.8 35 36 37.2 36 40 C 36 42.8 33.8 45 31 45 C 28.2 45 26 42.8 26 40 Z M 64 40 C 64 37.2 66.2 35 69 35 C 71.8 35 74 37.2 74 40 C 74 42.8 71.8 45 69 45 C 66.2 45 64 42.8 64 40 Z M 31 48 L 31 68 L 22 84 M 31 68 L 44 84 M 69 48 L 69 68 L 56 84 M 69 68 L 82 84',
    'M 10 71 C 10 63.8 15.8 58 23 58 C 30.2 58 36 63.8 36 71 C 36 78.2 30.2 84 23 84 C 15.8 84 10 78.2 10 71 Z M 64 71 C 64 63.8 69.8 58 77 58 C 84.2 58 90 63.8 90 71 C 90 78.2 84.2 84 77 84 C 69.8 84 64 78.2 64 71 Z M 23 71 L 44 47 L 56 71 L 23 71 M 44 47 L 67 47 L 77 71 M 44 47 L 37 42',
    'M 25 31 C 25 28.2 27.2 26 30 26 C 32.8 26 35 28.2 35 31 C 35 33.8 32.8 36 30 36 C 27.2 36 25 33.8 25 31 Z M 30 38 L 34 53 L 22 69 M 34 53 L 46 64 M 30 41 L 16 50 M 30 41 L 44 34 M 65 31 C 65 28.2 67.2 26 70 26 C 72.8 26 75 28.2 75 31 C 75 33.8 72.8 36 70 36 C 67.2 36 65 33.8 65 31 Z M 70 38 L 66 53 L 77 69 M 66 53 L 54 64 M 70 41 L 85 50 M 70 41 L 56 34',
    'M 15 81 C 9 49 24 18 42 24 C 57 29 30 70 49 78 M 85 81 C 91 49 76 18 58 24 C 43 29 70 70 51 78',
    'M 24 33 C 24 30.2 26.2 28 29 28 C 31.8 28 34 30.2 34 33 C 34 35.8 31.8 38 29 38 C 26.2 38 24 35.8 24 33 Z M 29 40 L 33 55 L 21 71 M 33 55 L 45 66 M 29 43 L 15 52 M 29 43 L 43 36 M 67 30 C 67 27.2 69.2 25 72 25 C 74.8 25 77 27.2 77 30 C 77 32.8 74.8 35 72 35 C 69.2 35 67 32.8 67 30 Z M 72 37 L 68 52 L 79 68 M 68 52 L 56 63 M 72 40 L 87 49 M 72 40 L 58 33',
    'M 11 50 C 11 46.7 13.7 44 17 44 C 20.3 44 23 46.7 23 50 C 23 53.3 20.3 56 17 56 C 13.7 56 11 53.3 11 50 Z M 77 50 C 77 46.7 79.7 44 83 44 C 86.3 44 89 46.7 89 50 C 89 53.3 86.3 56 83 56 C 79.7 56 77 53.3 77 50 Z M 24 51 L 34 51 L 40 38 L 48 69 L 57 31 L 65 51 L 76 51',
    'M 12 30 C 12 26.7 14.7 24 18 24 C 21.3 24 24 26.7 24 30 C 24 33.3 21.3 36 18 36 C 14.7 36 12 33.3 12 30 Z M 76 30 C 76 26.7 78.7 24 82 24 C 85.3 24 88 26.7 88 30 C 88 33.3 85.3 36 82 36 C 78.7 36 76 33.3 76 30 Z M 18 38 L 18 76 M 82 38 L 82 76 M 20 57 L 80 57 M 26 45 L 26 69 M 34 40 L 34 74 M 74 45 L 74 69 M 66 40 L 66 74',
    'M 15 84 C 7 41 24 16 52 16 C 82 16 93 40 86 84 M 29 84 C 26 48 34 30 52 30 C 70 30 76 48 72 84',
    'M 20 64 Q 7 44 22 31 Q 35 24 40 44 L 39 58 Q 32 73 20 64 Z M 61 76 Q 52 57 65 44 Q 77 34 85 56 L 83 72 Q 73 89 61 76 Z',
    'M 29 33 C 29 30.2 31.2 28 34 28 C 36.8 28 39 30.2 39 33 C 39 35.8 36.8 38 34 38 C 31.2 38 29 35.8 29 33 Z M 34 40 L 34 56 L 43 72 M 34 56 L 22 72 M 34 42 L 23 55 M 34 42 L 43 49 M 64 32 C 64 29.2 66.2 27 69 27 C 71.8 27 74 29.2 74 32 C 74 34.8 71.8 37 69 37 C 66.2 37 64 34.8 64 32 Z M 69 39 L 69 55 L 60 71 M 69 55 L 81 71 M 69 41 L 80 54 M 69 41 L 60 48',
    'M 8 85 L 39 29 L 55 58 L 69 40 L 93 85 M 21 85 L 39 57 L 54 85',
    'M 26 29 C 26 25.7 28.7 23 32 23 C 35.3 23 38 25.7 38 29 C 38 32.3 35.3 35 32 35 C 28.7 35 26 32.3 26 29 Z M 62 29 C 62 25.7 64.7 23 68 23 C 71.3 23 74 25.7 74 29 C 74 32.3 71.3 35 68 35 C 64.7 35 62 32.3 62 29 Z M 32 37 L 32 60 M 68 37 L 68 60 M 32 60 Q 19 77 7 64 M 32 60 Q 49 83 52 68 M 68 60 Q 81 77 93 64 M 68 60 Q 51 83 48 68',
    'M 12 35 C 12 25.6 19.6 18 29 18 C 38.4 18 46 25.6 46 35 C 46 44.4 38.4 52 29 52 C 19.6 52 12 44.4 12 35 Z M 54 35 C 54 25.6 61.6 18 71 18 C 80.4 18 88 25.6 88 35 C 88 44.4 80.4 52 71 52 C 61.6 52 54 44.4 54 35 Z M 35 50 L 49 79 M 65 50 L 51 79 M 42 76 L 56 83',
    'M 15 83 Q 15 34 45 38 Q 53 39 56 18 M 85 83 Q 85 34 55 38 Q 47 39 44 18',
    'M 20 51 L 80 51 M 26 39 L 26 63 M 34 34 L 34 68 M 74 39 L 74 63 M 66 34 L 66 68 M 26 21 C 26 18.2 28.2 16 31 16 C 33.8 16 36 18.2 36 21 C 36 23.8 33.8 26 31 26 C 28.2 26 26 23.8 26 21 Z M 64 21 C 64 18.2 66.2 16 69 16 C 71.8 16 74 18.2 74 21 C 74 23.8 71.8 26 69 26 C 66.2 26 64 23.8 64 21 Z',
    'M 28 33 C 28 30.2 30.2 28 33 28 C 35.8 28 38 30.2 38 33 C 38 35.8 35.8 38 33 38 C 30.2 38 28 35.8 28 33 Z M 33 40 L 37 55 L 25 71 M 37 55 L 49 66 M 33 43 L 19 52 M 33 43 L 47 36 M 64 26 C 64 23.2 66.2 21 69 21 C 71.8 21 74 23.2 74 26 C 74 28.8 71.8 31 69 31 C 66.2 31 64 28.8 64 26 Z M 69 33 L 65 48 L 76 64 M 65 48 L 53 59 M 69 36 L 84 45 M 69 36 L 55 29',
    'M 25 26 C 25 23.2 27.2 21 30 21 C 32.8 21 35 23.2 35 26 C 35 28.8 32.8 31 30 31 C 27.2 31 25 28.8 25 26 Z M 65 26 C 65 23.2 67.2 21 70 21 C 72.8 21 75 23.2 75 26 C 75 28.8 72.8 31 70 31 C 67.2 31 65 28.8 65 26 Z M 30 33 L 36 55 L 21 82 M 36 55 L 52 81 M 70 33 L 64 55 L 79 82 M 64 55 L 48 81',
    'M 22 28 C 22 24.7 24.7 22 28 22 C 31.3 22 34 24.7 34 28 C 34 31.3 31.3 34 28 34 C 24.7 34 22 31.3 22 28 Z M 66 28 C 66 24.7 68.7 22 72 22 C 75.3 22 78 24.7 78 28 C 78 31.3 75.3 34 72 34 C 68.7 34 66 31.3 66 28 Z M 28 37 L 35 57 L 17 80 M 35 57 L 46 78 M 72 37 L 65 57 L 83 80 M 65 57 L 54 78',
    'M 26 29 C 26 26.2 28.2 24 31 24 C 33.8 24 36 26.2 36 29 C 36 31.8 33.8 34 31 34 C 28.2 34 26 31.8 26 29 Z M 31 36 L 35 51 L 23 67 M 35 51 L 47 62 M 31 39 L 17 48 M 31 39 L 45 32 M 64 29 C 64 26.2 66.2 24 69 24 C 71.8 24 74 26.2 74 29 C 74 31.8 71.8 34 69 34 C 66.2 34 64 31.8 64 29 Z M 69 36 L 65 51 L 76 67 M 65 51 L 53 62 M 69 39 L 84 48 M 69 39 L 55 32',
  ];
  static const accentPaths=<String>[
    '',
    'M 17 85 Q 49 76 87 83',
    'M 12 31 L 88 31 M 19 16 L 19 46 M 27 22 L 27 40 M 73 22 L 73 40 M 81 16 L 81 46',
    'M 32 24 C 32 21.2 34.2 19 37 19 C 39.8 19 42 21.2 42 24 C 42 26.8 39.8 29 37 29 C 34.2 29 32 26.8 32 24 Z M 63 24 C 63 21.2 65.2 19 68 19 C 70.8 19 73 21.2 73 24 C 73 26.8 70.8 29 68 29 C 65.2 29 63 26.8 63 24 Z M 36 31 L 44 47 M 67 31 L 61 47 M 10 88 Q 50 80 90 88',
    'M 12 21 L 88 21 M 14 18 L 14 80 M 86 18 L 86 80 M 35 70 L 65 70',
    'M 37 23 C 37 20.2 39.2 18 42 18 C 44.8 18 47 20.2 47 23 C 47 25.8 44.8 28 42 28 C 39.2 28 37 25.8 37 23 Z M 53 23 C 53 20.2 55.2 18 58 18 C 60.8 18 63 20.2 63 23 C 63 25.8 60.8 28 58 28 C 55.2 28 53 25.8 53 23 Z M 42 78 L 58 78',
    'M 42 40 L 58 43 M 15 89 L 38 89 M 62 89 L 86 89',
    'M 22 75 Q 50 89 78 75',
    'M 18 51 L 31 57 M 82 51 L 69 57 M 15 80 L 27 80 M 73 80 L 85 80',
    'M 34 55 C 34 52.2 36.2 50 39 50 C 41.8 50 44 52.2 44 55 C 44 57.8 41.8 60 39 60 C 36.2 60 34 57.8 34 55 Z M 58 55 C 58 52.2 60.2 50 63 50 C 65.8 50 68 52.2 68 55 C 68 57.8 65.8 60 63 60 C 60.2 60 58 57.8 58 55 Z M 44 62 Q 51 69 58 62',
    'M 24 19 Q 38 9 49 20 M 50 86 Q 58 95 77 93',
    'M 7 85 Q 27 70 49 85 Q 70 68 93 84 M 18 66 L 12 89 M 81 63 L 88 88',
    'M 30 24 C 30 21.2 32.2 19 35 19 C 37.8 19 40 21.2 40 24 C 40 26.8 37.8 29 35 29 C 32.2 29 30 26.8 30 24 Z M 60 35 C 60 32.2 62.2 30 65 30 C 67.8 30 70 32.2 70 35 C 70 37.8 67.8 40 65 40 C 62.2 40 60 37.8 60 35 Z M 34 32 L 45 48 M 65 43 L 75 57',
    'M 32 43 Q 49 54 68 43 M 12 84 L 88 84',
    'M 45 41 C 45 38.2 47.2 36 50 36 C 52.8 36 55 38.2 55 41 C 55 43.8 52.8 46 50 46 C 47.2 46 45 43.8 45 41 Z M 21 25 L 37 45 M 63 45 L 79 25',
    'M 9 83 C 9 79.7 11.7 77 15 77 C 18.3 77 21 79.7 21 83 C 21 86.3 18.3 89 15 89 C 11.7 89 9 86.3 9 83 Z M 79 83 C 79 79.7 81.7 77 85 77 C 88.3 77 91 79.7 91 83 C 91 86.3 88.3 89 85 89 C 81.7 89 79 86.3 79 83 Z M 43 17 C 43 13.1 46.1 10 50 10 C 53.9 10 57 13.1 57 17 C 57 20.9 53.9 24 50 24 C 46.1 24 43 20.9 43 17 Z M 45 17 L 55 17',
    'M 31 29 L 31 38 L 44 51 M 69 29 L 69 38 L 56 51 M 19 84 L 81 84',
    'M 9 82 Q 51 96 91 81 M 10 34 L 23 34 M 75 22 L 93 22',
    'M 15 22 L 85 22 M 15 22 L 15 33 M 85 22 L 85 33 M 44 44 L 56 44',
    'M 37 47 Q 50 33 63 47 M 21 88 Q 50 79 79 88',
    'M 13 89 C 30 70 50 79 50 68 C 50 79 70 70 87 89 M 40 14 Q 50 8 60 14',
  ];
  static const count=21;
}

class FittedLogoGlyph extends StatelessWidget {
  const FittedLogoGlyph({super.key,required this.index,required this.size,
    required this.primary,required this.accent});
  final int index;
  final double size;
  final Color primary,accent;

  @override
  Widget build(BuildContext context) => Semantics(
    image:true,
    label:FittedLogoCatalog.names[index.clamp(0,20)],
    child:SizedBox.square(dimension:size,child:CustomPaint(
      painter:_BrandedLogoPainter(index,primary,accent),
    )),
  );
}

class _BrandedLogoPainter extends CustomPainter {
  const _BrandedLogoPainter(this.index,this.primary,this.accent);
  final int index;
  final Color primary,accent;
  static final _tokens=RegExp(r'[MLCQZ]|-?[0-9]+(?:\.[0-9]+)?');
  static final Map<String,Path> _cache={};

  Path _parse(String data)=>_cache.putIfAbsent(data,(){
    final path=Path(),tokens=_tokens.allMatches(data).map((e)=>e.group(0)!).toList();
    var i=0;
    double number()=>double.parse(tokens[i++]);
    while(i<tokens.length){
      final cmd=tokens[i++];
      switch(cmd){
        case 'M':path.moveTo(number(),number());
        case 'L':path.lineTo(number(),number());
        case 'Q':path.quadraticBezierTo(number(),number(),number(),number());
        case 'C':path.cubicTo(number(),number(),number(),number(),number(),number());
        case 'Z':path.close();
        default:throw FormatException('Unexpected vector path command');
      }
    }
    return path;
  });

  @override
  void paint(Canvas canvas,Size size){
    if(index<1||index>20)return;
    canvas.save();
    canvas.scale(size.width/100,size.height/100);
    final lines=[
      (FittedLogoCatalog.primaryPaths[index],primary,5.5),
      (FittedLogoCatalog.accentPaths[index],accent,4.2),
    ];
    for(final (data,color,thickness) in lines){
      if(data.isEmpty)continue;
      canvas.drawPath(_parse(data),Paint()
        ..color=color..style=PaintingStyle.stroke
        ..strokeWidth=thickness..strokeJoin=StrokeJoin.round
        ..strokeCap=StrokeCap.round);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _BrandedLogoPainter old)=>
    old.index!=index||old.primary!=primary||old.accent!=accent;
}
