import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/member_v26_api.dart';
import '../widgets/fitted_glass_atmosphere.dart';

/// Verified-adult review: a document and selfie are inspected by a human
/// administrator with MFA. Neither a declared DOB nor an upload approves age.
class FittedAgeVerificationB14 extends StatefulWidget {
  const FittedAgeVerificationB14({super.key,required this.api});
  final MemberV26Api api;
  @override
  State<FittedAgeVerificationB14> createState()=>_FittedAgeVerificationB14State();
}
class _FittedAgeVerificationB14State extends State<FittedAgeVerificationB14>{
  Map<String,dynamic> status={};
  Uint8List? document,selfie;
  String? documentMime,selfieMime,message;
  bool loading=true,busy=false,consented=false;
  @override
  void initState(){super.initState();refresh();}
  Future<void> refresh()async{
    if(!mounted)return;
    setState((){loading=true;message=null;});
    try{
      final result=await widget.api.ageReviewStatusB14();
      if(mounted)setState(()=>status=result);
    }catch(_){if(mounted)setState(()=>
      message='No fue posible consultar tu verificación. Revisa la conexión.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> choose(bool isSelfie)async{
    try{
      final result=await FilePicker.platform.pickFiles(
        type:FileType.image,allowMultiple:false,withData:true);
      if(result==null||result.files.isEmpty)return;
      final file=result.files.single;
      final bytes=file.bytes;
      final name=file.name.toLowerCase();
      final mime=name.endsWith('.png')?'image/png':
        (name.endsWith('.jpg')||name.endsWith('.jpeg'))?'image/jpeg':null;
      if(bytes==null||bytes.isEmpty||bytes.length>5242880||mime==null){
        if(mounted)setState(()=>
          message='Usa una imagen JPG o PNG de hasta 5 MB.');
        return;
      }
      if(!mounted)return;
      setState((){
        if(isSelfie){selfie=bytes;selfieMime=mime;}
        else{document=bytes;documentMime=mime;}
        message=null;
      });
    }catch(_){if(mounted)setState(()=>
      message='No pudimos abrir el archivo de imagen.');}
  }
  Future<void> submit()async{
    if(busy||!consented||document==null||selfie==null||
      documentMime==null||selfieMime==null)return;
    setState((){busy=true;message=null;});
    try{
      final started=await widget.api.ageBeginB14();
      final id=started['request_id']?.toString();
      if(started['status']!='draft'||id==null){
        throw MemberApiException(started['status']=='pending'
          ?'Ya existe una solicitud pendiente de revisión.'
          :started['status']=='approved'
            ?'Tu edad ya fue verificada.'
            :'No es posible abrir la solicitud. Revisa tu perfil y los límites.');
      }
      await widget.api.ageUploadB14(requestId:id,slot:'document',
        bytes:document!,contentType:documentMime!);
      await widget.api.ageUploadB14(requestId:id,slot:'selfie',
        bytes:selfie!,contentType:selfieMime!);
      final result=await widget.api.ageSubmitB14(id);
      if(result!='pending')throw MemberApiException(
        result=='documents_required'
        ?'Faltan archivos válidos en el almacenamiento privado.'
        :'No se pudo enviar la solicitud ($result).');
      document=null;selfie=null;
      if(mounted)setState(()=>
        message='Documentos enviados a revisión humana. Tu edad aún no está verificada.');
      await refresh();
    }catch(e){if(mounted)setState(()=>
      message=e is MemberApiException?e.message:
       'No se pudo completar el envío seguro. No se concedió la verificación.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> withdraw()async{
    if(busy)return;
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Retirar verificación de edad'),
      content:const Text('Se revocará el acceso a citas. También intentaremos '
        'eliminar las imágenes aportadas. Puedes solicitar el ejercicio de '
        'tus derechos sobre los datos personales.'),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Volver')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),
          child:const Text('Revocar y eliminar')),
      ],
    ));
    if(ok!=true||!mounted)return;
    setState(()=>busy=true);
    final id=status['request_id']?.toString();
    try{
      final result=await widget.api.ageCancelB14();
      if(result!='withdrawn')throw const MemberApiException('No se pudo revocar.');
      if(id!=null)await widget.api.agePurgeOwnB14(id);
      await refresh();
      if(mounted)setState(()=>
        message='Verificación revocada. Los documentos pendientes se eliminaron '
          'cuando estaban disponibles para tu cuenta.');
    }catch(_){if(mounted)setState(()=>
      message='Acceso revocado, pero la eliminación documental puede requerir '
        'atención del administrador. Solicita seguimiento mediante privacidad.');
    }finally{if(mounted)setState(()=>busy=false);}
  }
  Widget imageSlot(bool isSelfie){
    final bytes=isSelfie?selfie:document;
    return Card(child:Padding(padding:const EdgeInsets.all(12),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(isSelfie?'Foto actual con rostro visible':
          'Identificación oficial con fecha de nacimiento',
          style:Theme.of(context).textTheme.titleMedium),
        const SizedBox(height:8),
        if(bytes!=null)Image.memory(bytes,height:124,fit:BoxFit.contain,
          gaplessPlayback:false)
        else const SizedBox(height:90,child:Center(
          child:Icon(Icons.privacy_tip_outlined,size:36))),
        OutlinedButton.icon(
          key:Key(isSelfie?'age-select-selfie':'age-select-document'),
          onPressed:busy?null:()=>choose(isSelfie),
          icon:const Icon(Icons.add_photo_alternate_outlined),
          label:Text(bytes==null?'Seleccionar imagen':'Cambiar imagen')),
      ])));
  }
  @override
  Widget build(BuildContext context){
    final state=(status['status']??'not_started').toString();
    return Scaffold(
      appBar:AppBar(title:const Text('Verificación de mayoría de edad'),
        actions:[IconButton(onPressed:loading?null:refresh,
          icon:const Icon(Icons.refresh),tooltip:'Actualizar')]),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:760),
        child:ListView(padding:const EdgeInsets.all(18),children:[
          const FittedGlassPanel(child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('MAYORES DE 18 · IDENTIDAD PROTEGIDA',
                style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1)),
              SizedBox(height:10),
              Text('Para conocer personas reales revisamos una identificación '
                'oficial y una fotografía actual. Las imágenes son privadas '
                'y las revisa un administrador autorizado con MFA. '
                'Subirlas no garantiza aprobación ni acceso inmediato.'),
            ])),
          const SizedBox(height:14),
          if(loading)const LinearProgressIndicator(),
          Card(child:ListTile(
            key:const Key('age-status-b14'),
            leading:Icon(state=='approved'?Icons.verified_user_outlined:
              state=='pending'?Icons.hourglass_top:Icons.lock_person_outlined),
            title:Text(state=='approved'?'Mayoría de edad verificada':
              state=='pending'?'Revisión humana pendiente':
              state=='rejected'?'Solicitud no aprobada':
              'Solicita la verificación de edad'),
            subtitle:Text('Estado de la solicitud: $state'),
          )),
          if(message!=null)Padding(padding:const EdgeInsets.all(10),
            child:Text(message!,key:const Key('age-feedback-b14'))),
          if(!loading&&state!='approved'&&state!='pending')...[
            const SizedBox(height:10),
            const Text('Documento aceptado: identificación oficial vigente '
              'que muestre fotografía y fecha de nacimiento. Aporta una foto '
              'actual donde el rostro pueda compararse visualmente con '
              'la identificación. No envíes números de documento por texto.'),
            const SizedBox(height:10),
            LayoutBuilder(builder:(context,space){
              if(space.maxWidth<550)return Column(children:[
                imageSlot(false),imageSlot(true)]);
              return Row(children:[
                Expanded(child:imageSlot(false)),
                Expanded(child:imageSlot(true)),
              ]);
            }),
            CheckboxListTile(
              key:const Key('age-privacy-consent-b14'),
              value:consented,onChanged:busy?null:(v)=>
                setState(()=>consented=v??false),
              title:const Text('Autorizo la revisión manual de mis imágenes '
                'solo para comprobar mayoría de edad, prevenir suplantación '
                'y atender mis derechos de privacidad.'),
              subtitle:const Text('Consentimiento específico e independiente '
                'de las citas y de Pulso Real. La documentación no se publica.'),
            ),
            const SizedBox(height:8),
            FilledButton.icon(
              key:const Key('age-submit-b14'),
              onPressed:busy||!consented||document==null||selfie==null
                ?null:submit,
              icon:const Icon(Icons.verified_outlined),
              label:Text(busy?'Enviando de forma segura':
                'Enviar a revisión privada')),
          ],
          if(!loading&&(state=='pending'||state=='approved'))
            OutlinedButton.icon(
              key:const Key('age-withdraw-b14'),
              onPressed:busy?null:withdraw,
              icon:const Icon(Icons.delete_outline),
              label:const Text('Revocar verificación y solicitar eliminación')),
          const SizedBox(height:14),
          const Text('Puedes solicitar acceso, rectificación, cancelación '
            'u oposición desde el Aviso de privacidad de Fitted. '
            'Los controles de matching se validan siempre en el servidor.'),
        ]))),
    );
  }
}
