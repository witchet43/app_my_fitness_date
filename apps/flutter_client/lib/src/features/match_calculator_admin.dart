import 'package:flutter/material.dart';
import '../core/fitted_match_engine.dart';

/// Owner-only entry point: parent is gated with remote role + MFA/AAL2.
/// These are sample, synthetic profiles, never real private member data.
class MatchCalculatorAdmin extends StatefulWidget {
  const MatchCalculatorAdmin({super.key});
  @override
  State<MatchCalculatorAdmin> createState()=>_MatchCalculatorAdminState();
}

class _MatchCalculatorAdminState extends State<MatchCalculatorAdmin> {
  Map<String,int> weights=FittedMatchEngine.defaults;
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
        const Text('Calculadora del match',
          style:TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        const Text('Simulador auditable con perfiles ficticios. '
          'Un mismo deporte no es requisito: intención, estilo de vida, '
          'entrenamiento, recuperación y autonomía se ponderan juntos.'),
        const SizedBox(height:18),
        Row(children:[
          Expanded(child:Text('Ponderaciones · total 100 %',
            style:Theme.of(context).textTheme.titleLarge)),
          TextButton(onPressed:()=>setState(
            ()=>weights=FittedMatchEngine.defaults),child:const Text('Restaurar')),
        ]),
        for(final f in FittedMatchEngine.factors)...[
          Row(children:[
            Expanded(child:Text(language=='en'?f.en:f.es)),
            Text('${weights[f.id]} %',key:Key('weight-${f.id}')),
          ]),
          Slider(
            key:Key('weight-slider-${f.id}'),
            value:weights[f.id]!.toDouble(),
            min:0,max:100,divisions:100,
            label:'${weights[f.id]} %',
            onChanged:(v)=>adjust(f.id,v.round()),
          ),
        ],
        const Divider(),
        Wrap(spacing:12,runSpacing:12,children:[
          ChoiceChip(
            key:const Key('cross-sport-scenario'),
            label:const Text('Running + gym'),
            selected:complementary,
            onSelected:(_)=>setState(()=>complementary=true)),
          ChoiceChip(
            key:const Key('same-sport-scenario'),
            label:const Text('Running + running (otras prioridades)'),
            selected:!complementary,
            onSelected:(_)=>setState(()=>complementary=false)),
          SegmentedButton<String>(
            segments:const [
              ButtonSegment(value:'es',label:Text('ES')),
              ButtonSegment(value:'en',label:Text('EN')),
            ],
            selected:{language},
            onSelectionChanged:(s)=>setState(()=>language=s.first)),
        ]),
        const SizedBox(height:22),
        if(result!=null)...[
          Text('${result.percent} %',
            key:const Key('calculated-match-percent'),
            style:Theme.of(context).textTheme.displayMedium),
          Text(language=='en'?'Illustrative compatibility':
            'Compatibilidad ilustrativa'),
          const SizedBox(height:8),
          Text('Cobertura de factores: ${result.coverage} %'),
          const SizedBox(height:12),
          for(final reason in result.reasonCodes.values)
            Padding(padding:const EdgeInsets.symmetric(vertical:4),
              child:Row(children:[
                const Icon(Icons.check_circle_outline,size:19),
                const SizedBox(width:8),
                Expanded(child:Text(explainMatchReason(
                  reason,language:language))),
              ])),
        ]else const Text('Se requieren suficientes respuestas para calcular.'),
        const SizedBox(height:18),
        const Text('Prototipo de cálculo, no política activa en producción. '
          'Las ponderaciones y resultados aquí son simulados: '
          'su publicación requiere guardar una versión en el servidor, '
          'auditoría MFA y evaluar las restricciones de seguridad.'),
      ],
    );
  }
}
