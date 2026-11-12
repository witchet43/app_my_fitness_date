import 'package:flutter/material.dart';

import '../core/community_repository.dart';
import '../core/member_v26_api.dart';
import 'community_b4.dart';

/// This page is mounted only from the verified AAL2 owner space.
/// Each action rechecks owner MFA inside its own database RPC.
class CommunityModerationB4 extends StatefulWidget {
  const CommunityModerationB4({super.key,required this.api});
  final CommunityRepository api;
  @override
  State<CommunityModerationB4> createState()=>_CommunityModerationB4State();
}

class _CommunityModerationB4State extends State<CommunityModerationB4> {
  List<Map<String,dynamic>> reports=[];
  List<Map<String,dynamic>> deletions=[];
  List<Map<String,dynamic>> announcements=[];
  bool loading=true;
  bool sending=false;
  bool showDeletion=false;
  bool showAnnouncements=false;
  String? error;

  @override
  void initState(){
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final list=await widget.api.moderationReports();
      final pending=await widget.api.moderationDeletionRequests();
      final ownAnnouncements=await widget.api.adminCommunityAnnouncements();
      if(mounted)setState((){
        reports=list;
        deletions=pending;
        announcements=ownAnnouncements;
      });
    } on MemberApiException catch(e){
      if(mounted)setState(()=>error=e.message);
    }catch(_){
      if(mounted)setState(()=>
        error='La cola de moderación no está disponible. Reintenta.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> resolve(Map<String,dynamic> report) async {
    if(sending)return;
    final hasPost=report['post_id']!=null;
    var selectedAction='dismiss';
    final note=TextEditingController();
    String? validation;
    final result=await showDialog<Map<String,String>>(
      context:context,
      builder:(dialog)=>StatefulBuilder(
        builder:(dialog,update)=>AlertDialog(
          title:const Text('Resolver reporte'),
          content:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:480),
            child:SingleChildScrollView(child:Column(
              mainAxisSize:MainAxisSize.min,children:[
                const Text('Las decisiones son definitivas en el historial '
                  'de auditoría. No se comunica la identidad del denunciante.'),
                const SizedBox(height:12),
                DropdownButtonFormField<String>(
                  key:const Key('b4-moderation-action'),
                  initialValue:selectedAction,
                  decoration:const InputDecoration(
                    labelText:'Decisión'),
                  items:[
                    const DropdownMenuItem(value:'dismiss',
                      child:Text('Desestimar reporte')),
                    if(hasPost)const DropdownMenuItem(value:'hide_post',
                      child:Text('Ocultar publicación')),
                    const DropdownMenuItem(value:'suspend_user',
                      child:Text('Suspender en comunidad')),
                  ],
                  onChanged:(v){
                    if(v!=null)update(()=>selectedAction=v);
                  },
                ),
                const SizedBox(height:12),
                TextField(
                  key:const Key('b4-moderation-note'),
                  controller:note,maxLength:500,maxLines:3,
                  decoration:const InputDecoration(
                    labelText:'Justificación (5–500 caracteres)')),
                if(validation!=null)Text(validation!,
                  style:const TextStyle(color:Colors.redAccent)),
              ],
            )),
          ),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog),
              child:const Text('Cancelar')),
            FilledButton(
              key:const Key('b4-moderation-submit'),
              onPressed:(){
                final value=note.text.trim();
                if(value.length<5||value.length>500){
                  update(()=>validation='Escribe una justificación '
                    'de al menos cinco caracteres.');
                  return;
                }
                Navigator.pop(dialog,{
                  'action':selectedAction,'note':value,
                });
              },
              child:const Text('Confirmar decisión')),
          ],
        ),
      ),
    );
    note.dispose();
    if(result==null||!mounted)return;
    setState(()=>sending=true);
    try{
      final status=await widget.api.resolveModerationReport(
        reportId:(report['id']??'').toString(),
        action:result['action']!,note:result['note']!);
      if(status=='resolved'){
        await reload();
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text('Decisión guardada y auditada.')));
      }
    }on MemberApiException catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.message)));
    }catch(_){
      if(mounted)setState(()=>error='No se pudo resolver este reporte.');
    }finally{
      if(mounted)setState(()=>sending=false);
    }
  }

  Widget reportCard(Map<String,dynamic> report) {
    final reason=report['reason']?.toString()??'other';
    final target=report['subject_name']?.toString()??'Cuenta';
    final excerpt=report['post_excerpt']?.toString()??'';
    final id=report['id']?.toString()??'';
    return Card(
      key:Key('b4-report-$id'),
      margin:const EdgeInsets.only(bottom:12),
      child:Padding(
        padding:const EdgeInsets.all(18),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text('Reporte · ${communityReasonsB4[reason]??reason}',
              style:Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:7),
            Text('Cuenta reportada: $target'),
            if(excerpt.isNotEmpty)...[
              const SizedBox(height:7),
              Text('Extracto: $excerpt',
                maxLines:4,overflow:TextOverflow.ellipsis),
            ],
            if((report['detail']??'').toString().isNotEmpty)...[
              const SizedBox(height:7),
              Text('Contexto: ${report['detail']}'),
            ],
            const SizedBox(height:6),
            const Text('Identidad del denunciante reservada.'),
            const SizedBox(height:12),
            OutlinedButton.icon(
              key:Key('b4-resolve-$id'),
              onPressed:sending?null:()=>resolve(report),
              icon:const Icon(Icons.fact_check_outlined),
              label:const Text('Revisar y resolver')),
          ],
        ),
      ),
    );
  }

  Widget deletionCard(Map<String,dynamic> request) {
    final userId=(request['user_id']??'').toString();
    final shortId=userId.length>12
      ?'${userId.substring(0,8)}…${userId.substring(userId.length-4)}'
      :userId;
    return Card(
      key:Key('b4-deletion-$userId'),
      child:Padding(
        padding:const EdgeInsets.all(18),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text('Solicitud de baja · $shortId',
              style:Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:8),
            Text('Fecha: ${request['requested_at']??''}'),
            Text('Estado: ${request['status']??'pendiente'}'),
            const SizedBox(height:8),
            const Text('Requiere gestión humana de retención, '
              'exportación, Auth, Storage, respaldos y auditoría. '
              'No marcar como eliminada sin evidencia.'),
          ],
        ),
      ),
    );
  }

  Future<void> createAnnouncement() async {
    if(sending)return;
    final text=TextEditingController();
    var topic='running';
    String? validation;
    final draft=await showDialog<Map<String,String>>(
      context:context,builder:(dialog)=>StatefulBuilder(
        builder:(dialog,update)=>AlertDialog(
          title:const Text('Nuevo comunicado oficial'),
          content:ConstrainedBox(
            constraints:const BoxConstraints(maxWidth:480),
            child:SingleChildScrollView(child:Column(
              mainAxisSize:MainAxisSize.min,children:[
                const Text('Tu comunicado será visible a los miembros '
                  'que hayan aceptado participar en la comunidad. '
                  'No inventes eventos ni publiques información privada.'),
                const SizedBox(height:12),
                DropdownButtonFormField<String>(
                  initialValue:topic,
                  decoration:const InputDecoration(labelText:'Tema'),
                  items:[
                    for(final entry in communityTopicsB4.entries)
                      DropdownMenuItem(value:entry.key,
                        child:Text(entry.value)),
                  ],
                  onChanged:(v){
                    if(v!=null)update(()=>topic=v);
                  }),
                const SizedBox(height:12),
                TextField(
                  key:const Key('b4-announcement-content'),
                  controller:text,maxLength:480,minLines:3,maxLines:5,
                  decoration:const InputDecoration(
                    labelText:'Contenido oficial')),
                if(validation!=null)Text(validation!,
                  style:const TextStyle(color:Colors.redAccent)),
              ],
            )),
          ),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog),
              child:const Text('Cancelar')),
            FilledButton(
              key:const Key('b4-announcement-submit'),
              onPressed:(){
                final value=text.text.trim();
                if(value.length<15 || value.length>480 ||
                   RegExp(r'https?://|www\.|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|[0-9]{8,}',
                     caseSensitive:false).hasMatch(value)){
                  update(()=>validation='Escribe de 15 a 480 caracteres '
                    'sin enlaces, correos ni teléfonos.');
                  return;
                }
                Navigator.pop(dialog,{'topic':topic,'content':value});
              },
              child:const Text('Publicar comunicado')),
          ],
        ),
      ),
    );
    text.dispose();
    if(draft==null||!mounted)return;
    setState(()=>sending=true);
    try{
      final response=await widget.api.adminPublishCommunityAnnouncement(
        draft['topic']!,draft['content']!);
      if(response=='published'){
        await reload();
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text(
            'Comunicado oficial publicado para miembros de la comunidad.')));
      }
    }catch(_){
      if(mounted)setState(()=>
        error='No fue posible publicar el comunicado. Verifica MFA.');
    }finally{
      if(mounted)setState(()=>sending=false);
    }
  }

  Future<void> removeAnnouncement(Map<String,dynamic> item) async {
    final id=(item['id']??'').toString();
    final ok=await showDialog<bool>(
      context:context,builder:(dialog)=>AlertDialog(
        title:const Text('Retirar comunicado'),
        content:const Text('Dejará de mostrarse a los miembros. '
          'Su historial de auditoría se conserva.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog,false),
            child:const Text('Volver')),
          FilledButton(
            key:const Key('b4-announcement-remove-confirm'),
            onPressed:()=>Navigator.pop(dialog,true),
            child:const Text('Retirar')),
        ],
      ),
    );
    if(ok!=true||!mounted)return;
    try{
      await widget.api.adminRemoveCommunityAnnouncement(id);
      await reload();
    }catch(_){
      if(mounted)setState(()=>
        error='No se pudo retirar el comunicado.');
    }
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      title:const Text('Moderación de comunidad'),
      actions:[IconButton(
        key:const Key('b4-moderation-reload'),
        onPressed:loading?null:reload,
        icon:const Icon(Icons.refresh),
        tooltip:'Actualizar cola',
      )],
    ),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:850),
      child:ListView(
        key:const Key('b4-moderation-list'),
        padding:const EdgeInsets.all(18),
        children:[
          Text('Seguridad de la comunidad',
            style:Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height:8),
          const Text('Solo propietario con MFA. Las decisiones de '
            'moderación se registran con autor, fecha y motivo en '
            'un historial no accesible para los miembros.'),
          const SizedBox(height:16),
          Wrap(spacing:10,runSpacing:10,children:[
            ChoiceChip(
              key:const Key('b4-moderation-tab-reports'),
              label:Text('Reportes pendientes (${reports.length})'),
              selected:!showDeletion,
              onSelected:(_)=>setState((){
                showDeletion=false;showAnnouncements=false;
              })), 
            ChoiceChip(
              key:const Key('b4-moderation-tab-deletions'),
              label:Text('Solicitudes de baja (${deletions.length})'),
              selected:showDeletion,
              onSelected:(_)=>setState((){
                showDeletion=true;showAnnouncements=false;
              })),
            ChoiceChip(
              key:const Key('b4-moderation-tab-announcements'),
              label:Text('Comunicados (${announcements.length})'),
              selected:showAnnouncements,
              onSelected:(_)=>setState((){
                showAnnouncements=true;showDeletion=false;
              })),
          ]),
          const SizedBox(height:18),
          if(loading)const Center(child:CircularProgressIndicator()),
          if(error!=null)...[
            Text(error!,key:const Key('b4-moderation-error'),
              style:const TextStyle(color:Colors.redAccent)),
            TextButton(onPressed:reload,child:const Text('Reintentar')),
          ],
          if(!loading && error==null && !showDeletion && !showAnnouncements)...[
            if(reports.isEmpty)const Text('No hay reportes pendientes.',
              key:Key('b4-reports-empty')),
            for(final report in reports)reportCard(report),
          ],
          if(!loading && error==null && showDeletion && !showAnnouncements)...[
            if(deletions.isEmpty)const Text(
              'No hay solicitudes de baja pendientes.',
              key:Key('b4-deletions-empty')),
            for(final request in deletions)deletionCard(request),
          ],
          if(!loading && error==null && showAnnouncements)...[
            FilledButton.icon(
              key:const Key('b4-admin-new-announcement'),
              onPressed:sending?null:createAnnouncement,
              icon:const Icon(Icons.campaign_outlined),
              label:const Text('Publicar comunicado oficial')),
            const SizedBox(height:14),
            if(announcements.isEmpty)
              const Text('Todavía no hay comunicados oficiales.',
                key:Key('b4-announcements-empty')),
            for(final item in announcements)
              Card(child:Padding(
                padding:const EdgeInsets.all(18),
                child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text((item['topic']??'Deporte').toString(),
                      style:Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height:8),
                    Text((item['content']??'').toString()),
                    const SizedBox(height:8),
                    Text('Estado: ${item['status']??'desconocido'}'),
                    if(item['status']=='visible')OutlinedButton.icon(
                      key:Key('b4-announcement-remove-${item['id']}'),
                      onPressed:()=>removeAnnouncement(item),
                      icon:const Icon(Icons.remove_circle_outline),
                      label:const Text('Retirar comunicado')),
                  ],
                ),
              )),
          ],
          const SizedBox(height:20),
          const Text('El acceso a una beta social real exige personal '
            'de respuesta humana, protocolos de incidentes y gates '
            'de seguridad aprobados.'),
        ],
      ),
    )),
  );
}
