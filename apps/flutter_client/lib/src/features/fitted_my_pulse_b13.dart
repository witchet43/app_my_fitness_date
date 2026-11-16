import 'package:flutter/material.dart';
import '../core/dating_repository_b11.dart';
import '../core/fitted_locale.dart';

/// Data subject sees their own REVIEWED subjective observations and can appeal.
/// No reporter identity, no public score and no cross-member leakage.
class FittedMyPulseRealB13 extends StatefulWidget{
  const FittedMyPulseRealB13({super.key,required this.api});
  final DatingRepositoryB11 api;
  @override
  State<FittedMyPulseRealB13> createState()=>_FittedMyPulseRealB13State();
}
class _FittedMyPulseRealB13State extends State<FittedMyPulseRealB13>{
  bool loading=true,busy=false;
  String? error;
  List<Map<String,dynamic>> records=[];
  @override
  void initState(){super.initState();refresh();}
  Future<void> refresh()async{
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final data=await widget.api.myPulseObservationsB13();
      if(mounted)setState(()=>records=data);
    }catch(_){if(mounted)setState(()=>
      error='No se pudieron consultar tus observaciones privadas.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> appeal(String id)async{
    if(busy)return;
    String note='';
    final reason=await showDialog<String>(context:context,
      builder:(dialog)=>AlertDialog(
        title:const Text('Solicitar revisión'),
        content:Column(mainAxisSize:MainAxisSize.min,children:[
          const Text('Estas observaciones son subjetivas. '
            'Explica qué no coincide con tu experiencia. Tu apelación '
            'se conserva de forma privada para la moderación humana.'),
          const SizedBox(height:12),
          TextField(key:const Key('pulse-appeal-note'),
            maxLength:500,maxLines:4,onChanged:(v)=>note=v,
            decoration:const InputDecoration(labelText:'Tu versión de los hechos')),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog),
            child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(dialog,note.trim()),
            child:const Text('Apelar')),
        ]));
    if(reason==null||!mounted)return;
    if(reason.length<10){setState(()=>
      error='Escribe al menos 10 caracteres para solicitar la revisión.');return;}
    setState(()=>busy=true);
    try{
      final result=await widget.api.appealPulseObservationB13(id,reason);
      if(mounted&&result=='appeal_requested'){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('Apelación privada enviada.')));
        await refresh();
      }
    }catch(_){if(mounted)setState(()=>error='No se pudo registrar la apelación.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const FittedText('Pulso Real · mis derechos'),
      actions:[IconButton(onPressed:loading?null:refresh,
        icon:const Icon(Icons.refresh))]),
    body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:800),
      child:ListView(padding:const EdgeInsets.all(18),children:[
        const Text('Solo tú puedes consultar las observaciones revisadas '
          'sobre tu estilo de vida. No son pruebas de mentira ni '
          'calificaciones públicas. Puedes solicitar una nueva revisión.'),
        const SizedBox(height:16),
        if(loading)const LinearProgressIndicator(),
        if(error!=null)Text(error!,key:const Key('pulse-rights-error')),
        if(!loading&&records.isEmpty&&error==null)
          const Text('No existen observaciones revisadas sobre tu perfil.',
            key:Key('pulse-rights-empty')),
        for(final item in records)
          Card(child:ListTile(
            title:Text('How I ${item['dimension']}'),
            subtitle:Text('${item['observation']} · ${item['review_state']}'),
            trailing:item['review_state']=='approved'
              ?TextButton(
                onPressed:busy?null:()=>appeal((item['id']??'').toString()),
                child:const Text('Apelar')):null,
          )),
      ]))),
  );
}
