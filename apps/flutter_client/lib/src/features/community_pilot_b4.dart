import 'package:flutter/material.dart';

import '../core/community_repository.dart';
import '../core/member_v26_api.dart';

/// Explicit AAL2 owner-only pilot invitation. Never grants member roles,
/// never enables Dating, and never uses client-supplied authorization flags.
class CommunityPilotB4 extends StatefulWidget {
  const CommunityPilotB4({super.key,required this.api});
  final CommunityRepository api;
  @override
  State<CommunityPilotB4> createState()=>_CommunityPilotB4State();
}

class _CommunityPilotB4State extends State<CommunityPilotB4> {
  List<Map<String,dynamic>> members=[];
  bool loading=true;
  bool busy=false;
  String? error;

  @override
  void initState(){super.initState();reload();}

  Future<void> reload() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try {
      final result=await widget.api.pilotMembers();
      if(mounted)setState(()=>members=result);
    } on MemberApiException catch(e) {
      if(mounted)setState(()=>error=e.message);
    } catch (_) {
      if(mounted)setState(()=>
        error='No se pudo cargar el acceso de piloto.');
    } finally {
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> invite() async {
    if(busy)return;
    final email=TextEditingController();
    String? validation;
    final selected=await showDialog<String>(
      context:context,builder:(dialog)=>StatefulBuilder(
        builder:(dialog,update)=>AlertDialog(
          title:const Text('Autorizar cuenta de prueba'),
          content:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:460),
            child:Column(mainAxisSize:MainAxisSize.min,children:[
              const Text('La cuenta ya debe existir en My Fitness Date '
                'y tener su correo confirmado. Este permiso habilita '
                'solamente la comunidad de prueba, no FitDating.'),
              const SizedBox(height:12),
              TextField(
                key:const Key('b4-pilot-email'),
                controller:email,
                keyboardType:TextInputType.emailAddress,
                decoration:const InputDecoration(
                  labelText:'Correo de la cuenta registrada')),
              if(validation!=null)Text(validation!,
                style:const TextStyle(color:Colors.redAccent)),
            ]),
          ),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog),
              child:const Text('Cancelar')),
            FilledButton(
              key:const Key('b4-pilot-submit'),
              onPressed:(){
                final value=email.text.trim();
                if(value.length<5||value.length>254||
                    !RegExp(
                      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
                      .hasMatch(value)){
                  update(()=>validation='Escribe un correo válido.');
                  return;
                }
                Navigator.pop(dialog,value);
              },
              child:const Text('Autorizar acceso')),
          ],
        ),
      ),
    );
    email.dispose();
    if(selected==null||!mounted)return;
    setState(()=>busy=true);
    try{
      final outcome=await widget.api.admitPilotMember(selected);
      if(outcome=='admitted'){
        await reload();
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text('Cuenta autorizada para el piloto.')));
      }
    }on MemberApiException catch(e){
      if(mounted)setState(()=>error=e.message);
    }catch(_){
      if(mounted)setState(()=>
        error='No se pudo autorizar. Confirma el correo y tu MFA.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  Future<void> revoke(Map<String,dynamic> member) async {
    if(busy)return;
    final id=(member['user_id']??'').toString();
    final email=(member['email']??'esta cuenta').toString();
    final accept=await showDialog<bool>(
      context:context,builder:(dialog)=>AlertDialog(
        title:const Text('Revocar acceso de piloto'),
        content:Text('Se impedirá el acceso a la comunidad de $email '
          'y sus publicaciones dejarán de mostrarse. '
          'Su cuenta deportiva y reservas no se eliminarán.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),
            child:const Text('Conservar acceso')),
          FilledButton(
            key:const Key('b4-pilot-revoke-confirm'),
            onPressed:()=>Navigator.pop(dialog,true),
            child:const Text('Revocar acceso')),
        ],
      ),
    );
    if(accept!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      final outcome=await widget.api.revokePilotMember(id);
      if(outcome=='revoked')await reload();
    }catch(_){
      if(mounted)setState(()=>error='No se pudo revocar el permiso.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Acceso a piloto cerrado'),
      actions:[IconButton(
        tooltip:'Actualizar',
        onPressed:loading?null:reload,
        icon:const Icon(Icons.refresh),
      )]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:780),
      child:ListView(padding:const EdgeInsets.all(20),children:[
        Text('Autorizar participantes',
          style:Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height:9),
        const Text('La comunidad permanece CERRADA para cuentas no '
          'autorizadas. Puedes habilitar o revocar miembros existentes '
          'sin compilar ni desplegar nuevamente. Se registra una '
          'auditoría por cada decisión.'),
        const SizedBox(height:18),
        FilledButton.icon(
          key:const Key('b4-pilot-invite'),
          onPressed:busy?null:invite,
          icon:const Icon(Icons.person_add_alt_1_outlined),
          label:const Text('Autorizar cuenta registrada')),
        const SizedBox(height:15),
        if(loading)const Center(child:CircularProgressIndicator()),
        if(error!=null)...[
          Text(error!,key:const Key('b4-pilot-error'),
            style:const TextStyle(color:Colors.redAccent)),
          TextButton(onPressed:reload,child:const Text('Reintentar')),
        ],
        if(!loading&&error==null&&members.isEmpty)
          const Padding(
            padding:EdgeInsets.symmetric(vertical:20),
            child:Text('Ninguna cuenta está autorizada todavía. '
              'La comunidad seguirá cerrada.',
              key:Key('b4-pilot-empty'))),
        for(final item in members)
          Card(child:ListTile(
            key:Key('b4-pilot-member-${item['user_id']}'),
            title:Text((item['display_name']??item['email']??'Cuenta').toString()),
            subtitle:Text('${item['email']??''} · '
              '${item['active']==true?'Autorizado':'Revocado'}'),
            trailing:item['active']==true
              ?TextButton(
                key:Key('b4-pilot-revoke-${item['user_id']}'),
                onPressed:busy?null:()=>revoke(item),
                child:const Text('Revocar'))
              :const Icon(Icons.lock_outline),
          )),
        const SizedBox(height:18),
        const Text('El acceso al piloto no constituye autorización para '
          'beta pública. Siguen pendientes edad verificada, personal de '
          'moderación, incidentes y privacidad integral.'),
      ]),
    )),
  );
}
