import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/fitted_locale.dart';
import '../core/fitted_match_engine.dart';
import '../theme/fitness_date_theme.dart';

/// Single in-app admin studio. Backend independently verifies owner + MFA.
/// Synthetic inputs never leak actual members' answers.
class MatchCalculatorAdmin extends StatefulWidget {
  const MatchCalculatorAdmin({super.key,required this.client});
  final SupabaseClient client;
  @override
  State<MatchCalculatorAdmin> createState()=>_MatchCalculatorAdminState();
}
class _MatchCalculatorAdminState extends State<MatchCalculatorAdmin> {
  Map<String,int> weights=FittedMatchEngine.defaults;
  int? serverVersion;
  int? distanceKm;
  bool saving=false,loading=true,complementary=true;
  String? policyMessage;
  bool get english=>FittedLocaleScope.languageOf(context)=='en';
  String tr(String es,String en)=>english?en:es;

  static const runner=<String,String>{
    'sport':'running','intent':'long_term','weekday':'home',
    'travel':'flexible','frequency':'four_five',
    'training_mode':'consistent','sleep':'early_bird',
    'together':'balanced','train_partner':'sometimes',
    'competitions':'sometimes','alcohol':'occasional',
  };
  static const gym=<String,String>{
    'sport':'strength','intent':'open_to_serious','weekday':'home',
    'travel':'train_away','frequency':'four_five',
    'training_mode':'focused','sleep':'early_bird',
    'together':'balanced','train_partner':'sometimes',
    'competitions':'sometimes','alcohol':'occasional',
  };
  static const otherRunner=<String,String>{
    'sport':'running','intent':'exploring','weekday':'often_out',
    'travel':'rest_and_disconnect','frequency':'six_plus',
    'training_mode':'competitive','sleep':'night_owl',
    'together':'independent','train_partner':'separately',
    'competitions':'regularly','alcohol':'social',
  };

  @override
  void initState(){super.initState();loadPolicy();}
  Future<void> loadPolicy()async{
    if(mounted)setState(()=>loading=true);
    try{
      final data=await widget.client.rpc('admin_fitted_match_policy_get');
      if(data is! Map || data['status']!='ok'){
        throw StateError('Owner or MFA missing');
      }
      final values=Map<String,int>.from(
        (data['weights'] as Map).map(
          (k,v)=>MapEntry(k.toString(),(v as num).toInt())));
      if(!FittedMatchEngine.validWeights(values)){
        throw StateError('Invalid stored weights');
      }
      if(!mounted)return;
      setState((){
        weights=values;serverVersion=(data['version'] as num).toInt();
        distanceKm=(data['max_distance_km'] as num?)?.toInt();
        loading=false;policyMessage=null;
      });
    }catch(_){
      if(mounted)setState((){
        serverVersion=null;loading=false;
        policyMessage=tr(
          'No se pudo cargar la política. Comprueba tu rol, MFA y la conexión.',
          'Could not load policy. Verify your role, MFA and connection.');
      });
    }
  }

  /// Allocate integer weights using largest remainders, preserving exact 100.
  Map<String,int> _distribute(Map<String,int> scores){
    if(scores.isEmpty)return {};
    final total=scores.values.fold<int>(0,(a,b)=>a+b);
    if(total<=0)return {};
    final result=<String,int>{};
    final remainders=<String,double>{};
    var used=0;
    for(final item in scores.entries){
      final raw=100*item.value/total;
      final whole=raw.floor();
      result[item.key]=whole;used+=whole;
      remainders[item.key]=raw-whole;
    }
    final ordered=scores.keys.toList()..sort((a,b){
      final x=remainders[b]!.compareTo(remainders[a]!);
      return x==0?a.compareTo(b):x;
    });
    for(var i=0;i<100-used;i++){
      result[ordered[i%ordered.length]]=result[ordered[i%ordered.length]]!+1;
    }
    return result;
  }
  void addFactor(String id){
    if(weights.containsKey(id))return;
    setState(()=>weights=_distribute({...weights,id:12}));
  }
  void removeFactor(String id){
    if(weights.length<=3)return;
    final remaining=Map<String,int>.from(weights)..remove(id);
    setState(()=>weights=_distribute(remaining));
  }
  void adjust(String id,int selected){
    final others=<String,int>{
      for(final e in weights.entries)if(e.key!=id)e.key:e.value,
    };
    if(others.isEmpty)return;
    final available=100-selected;
    final parts=_distribute(others);
    final target=<String,int>{id:selected};
    var used=0;
    final order=others.keys.toList();
    for(var i=0;i<order.length;i++){
      final v=i==order.length-1
        ?available-used
        :(available*parts[order[i]]!/100).round();
      final value=v.clamp(0,available-used);
      target[order[i]]=value;used+=value;
    }
    setState(()=>weights=target);
  }
  void importance(String id,int tier){
    final chosen=tier==3?30:tier==2?17:7;
    adjust(id,chosen);
  }
  int tierFor(int weight)=>weight>=24?3:weight>=12?2:1;

  Future<void> savePolicy()async{
    if(serverVersion==null||saving||
      !FittedMatchEngine.validWeights(weights))return;
    setState((){saving=true;policyMessage=null;});
    try{
      final response=await widget.client.rpc(
        'admin_fitted_match_policy_save',
        params:{
          'p_weights':weights,
          'p_expected_version':serverVersion,
          'p_max_distance_km':distanceKm,
        },
      );
      if(response is! Map||response['status']!='saved'){
        throw StateError('conflict or unauthorized');
      }
      if(mounted)setState((){
        serverVersion=(response['version'] as num).toInt();
        policyMessage=tr(
          'Política guardada y auditada (versión $serverVersion). '
          'El descubrimiento sigue restringido.',
          'Policy saved and audited (version $serverVersion). '
          'Discovery remains restricted.');
      });
    }catch(_){
      if(mounted)setState(()=>policyMessage=tr(
        'No se guardó: verifica MFA o recarga la versión activa.',
        'Save failed: verify MFA or reload the active version.'));
    }finally{if(mounted)setState(()=>saving=false);}
  }

  Widget factorTile(MatchFactor f){
    final w=weights[f.id]!;
    final en=english;
    final levels=[
      (1,tr('Baja','Low')),
      (2,tr('Media','Medium')),
      (3,tr('Alta','High')),
    ];
    return Card(
      key:Key('match-factor-${f.id}'),
      child:Padding(
        padding:const EdgeInsets.all(14),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Icon(Icons.tune,size:19,color:FitDateColors.lilac),
            const SizedBox(width:10),
            Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(en?f.en:f.es,
                  style:Theme.of(context).textTheme.titleSmall),
                Text(en?f.descriptionEn:f.descriptionEs,
                  style:Theme.of(context).textTheme.bodySmall),
              ])),
            IconButton(
              key:Key('remove-factor-${f.id}'),
              onPressed:weights.length>3?()=>removeFactor(f.id):null,
              tooltip:tr('Quitar factor','Remove factor'),
              icon:const Icon(Icons.close)),
          ]),
          const SizedBox(height:8),
          Wrap(spacing:7,runSpacing:5,crossAxisAlignment:WrapCrossAlignment.center,
            children:[
              for(final level in levels)
                ChoiceChip(
                  key:Key('importance-${f.id}-${level.$1}'),
                  label:Text(level.$2),
                  selected:tierFor(w)==level.$1,
                  onSelected:(_)=>importance(f.id,level.$1)),
              Padding(
                padding:const EdgeInsets.only(left:4),
                child:Text('$w%',
                  key:Key('weight-${f.id}'),
                  style:Theme.of(context).textTheme.titleMedium)),
            ]),
          Slider(
            key:Key('weight-slider-${f.id}'),
            value:w.toDouble(),min:0,max:100,divisions:100,
            label:'$w%',
            onChanged:(v)=>adjust(f.id,v.round())),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final r=FittedMatchEngine.evaluate(
      a:runner,b:complementary?gym:otherRunner,weights:weights,
      aInterests:const {'music','outdoors','culture'},
      bInterests:complementary
        ?const {'music','cooking','culture'}
        :const {'gaming','pets','writing'});
    final unused=FittedMatchEngine.factors
      .where((f)=>!weights.containsKey(f.id)).toList();
    return ListView(
      key:const Key('match-calculator-admin'),
      padding:const EdgeInsets.all(20),children:[
        Text(tr('Calculadora del match','Match Calculator'),
          style:Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height:9),
        Text(tr(
          'Compatibilidad antes que igualdad. Diseña una política transparente '
          'y pruébala con personas ficticias antes de guardarla.',
          'Compatibility before sameness. Design a transparent policy and '
          'test it with fictional people before saving.')),
        const SizedBox(height:15),
        Card(child:Padding(padding:const EdgeInsets.all(16),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Expanded(child:Text(tr('Factores activos','Active factors'),
                style:Theme.of(context).textTheme.titleLarge)),
              Text('${weights.values.fold<int>(0,(a,b)=>a+b)} / 100%',
                key:const Key('match-weight-total'),
                style:Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height:8),
            Text(tr('Las etiquetas Alta, Media y Baja proponen un peso. '
              'Puedes ajustar los porcentajes; el total se recalcula a 100%.',
              'High, Medium and Low suggest a weight. Fine-tune percentages; '
              'the total is automatically balanced to 100%.')),
            const SizedBox(height:12),
            if(loading)const LinearProgressIndicator(),
            if(policyMessage!=null)Padding(
              padding:const EdgeInsets.only(bottom:8),
              child:Text(policyMessage!)),
            Wrap(spacing:9,runSpacing:8,children:[
              PopupMenuButton<String>(
                key:const Key('add-match-factor'),
                enabled:unused.isNotEmpty&&!loading,
                tooltip:tr('Añadir factor','Add factor'),
                onSelected:addFactor,
                itemBuilder:(_)=>[
                  for(final f in unused)
                    PopupMenuItem(value:f.id,
                      child:Text(english?f.en:f.es)),
                ],
                child:Chip(
                  avatar:const Icon(Icons.add,size:18),
                  label:Text(tr('Agregar parámetro','Add factor'))),
              ),
              ActionChip(
                label:Text(tr('Restaurar ponderaciones','Reset weights')),
                onPressed:()=>setState(
                  ()=>weights=FittedMatchEngine.defaults)),
              ActionChip(
                label:Text(tr('Recargar política','Reload policy')),
                onPressed:loadPolicy),
            ]),
          ]),
        )),
        const SizedBox(height:8),
        for(final f in FittedMatchEngine.factors)
          if(weights.containsKey(f.id))factorTile(f),
        const SizedBox(height:9),
        Card(child:Padding(padding:const EdgeInsets.all(15),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(tr('Distancia: filtro, no puntuación',
              'Distance: filter, not score'),
              style:Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:7),
            Text(tr(
              'Define un radio operativo futuro, independiente del porcentaje. '
              'No usaremos ubicaciones exactas ni lo aplicaremos a candidatos '
              'sin una validación regional de privacidad y cobertura.',
              'Set a future operational radius, independent of the score. '
              'No precise locations or candidate filtering without regional '
              'privacy and coverage validation.')),
            const SizedBox(height:9),
            DropdownButtonFormField<int>(
              key:ValueKey('distance-${distanceKm??0}'),
              initialValue:distanceKm,
              decoration:InputDecoration(
                labelText:tr('Radio regional previsto','Planned regional radius')),
              items:[
                DropdownMenuItem<int>(
                  value:null,child:Text(tr('Sin definir','Not configured'))),
                for(final km in [10,20,50,100,250])
                  DropdownMenuItem(value:km,child:Text('$km km')),
              ],
              onChanged:(v)=>setState(()=>distanceKm=v)),
          ]),
        )),
        const SizedBox(height:12),
        FilledButton.icon(
          key:const Key('save-match-policy'),
          onPressed:serverVersion==null||saving||loading||
            !FittedMatchEngine.validWeights(weights)?null:savePolicy,
          icon:const Icon(Icons.lock_outline),
          label:Text(saving?tr('Guardando…','Saving…'):
            tr('Guardar política · MFA','Save policy · MFA'))),
        const Divider(height:36),
        Text(tr('Laboratorio de compatibilidad',
          'Compatibility studio'),
          style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:10),
        Wrap(spacing:8,runSpacing:8,children:[
          ChoiceChip(
            key:const Key('cross-sport-scenario'),
            label:Text(tr('Running + gimnasio','Running + gym')),
            selected:complementary,
            onSelected:(_)=>setState(()=>complementary=true)),
          ChoiceChip(
            key:const Key('same-sport-scenario'),
            label:Text(tr('Mismo deporte, ritmos distintos',
              'Same sport, different rhythms')),
            selected:!complementary,
            onSelected:(_)=>setState(()=>complementary=false)),
        ]),
        const SizedBox(height:14),
        if(r==null)
          Text(tr('No hay cobertura suficiente para calcular. '
            'Se requiere evidencia sobre intención y hábitos.',
            'Insufficient evidence to score. Relationship intent and '
            'lifestyle evidence are required.'))
        else Card(child:Padding(padding:const EdgeInsets.all(18),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Text('${r.percent}%',
                key:const Key('calculated-match-percent'),
                style:Theme.of(context).textTheme.displayMedium),
              const SizedBox(width:12),
              Expanded(child:Text(tr(
                'Compatibilidad simulada y explicable',
                'Simulated, explainable compatibility'),
                style:Theme.of(context).textTheme.titleMedium)),
            ]),
            Text(tr('Cobertura de evidencia: ${r.coverage}%',
              'Evidence coverage: ${r.coverage}%')),
            const SizedBox(height:14),
            for(final f in FittedMatchEngine.factors)
              if(r.factors.containsKey(f.id))...[
                Row(children:[
                  Expanded(child:Text(english?f.en:f.es)),
                  Text('${weights[f.id]??0}% · '
                    '${r.factors[f.id]!.round()}% '+
                    tr('alineación','alignment')),
                ]),
                LinearProgressIndicator(
                  value:r.factors[f.id]!/100,
                  minHeight:5,color:FitDateColors.lilac),
                Padding(padding:const EdgeInsets.fromLTRB(0,6,0,13),
                  child:Text(explainMatchReason(
                    r.reasonCodes[f.id]!,language:english?'en':'es'),
                    style:Theme.of(context).textTheme.bodySmall)),
              ],
            Text(tr('El porcentaje se calcula como promedio ponderado '
              'de los factores con respuestas suficientes; no es una '
              'probabilidad de éxito romántico.',
              'This score is the weighted average of supported evidence; '
              'it is not a probability of relationship success.'),
              style:Theme.of(context).textTheme.bodySmall),
          ]),
        )),
        const SizedBox(height:14),
        Text(tr('Esta pantalla utiliza casos ficticios. Las políticas guardadas '
          'no activan el descubrimiento real: elegibilidad, edad, '
          'seguridad y Gym Shield conservan sus restricciones.',
          'This studio uses fictional profiles. Saving a policy never '
          'enables real dating discovery; eligibility, age, safety and '
          'Gym Shield restrictions remain in force.')),
      ],
    );
  }
}
