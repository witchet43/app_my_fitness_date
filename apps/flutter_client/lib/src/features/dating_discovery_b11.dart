import 'package:flutter/material.dart';
import '../core/dating_repository_b11.dart';

/// This UI can ONLY be reached after the server returns enabled=true.
class DatingDiscoveryB11 extends StatefulWidget {
  const DatingDiscoveryB11({super.key,required this.api});
  final DatingRepositoryB11 api;
  @override
  State<DatingDiscoveryB11> createState()=>_DatingDiscoveryB11State();
}
class _DatingDiscoveryB11State extends State<DatingDiscoveryB11>{
  bool loading=true;
  String? error;
  String? busyId;
  List<Map<String,dynamic>> candidates=[];
  List<Map<String,dynamic>> matches=[];
  @override
  void initState(){super.initState();reload();}
  Future<void> reload() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final c=await widget.api.discoverB11();
      final m=await widget.api.matchesB11();
      if(mounted)setState((){candidates=c;matches=m;});
    }catch(_){
      if(mounted)setState(()=>error=
        'El acceso seguro no está disponible. '
        'No se mostrará información de otras personas.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }
  Future<void> like(String id) async {
    if(busyId!=null)return;
    final agreed=await showDialog<bool>(
      context:context,
      builder:(ctx)=>AlertDialog(
        title:const Text('¿Te interesa conocer a esta persona?'),
        content:const Text('Solo habrá match si ambos expresan interés.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Expresar interés')),
        ],
      ),
    );
    if(agreed!=true||!mounted)return;
    setState(()=>busyId=id);
    try{
      final status=await widget.api.likeB11(id);
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(status=='matched'
          ?'¡Interés mutuo! Ya pueden conversar.'
          :'Interés privado registrado.')));
      await reload();
    }catch(_){
      if(mounted)setState(()=>error='No se pudo registrar el interés.');
    }finally{
      if(mounted)setState(()=>busyId=null);
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Compatibilidad de vida'),
      actions:[IconButton(
        key:const Key('b11-refresh-discovery'),
        tooltip:'Actualizar personas y matches',
        icon:const Icon(Icons.refresh),
        onPressed:loading?null:reload)]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:820),
      child:ListView(padding:const EdgeInsets.all(16),children:[
        const Text('Compatibilidad antes que mismo deporte',
          style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:10),
        const Text('Solo miembros adultos elegibles y autorizados. '
          'Tu gimnasio, horario, rutas y preferencias completas no '
          'son visibles aquí. Las fotografías requieren moderación.'),
        if(loading)const LinearProgressIndicator(),
        if(error!=null)Text(error!,key:const Key('b11-discovery-error')),
        const SizedBox(height:18),
        const Text('Personas compatibles',
          style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        if(!loading&&error==null&&candidates.isEmpty)
          const Text('Todavía no hay perfiles autorizados. '
            'No presentamos personas ficticias como reales.',
            key:Key('b11-candidates-empty')),
        for(final person in candidates)
          Card(child:Padding(
            padding:const EdgeInsets.all(14),
            child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text((person['display_name']??'').toString(),
                  style:Theme.of(context).textTheme.titleLarge),
                Text((person['city']??'').toString()),
                const SizedBox(height:6),
                for(final reason in (person['reason_codes'] is List
                    ?person['reason_codes'] as List:[]))
                  Padding(padding:const EdgeInsets.only(bottom:5),
                    child:Text(reasonDescriptionB11(reason.toString()))),
                const SizedBox(height:8),
                FilledButton.icon(
                  key:Key('b11-like-${person['user_id']}'),
                  onPressed:busyId==null?
                    ()=>like((person['user_id']??'').toString()):null,
                  icon:const Icon(Icons.favorite_outline),
                  label:const Text('Me interesa')),
              ]),
          )),
        const SizedBox(height:24),
        const Text('Matches mutuos',
          style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
        if(!loading&&error==null&&matches.isEmpty)
          const Text('Aún no hay interés recíproco.',
            key:Key('b11-matches-empty')),
        for(final match in matches)
          ListTile(
            key:Key('b11-match-${match['id']}'),
            title:Text((match['display_name']??'Match').toString()),
            subtitle:const Text('Interés confirmado por ambas personas'),
            trailing:const Icon(Icons.chat_outlined),
            onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(
              builder:(_)=>DatingChatB11(
                api:widget.api,
                matchId:(match['id']??'').toString(),
                title:(match['display_name']??'Match').toString()),
            )).then((_){if(mounted)reload();}),
          ),
      ]),
    )),
  );
}

/// Only approved, server-generated opaque reason codes. Unknown codes
/// are not printed, preventing unreviewed server values leaking private data.
String reasonDescriptionB11(String code){
  const messages=<String,String>{
    'sleep_similar':'Sus ritmos de descanso son parecidos.',
    'sleep_discuss':'Sus descansos difieren; conviene conversarlo.',
    'weekday_similar':'Disfrutan semanas similares.',
    'weekday_discuss':'Prefieren distintos planes entre semana.',
    'intent_aligned':'Comparten intención de relación.',
    'intent_discuss':'Sus expectativas merecen una conversación.',
    'autonomy_aligned':'Coinciden en independencia y tiempo compartido.',
    'autonomy_discuss':'Conversen sobre cuánto tiempo compartir.',
    'training_similar':'Su frecuencia deportiva es similar.',
    'training_respect':'Sus entrenamientos pueden ser distintos.',
    'sport_shared_low':'Disfrutan un deporte común; no es lo más importante.',
    'sport_different_ok':'Deportes distintos no impiden encajar.',
  };
  return messages[code]??'Una preferencia requiere conversación.';
}

class DatingChatB11 extends StatefulWidget {
  const DatingChatB11({super.key,required this.api,
    required this.matchId,required this.title});
  final DatingRepositoryB11 api;
  final String matchId;
  final String title;
  @override
  State<DatingChatB11> createState()=>_DatingChatB11State();
}
class _DatingChatB11State extends State<DatingChatB11>{
  final text=TextEditingController();
  List<Map<String,dynamic>> items=[];
  List<String> ideas=[];
  bool loading=true;
  bool busy=false;
  String? error;
  @override
  void initState(){super.initState();reload();}
  @override
  void dispose(){text.dispose();super.dispose();}
  Future<void> reload() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final msgs=await widget.api.messagesB11(widget.matchId);
      final suggestions=await widget.api.ideasB11(widget.matchId);
      if(mounted)setState((){items=msgs;ideas=suggestions;});
    }catch(_){
      if(mounted)setState(()=>error='No se pudo consultar este chat privado.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }
  Future<void> send() async {
    if(busy||text.text.trim().isEmpty)return;
    setState(()=>busy=true);
    try{
      await widget.api.sendB11(widget.matchId,text.text.trim());
      text.clear();
      await reload();
    }catch(_){
      if(mounted)setState(()=>error='No se pudo enviar. Revisa la conexión.');
    }finally{
      if(mounted)setState(()=>busy=false);
    }
  }
  Future<void> report() async {
    final reason=await showDialog<String>(
      context:context,builder:(ctx)=>SimpleDialog(
        title:const Text('Reportar y bloquear a esta persona'),
        children:[
          for(final reason in ['harassment','spam','impersonation','unsafe','other'])
            SimpleDialogOption(onPressed:()=>Navigator.pop(ctx,reason),
              child:Text(switch(reason){
                'harassment'=>'Acoso','spam'=>'Spam',
                'impersonation'=>'Suplantación',
                'unsafe'=>'Riesgo de seguridad',_=>'Otro motivo',
              })),
        ],
      ),
    );
    if(reason==null||!mounted)return;
    try{
      await widget.api.reportB11(widget.matchId,reason);
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text('Reporte enviado y cuenta bloqueada.')));
        Navigator.of(context).pop();
      }
    }catch(_){
      if(mounted)setState(()=>error='No se pudo completar el reporte.');
    }
  }
  String ideaName(String v)=>switch(v){
    'walk_coffee'=>'Caminata + café',
    'yoga_brunch'=>'Yoga + brunch',
    'museum_walk'=>'Museo + caminata',
    'outdoor_market'=>'Mercado al aire libre',
    _=>'Plan sencillo, sin revelar ubicaciones',
  };
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.title),actions:[
      IconButton(key:const Key('b11-report'),
        tooltip:'Reportar y bloquear',
        onPressed:report,icon:const Icon(Icons.report_outlined)),
    ]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:760),
      child:Column(children:[
        const Padding(padding:EdgeInsets.all(12),
          child:Text('Chat privado solo después de un match mutuo. '
            'Puedes reportar o bloquear cuando lo necesites.')),
        if(loading)const LinearProgressIndicator(),
        if(error!=null)Text(error!,key:const Key('b11-chat-error')),
        Expanded(child:ListView(
          key:const Key('b11-chat-messages'),
          padding:const EdgeInsets.all(12),
          children:[
            for(final msg in items.reversed)
              Card(child:ListTile(title:Text(
                (msg['body']??'').toString()))),
          ],
        )),
        if(ideas.isNotEmpty)Padding(
          padding:const EdgeInsets.all(12),
          child:Wrap(spacing:10,children:[
            for(final idea in ideas)
              Chip(label:Text(ideaName(idea))),
          ]),
        ),
        const Padding(
          padding:EdgeInsets.all(8),
          child:Text('Active Date: ideas, no reservas ni ubicaciones reales.')),
        Row(children:[
          Expanded(child:TextField(
            key:const Key('b11-message-input'),
            controller:text,maxLength:1200,
            decoration:const InputDecoration(labelText:'Mensaje',
              contentPadding:EdgeInsets.all(12)),
          )),
          IconButton(key:const Key('b11-send'),
            onPressed:busy?null:send,tooltip:'Enviar mensaje',
            icon:const Icon(Icons.send)),
        ]),
      ]),
    )),
  );
}
