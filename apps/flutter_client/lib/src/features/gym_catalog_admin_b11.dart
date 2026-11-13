import 'package:flutter/material.dart';

import '../core/brand_admin_repository.dart';

/// Catalog operations are allowed only for the independently authenticated
/// AAL2 brand owner. The database logs each new gym registration.
class GymCatalogueAdminB11 extends StatefulWidget {
  const GymCatalogueAdminB11({super.key,required this.repository});
  final BrandAdminRepository repository;
  @override
  State<GymCatalogueAdminB11> createState()=>_GymCatalogueAdminB11State();
}

class _GymCatalogueAdminB11State extends State<GymCatalogueAdminB11>{
  final name=TextEditingController();
  final city=TextEditingController();
  List<Map<String,dynamic>> gyms=[];
  String? error;
  String? note;
  bool busy=false;
  bool loading=true;

  @override
  void initState(){super.initState();reload();}

  @override
  void dispose(){name.dispose();city.dispose();super.dispose();}

  Future<void> reload() async {
    if(!mounted)return;
    setState(()=>loading=true);
    try{
      final rows=await widget.repository.loadCuratedGymsB11();
      if(mounted)setState(()=>gyms=rows);
    }catch(_){
      if(mounted)setState(()=>error=
        'No se pudo cargar el catálogo administrado.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> register() async {
    if(busy)return;
    final gym=name.text.trim(),place=city.text.trim();
    if(gym.length<3||gym.length>120||place.length<2||place.length>100){
      setState(()=>error='Revisa el nombre oficial y la ciudad.');
      return;
    }
    final approved=await showDialog<bool>(
      context:context,builder:(ctx)=>AlertDialog(
        title:const Text('Confirmar gimnasio real'),
        content:Text('¿Confirmas que "$gym" existe en "$place" '
          'y debe ofrecerse en el catálogo protegido? '
          'No registres gimnasios de prueba.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Registrar')),
        ],
      ));
    if(approved!=true||!mounted)return;
    setState((){
      busy=true;error=null;note=null;
    });
    try{
      await widget.repository.registerGymB11(gym,place);
      if(!mounted)return;
      name.clear();city.clear();
      setState(()=>note='Gimnasio registrado con auditoría.');
      await reload();
    }catch(_){
      if(mounted)setState(()=>error='No se pudo registrar. '
        'Confirma tu sesión administrativa y MFA.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Catálogo de gimnasios')),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:720),
      child:ListView(padding:const EdgeInsets.all(18),children:[
        Text('Gym Shield · catálogos',
          style:Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:8),
        const Text('Solo el administrador con MFA puede registrar gimnasios. '
          'Los registros quedan auditados y no indican quién entrena en ellos. '
          'Verifica que cada nombre corresponde a un lugar real.'),
        const SizedBox(height:16),
        TextField(
          key:const Key('b11-admin-gym-name'),
          controller:name,maxLength:120,
          decoration:const InputDecoration(labelText:'Nombre del gimnasio'),
        ),
        TextField(
          key:const Key('b11-admin-gym-city'),
          controller:city,maxLength:100,
          decoration:const InputDecoration(labelText:'Ciudad'),
        ),
        FilledButton.icon(
          key:const Key('b11-admin-register-gym'),
          onPressed:busy?null:register,
          icon:const Icon(Icons.add_location_alt_outlined),
          label:Text(busy?'Registrando…':'Registrar gimnasio real'),
        ),
        if(error!=null)Text(error!,
          key:const Key('b11-admin-gym-error'),
          style:const TextStyle(color:Colors.redAccent)),
        if(note!=null)Text(note!,
          key:const Key('b11-admin-gym-success')),
        const SizedBox(height:20),
        Text('Gimnasios administrados',
          style:Theme.of(context).textTheme.titleMedium),
        if(loading)const LinearProgressIndicator(),
        if(!loading&&gyms.isEmpty)
          const Text('Todavía no hay gimnasios reales registrados.'),
        for(final gym in gyms)
          ListTile(
            leading:const Icon(Icons.fitness_center_outlined),
            title:Text((gym['name']??'').toString()),
            subtitle:Text((gym['city']??'').toString()),
          ),
      ]),
    )),
  );
}
