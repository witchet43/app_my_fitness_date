import 'package:flutter/material.dart';

import '../core/dating_repository_b11.dart';

/// One explicit, server-gated transition. Never displays another person's
/// gym or schedule. Unapproved/demo gyms are excluded by the API and SQL.
class GymShieldActivationB11 extends StatefulWidget {
  const GymShieldActivationB11({
    super.key,required this.api,required this.mode,
  });
  final DatingRepositoryB11 api;
  final String mode;

  @override
  State<GymShieldActivationB11> createState()=>_GymShieldActivationB11State();
}

class _GymShieldActivationB11State extends State<GymShieldActivationB11> {
  bool loading=true;
  bool submitting=false;
  String? error;
  String? gymId;
  List<Map<String,dynamic>> gyms=[];
  final List<Map<String,int>> slots=[];
  int day=1;
  int start=420;
  int end=540;

  static const weekdays=[
    'Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado',
  ];
  static final times=[
    for(var m=300;m<=1380;m+=30)m,
  ];
  static String formatTime(int minute)=>
    '${(minute~/60).toString().padLeft(2,'0')}:'
    '${(minute%60).toString().padLeft(2,'0')}';

  @override
  void initState(){super.initState();loadGyms();}

  Future<void> loadGyms() async {
    try{
      final values=await widget.api.gymCatalogB11();
      if(mounted)setState((){
        gyms=values.where((item)=>
          item['id'] is String &&
          item['name'] is String &&
          item['city'] is String).toList();
      });
    }catch(_){
      if(mounted)setState(()=>error=
        'El catálogo seguro no está disponible. Comprueba tu acceso.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }

  void addSlot(){
    if(slots.length>=14||start>=end){
      setState(()=>error='Revisa la franja o el límite de 14 horarios.');
      return;
    }
    if(slots.any((s)=>s['day']==day &&
      start<s['endMinutes']! && s['startMinutes']!<end)){
      setState(()=>error='Las franjas del mismo día no deben traslaparse.');
      return;
    }
    setState((){
      error=null;
      slots.add({'day':day,'startMinutes':start,'endMinutes':end});
    });
  }

  Future<void> submitGymActivation() async {
    final selected=gymId;
    if(selected==null)return;
    if(widget.mode=='same_gym_other_time'&&slots.isEmpty){
      setState(()=>error='Agrega al menos una franja privada.');
      return;
    }
    setState((){
      submitting=true;error=null;
    });
    try{
      final result=await widget.api.activateB11(selected,
        widget.mode=='same_gym_other_time'
          ?List<Map<String,int>>.from(slots)
          :<Map<String,int>>[]);
      if(result!='activated')throw StateError('Activation not approved');
      if(mounted)Navigator.of(context).pop(true);
    }catch(_){
      if(mounted)setState(()=>error=
        'No fue posible activar. Las verificaciones o la '
        'configuración de Gym Shield siguen pendientes.');
    }finally{
      if(mounted)setState(()=>submitting=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strict=widget.mode!='same_gym_other_time';
    return Scaffold(
      appBar:AppBar(title:const Text('Configurar Gym Shield')),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:720),
        child:ListView(
          key:const Key('b11-gym-shield-activation'),
          padding:const EdgeInsets.all(18),
          children:[
            Text(strict
              ?'Modo A · Excluir el gimnasio donde entreno'
              :'Modo B · Mismo gimnasio solo con separación temporal',
              style:Theme.of(context).textTheme.titleLarge),
            const SizedBox(height:10),
            const Text('Tu gimnasio y tus horarios son privados. '
              'No se muestran a candidatos ni a matches. '
              'Esta configuración solo funciona con autorización '
              'independiente de edad, consentimiento y moderación.'),
            const SizedBox(height:18),
            if(loading)const LinearProgressIndicator(),
            if(!loading&&gyms.isEmpty)
              const Card(child:Padding(
                padding:EdgeInsets.all(16),
                child:Text('No hay gimnasios reales aprobados en el '
                  'catálogo. Un administrador debe registrar el lugar '
                  'antes de habilitar las citas. No usamos gimnasios '
                  'ficticios ni aceptamos ubicaciones sin validar.'),
              )),
            if(gyms.isNotEmpty) DropdownButtonFormField<String>(
              key:const Key('b11-gym-select'),
              isExpanded:true,
              initialValue:gymId,
              decoration:const InputDecoration(
                labelText:'Selecciona tu gimnasio privado'),
              items:[
                for(final gym in gyms)
                  DropdownMenuItem(
                    value:gym['id'].toString(),
                    child:Text('${gym['name']} · ${gym['city']}',
                      overflow:TextOverflow.ellipsis),
                  ),
              ],
              onChanged:submitting?null:(value)=>
                setState(()=>gymId=value),
            ),
            if(!strict)...[
              const SizedBox(height:16),
              const Text('Horarios privados para proteger tu rutina. '
                'Solo se usan para evitar coincidencias con menos '
                'de 30 minutos de separación.'),
              DropdownButtonFormField<int>(
                key:const Key('b11-day'),
                initialValue:day,
                decoration:const InputDecoration(labelText:'Día de la semana'),
                items:[
                  for(var d=0;d<7;d++)
                    DropdownMenuItem(value:d,child:Text(weekdays[d])),
                ],
                onChanged:submitting?null:(value){
                  if(value!=null)setState(()=>day=value);
                },
              ),
              Row(children:[
                Expanded(child:DropdownButtonFormField<int>(
                  key:const Key('b11-slot-start'),
                  initialValue:start,
                  decoration:const InputDecoration(labelText:'Desde'),
                  items:[
                    for(final m in times)
                      DropdownMenuItem(value:m,child:Text(formatTime(m))),
                  ],
                  onChanged:submitting?null:(value){
                    if(value!=null)setState(()=>start=value);
                  },
                )),
                const SizedBox(width:12),
                Expanded(child:DropdownButtonFormField<int>(
                  key:const Key('b11-slot-end'),
                  initialValue:end,
                  decoration:const InputDecoration(labelText:'Hasta'),
                  items:[
                    for(final m in times)
                      DropdownMenuItem(value:m,child:Text(formatTime(m))),
                  ],
                  onChanged:submitting?null:(value){
                    if(value!=null)setState(()=>end=value);
                  },
                )),
              ]),
              OutlinedButton.icon(
                key:const Key('b11-add-slot'),
                onPressed:submitting?null:addSlot,
                icon:const Icon(Icons.add),
                label:const Text('Añadir franja privada'),
              ),
              for(var i=0;i<slots.length;i++)
                ListTile(
                  title:Text('${weekdays[slots[i]['day']!]} · '
                    '${formatTime(slots[i]['startMinutes']!)} – '
                    '${formatTime(slots[i]['endMinutes']!)}'),
                  trailing:IconButton(
                    tooltip:'Quitar franja',
                    onPressed:submitting?null:()=>
                      setState(()=>slots.removeAt(i)),
                    icon:const Icon(Icons.delete_outline),
                  ),
                ),
            ],
            if(error!=null)Padding(
              padding:const EdgeInsets.symmetric(vertical:10),
              child:Text(error!,
                key:const Key('b11-gym-error'),
                style:const TextStyle(color:Colors.redAccent)),
            ),
            const SizedBox(height:20),
            FilledButton.icon(
              key:const Key('b11-activate-confirm'),
              onPressed:loading||submitting||gymId==null
                ?null:submitGymActivation,
              icon:const Icon(Icons.verified_user_outlined),
              label:Text(submitting
                ?'Verificando…'
                :'Activar mi participación protegida'),
            ),
          ],
        ),
      )),
    );
  }
}
