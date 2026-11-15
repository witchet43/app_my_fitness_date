import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import '../core/fitted_locale.dart';

/// User-owned private training schedule. Never publishes training places,
/// day/window combinations, or the member's identity to other users.
class FittedGymShieldV28 extends StatefulWidget {
  const FittedGymShieldV28({
    super.key,required this.api,required this.onAddPlace,
  });
  final MemberV26Api api;
  final Future<void> Function() onAddPlace;
  @override
  State<FittedGymShieldV28> createState()=>_FittedGymShieldV28State();
}

class _FittedGymShieldV28State extends State<FittedGymShieldV28> {
  static const modes=['exclude_same_gym','different_time','include_same_time'];
  static const timeCodes=['early','morning','midday','evening'];
  static const modeTitlesEs=[
    'Mi gimnasio es mi espacio privado',
    'Mismo gimnasio, otros horarios',
    'Mismo gimnasio, incluso mi horario',
  ];
  static const modeTitlesEn=[
    'Keep my gym separate',
    'Same gym, different times',
    'Same gym, even the same time',
  ];
  static const modeDetailsEs=[
    'No quiero coincidencias con personas de mi gimnasio.',
    'Acepto compartir gimnasio, pero quiero proteger mi franja habitual.',
    'Aceptaría coincidir también en mis horarios. La búsqueda en este modo '
      'permanece deshabilitada hasta completar la evaluación de seguridad.',
  ];
  static const modeDetailsEn=[
    'Do not suggest anyone from my gym.',
    'Sharing a gym is fine, but protect my usual training window.',
    'I would accept a shared gym and time window. Discovery in this mode '
      'stays disabled until the independent safety review is complete.',
  ];
  String mode='exclude_same_gym';
  List<Map<String,dynamic>> places=[];
  final List<Map<String,dynamic>> windows=[];
  bool loading=true,saving=false;
  String? message;

  @override
  void initState(){super.initState();load();}
  String tr(String es,String en)=>FittedLocaleScope.t(context,es,en);
  bool get english=>FittedLocaleScope.languageOf(context)=='en';

  Future<void> load() async {
    setState((){loading=true;message=null;});
    try {
      final result=await Future.wait<dynamic>([
        widget.api.loadPlaces(),
        widget.api.auth.rpc('fitted_shield_get_v28'),
      ]);
      final config=Map<String,dynamic>.from(result[1] as Map);
      if(config['status']!='ok')throw StateError('Unauthorized');
      if(!mounted)return;
      setState((){
        places=List<Map<String,dynamic>>.from(result[0] as List);
        mode=modes.contains(config['mode'])?config['mode'] as String:modes.first;
        windows.clear();
        for(final raw in (config['windows'] as List? ?? [])){
          if(raw is Map){
            final v=Map<String,dynamic>.from(raw);
            if(v['place_id'] is String && v['day'] is int &&
              timeCodes.contains(v['window'])){
              windows.add(v);
            }
          }
        }
      });
    }catch(_){
      if(mounted)setState(()=>message=tr(
        'No se pudo cargar Gym Shield. Revisa tu sesión y vuelve a intentar.',
        'Gym Shield could not be loaded. Check your session and try again.'));
    }finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> save() async{
    if(saving||loading)return;
    setState((){saving=true;message=null;});
    try{
      final response=await widget.api.auth.rpc('fitted_shield_save_v28',
        params:{'p_mode':mode,'p_windows':windows});
      final result=Map<String,dynamic>.from(response as Map);
      if(result['status']!='saved')throw StateError('Save not approved');
      if(mounted)setState(()=>message=tr(
        'Preferencias y horarios guardados de forma privada. '
        'Esto no publica tu gimnasio ni activa encuentros.',
        'Your preferences and training windows are privately saved. '
        'This does not reveal your gym or enable dating.'));
    }catch(_){
      if(mounted)setState(()=>message=tr(
        'No se pudo guardar. Comprueba tu sesión y los lugares seleccionados.',
        'Could not save. Check your session and selected places.'));
    }finally{if(mounted)setState(()=>saving=false);}
  }

  String dayName(int index){
    const es=['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'];
    const en=['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return (english?en:es)[index];
  }

  String timeName(String code){
    final i=timeCodes.indexOf(code);
    if(i<0)return code;
    const es=['Muy temprano','Mañana','Mediodía','Tarde/noche'];
    const en=['Early','Morning','Midday','Evening'];
    return (english?en:es)[i];
  }

  Future<void> addWindow(Map<String,dynamic> place) async{
    if(windows.length>=28)return;
    var day=0,window='morning';
    final result=await showDialog<Map<String,dynamic>>(context:context,
      builder:(ctx)=>StatefulBuilder(builder:(ctx,refresh)=>
        AlertDialog(
          title:Text(tr('Añadir franja habitual','Add usual time window')),
          content:Column(mainAxisSize:MainAxisSize.min,children:[
            Text((place['place_name']??'').toString()),
            const SizedBox(height:12),
            DropdownButtonFormField<int>(
              key:const Key('gym-shield-day'),
              initialValue:day,
              decoration:InputDecoration(labelText:tr('Día','Day')),
              items:[for(var d=0;d<7;d++)
                DropdownMenuItem(value:d,child:Text(dayName(d)))],
              onChanged:(v)=>refresh(()=>day=v??0)),
            const SizedBox(height:12),
            DropdownButtonFormField<String>(
              key:const Key('gym-shield-window'),
              initialValue:window,
              decoration:InputDecoration(labelText:tr(
                'Momento aproximado','Approximate time')),
              items:[for(final code in timeCodes)
                DropdownMenuItem(value:code,child:Text(timeName(code)))],
              onChanged:(v)=>refresh(()=>window=v??'morning')),
            const SizedBox(height:14),
            Text(tr('Nunca pedimos una hora exacta ni compartimos esta rutina.',
              'We never request an exact time or reveal this routine.'),
              style:Theme.of(context).textTheme.bodySmall),
          ]),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(ctx),
              child:Text(tr('Cancelar','Cancel'))),
            FilledButton(onPressed:()=>Navigator.pop(ctx,{
                'place_id':place['id'],'day':day,'window':window,
              }),child:Text(tr('Añadir','Add'))),
          ],
        )),
    );
    if(result==null)return;
    final already=windows.any((v)=>v['place_id']==result['place_id'] &&
      v['day']==result['day']&&v['window']==result['window']);
    if(!already&&windows.length<28)setState(()=>windows.add(result));
  }

  Future<void> removePlace(Map<String,dynamic> place) async{
    final id=place['id']?.toString();
    if(id==null)return;
    final confirm=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:Text(tr('Quitar lugar privado','Remove private place')),
        content:Text(tr('Se eliminarán también sus ventanas habituales. '
          'Esta acción no afecta otros lugares.',
          'Its usual time windows will also be deleted. '
          'Other places are unaffected.')),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text(tr('Cancelar','Cancel'))),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text(tr('Eliminar','Delete'))),
        ],
      ),
    );
    if(confirm!=true||!mounted)return;
    try{
      await widget.api.removePlace(id);
      setState(()=>windows.removeWhere((w)=>w['place_id']==id));
      await load();
    }catch(_){
      if(mounted)setState(()=>message=tr(
        'No se pudo quitar este lugar.',
        'Could not remove this place.'));
    }
  }

  Widget modeCard(int i) {
    final active=mode==modes[i];
    return Semantics(
      selected:active,
      child:InkWell(
        key:Key('gym-shield-mode-${modes[i]}'),
        borderRadius:BorderRadius.circular(17),
        onTap:()=>setState(()=>mode=modes[i]),
        child:AnimatedContainer(
          duration:const Duration(milliseconds:180),
          padding:const EdgeInsets.all(17),
          decoration:BoxDecoration(
            color:active?const Color(0xFF283E3B):const Color(0xFF1A292C),
            borderRadius:BorderRadius.circular(17),
            border:Border.all(color:active
              ?const Color(0xFFD5BE8A):const Color(0xFF425150)),
          ),
          child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Icon(active?Icons.radio_button_checked:Icons.radio_button_off,
              color:const Color(0xFFD5BE8A),size:23),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text((english?modeTitlesEn:modeTitlesEs)[i],
                  style:Theme.of(context).textTheme.titleSmall),
                const SizedBox(height:6),
                Text((english?modeDetailsEn:modeDetailsEs)[i],
                  style:Theme.of(context).textTheme.bodySmall),
              ])),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(tr('Gym Shield · Tu espacio',
      'Gym Shield · Your space'))),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:990),
      child:ListView(padding:const EdgeInsets.all(20),children:[
        Text(tr('Protege tu rutina','Protect your routine'),
          style:Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height:8),
        Text(tr(
          'Tú decides quién puede coincidir contigo. Tus lugares de '
          'entrenamiento y horarios son privados; no aparecen en otros perfiles.',
          'You choose who can share your training space. Your training '
          'places and schedule stay private and never appear in other profiles.')),
        const SizedBox(height:22),
        Text(tr('01 · Tus límites','01 · Your boundaries'),
          style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:12),
        for(var i=0;i<modes.length;i++)...[
          modeCard(i),const SizedBox(height:9),
        ],
        const SizedBox(height:19),
        Text(tr('02 · Mis lugares y momentos habituales',
          '02 · My usual places and times'),
          style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:9),
        Text(tr(
          'Configura solo ventanas generales. No registramos horarios exactos.',
          'Choose broad time windows only. Exact hours are not recorded.')),
        if(loading)const LinearProgressIndicator(),
        if(places.isEmpty&&!loading)
          Padding(padding:const EdgeInsets.symmetric(vertical:18),
            child:Text(tr('Aún no tienes lugares privados registrados.',
              'No private training places saved yet.'))),
        for(final place in places)...[
          const SizedBox(height:10),
          Card(child:Padding(padding:const EdgeInsets.all(16),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                const Icon(Icons.place_outlined,color:Color(0xFFD5BE8A)),
                const SizedBox(width:10),
                Expanded(child:Text(
                  (place['place_name']??'').toString(),
                  style:Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  key:Key('gym-shield-delete-place-${place['id']}'),
                  onPressed:()=>removePlace(place),
                  tooltip:tr('Eliminar lugar','Remove place'),
                  icon:const Icon(Icons.delete_outline)),
                TextButton.icon(
                  key:Key('gym-shield-add-window-${place['id']}'),
                  onPressed:windows.length>=28?null:()=>addWindow(place),
                  icon:const Icon(Icons.add),
                  label:Text(tr('Franja','Time slot'))),
              ]),
              Wrap(spacing:6,runSpacing:6,children:[
                for(final entry in windows.where(
                  (w)=>w['place_id']==place['id']))
                  InputChip(
                    label:Text('${dayName(entry['day'] as int)} · '
                      '${timeName(entry['window'] as String)}'),
                    onDeleted:()=>setState(()=>windows.remove(entry)),
                  ),
              ]),
            ]),
          )),
        ],
        const SizedBox(height:14),
        OutlinedButton.icon(
          key:const Key('gym-shield-add-place'),
          onPressed:()async{await widget.onAddPlace();await load();},
          icon:const Icon(Icons.add_location_alt_outlined),
          label:Text(tr('Agregar lugar privado','Add private training place'))),
        const SizedBox(height:16),
        Text(tr('La tercera opción expresa tu preferencia; no habilita por '
            'sí sola la búsqueda en el mismo gimnasio y horario. '
            'La verificación independiente y las protecciones siguen vigentes.',
          'The third option records your preference. Same-gym, same-time '
            'discovery is not automatically enabled; independent safety '
            'checks and restrictions still apply.'),
          style:Theme.of(context).textTheme.bodySmall),
        if(message!=null)Padding(
          padding:const EdgeInsets.symmetric(vertical:12),
          child:Text(message!,key:const Key('gym-shield-save-status'))),
        const SizedBox(height:16),
        FilledButton.icon(
          key:const Key('gym-shield-save'),
          onPressed:loading||saving?null:save,
          icon:const Icon(Icons.lock_outline),
          label:Text(saving?tr('Guardando…','Saving…'):
            tr('Guardar mis preferencias privadas','Save my private preferences'))),
        const SizedBox(height:28),
      ]),
    )),
  );
}
