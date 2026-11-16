import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import '../theme/fitness_date_theme.dart';

/// Human review only. The client cannot create an approved media record.
/// Server checks AAL2 and audits each accepted/rejected decision.
class FittedPhotoModerationB17 extends StatefulWidget{
  const FittedPhotoModerationB17({super.key,required this.api});
  final MemberV26Api api;
  @override
  State<FittedPhotoModerationB17> createState()=>_FittedPhotoModerationB17State();
}
class _FittedPhotoModerationB17State
    extends State<FittedPhotoModerationB17>{
  List<Map<String,dynamic>> queue=[];
  String? message;
  bool busy=false,loading=true;
  @override
  void initState(){super.initState();reload();}
  Future<void> reload()async{
    if(!mounted)return;
    setState((){loading=true;message=null;});
    try{
      final list=await widget.api.adminPhotoQueueB17();
      if(mounted)setState(()=>queue=list);
    }catch(_){
      if(mounted)setState(()=>message=
        'No se pudo abrir la cola. Se necesita acceso de administrador con MFA.');
    }finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> inspect(Map<String,dynamic> item)async{
    if(busy)return;
    setState(()=>busy=true);
    try{
      final bytes=await widget.api.adminPhotoPreviewB17(
        item['object_key'].toString());
      if(!mounted)return;
      String decision='rejected',reason='';
      final answer=await showDialog<Map<String,String>>(
        context:context,builder:(dialog)=>StatefulBuilder(
          builder:(dialog,setDialog)=>AlertDialog(
            title:const Text('Moderación de foto de perfil'),
            content:SizedBox(width:520,
              child:SingleChildScrollView(child:Column(
                mainAxisSize:MainAxisSize.min,
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('Titular: '+(item['display_name']??'Miembro').toString()),
                  const SizedBox(height:10),
                  SizedBox(height:285,width:460,
                    child:Image.memory(bytes,fit:BoxFit.contain)),
                  const SizedBox(height:14),
                  const Text('Revisa que no aparezcan terceros sin permiso, '
                    'menores, contenido explícito, identificaciones '
                    'personales, direcciones ni datos de contacto. '
                    'La aprobación no certifica la identidad.'),
                  const SizedBox(height:12),
                  DropdownButtonFormField<String>(
                    initialValue:decision,
                    items:const [
                      DropdownMenuItem(value:'rejected',
                        child:Text('Rechazar imagen')),
                      DropdownMenuItem(value:'approved',
                        child:Text('Aprobar fotografía')),
                    ],
                    onChanged:(v){
                      if(v!=null)setDialog(()=>decision=v);
                    }),
                  const SizedBox(height:12),
                  TextField(
                    key:const Key('b17-photo-review-note'),
                    maxLength:400,maxLines:3,
                    decoration:const InputDecoration(
                      labelText:'Motivo auditado (mínimo 8 caracteres)'),
                    onChanged:(v)=>setDialog(()=>reason=v)),
                ]))),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(dialog),
                child:const Text('Cancelar')),
              FilledButton(
                key:const Key('b17-photo-review-confirm'),
                onPressed:reason.trim().length<8?null:
                  ()=>Navigator.pop(dialog,{
                    'decision':decision,'reason':reason.trim()}),
                child:const Text('Guardar decisión')),
            ],
          )));
      if(answer==null||!mounted)return;
      final result=await widget.api.adminPhotoDecideB17(
        item['id'].toString(),answer['decision']!,answer['reason']!);
      if(!mounted)return;
      await reload();
      if(mounted)setState(()=>message=result=='approved'||result=='rejected'
        ?'Decisión de moderación registrada: '+result
        :'La solicitud no pudo resolverse: '+result);
    }catch(_){
      if(mounted)setState(()=>message='No se pudo abrir o resolver la imagen.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Fitted · moderación de fotografías'),
      actions:[IconButton(onPressed:loading?null:reload,
        icon:const Icon(Icons.refresh))]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:850),
      child:ListView(padding:const EdgeInsets.all(20),children:[
        Card(child:Padding(padding:const EdgeInsets.all(18),
          child:Row(children:[
            const Icon(Icons.shield_outlined,
              color:FitDateColors.aqua,size:30),
            const SizedBox(width:14),
            const Expanded(child:Text(
              'Las fotografías se almacenan en privado. Solo imágenes '
              'aprobadas podrán compartirse con adultos elegibles, '
              'y solo cuando el titular autorice la visibilidad.')),
          ]))),
        const SizedBox(height:15),
        if(loading)const LinearProgressIndicator(),
        if(message!=null)
          Text(message!,key:const Key('b17-photo-admin-message')),
        if(!loading&&queue.isEmpty)
          const ListTile(title:Text('No hay fotos pendientes.')),
        for(final item in queue)
          Card(child:ListTile(
            key:Key('b17-moderate-'+item['id'].toString()),
            leading:const Icon(Icons.photo_camera_back_outlined),
            title:Text((item['display_name']??'Miembro').toString()),
            subtitle:Text('Subida: '+(item['created_at']??'').toString()),
            trailing:FilledButton(
              onPressed:busy?null:()=>inspect(item),
              child:const Text('Revisar')),
          )),
      ]))),
  );
}
