import 'package:flutter/material.dart';
import '../core/member_v26_api.dart';
import '../core/fitted_locale.dart';
import '../widgets/fitted_glass_atmosphere.dart';

/// Moderation is not automated: human review with recorded justification,
/// plus independent AAL2 server-side authorization for each decision.
class FittedPulseModerationB13 extends StatefulWidget {
  const FittedPulseModerationB13({super.key,required this.api});
  final MemberV26Api api;
  @override
  State<FittedPulseModerationB13> createState()=>_FittedPulseModerationB13State();
}
class _FittedPulseModerationB13State extends State<FittedPulseModerationB13>{
  bool loading=true,busy=false;
  String? error;
  List<Map<String,dynamic>> items=[];
  @override
  void initState(){super.initState();load();}
  Future<void> load() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try{
      final data=await widget.api.adminPulseReviewQueueB13();
      if(mounted)setState(()=>items=data);
    }catch(_){if(mounted)setState(()=>error=
      'Acceso no disponible. Verifica sesión administrativa, MFA y API.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> decide(Map<String,dynamic> item)async{
    if(busy)return;
    String decision='reject',note='';
    String? problem;
    final id=(item['id']??'').toString();
    final result=await showDialog<Map<String,String>>(context:context,
      builder:(dialog)=>StatefulBuilder(builder:(dialog,update)=>
      AlertDialog(
        title:const FittedText('Evaluación privada · revisión humana'),
        content:SizedBox(width:440,child:SingleChildScrollView(
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            const FittedText('Una discrepancia es una experiencia subjetiva, '              'no evidencia de engaño. No publicar afirmaciones sin revisión.'),
            const SizedBox(height:15),
            DropdownButtonFormField<String>(
              key:const Key('pulse-review-decision'),initialValue:decision,
              items:const [
                DropdownMenuItem(value:'reject',child:Text('Rechazar')),
                DropdownMenuItem(value:'approve',child:Text('Aprobar como observación privada')),
                DropdownMenuItem(value:'remove',child:Text('Retirar')),
              ],
              onChanged:(v){if(v!=null)update(()=>decision=v);}),
            const SizedBox(height:10),
            TextField(key:const Key('pulse-review-note'),
              maxLength:500,maxLines:3,
              onChanged:(s)=>note=s,
              decoration:const InputDecoration(
                labelText:'Justificación auditada (mínimo 5 caracteres)')),
            if(problem!=null)Text(problem!,
              style:const TextStyle(color:Colors.redAccent)),
          ]))),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialog),
            child:const Text('Cancelar')),
          FilledButton(
            key:const Key('pulse-review-confirm'),
            onPressed:(){
              if(note.trim().length<5){
                update(()=>problem='La justificación es obligatoria.');
                return;
              }
              Navigator.pop(dialog,{'decision':decision,'note':note.trim()});
            },child:const Text('Registrar decisión')),
        ],
      )));
    if(result==null||!mounted)return;
    setState(()=>busy=true);
    try {
      final state=await widget.api.adminResolvePulseSignalB13(
        signalId:id,decision:result['decision']!,note:result['note']!);
      if(mounted&&state=='resolved'){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('Resolución auditada y guardada.')));
        await load();
      }
    }catch(_){if(mounted)setState(()=>
      error='No se pudo registrar la resolución; verifica permisos.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const FittedText('Pulso Real · moderación'),actions:[
      IconButton(onPressed:loading?null:load,icon:const Icon(Icons.refresh),
        tooltip:'Actualizar cola'),
    ]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:850),
      child:ListView(padding:const EdgeInsets.all(18),children:[
        const FittedGlassPanel(child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('CONFIANZA SIN JUICIOS AUTOMÁTICOS',
              style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1.2)),
            SizedBox(height:8),
            Text('Las señales son privadas; únicamente un moderador '
              'autorizado o administrador MFA puede revisarlas. '
              'La aprobación nunca las publica automáticamente. '
              'Las apelaciones se revisan por la misma cola.'),
          ])),
        const SizedBox(height:16),
        if(loading)const LinearProgressIndicator(),
        if(error!=null)Text(error!,key:const Key('pulse-admin-error')),
        if(!loading&&items.isEmpty&&error==null)const ListTile(
          key:Key('pulse-admin-empty'),
          title:Text('No hay evaluaciones pendientes.')),
        for(final item in items)
          Card(key:Key('pulse-admin-review-${item['id']}'),
            child:Padding(padding:const EdgeInsets.all(16),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  Text('How I ${item['dimension']} · ${item['review_state']}',
                    style:Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height:6),
                  Text('Señal: ${item['observation']}'),
                  if((item['appeal_note']??'').toString().isNotEmpty)
                    Text('Apelación: ${item['appeal_note']}'),
                  const SizedBox(height:6),
                  const Text('Solo datos internos; la identidad del autor '
                    'no aparece en los perfiles públicos.'),
                  const SizedBox(height:10),
                  FilledButton.icon(onPressed:busy?null:()=>decide(item),
                    icon:const Icon(Icons.fact_check_outlined),
                    label:const Text('Revisar evaluación')),
                ]))),
      ]))),
  );
}
