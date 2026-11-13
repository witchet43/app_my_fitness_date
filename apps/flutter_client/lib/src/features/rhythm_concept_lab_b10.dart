import 'package:flutter/material.dart';
import '../core/rhythm_concept_b10.dart';
import '../core/dating_repository_b11.dart';

/// B10 concept-only study. All values stay in this widget state until close.
/// Never treated as onboarding, a saved lifestyle profile or a real match.
class RhythmConceptLabB10 extends StatefulWidget {
  const RhythmConceptLabB10({super.key,this.repository,this.canSave=false});
  final DatingRepositoryB11? repository;
  final bool canSave;

  @override
  State<RhythmConceptLabB10> createState() => _RhythmConceptLabB10State();
}

const rhythmLabelsB10 = <String,Map<String,String>>{
  'running':{'es':'Running / correr','en':'Running'},
  'strength':{'es':'Fuerza / gimnasio','en':'Strength / gym'},
  'cycling':{'es':'Ciclismo','en':'Cycling'},
  'hyrox':{'es':'HYROX','en':'HYROX'},
  'crossfit':{'es':'CrossFit','en':'CrossFit'},
  'boxing':{'es':'Box','en':'Boxing'},
  'yoga':{'es':'Yoga','en':'Yoga'},
  'pilates':{'es':'Pilates','en':'Pilates'},
  'barre':{'es':'Barre','en':'Barre'},
  'swimming':{'es':'Natación','en':'Swimming'},
  'hiking':{'es':'Senderismo','en':'Hiking'},
  'climbing':{'es':'Escalada','en':'Climbing'},
  'racket':{'es':'Deportes de raqueta','en':'Racket sports'},
  'walking':{'es':'Caminata','en':'Walking'},
  'other':{'es':'Otra actividad','en':'Other activity'},
  'flexible':{'es':'Flexible','en':'Flexible'},
  'two_three':{'es':'2–3 por semana','en':'2–3 per week'},
  'four_five':{'es':'4–5 por semana','en':'4–5 per week'},
  'six_plus':{'es':'6 o más por semana','en':'6 or more per week'},
  'early_morning':{'es':'Muy temprano','en':'Early morning'},
  'morning':{'es':'Mañana','en':'Morning'},
  'midday':{'es':'Mediodía','en':'Midday'},
  'evening':{'es':'Tarde / noche','en':'Evening'},
  'recreational':{'es':'Recreativo','en':'Recreational'},
  'consistent':{'es':'Constante','en':'Consistent'},
  'focused':{'es':'Enfoque de entrenamiento','en':'Training-focused'},
  'competitive':{'es':'Competitivo','en':'Competitive'},
  'solo':{'es':'Solo / sola','en':'Alone'},
  'friends':{'es':'Con amistades','en':'With friends'},
  'partner':{'es':'Con pareja','en':'With a partner'},
  'mixed':{'es':'Mixto','en':'Mixed'},
  'never':{'es':'Nunca','en':'Never'},
  'sometimes':{'es':'A veces','en':'Sometimes'},
  'regularly':{'es':'Habitualmente','en':'Regularly'},
  'home':{'es':'Prefiero estar en casa','en':'Usually home'},
  'sometimes_out':{'es':'Planes ocasionales','en':'Occasional outings'},
  'often_out':{'es':'Salgo con frecuencia','en':'Frequently out'},
  'early_training':{'es':'Entrenar temprano','en':'Early training'},
  'brunch':{'es':'Brunch','en':'Brunch'},
  'nightlife':{'es':'Vida nocturna','en':'Nightlife'},
  'outdoors':{'es':'Aire libre','en':'Outdoors'},
  'recovery':{'es':'Recuperación y descanso','en':'Recovery'},
  'family':{'es':'Tiempo en familia','en':'Family time'},
  'early_bird':{'es':'Madrugo','en':'Early bird'},
  'night_owl':{'es':'Prefiero la noche','en':'Night owl'},
  'prefer_not':{'es':'Prefiero no decir','en':'Prefer not to say'},
  'none':{'es':'No consumo','en':'None'},
  'occasional':{'es':'Ocasional','en':'Occasional'},
  'social':{'es':'Social','en':'Social'},
  'frequent':{'es':'Frecuente','en':'Frequent'},
  'unrestricted':{'es':'Sin restricciones','en':'Unrestricted'},
  'vegetarian':{'es':'Vegetariano/a','en':'Vegetarian'},
  'vegan':{'es':'Vegano/a','en':'Vegan'},
  'train_away':{'es':'Mantengo rutina en viajes','en':'I train while traveling'},
  'rest_and_disconnect':{'es':'Descanso al viajar','en':'I rest when traveling'},
  'music':{'es':'Música','en':'Music'},
  'art':{'es':'Arte','en':'Art'},
  'writing':{'es':'Escritura','en':'Writing'},
  'gaming':{'es':'Videojuegos','en':'Gaming'},
  'cooking':{'es':'Cocina','en':'Cooking'},
  'pets':{'es':'Mascotas','en':'Pets'},
  'concerts':{'es':'Conciertos','en':'Concerts'},
  'books':{'es':'Libros','en':'Books'},
  'culture':{'es':'Cultura','en':'Culture'},
  'long_term':{'es':'Relación a largo plazo','en':'Long-term relationship'},
  'open_to_serious':{'es':'Abierto/a a algo serio','en':'Open to serious'},
  'intentional':{'es':'Citas con intención','en':'Dating intentionally'},
  'exploring':{'es':'Aún explorando','en':'Still exploring'},
  'balanced':{'es':'Equilibrio','en':'Balanced'},
  'more_together':{'es':'Más tiempo juntos','en':'More time together'},
  'independent':{'es':'Valoro independencia','en':'I value independence'},
  'often':{'es':'A menudo','en':'Often'},
  'rarely':{'es':'Rara vez','en':'Rarely'},
  'separately':{'es':'Está bien entrenar por separado','en':'Separate training is great'},
  'not_required':{'es':'No es indispensable','en':'Not a requirement'},
  'nice_to_have':{'es':'Sería agradable','en':'Nice to have'},
  'important':{'es':'Es importante','en':'Important'},
  'exclude_gym':{'es':'A: Excluir mi gimnasio','en':'A: Exclude my gym'},
  'same_gym_different_time':{'es':'B: Evitar mi franja habitual','en':'B: Avoid my usual time window'},
};

class _RhythmConceptLabB10State extends State<RhythmConceptLabB10> {
  bool english = false;
  bool showIdeas = false;
  bool loading = false;
  bool saving = false;
  String? saveNotice;
  String? saveError;
  String scenario = 'cross_sport';
  final answers = emptyRhythmB10();
  final additionalSports = <String>{};
  final weekends = <String>{};
  final interests = <String>{};
  final challenge = TextEditingController();
  final weeknight = TextEditingController();

  final support = TextEditingController();

  @override
  void initState() {
    super.initState();
    if(widget.repository!=null && widget.canSave) loadSaved();
  }

  Future<void> loadSaved() async {
    if(widget.repository==null || !widget.canSave)return;
    setState(()=>loading=true);
    try {
      final doc=await widget.repository!.loadRhythmB11();
      if(!mounted)return;
      if(doc!=null){
        setState((){
          final values=doc['answers'];
          if(values is Map){
            for(final item in values.entries){
              final key=item.key.toString();
              final candidate=item.value.toString();
              if(key!='privacy' &&
                  rhythmOptionsB10[key]?.contains(candidate)==true){
                answers[key]=candidate;
              }
            }
          }
          void restore(String key,Set<String> selected) {
            final raw=doc[key];
            if(raw is! List)return;
            final source=key=='additional_sports'?'sport':
              key=='weekends'?'weekend':'interests';
            selected.clear();
            for(final value in raw){
              if(value is String &&
                  rhythmOptionsB10[source]?.contains(value)==true){
                selected.add(value);
              }
            }
          }
          restore('additional_sports',additionalSports);
          restore('weekends',weekends);
          restore('interests',interests);
          challenge.text=(doc['challenge']??'').toString();
          weeknight.text=(doc['weeknight']??'').toString();
          support.text=(doc['support']??'').toString();
        });
      }
    }catch(_){
      if(mounted)setState(()=>saveError=
        'No se pudieron leer tus ritmos privados.');
    }finally{
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> saveRhythms() async {
    if(saving||!widget.canSave||widget.repository==null)return;
    final issue=validateRhythmB10(answers,
      additionalSports:additionalSports,weekends:weekends,
      interests:interests,challenge:challenge.text,
      weeknight:weeknight.text,support:support.text);
    if(issue!=null){
      setState(()=>saveError='Revisa los campos seleccionados.');
      return;
    }
    final draft=<String,dynamic>{
      'answers':{
        for(final entry in answers.entries)
          if(entry.key!='privacy')entry.key:entry.value,
      },
      'additional_sports':additionalSports.toList()..sort(),
      'weekends':weekends.toList()..sort(),
      'interests':interests.toList()..sort(),
      'challenge':challenge.text.trim(),
      'weeknight':weeknight.text.trim(),
      'support':support.text.trim(),
    };
    setState((){
      saving=true;saveError=null;saveNotice=null;
    });
    try{
      await widget.repository!.saveRhythmB11(draft);
      if(mounted)setState(()=>saveNotice=
        'Tus tres ritmos quedaron guardados de forma privada. '
        'Esto NO activa discovery ni mensajes.');
    }catch(_){
      if(mounted)setState(()=>saveError=
        'No fue posible guardar. Revisa el consentimiento o la conexión.');
    }finally{
      if(mounted)setState(()=>saving=false);
    }
  }

  String tr(String es,String en) => english ? en : es;
  String label(String code) =>
      rhythmLabelsB10[code]?[english?'en':'es'] ?? code;

  @override
  void dispose() {
    challenge.dispose();
    weeknight.dispose();
    support.dispose();
    super.dispose();
  }

  Widget heading(String es,String en,IconData icon) => Padding(
    padding:const EdgeInsets.fromLTRB(0,22,0,12),
    child:Row(children:[
      Icon(icon),
      const SizedBox(width:10),
      Expanded(child:Text(tr(es,en),
        style:Theme.of(context).textTheme.titleLarge)),
    ]),
  );

  Widget select(String field,String es,String en) => Padding(
    padding:const EdgeInsets.only(bottom:14),
    child:DropdownButtonFormField<String>(
      key:ValueKey('b10-$field-${answers[field]}'),
      isExpanded:true,
      initialValue:answers[field],
      decoration:InputDecoration(labelText:tr(es,en)),
      items:[
        for(final option in rhythmOptionsB10[field]!)
          DropdownMenuItem<String>(
            value:option,
            child:Text(label(option),overflow:TextOverflow.ellipsis),
          ),
      ],
      onChanged:(value) {
        if(value==null)return;
        setState((){
          answers[field]=value;
          if(field=='sport')additionalSports.remove(value);
        });
      },
    ),
  );

  Widget multi(String field,Set<String> selected,String es,String en,
      {int max=7}) => Column(
    crossAxisAlignment:CrossAxisAlignment.start,
    children:[
      Padding(padding:const EdgeInsets.only(bottom:8),
        child:Text(tr(es,en))),
      Wrap(spacing:7,runSpacing:6,children:[
        for(final option in rhythmOptionsB10[field]!)
          FilterChip(
            key:Key('b10-$field-$option'),
            label:Text(label(option)),
            selected:selected.contains(option),
            onSelected:(next){
              if(next && selected.length>=max) return;
              if(field=='sport' && next && answers['sport']==option)return;
              setState((){
                if(next){selected.add(option);}else{selected.remove(option);}
              });
            },
          ),
      ]),
      const SizedBox(height:14),
    ],
  );

  Widget paragraphField(String es,String en,TextEditingController controller,
      String field,{int max=120}) => Padding(
    padding:const EdgeInsets.only(bottom:14),
    child:TextField(
      key:Key('b10-$field'),
      controller:controller,
      maxLength:max,
      maxLines:2,
      decoration:InputDecoration(
        labelText:tr(es,en),
        alignLabelWithHint:true,
        helperText:tr('Opcional · sólo esta pantalla',
          'Optional · this screen only'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sample = hypotheticalRhythmB10(scenario);
    final reasons = explainRhythmB10(answers,sample);
    final validation = validateRhythmB10(answers,
      additionalSports:additionalSports,
      weekends:weekends,
      interests:interests,
      challenge:challenge.text,
      weeknight:weeknight.text,
      support:support.text,
    );
    return Scaffold(
      appBar:AppBar(title:Text(tr(
        'Estudio de ritmo · FITTED (concepto)',
        'Rhythm studio · FITTED (concept)'))),
      body:Center(
        child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:820),
          child:ListView(
            key:const Key('b10-lab'),
            padding:const EdgeInsets.all(18),
            children:[
              Card(child:Padding(
                padding:const EdgeInsets.all(18),
                child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    Text('FITTED · Match your rhythm.',
                      style:Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height:9),
                    Text(tr(
                      'Prototipo interactivo del concepto exploratorio. '
                      'No es un perfil guardado, una persona real ni una invitación a citas.',
                      'Interactive exploratory concept. '
                      'Not a saved profile, a real person, or a dating invitation.',
                    ),key:const Key('b10-prototype-only')),
                    const SizedBox(height:9),
                    Text(tr(
                      'Nada de lo escrito aquí sale de esta pantalla. '
                      'No hay fotografías, contacto, gimnasio ni horarios exactos.',
                      'Nothing entered here leaves this screen. '
                      'No photos, contact details, gyms, or exact schedules.',
                    )),
                    SwitchListTile(
                      key:const Key('b10-language'),
                      title:const Text('English / Español'),
                      value:english,
                      onChanged:(v)=>setState(()=>english=v),
                    ),
                  ],
                ),
              )),
              if(loading)const LinearProgressIndicator(),
              if(widget.canSave&&widget.repository!=null)
                Card(child:Padding(
                  padding:const EdgeInsets.all(12),
                  child:Text(tr(
                    'Tus ritmos pueden guardarse con consentimiento separado. '
                    'No se muestran perfiles sin edad verificada.',
                    'Your rhythms can be saved with separate consent. '
                    'No profiles appear without independent age verification.',
                  ),key:const Key('b11-private-persistence')),
                )),
              heading('1. How I Move · Training DNA',
                '1. How I Move · Training DNA',Icons.directions_run_outlined),
              select('sport','Actividad principal','Primary activity'),
              multi('sport',additionalSports,
                'Otras actividades que disfruto','Other activities I enjoy'),
              select('frequency','Frecuencia semanal','Weekly frequency'),
              select('window','Horario general preferido',
                'Preferred general time of day'),
              select('training_mode','Modo actual','Current mode'),
              select('training_with','Prefiero entrenar',
                'I prefer to train'),
              select('competitions','Competiciones',
                'Competition participation'),
              paragraphField('Mi reto actual (opcional)',
                'My current challenge (optional)',challenge,'challenge',max:100),

              heading('2. How I Live · Life Rhythm',
                '2. How I Live · Life Rhythm',Icons.nightlight_outlined),
              select('weekday','Entre semana suelo…',
                'On weekdays I usually…'),
              multi('weekend',weekends,'Mi fin de semana puede incluir',
                'My weekends may include',max:6),
              select('sleep','Ritmo de sueño','Sleep rhythm'),
              select('alcohol','Alcohol (opcional, sin juicios)',
                'Alcohol (optional, no judgment)'),
              select('food','Alimentación (opcional)',
                'Food approach (optional)'),
              select('travel','Cuando viajo',
                'When I travel'),
              multi('interests',interests,
                'Más allá del entrenamiento','Beyond training',max:10),

              heading('3. How I Relate · Relationship Rhythm',
                '3. How I Relate · Relationship Rhythm',
                Icons.favorite_outline),
              select('intent','Qué busco','What I am looking for'),
              select('together','Tiempo juntos e independencia',
                'Togetherness and independence'),
              select('train_partner','Entrenar en pareja',
                'Training with a partner'),
              select('active_importance',
                'Vida activa de mi pareja',
                'How much my partner being active matters'),
              paragraphField('Una noche entre semana en pareja sería…',
                'A weeknight together would look like…',
                weeknight,'weeknight'),
              paragraphField('Durante un bloque de entrenamiento necesito…',
                'During a training block I would need…',
                support,'support'),

              heading('Gym Shield · seguridad del espacio propio',
                'Gym Shield · protect your own space',
                Icons.shield_outlined),
              select('privacy','Modo a estudiar (no guardado)',
                'Mode to explore (not saved)'),
              const SizedBox(height:4),
              ListTile(
                key:const Key('b10-gym-c-locked'),
                leading:const Icon(Icons.lock_outline),
                title:Text(tr(
                  'C: Mismo gimnasio sin restricciones',
                  'C: Same gym without restrictions')),
                subtitle:Text(tr(
                  'No disponible. Requiere análisis de riesgo y aprobación. '
                  'Los controles reales A/B siguen en FitDating.',
                  'Unavailable. Requires threat assessment and approval. '
                  'Actual A/B controls remain in FitDating.',
                )),
              ),
              const Divider(height:32),
              heading('Compatibilidad explicable · simulación',
                'Explainable compatibility · simulation',
                Icons.balance_outlined),
              Text(tr(
                'Comparamos tus selecciones con un ESCENARIO FICTICIO, '
                'no con otra persona ni con datos del servidor. '
                'Las razones explican hábitos, no un porcentaje de atractivo.',
                'We compare your selections with a FICTIONAL SCENARIO, '
                'not a person or server data. Reasons explain lifestyle, '
                'not an attractiveness percentage.',
              ),key:const Key('b10-fiction-disclaimer')),
              const SizedBox(height:14),
              DropdownButtonFormField<String>(
                key:const Key('b10-scenario'),
                initialValue:scenario,
                isExpanded:true,
                decoration:InputDecoration(
                  labelText:tr('Escenario de demostración',
                    'Demonstration scenario')),
                items:[
                  DropdownMenuItem(
                    value:'cross_sport',
                    child:Text(tr('Yoga y ritmo similar',
                      'Yoga with a similar rhythm'))),
                  DropdownMenuItem(
                    value:'same_sport_other_rhythm',
                    child:Text(tr('Running y ritmos diferentes',
                      'Running with different rhythms'))),
                ],
                onChanged:(value){
                  if(value!=null)setState(()=>scenario=value);
                },
              ),
              const SizedBox(height:12),
              if(validation!=null)
                Text(tr('Revisa los campos de la simulación.',
                  'Review the simulation fields.')),
              for(final reason in reasons)
                Card(
                  key:Key('b10-reason-${reason.layer}-${reasons.indexOf(reason)}'),
                  child:ListTile(
                    leading:Icon(reason.importance=='high'
                      ?Icons.favorite_border:Icons.tips_and_updates_outlined),
                    title:Text(reason.message(english:english)),
                    subtitle:Text(tr(
                      reason.importance=='high'
                        ?'Importancia alta para el ritmo (hipótesis)'
                        :reason.importance=='medium'
                          ?'Actividad: importancia media (hipótesis)'
                          :'Mismo deporte: importancia baja (hipótesis)',
                      reason.importance=='high'
                        ?'Higher importance for lifestyle (hypothesis)'
                        :reason.importance=='medium'
                          ?'Activity: medium importance (hypothesis)'
                          :'Same sport: low importance (hypothesis)',
                    )),
                  ),
                ),
              const SizedBox(height:12),
              OutlinedButton.icon(
                key:const Key('b10-active-date-ideas'),
                onPressed:()=>setState(()=>showIdeas=!showIdeas),
                icon:const Icon(Icons.lightbulb_outline),
                label:Text(tr('Ver ideas hipotéticas de Active Date',
                  'View hypothetical Active Date ideas')),
              ),
              if(showIdeas) ...[
                Text(tr(
                  'Sólo después de un match mutuo real, nunca antes. '
                  'No son reservaciones ni ubicaciones reales.',
                  'Only after a real mutual match, never before. '
                  'These are not bookings or real locations.',
                ),key:const Key('b10-after-mutual')),
                for(final idea in hypotheticalActiveDatesB10(answers,sample))
                  ListTile(
                    leading:const Icon(Icons.park_outlined),
                    title:Text(switch(idea){
                      'yoga_brunch'=>tr('Yoga + brunch','Yoga + brunch'),
                      'museum_walk'=>tr('Museo + caminata','Museum + walk'),
                      'outdoor_market'=>tr('Mercado al aire libre',
                        'Outdoor market'),
                      _=>tr('Caminata + café','Walk + coffee'),
                    }),
                  ),
              ],
              if(widget.canSave&&widget.repository!=null)...[
                const SizedBox(height:18),
                FilledButton.icon(
                  key:const Key('b11-save-rhythm'),
                  onPressed:saving||loading?null:saveRhythms,
                  icon:const Icon(Icons.lock_outline),
                  label:Text(tr('Guardar mis tres ritmos privados',
                    'Save my three private rhythms')),
                ),
                if(saveNotice!=null)
                  Text(saveNotice!,key:const Key('b11-save-success')),
                if(saveError!=null)
                  Text(saveError!,key:const Key('b11-save-error')),
              ]else
                Text(tr('Para guardar, acepta primero el consentimiento '
                    'separado de FitDating.',
                  'To save, first accept the separate FitDating consent.'),
                  key:const Key('b11-consent-before-save')),
              const SizedBox(height:18),
              Text(tr(
                'Estado: propuesta no validada. '
                'No se permiten discovery real, fotos, swipe, '
                'match, chat ni envíos hasta cumplir los gates legales, '
                'verificación independiente de edad y moderación.',
                'Status: unvalidated proposal. '
                'No real discovery, photos, swipes, matches, chats, or sending '
                'until legal, independent age verification and moderation '
                'gates are approved.',
              ),key:const Key('b10-locked-policy')),
              const SizedBox(height:32),
            ],
          ),
        ),
      ),
    );
  }
}
