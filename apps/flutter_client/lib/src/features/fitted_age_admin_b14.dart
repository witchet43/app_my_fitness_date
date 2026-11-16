import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import '../widgets/fitted_glass_atmosphere.dart';

/// Human-operated age verification & launch station in the SAME admin app.
/// Only a server-verified brand admin with AAL2 MFA may inspect ID evidence.
class FittedAgeAdminB14 extends StatefulWidget{
  const FittedAgeAdminB14({super.key,required this.api});
  final MemberV26Api api;
  @override
  State<FittedAgeAdminB14> createState()=>_FittedAgeAdminB14State();
}
class _FittedAgeAdminB14State extends State<FittedAgeAdminB14>{
  bool loading=true,busy=false,operatorAck=false,privacyAck=false,incidentAck=false;
  List<Map<String,dynamic>> queue=[];
  Map<String,dynamic> program={};
  String? message;
  final responsibility=TextEditingController();
  @override
  void initState(){super.initState();reload();}
  @override
  void dispose(){responsibility.dispose();super.dispose();}
  Future<void> reload()async{
    if(!mounted)return;
    setState((){loading=true;message=null;});
    try{
      final results=await Future.wait<dynamic>([
        widget.api.adminAgeQueueB14(),
        widget.api.manualDatingStatusB14(),
      ]);
      if(mounted)setState((){
        queue=(results[0] as List).cast<Map<String,dynamic>>();
        program=results[1] as Map<String,dynamic>;
      });
    }catch(_){if(mounted)setState(()=>
      message='No se pudieron consultar expedientes. Comprueba MFA administrativa.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> review(Map<String,dynamic> item)async{
    if(busy)return;
    setState((){busy=true;message=null;});
    Uint8List doc,face;
    try{
      final bytes=await Future.wait<Uint8List>([
        widget.api.adminAgeEvidenceB14(item['document_path'].toString()),
        widget.api.adminAgeEvidenceB14(item['selfie_path'].toString()),
      ]);
      doc=bytes[0];face=bytes[1];
      if(doc.isEmpty||face.isEmpty)throw Exception('missing evidence');
    }catch(_){if(mounted)setState((){
      busy=false;message='No se pudieron abrir ambas imágenes. No se tomó ninguna decisión.';
    });return;}
    if(!mounted)return;
    String decision='rejected',date='',expiry='',note='';
    bool valid=false,similar=false;
    String? issue;
    final selected=await showDialog<Map<String,dynamic>>(context:context,
      builder:(dialog)=>StatefulBuilder(builder:(dialog,update)=>AlertDialog(
        title:const Text('Revisión de identidad y mayoría de edad'),
        content:SizedBox(width:600,child:SingleChildScrollView(child:
          Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              const Text('Verifica personalmente la autenticidad visible, '
                'la fecha de nacimiento y que la persona se parezca a '
                'la fotografía de su identificación. No copies el número '
                'del documento. Si existen dudas, rechaza la solicitud.'),
              const SizedBox(height:12),
              Text('Fecha registrada en el perfil: ${item['declared_birthdate']??'no disponible'}'),
              const SizedBox(height:12),
              Text('IDENTIFICACIÓN',style:Theme.of(dialog).textTheme.labelLarge),
              Image.memory(doc,height:230,fit:BoxFit.contain),
              const SizedBox(height:12),
              Text('FOTOGRAFÍA DE COMPARACIÓN',
                style:Theme.of(dialog).textTheme.labelLarge),
              Image.memory(face,height:230,fit:BoxFit.contain),
              const SizedBox(height:8),
              DropdownButtonFormField<String>(
                key:const Key('age-admin-decision'),initialValue:decision,
                items:const [
                  DropdownMenuItem(value:'rejected',child:Text('Rechazar')),
                  DropdownMenuItem(value:'approved',child:Text('Aprobar tras comprobación')),
                ],
                onChanged:(v){if(v!=null)update(()=>decision=v);}),
              TextField(
                key:const Key('age-admin-document-birthdate'),
                decoration:const InputDecoration(
                  labelText:'Fecha en identificación (AAAA-MM-DD)'),
                onChanged:(v)=>date=v,
              ),
              TextField(
                key:const Key('age-admin-document-expiry'),
                decoration:const InputDecoration(
                  labelText:'Vencimiento (AAAA-MM-DD, opcional)'),
                onChanged:(v)=>expiry=v,
              ),
              CheckboxListTile(
                key:const Key('age-admin-document-valid'),
                value:valid,
                onChanged:(v)=>update(()=>valid=v??false),
                title:const Text('He revisado el documento y parece legítimo y vigente')),
              CheckboxListTile(
                key:const Key('age-admin-photo-match'),
                value:similar,onChanged:(v)=>update(()=>similar=v??false),
                title:const Text('He comparado las fotografías y corresponden a '
                  'la misma persona con confianza suficiente')),
              TextField(
                key:const Key('age-admin-note'),maxLength:500,maxLines:3,
                decoration:const InputDecoration(
                  labelText:'Justificación auditada (mínimo 10 caracteres)'),
                onChanged:(v)=>note=v,
              ),
              if(issue!=null)Text(issue!,style:const TextStyle(color:Colors.redAccent)),
            ]))),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog),
            child:const Text('Cancelar')),
          FilledButton(
            key:const Key('age-admin-confirm'),
            onPressed:(){
              final parsed=DateTime.tryParse(date.trim());
              final exp=expiry.trim().isEmpty?null:DateTime.tryParse(expiry.trim());
              if(note.trim().length<10 || 
                (decision=='approved' && (!valid||!similar||parsed==null||
                 (expiry.trim().isNotEmpty&&exp==null)))){
                update(()=>issue='Para aprobar debes comprobar todos los criterios '
                  'y registrar ambas fechas correctamente. Para rechazar, explica el motivo.');
                return;
              }
              Navigator.pop(dialog,{
                'decision':decision,'document_valid':valid,
                'photo_match':similar,'date':parsed,'expiry':exp,'note':note.trim(),
              });
            },
            child:const Text('Guardar resolución')),
        ],
      )));
    // Drop sensitive images from this screen after the review dialog closes.
    doc=Uint8List(0);face=Uint8List(0);
    if(selected==null||!mounted){setState(()=>busy=false);return;}
    try{
      final state=await widget.api.adminAgeDecideB14(
        requestId:item['request_id'].toString(),
        decision:selected['decision'].toString(),
        documentedBirthdate:selected['date'] as DateTime?,
        documentExpiry:selected['expiry'] as DateTime?,
        documentValid:selected['document_valid']==true,
        photoMatch:selected['photo_match']==true,
        reason:selected['note'].toString(),
      );
      if(!const ['approved','rejected'].contains(state)){
        throw MemberApiException('El servidor rechazó la decisión ($state).');
      }
      String cleanup='No se confirmó la eliminación de los archivos.';
      try{
        final erased=await widget.api.adminAgePurgeB14(
          requestId:item['request_id'].toString(),
          documentPath:item['document_path'].toString(),
          selfiePath:item['selfie_path'].toString());
        if(erased=='erased')cleanup='Las imágenes se eliminaron tras la revisión.';
      }catch(_){/* Keep the erasure failure visible and auditable. */}
      await reload();
      if(mounted)setState(()=>message=
        'Decisión registrada: $state. $cleanup');
    }catch(e){if(mounted)setState(()=>message=e is MemberApiException
      ?e.message:'No se pudo registrar la resolución. Verifica tu sesión.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> setLaunch(bool enabled)async{
    if(busy)return;
    if(enabled && (!operatorAck||!privacyAck||!incidentAck||
      responsibility.text.trim().length<20)){
      setState(()=>message='Confirma la operación humana, el tratamiento '
        'documental y la atención de incidentes; indica al responsable.');
      return;
    }
    setState((){busy=true;message=null;});
    try{
      final result=await widget.api.adminDatingLaunchB14(
        enabled:enabled,operatorAck:operatorAck,privacyAck:privacyAck,
        incidentAck:incidentAck,responsibility:responsibility.text.trim());
      if(result!='enabled' && result!='disabled'){
        throw MemberApiException('No se aprobó la activación ($result).');
      }
      await reload();
      if(mounted)setState(()=>message=result=='enabled'
        ?'Operación habilitada. Solo cuentas verificadas, con consentimiento '
          'y perfil completo podrán aparecer en el matching.'
        :'Operación suspendida en el servidor.');
    }catch(e){if(mounted)setState(()=>message=e is MemberApiException
      ?e.message:'No se completó la operación administrativa.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context){
    final live=program['enabled']==true;
    return Scaffold(
      appBar:AppBar(title:const Text('Seguridad · verificar adultos'),
        actions:[IconButton(onPressed:loading?null:reload,
          icon:const Icon(Icons.refresh))]),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:920),
        child:ListView(padding:const EdgeInsets.all(18),children:[
          const FittedGlassPanel(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('PROTECCIÓN REAL · NO SIMULADA',
                style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1)),
              SizedBox(height:8),
              Text('Revisa las identificaciones en esta consola MFA. '
                'Las imágenes jamás se muestran a otros miembros. '
                'Después de cada decisión eliminamos la evidencia primaria '
                'cuando el almacenamiento lo confirma.'),
            ])),
          const SizedBox(height:18),
          if(loading)const LinearProgressIndicator(),
          if(message!=null)Padding(padding:const EdgeInsets.all(12),
            child:Text(message!,key:const Key('age-admin-feedback-b14'))),
          Text('Solicitudes de edad pendientes (${queue.length})',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          if(!loading&&queue.isEmpty)
            const ListTile(title:Text('No hay solicitudes de edad pendientes.')),
          for(final item in queue)
            Card(child:ListTile(
              key:Key('age-admin-case-${item['request_id']}'),
              leading:const Icon(Icons.verified_user_outlined),
              title:Text((item['display_name']??'Miembro').toString()),
              subtitle:Text('Recibido: ${item['submitted_at']??''}'),
              trailing:OutlinedButton(
                onPressed:busy?null:()=>review(item),
                child:const Text('Examinar evidencia')),
            )),
          const Divider(height:40),
          Text('Apertura controlada de FitDating',
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          ListTile(
            leading:Icon(live?Icons.check_circle:Icons.lock_outline),
            title:Text(live?'Operación de citas habilitada':
              'Operación de citas cerrada'),
            subtitle:const Text('La aprobación del operador no verifica a '
              'ninguna persona. Cada miembro necesita su revisión documental '
              'independiente, consentimiento y perfil elegible.'),
          ),
          if(!live)...[
            CheckboxListTile(value:operatorAck,
              key:const Key('age-operator-attestation-b14'),
              onChanged:busy?null:(v)=>setState(()=>operatorAck=v??false),
              title:const Text('Asumo la revisión humana periódica de identidades '
                'y de las colas de moderación y apelaciones.')),
            CheckboxListTile(value:privacyAck,
              key:const Key('age-privacy-attestation-b14'),
              onChanged:busy?null:(v)=>setState(()=>privacyAck=v??false),
              title:const Text('Revisé los textos de privacidad y atenderé '
                'consentimiento, acceso, cancelación, evidencias y bajas.')),
            CheckboxListTile(value:incidentAck,
              key:const Key('age-incident-attestation-b14'),
              onChanged:busy?null:(v)=>setState(()=>incidentAck=v??false),
              title:const Text('Me comprometo a atender reportes e incidentes '
                'con los protocolos y canales operativos existentes.')),
            TextField(controller:responsibility,maxLength:500,minLines:2,maxLines:3,
              decoration:const InputDecoration(
                labelText:'Responsable operativo y cobertura de atención')),
          ],
          const SizedBox(height:10),
          FilledButton.icon(
            key:const Key('age-admin-activate-b14'),
            onPressed:busy||loading?null:()=>setLaunch(!live),
            icon:Icon(live?Icons.pause_circle_outline:Icons.security),
            label:Text(live?'Suspender descubrimiento y matching':
              'Activar matching solo para adultos verificados')),
          const SizedBox(height:12),
          const Text('La activación queda auditada con identidad y MFA '
            'del administrador. No constituye certificación legal o '
            'verificación externa de un proveedor. Si no habrá atención '
            'humana disponible, mantén la operación suspendida.'),
        ]))),
    );
  }
}
