import 'package:flutter/material.dart';

/// Continuous, accessible HSV hue + saturation/value control with HEX entry.
class FittedColorPicker extends StatefulWidget {
  const FittedColorPicker({super.key,required this.label,required this.initialColor});
  final String label;
  final Color initialColor;
  static Future<Color?> show(BuildContext context,{
    required String label,required Color initialColor,
  })=>showDialog<Color>(context:context,builder:(_)=>FittedColorPicker(
    label:label,initialColor:initialColor));
  @override
  State<FittedColorPicker> createState()=>_FittedColorPickerState();
}
class _FittedColorPickerState extends State<FittedColorPicker>{
  late HSVColor hsv;
  late TextEditingController hex;
  bool valid=true;
  static const suggestions=<Color>[
    Color(0xFFDDE7EC),Color(0xFF8196A2),Color(0xFF1A2D38),
    Color(0xFF8EF0D5),Color(0xFF68D4C7),Color(0xFFC6D7E0),
    Color(0xFFBBA6DB),Color(0xFF7AA5CA),Color(0xFFD5BE8A),
    Color(0xFF8D9A9D),Color(0xFF455D4B),Color(0xFFEAAB99),
  ];
  static final _validHex=RegExp(r'^#[0-9a-fA-F]{6}$');
  String _toHex(Color c)=>'#${(c.toARGB32()&0xFFFFFF).toRadixString(16).padLeft(6,'0').toUpperCase()}';
  @override
  void initState(){super.initState();
    hsv=HSVColor.fromColor(widget.initialColor);
    hex=TextEditingController(text:_toHex(widget.initialColor));
  }
  @override
  void dispose(){hex.dispose();super.dispose();}
  void _set(HSVColor next){
    setState((){
      hsv=next;valid=true;hex.text=_toHex(hsv.toColor());
    });
  }
  void _enterHex(String raw){
    final value=raw.trim();
    setState((){
      valid=_validHex.hasMatch(value);
      if(valid)hsv=HSVColor.fromColor(Color(
        int.parse(value.substring(1),radix:16)|0xFF000000));
    });
  }
  void _updateSV(Offset p,double width){
    if(width<=0)return;
    _set(hsv.withSaturation((p.dx/width).clamp(0.0,1.0))
      .withValue((1-p.dy/180).clamp(0.0,1.0)));
  }
  void _updateHue(double x,double width){
    if(width>0)_set(hsv.withHue((x/width*359.99).clamp(0.0,359.99)));
  }
  @override
  Widget build(BuildContext context){
    final c=hsv.toColor();
    final fg=c.computeLuminance()>.44?Colors.black87:Colors.white;
    final pickerWidth=(MediaQuery.sizeOf(context).width-112)
      .clamp(200.0,360.0).toDouble();
    return AlertDialog(
      key:const Key('brand-hsv-picker'),
      title:Text('Color: ${widget.label}'),
      content:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:430),
        child:SingleChildScrollView(child:Column(
          mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.stretch,
          children:[
            Text('Elige un punto en la paleta, mueve el tono o escribe HEX.',
              style:Theme.of(context).textTheme.bodySmall),
            const SizedBox(height:15),
            SizedBox(width:pickerWidth,height:180,
              child:GestureDetector(
                key:const Key('brand-hsv-sv'),behavior:HitTestBehavior.opaque,
                onTapDown:(v)=>_updateSV(v.localPosition,pickerWidth),
                onPanUpdate:(v)=>_updateSV(v.localPosition,pickerWidth),
                child:CustomPaint(painter:_SVPainter(hsv),
                  size:Size(pickerWidth,180)))),
            const SizedBox(height:16),
            SizedBox(width:pickerWidth,height:24,
              child:GestureDetector(
                key:const Key('brand-hsv-hue'),behavior:HitTestBehavior.opaque,
                onTapDown:(v)=>_updateHue(v.localPosition.dx,pickerWidth),
                onPanUpdate:(v)=>_updateHue(v.localPosition.dx,pickerWidth),
                child:CustomPaint(painter:_HuePainter(hsv.hue),
                  size:Size(pickerWidth,24)))),
            const SizedBox(height:18),
            Row(children:[
              Expanded(child:Container(
                key:const Key('brand-hsv-preview'),height:52,
                decoration:BoxDecoration(color:c,
                  borderRadius:BorderRadius.circular(12),
                  border:Border.all(color:Theme.of(context).dividerColor)),
                alignment:Alignment.center,
                child:Text('VISTA PREVIA',style:TextStyle(
                  color:fg,fontSize:11,fontWeight:FontWeight.w800)))),
              const SizedBox(width:12),
              Expanded(child:TextField(
                controller:hex,key:const Key('brand-hsv-hex'),
                maxLength:7,textCapitalization:TextCapitalization.characters,
                decoration:InputDecoration(labelText:'HEX',counterText:'',
                  errorText:valid?null:'Usa #RRGGBB'),
                onChanged:_enterHex)),
            ]),
            const SizedBox(height:6),
            Text('Colores de referencia',style:Theme.of(context).textTheme.labelMedium),
            const SizedBox(height:10),
            Wrap(spacing:9,runSpacing:9,children:[
              for(final suggestion in suggestions)
                Tooltip(message:_toHex(suggestion),
                  child:InkWell(
                    key:Key('brand-preset-${_toHex(suggestion)}'),
                    borderRadius:BorderRadius.circular(50),
                    onTap:()=>_set(HSVColor.fromColor(suggestion)),
                    child:Container(width:32,height:32,
                      decoration:BoxDecoration(shape:BoxShape.circle,
                        color:suggestion,border:Border.all(
                          color:Theme.of(context).colorScheme.onSurface,
                          width:c==suggestion?2.5:.5))))),
            ]),
          ],
        )),
      ),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancelar')),
        FilledButton(key:const Key('brand-hsv-apply'),
          onPressed:valid?()=>Navigator.pop(context,c):null,
          child:const Text('Aplicar color')),
      ],
    );
  }
}
class _SVPainter extends CustomPainter{
  const _SVPainter(this.hsv);
  final HSVColor hsv;
  @override
  void paint(Canvas canvas,Size size){
    final r=Offset.zero&size;
    final pure=HSVColor.fromAHSV(1,hsv.hue,1,1).toColor();
    canvas.drawRect(r,Paint()..shader=LinearGradient(
      colors:[Colors.white,pure]).createShader(r));
    canvas.drawRect(r,Paint()..shader=const LinearGradient(
      begin:Alignment.topCenter,end:Alignment.bottomCenter,
      colors:[Colors.transparent,Colors.black]).createShader(r));
    final point=Offset(hsv.saturation*size.width,(1-hsv.value)*size.height);
    canvas.drawCircle(point,8,Paint()..color=Colors.white
      ..style=PaintingStyle.stroke..strokeWidth=2.5);
    canvas.drawCircle(point,10,Paint()..color=Colors.black54
      ..style=PaintingStyle.stroke..strokeWidth=1);
  }
  @override
  bool shouldRepaint(_SVPainter old)=>old.hsv!=hsv;
}
class _HuePainter extends CustomPainter{
  const _HuePainter(this.hue);
  final double hue;
  @override
  void paint(Canvas canvas,Size size){
    final r=Offset.zero&size;
    canvas.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(10)),
      Paint()..shader=LinearGradient(colors:[
        for(var i=0;i<=6;i++)
          HSVColor.fromAHSV(1,(i*60.0)%360,1,1).toColor(),
      ]).createShader(r));
    final x=(hue/360*size.width).clamp(0.0,size.width);
    canvas.drawCircle(Offset(x,size.height/2),size.height*.48,
      Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=3);
  }
  @override
  bool shouldRepaint(_HuePainter old)=>old.hue!=hue;
}
