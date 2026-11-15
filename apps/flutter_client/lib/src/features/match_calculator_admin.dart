import '../core/fitted_locale.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/fitted_match_engine.dart';

/// Owner-only entry point: parent is gated with remote role + MFA/AAL2.
/// These are sample, synthetic profiles, never real private member data.
class MatchCalculatorAdmin extends StatefulWidget {
  const MatchCalculatorAdmin({super.key,required this.client});
  final SupabaseClient client;
  @override
  State<MatchCalculatorAdmin> createState()=>_MatchCalculatorAdminState();
}

class _MatchCalculatorAdminState extends State<MatchCalculatorAdmin> {
  Map<String,int> weights=FittedMatchEngine.defaults;
  int? serverVersion;
  bool saving=false;
  bool loading=true;
  String? policyMessage;

  @override
  void initState(){super.initState();loadPolicy();}

  Future<void> loadPolicy() async {
    try {
      final response=await widget.client.rpc('admin_fitted_match_policy_get');
      if(response is! Map || response['status']!='ok')throw StateError('Role gate');
      final raw=Map<String,dynamic>.from(response['weights'] as Map);
      final values=raw.map((key,value)=>MapEntry(key,(value as num).toInt()));
      if(!FittedMatchEngine.validWeights(values))throw StateError('Invalid weights');
      if(mounted)setState((){
        weights=values;serverVersion=(response['version'] as num).toInt();
        loading=false;policyMessage=null;
      });
    } catch (_) {
      if(mounted)setState((){
        loading=false;serverVersion=null;
        policyMessage='No se pudo cargar la configuración. Verifica MFA y la migración del servidor.';
      });
    }
  }

  Future<void> savePolicy() async {
    if(serverVersion==null||saving)return;
    setState((){saving=true;policyMessage=null;});
    try {
      final response=await widget.client.rpc('admin_fitted_match_policy_save',params:{
        'p_weights':weights,'p_expected_version':serverVersion,
      });
      if(response is! Map||response['status']!='saved'){
        throw StateError('Conflict or denied');
      }
      if(mounted)setState((){
        serverVersion=(response['version'] as num).toInt();
        policyMessage='Política guardada y auditada (versión $serverVersion). No activa citas.';
      });
    }catch(_){
      if(mounted)setState(()=>policyMessage='No se guardó: verifica MFA o recarga la versión activa.');
    }finally{if(mounted)setState(()=>saving=false);}
  }
  String language='es';
  bool complementary=true;

  static const runner = <String,String>{
    'sport':'running','intent':'long_term','weekday':'home',
    'travel':'flexible','frequency':'four_five',
    'training_mode':'consistent','sleep':'early_bird',
    'together':'balanced','train_partner':'sometimes',
  };
  static const gym = <String,String>{
    'sport':'strength','intent':'open_to_serious','weekday':'home',
    'travel':'train_away','frequency':'four_five',
    'training_mode':'focused','sleep':'early_bird',
    'together':'balanced','train_partner':'sometimes',
  };
  static const otherRunner = <String,String>{
    'sport':'running','intent':'exploring','weekday':'often_out',
    'travel':'rest_and_disconnect','frequency':'six_plus',
    'training_mode':'competitive','sleep':'night_owl',
    'together':'independent','train_partner':'separately',
  };

  void adjust(String id,int selected) {
    final rest=FittedMatchEngine.factors.where((f)=>f.id!=id).toList();
    final remaining=100-selected;
    final oldTotal=rest.fold<int>(0,(sum,f)=>sum+(weights[f.id]??0));
    final next=<String,int>{id:selected};
    var used=0;
    for(var i=0;i<rest.length;i++){
      final value=i==rest.length-1
        ? remaining-used
        : oldTotal>0
          ? (remaining*(weights[rest[i].id]!)/oldTotal).round()
          : (remaining/rest.length).floor();
      next[rest[i].id]=value.clamp(0,remaining-used);
      used+=next[rest[i].id]!;
    }
    setState(()=>weights=next);
  }

  @override
  Widget build(BuildContext context) {
    final result=FittedMatchEngine.evaluate(
      a:runner,b:complementary?gym:otherRunner,weights:weights);
    return ListView(
      key:const Key('match-calculator-admin'),
      padding:const EdgeInsets.all(24),
      children:[
        const FittedText('Calculadora del match',
          style:TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        const FittedText('Simulador auditable con perfiles ficticios. '
          'Un mismo deporte no es requisito: intención, estilo de vida, '
          'entrenamiento, recuperación y autonomía se ponderan juntos.'),
        if(loading)const LinearProgressIndicator(),
        if(policyMessage!=null)Padding(
          padding:const EdgeInsets.symmetric(vertical:12),
          child:FittedText(policyMessage!)),
        const SizedBox(height:18),
        Row(children:[
          Expanded(child:FittedText('Ponderaciones · total 100 %',
            style:Theme.of(context).textTheme.titleLarge)),
          TextButton(onPressed:()=>setState(
            ()=>weights=FittedMatchEngine.defaults),child:const FittedText('Restaurar')),
        ]),
        for(final f in FittedMatchEngine.factors)...[
          Row(children:[
            Expanded(child:FittedText(language=='en'?f.en:f.es)),
            FittedText('${weights[f.id]} %',key:Key('weight-${f.id}')),
          ]),
          Slider(
            key:Key('weight-slider-${f.id}'),
            value:weights[f.id]!.toDouble(),
            min:0,max:100,divisions:100,
            label:'${weights[f.id]} %',
            onChanged:(v)=>adjust(f.id,v.round()),
          ),
        ],
        FilledButton.icon(
          key:const Key('save-match-policy'),
          onPressed:serverVersion==null||saving?null:savePolicy,
          icon:const Icon(Icons.verified_outlined),
          label:FittedText(saving?'Guardando…':'Guardar ponderaciones · requiere MFA'),
        ),
        const Divider(),
        Wrap(spacing:12,runSpacing:12,children:[
          ChoiceChip(
            key:const Key('cross-sport-scenario'),
            label:const FittedText('Running + gym'),
            selected:complementary,
            onSelected:(_)=>setState(()=>complementary=true)),
          ChoiceChip(
            key:const Key('same-sport-scenario'),
            label:const FittedText('Running + running (otras prioridades)'),
            selected:!complementary,
            onSelected:(_)=>setState(()=>complementary=false)),
          SegmentedButton<String>(
            segments:const [
              ButtonSegment(value:'es',label:FittedText('ES')),
              ButtonSegment(value:'en',label:FittedText('EN')),
            ],
            selected:{language},
            onSelectionChanged:(s)=>setState(()=>language=s.first)),
        ]),
        const SizedBox(height:22),
        if(result!=null)...[
          FittedText('${result.percent} %',
            key:const Key('calculated-match-percent'),
            style:Theme.of(context).textTheme.displayMedium),
          FittedText(language=='en'?'Illustrative compatibility':
            'Compatibilidad ilustrativa'),
          const SizedBox(height:8),
          FittedText('Cobertura de factores: ${result.coverage} %'),
          const SizedBox(height:12),
          for(final reason in result.reasonCodes.values)
            Padding(padding:const EdgeInsets.symmetric(vertical:4),
              child:Row(children:[
                const Icon(Icons.check_circle_outline,size:19),
                const SizedBox(width:8),
                Expanded(child:FittedText(explainMatchReason(
                  reason,language:language))),
              ])),
        ]else const FittedText('Se requieren suficientes respuestas para calcular.'),
        const SizedBox(height:18),
        const FittedText('Prototipo de cálculo, no política activa en producción. '
          'Las ponderaciones y resultados aquí son simulados: '
          'guardar ponderaciones NO activa el descubrimiento real. '
          'Faltan evaluación y controles de seguridad del motor.'),
      ],
    );
  }
}
