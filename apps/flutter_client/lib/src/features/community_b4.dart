import 'package:flutter/material.dart';

import '../core/community_repository.dart';
import '../core/member_v26_api.dart';

const communityTopicsB4 = <String, String>{
  'running':'Running',
  'cycling':'Ciclismo',
  'hiking':'Senderismo',
  'gym':'Fuerza y gimnasio',
  'wellness':'Bienestar',
  'other':'Otros deportes',
};
const communityReasonsB4 = <String, String>{
  'harassment':'Acoso o trato ofensivo',
  'spam':'Publicidad o spam',
  'privacy':'Datos personales o privacidad',
  'unsafe':'Actividad o conducta insegura',
  'other':'Otro problema',
};

class CommunityB4 extends StatefulWidget {
  const CommunityB4({super.key, required this.api});
  final CommunityRepository api;

  @override
  State<CommunityB4> createState() => _CommunityB4State();
}

class _CommunityB4State extends State<CommunityB4> {
  bool loading = true;
  bool loadingMore = false;
  bool sending = false;
  bool hasMore = false;
  String status = 'checking';
  String? error;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)));
    }
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() { loading = true; error = null; });
    try {
      final nextStatus = await widget.api.communityStatus();
      final nextPosts = nextStatus == 'available'
          ? await widget.api.communityFeed()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          status = nextStatus;
          posts = nextPosts;
          hasMore = nextPosts.length == 15;
        });
      }
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'No se pudo consultar la comunidad. Reintenta.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> more() async {
    if (loadingMore || !hasMore || posts.isEmpty) return;
    final cursor = DateTime.tryParse(
      posts.last['created_at']?.toString() ?? '');
    if (cursor == null) return;
    setState(() => loadingMore = true);
    try {
      final next = await widget.api.communityFeed(before: cursor);
      if (mounted) {
        final seen = posts.map((p) => p['id']).toSet();
        setState(() {
          posts.addAll(next.where((p) => !seen.contains(p['id'])));
          hasMore = next.length == 15;
        });
      }
    } catch (_) {
      message('No se pudo cargar la siguiente página.');
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Future<void> optIn() async {
    if (sending) return;
    setState(() { sending = true; error = null; });
    try {
      await widget.api.acceptCommunityConsent();
      await reload();
    } on MemberApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'No se pudo registrar tu consentimiento.');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> create() async {
    if (sending || status != 'available') return;
    final content = TextEditingController();
    var selectedTopic = 'running';
    String? validation;
    final draft = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Compartir con la comunidad'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 490),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
                const Text('Comparte una idea o pregunta deportiva. '
                  'No incluyas teléfonos, enlaces, direcciones ni horarios '
                  'privados. No se admiten mensajes directos.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('b4-post-topic'),
                  initialValue: selectedTopic,
                  decoration: const InputDecoration(labelText: 'Tema'),
                  items: [
                    for (final entry in communityTopicsB4.entries)
                      DropdownMenuItem(value:entry.key,
                        child:Text(entry.value)),
                  ],
                  onChanged: (value) {
                    if (value != null) update(() => selectedTopic = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('b4-post-content'),
                  controller: content,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 480,
                  decoration: const InputDecoration(
                    labelText: 'Tu publicación'),
                ),
                if (validation != null) Text(validation!,
                  style: const TextStyle(color: Colors.redAccent)),
              ],
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancelar')),
            FilledButton(
              key: const Key('b4-post-submit'),
              onPressed: () {
                final text = content.text.trim();
                final containsPrivateData = RegExp(
                  r'(https?://|www\\.|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}|[0-9]{8,})',
                  caseSensitive:false,
                ).hasMatch(text);
                if (text.length < 15 || text.length > 480 ||
                    containsPrivateData) {
                  update(() => validation = 'Escribe entre 15 y 480 caracteres '
                    'sin enlaces, correos ni teléfonos.');
                  return;
                }
                Navigator.pop(dialog, {
                  'topic':selectedTopic,'content':text,
                });
              },
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
    content.dispose();
    if (draft == null || !mounted) return;
    setState(() => sending = true);
    try {
      final outcome = await widget.api.publishCommunityPost(
        draft['topic']!, draft['content']!);
      if (outcome == 'published') {
        await reload();
        message('Publicación guardada en la comunidad.');
      } else {
        message('No pudimos publicar: $outcome');
      }
    } on MemberApiException catch (e) {
      message(e.message);
    } catch (_) {
      message('No se pudo publicar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> remove(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Retirar mi publicación'),
        content: const Text('El texto desaparecerá del muro, '
          'pero podría conservarse en registros internos de moderación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog,false),
            child: const Text('Conservar')),
          FilledButton(
            key: const Key('b4-remove-confirm'),
            onPressed: () => Navigator.pop(dialog,true),
            child: const Text('Retirar publicación')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    try {
      await widget.api.removeCommunityPost(id);
      if (mounted) setState(() =>
        posts.removeWhere((p) => p['id'] == id));
      message('Publicación retirada del muro.');
    } on MemberApiException catch (e) {
      message(e.message);
    } catch (_) {
      message('No fue posible retirar tu publicación.');
    }
  }

  Future<void> block(Map<String, dynamic> item) async {
    final authorId = (item['author_id'] ?? '').toString();
    final name = (item['author_name'] ?? 'esta persona').toString();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Bloquear a esta persona'),
        content: Text('Dejarás de ver las publicaciones de $name, '
          'y esa persona tampoco verá las tuyas en la comunidad.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog,false),
            child: const Text('Cancelar')),
          FilledButton(
            key: const Key('b4-block-confirm'),
            onPressed: () => Navigator.pop(dialog,true),
            child: const Text('Bloquear')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    try {
      final status = await widget.api.setCommunityBlock(
        authorId, blocked:true);
      if (status == 'blocked' && mounted) {
        setState(() =>
          posts.removeWhere((p) => p['author_id'] == authorId));
        message('Bloqueo guardado: ya no compartirán este muro.');
      }
    } on MemberApiException catch (e) {
      message(e.message);
    } catch (_) {
      message('No se pudo bloquear la cuenta.');
    }
  }

  Future<void> report(Map<String, dynamic> item,
      {required bool profile}) async {
    var reason = 'harassment';
    final detail = TextEditingController();
    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(profile ? 'Reportar perfil' : 'Reportar publicación'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
                const Text('El reporte es privado y llegará a moderación. '
                  'La persona reportada no verá tu identidad.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('b4-report-reason'),
                  initialValue: reason,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del reporte'),
                  items: [
                    for (final item in communityReasonsB4.entries)
                      DropdownMenuItem(
                        value:item.key,child:Text(item.value)),
                  ],
                  onChanged: (v) {
                    if (v != null) update(() => reason = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('b4-report-detail'),
                  controller: detail, maxLength: 300,maxLines:3,
                  decoration: const InputDecoration(
                    labelText: 'Contexto adicional (opcional)'),
                ),
              ],
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancelar')),
            FilledButton(
              key: const Key('b4-report-submit'),
              onPressed: () => Navigator.pop(dialog,{
                'reason':reason,'detail':detail.text.trim(),
              }),
              child: const Text('Enviar reporte')),
          ],
        ),
      ),
    );
    detail.dispose();
    if (data == null || !mounted) return;
    try {
      final outcome = await widget.api.reportCommunity(
        postId:profile?null:(item['id'] ?? '').toString(),
        userId:profile?(item['author_id'] ?? '').toString():null,
        reason:data['reason']!,detail:data['detail']!,
      );
      message(outcome == 'already_reported'
        ? 'Ya habías reportado este elemento.'
        : 'Reporte privado recibido para revisión humana.');
    } on MemberApiException catch (e) {
      message(e.message);
    } catch (_) {
      message('No se pudo enviar el reporte.');
    }
  }

  Future<void> openPrivacy() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CommunityPrivacyB4(api:widget.api)));
    if (mounted) await reload();
  }

  Widget itemCard(Map<String, dynamic> item) {
    final mine = item['is_mine'] == true;
    final id = (item['id'] ?? '').toString();
    final createdAt = DateTime.tryParse(
      (item['created_at'] ?? '').toString())?.toLocal();
    String time = createdAt == null ? '' :
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    final author = (item['author_name'] ?? 'Deportista').toString();
    final topic = (item['topic'] ?? '').toString();
    return Card(
      key:Key('b4-post-$id'),
      margin:const EdgeInsets.only(bottom:12),
      child:Padding(
        padding:const EdgeInsets.all(17),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Row(children:[
              const CircleAvatar(child:Icon(Icons.directions_run)),
              const SizedBox(width:10),
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text(author,style:Theme.of(context).textTheme.titleMedium),
                  Text('${communityTopicsB4[topic] ?? 'Deporte'} · $time',
                    style:Theme.of(context).textTheme.bodySmall),
                ],
              )),
              PopupMenuButton<String>(
                key:Key('b4-post-actions-$id'),
                tooltip:'Opciones de la publicación',
                onSelected:(choice){
                  if(choice=='remove') {remove(item);}
                  if(choice=='report_post') {report(item,profile:false);}
                  if(choice=='report_profile') {report(item,profile:true);}
                  if(choice=='block') {block(item);}
                },
                itemBuilder:(_)=>mine
                  ? [const PopupMenuItem(
                    value:'remove',child:Text('Retirar mi publicación'))]
                  : [
                    const PopupMenuItem(
                      value:'report_post',child:Text('Reportar publicación')),
                    const PopupMenuItem(
                      value:'report_profile',child:Text('Reportar perfil')),
                    const PopupMenuItem(
                      value:'block',child:Text('Bloquear persona')),
                  ],
              ),
            ]),
            const SizedBox(height:12),
            Text((item['content'] ?? '').toString(),
              style:Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget gate() {
    if(status == 'consent_required') {
      return Card(child:Padding(
        padding:const EdgeInsets.all(22),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text('Comunidad opcional',
              style:Theme.of(context).textTheme.titleLarge),
            const SizedBox(height:10),
            const Text('Las publicaciones visibles llevan tu nombre público. '
              'Puedes reportar, bloquear o retirar lo que compartes. '
              'El consentimiento para la comunidad NO habilita FitDating. '
              'No publiques tu dirección, gimnasio, rutina ni teléfono.'),
            const SizedBox(height:16),
            FilledButton.icon(
              key:const Key('b4-consent-submit'),
              onPressed:sending?null:optIn,
              icon:const Icon(Icons.volunteer_activism_outlined),
              label:const Text('Acepto participar en la comunidad')),
          ],
        ),
      ));
    }
    final label = switch(status) {
      'profile_required'=>'Completa tu perfil deportivo y declara tu mayoría de edad.',
      'legal_required'=>'Acepta los términos y el aviso de privacidad actualizados.',
      'suspended'=>'El acceso a la comunidad está suspendido por moderación.',
      'deletion_pending'=>'Solicitaste la baja. La comunidad está deshabilitada.',
      'admin_separate'=>'Tu cuenta administrativa no publica como miembro.',
      'not_authenticated'=>'Debes iniciar sesión para acceder.',
      _=>'La comunidad no está disponible para esta cuenta.',
    };
    return Padding(
      padding:const EdgeInsets.symmetric(vertical:28),
      child:Text(label,key:const Key('b4-community-gate')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(
      title:const Text('Comunidad deportiva'),
      actions:[
        IconButton(
          key:const Key('b4-blocks-open'),
          tooltip:'Personas bloqueadas',
          icon:const Icon(Icons.block_outlined),
          onPressed:()=>Navigator.of(context).push(
            MaterialPageRoute<void>(builder:(_)=>
              CommunityBlocksB4(api:widget.api))),
        ),
        IconButton(
          key:const Key('b4-privacy-open'),
          tooltip:'Privacidad y baja',
          icon:const Icon(Icons.privacy_tip_outlined),
          onPressed:openPrivacy,
        ),
        IconButton(
          key:const Key('b4-community-reload'),
          tooltip:'Actualizar muro',
          icon:const Icon(Icons.refresh),
          onPressed:loading?null:reload,
        ),
      ],
    ),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:850),
      child:RefreshIndicator(
        onRefresh:reload,
        child:ListView(
          key:const Key('b4-community-list'),
          physics:const AlwaysScrollableScrollPhysics(),
          padding:const EdgeInsets.all(18),
          children:[
            Text('Compartimos el movimiento',
              style:Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height:8),
            const Text('Comparte experiencias deportivas y conecta con '
              'personas de forma voluntaria. Sin chat privado ni citas.'),
            if(loading)const Padding(
              padding:EdgeInsets.all(24),
              child:Center(child:CircularProgressIndicator())),
            if(error!=null)...[
              const SizedBox(height:14),
              Text(error!,key:const Key('b4-community-error'),
                style:const TextStyle(color:Colors.redAccent)),
              TextButton(onPressed:reload,child:const Text('Reintentar')),
            ],
            if(!loading && error==null && status!='available')gate(),
            if(!loading && status=='available')...[
              const SizedBox(height:14),
              FilledButton.icon(
                key:const Key('b4-create-post'),
                onPressed:sending?null:create,
                icon:const Icon(Icons.edit_note_outlined),
                label:const Text('Crear publicación')),
              const SizedBox(height:20),
              if(posts.isEmpty && error==null)
                const Padding(
                  padding:EdgeInsets.all(20),
                  child:Text('Todavía no hay publicaciones. '
                    'Comparte la primera experiencia deportiva auténtica.',
                    key:Key('b4-empty-feed'))),
              for(final item in posts)itemCard(item),
              if(hasMore)TextButton(
                key:const Key('b4-more'),
                onPressed:loadingMore?null:more,
                child:Text(loadingMore?'Cargando…':'Mostrar más')),
            ],
            const SizedBox(height:20),
            const Text('Reportes revisados por personas. '
              'La moderación de una comunidad real requiere un equipo activo.',
              textAlign:TextAlign.center),
          ],
        ),
      ),
    )),
  );
}

class CommunityBlocksB4 extends StatefulWidget {
  const CommunityBlocksB4({super.key,required this.api});
  final CommunityRepository api;
  @override
  State<CommunityBlocksB4> createState()=>_CommunityBlocksB4State();
}
class _CommunityBlocksB4State extends State<CommunityBlocksB4> {
  List<Map<String,dynamic>> items=[];
  bool loading=true;
  String? error;

  @override
  void initState(){super.initState();reload();}

  Future<void> reload() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final rows=await widget.api.communityBlocks();
      if(mounted)setState(()=>items=rows);
    }catch(_){
      if(mounted)setState(()=>
        error='No pudimos consultar los bloqueos.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> unblock(Map<String,dynamic> item) async {
    final id=(item['blocked_id']??'').toString();
    try{
      final result=await widget.api.setCommunityBlock(id,blocked:false);
      if(result=='unblocked'&&mounted) {
        setState(()=>items.removeWhere((p)=>p['blocked_id']==id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('Cuenta desbloqueada.')));
      }
    }catch(_){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('No se pudo desbloquear.')));
    }
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Personas bloqueadas')),
    body:ListView(padding:const EdgeInsets.all(18),children:[
      const Text('El bloqueo funciona en ambos sentidos dentro '
        'de la comunidad y nunca avisa a la otra persona.'),
      if(loading)const Center(child:CircularProgressIndicator()),
      if(error!=null)Text(error!),
      if(!loading&&items.isEmpty)
        const Text('No tienes personas bloqueadas.',
          key:Key('b4-blocks-empty')),
      for(final item in items)Card(child:ListTile(
        title:Text((item['display_name']??'Persona bloqueada').toString()),
        trailing:TextButton(
          key:Key('b4-unblock-${item['blocked_id']}'),
          onPressed:()=>unblock(item),
          child:const Text('Desbloquear')),
      )),
    ]),
  );
}

class CommunityPrivacyB4 extends StatefulWidget {
  const CommunityPrivacyB4({super.key,required this.api});
  final CommunityRepository api;
  @override
  State<CommunityPrivacyB4> createState()=>_CommunityPrivacyB4State();
}
class _CommunityPrivacyB4State extends State<CommunityPrivacyB4> {
  bool loading=true;
  bool submitting=false;
  String status='none';
  List<Map<String,dynamic>> history=[];
  String? error;

  @override
  void initState(){super.initState();reload();}
  Future<void> reload() async{
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final s=await widget.api.communityDeletionStatus();
      final p=await widget.api.myCommunityPosts();
      if(mounted)setState((){
        status=s;
        history=p;
      });
    }catch(_){
      if(mounted)setState(()=>
        error='No se pudo consultar tu información.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> requestDeletion() async {
    if(submitting||status!='none')return;
    var confirmed=false;
    final accepted=await showDialog<bool>(
      context:context,builder:(dialog)=>StatefulBuilder(
        builder:(dialog,update)=>AlertDialog(
          title:const Text('Solicitar baja de cuenta'),
          content:Column(mainAxisSize:MainAxisSize.min,children:[
            const Text('Esta acción enviará una solicitud humana de baja, '
              'ocultará tus publicaciones y desactivará tu participación '
              'en la comunidad. La eliminación definitiva de Auth, '
              'archivos, copias de seguridad y registros NO es inmediata.'),
            CheckboxListTile(
              value:confirmed,
              onChanged:(v)=>update(()=>confirmed=v??false),
              title:const Text('Comprendo que es una solicitud, '
                'no un borrado inmediato.')),
          ]),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(dialog,false),
              child:const Text('Conservar cuenta')),
            FilledButton(
              key:const Key('b4-delete-request-confirm'),
              onPressed:confirmed?()=>Navigator.pop(dialog,true):null,
              child:const Text('Enviar solicitud de baja')),
          ],
        ),
      ),
    );
    if(accepted!=true||!mounted)return;
    setState(()=>submitting=true);
    try{
      final result=await widget.api.requestCommunityDeletion();
      if(mounted)setState(()=>status=result);
      await reload();
    }catch(_){
      if(mounted)setState(()=>error='No se pudo solicitar la baja.');
    }finally{
      if(mounted)setState(()=>submitting=false);
    }
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Privacidad y baja')),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:700),
      child:ListView(padding:const EdgeInsets.all(18),children:[
        Text('Tus publicaciones',
          style:Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height:8),
        const Text('Puedes consultar los textos que compartiste, '
          'incluyendo aquellos retirados u ocultos. Un expediente '
          'completo de datos personales se gestiona por el proceso '
          'de privacidad de la plataforma.'),
        if(loading)const Center(child:CircularProgressIndicator()),
        if(error!=null)Text(error!,key:const Key('b4-privacy-error')),
        if(!loading&&history.isEmpty)
          const Text('No has creado publicaciones.',
            key:Key('b4-history-empty')),
        for(final post in history)Card(child:ListTile(
          title:Text((post['content']??'').toString()),
          subtitle:Text('Estado: ${post['status']??'desconocido'}'),
        )),
        const SizedBox(height:22),
        Text('Baja de cuenta',
          style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        Text(status=='none'
          ?'Si solicitas la baja, dejaremos de mostrar tus publicaciones '
            'y abriremos una revisión humana de eliminación y retención.'
          :'Solicitud de baja registrada: $status. La eliminación '
            'definitiva sigue su procedimiento interno.'),
        const SizedBox(height:16),
        if(status=='none')OutlinedButton.icon(
          key:const Key('b4-delete-request'),
          onPressed:submitting?null:requestDeletion,
          icon:const Icon(Icons.person_remove_outlined),
          label:const Text('Solicitar eliminación de mi cuenta')),
      ]),
    )),
  );
}
