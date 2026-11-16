import '../core/fitted_locale.dart';
import 'package:flutter/material.dart';
import '../core/rhythm_concept_b10.dart';
import '../core/dating_repository_b11.dart';

/// B10 concept-only study. All values stay in this widget state until close.
/// Never treated as onboarding, a saved lifestyle profile or a real match.
class RhythmConceptLabB10 extends StatefulWidget {
  const RhythmConceptLabB10({super.key,this.repository,this.canSave=false,
    this.profileMode=false,this.initialPillar=0})
    :assert(initialPillar>=0 && initialPillar<=2);
  /// Open the requested real saved-profile section, not a preview.
  final int initialPillar;
  final DatingRepositoryB11? repository;
  final bool canSave;
  final bool profileMode;

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
  int activePillar=0;
  bool showIdeas = false;
  bool loading = false;
  bool saving = false;
  String? saveNotice;
  String? saveError;
  String scenario = 'cross_sport';
  late final Map<String,String> answers;
  final additionalSports = <String>{};
  final weekends = <String>{};
  final interests = <String>{};
  final challenge = TextEditingController();
  final weeknight = TextEditingController();

  final support = TextEditingController();

  @override
  void initState() {
    super.initState();
    activePillar=widget.initialPillar;
    // Saved answers are user declarations; never count preview defaults as facts.
    answers=widget.profileMode?<String,String>{}:emptyRhythmB10();
    if(widget.repository!=null && widget.canSave) loadSaved();
  }

  @override
  void didUpdateWidget(covariant RhythmConceptLabB10 oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.initialPillar!=widget.initialPillar){
      // The page may be reused during navigation/restoration.
      activePillar=widget.initialPillar;
    }
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(widget.profileMode)english=FittedLocaleScope.languageOf(context)=='en';
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

  Widget profileProgress(){
    final identifiers=english
      ?const ['How I Move','How I Live','How I Relate']
      :const ['Cómo me muevo','Cómo vivo','Cómo me relaciono'];
    const icons=[Icons.directions_run_outlined,Icons.wb_sunny_outlined,
      Icons.people_outline];
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(tr('Tu perfil en tres dimensiones','Your profile in three dimensions'),
        style:Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height:8),
      Text(tr('No necesitas practicar el mismo deporte para conectar. '
        'Cuenta cómo te mueves, vives y te relacionas.',
        'You do not need the same sport to connect. '
        'Share how you move, live and relate.')),
      const SizedBox(height:16),
      Row(children:[
        for(var i=0;i<3;i++)Expanded(
          child:Padding(
            padding:EdgeInsets.only(right:i==2?0:8),
            child:InkWell(
              key:Key('pillar-tab-$i'),
              borderRadius:BorderRadius.circular(16),
              onTap:()=>setState(()=>activePillar=i),
              child:AnimatedContainer(
                duration:const Duration(milliseconds:200),
                padding:const EdgeInsets.symmetric(vertical:16,horizontal:6),
                decoration:BoxDecoration(
                  color:i==activePillar
                    ?Theme.of(context).colorScheme.primaryContainer
                    :Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius:BorderRadius.circular(16),
                  border:Border.all(color:i==activePillar
                    ?Theme.of(context).colorScheme.primary
                    :Colors.transparent)),
                child:Column(children:[
                  Icon(icons[i],size:25),
                  const SizedBox(height:7),
                  Text('0${i+1}',style:Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height:3),
                  Text(identifiers[i],textAlign:TextAlign.center,
                    style:Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight:i==activePillar
                        ?FontWeight.w800:FontWeight.w500)),
                ]),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height:10),
      LinearProgressIndicator(value:(activePillar+1)/3,minHeight:4,
        borderRadius:BorderRadius.circular(4)),
      const SizedBox(height:12),
      Row(children:[
        const Icon(Icons.lock_outline,size:16),
        const SizedBox(width:8),
        Expanded(child:Text(tr(
          'Tus respuestas son privadas. Tus gimnasios y horarios exactos '
          'no se muestran a otras personas.',
          'Your answers stay private. Exact gym locations and schedules '
          'are never shown to others.'),
          style:Theme.of(context).textTheme.bodySmall)),
      ]),
    ]);
  }

  Widget profileActions()=>Padding(
    padding:const EdgeInsets.only(top:18,bottom:16),
    child:Row(children:[
      if(activePillar>0)
        OutlinedButton.icon(
          key:const Key('pillar-back'),
          onPressed:()=>setState(()=>activePillar--),
          icon:const Icon(Icons.arrow_back),
          label:Text(tr('Anterior','Back'))),
      const Spacer(),
      if(activePillar<2)
        FilledButton.icon(
          key:const Key('pillar-next'),
          onPressed:()=>setState(()=>activePillar++),
          icon:const Icon(Icons.arrow_forward),
          label:Text(tr('Siguiente','Next'))),
      if(activePillar==2)
        FilledButton.icon(
          key:const Key('pillars-save'),
          onPressed:saving||loading||!widget.canSave?null:saveRhythms,
          icon:const Icon(Icons.lock_outline),
          label:Text(tr('Guardar mis tres pilares','Save my three pillars'))),
    ]),
  );

  Widget profileSections()=>Column(
    crossAxisAlignment:CrossAxisAlignment.stretch,
    children:[
      profileProgress(),
      const SizedBox(height:16),
      Card(clipBehavior:Clip.antiAlias,child:Padding(
        padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(activePillar==0)...[
            Text(tr('Tu semana en movimiento',
              'Your week in motion'),
              style:Theme.of(context).textTheme.bodyMedium),
            heading('Cómo me muevo · Mi actividad',
              'How I Move · Training DNA',Icons.directions_run_outlined),
            profileSelect('sport','Actividad principal','Primary activity'),
            multi('sport',additionalSports,'Otras actividades que disfruto',
              'Other activities I enjoy'),
            profileSelect('frequency','Frecuencia semanal','Weekly frequency'),
            profileSelect('window','Horario general preferido',
              'Preferred general time of day'),
            profileSelect('training_mode','Modo actual','Current training mode'),
            profileSelect('training_with','Prefiero entrenar','I prefer to train'),
            profileSelect('competitions','Competiciones','Competition participation'),
            paragraphField('Mi reto actual (opcional)',
              'My current challenge (optional)',challenge,'challenge',max:100),
          ],
          if(activePillar==1)...[
            Text(tr('Lo que haces con tus mañanas, tus descansos y tus fines de semana cuenta más que una bio.',
              'What you do with mornings, recovery and weekends matters more than a bio.'),
              style:Theme.of(context).textTheme.bodyMedium),
            heading('Cómo vivo · Mi ritmo',
              'How I Live · Life Rhythm',Icons.wb_sunny_outlined),
            profileSelect('weekday','Entre semana suelo…','On weekdays I usually…'),
            multi('weekend',weekends,'Mi fin de semana puede incluir',
              'My weekends may include',max:6),
            profileSelect('alcohol','Alcohol (opcional, sin juicios)',
              'Alcohol (optional, no judgment)'),
            profileSelect('sleep','Ritmo de sueño','Sleep rhythm'),
            profileSelect('food','Alimentación (opcional)',
              'Food preferences (optional)'),
            profileSelect('travel','Cuando viajo','When I travel'),
            multi('interests',interests,'Más allá del entrenamiento',
              'Beyond training',max:10),
          ],
          if(activePillar==2)...[
            Text(tr('Muestra cómo compartes tiempo y cómo acompañas el entrenamiento de otra persona.',
              'Show how you share time and support someone through training.'),
              style:Theme.of(context).textTheme.bodyMedium),
            heading('Cómo me relaciono · Mi manera de conectar',
              'How I Relate · Relationship Rhythm',Icons.people_outline),
            profileSelect('intent','Qué busco','What I am looking for'),
            profileSelect('together','Tiempo juntos e independencia',
              'Togetherness and independence'),
            profileSelect('train_partner','Entrenar en pareja',
              'Training with a partner'),
            profileSelect('active_importance','Vida activa de mi pareja',
              'How important my partner being active is'),
            paragraphField('Una noche entre semana en pareja sería…',
              'A weeknight together would look like…',
              weeknight,'weeknight'),
            paragraphField('Durante un bloque de entrenamiento necesito…',
              'During a training block I need…',support,'support'),
          ],
        ]),
      )),
      if(loading)const LinearProgressIndicator(),
      if(saveNotice!=null)Text(saveNotice!,
        key:const Key('b11-save-success')),
      if(saveError!=null)Text(saveError!,key:const Key('b11-save-error')),
      if(!widget.canSave)Padding(
        padding:const EdgeInsets.symmetric(vertical:10),
        child:Text(tr(
          'Guardar requiere aceptar el consentimiento separado de FitDating. '
          'Ajustar tus respuestas no publica tu perfil ni activa matches.',
          'Saving requires separate FitDating consent. '
          'Editing answers does not publish your profile or enable matches.'))),
      profileActions(),
    ],
  );

  Widget heading(String es,String en,IconData icon) => Padding(
    padding:const EdgeInsets.fromLTRB(0,22,0,12),
    child:Row(children:[
      Icon(icon),
      const SizedBox(width:10),
      Expanded(child:FittedText(tr(es,en),
        style:Theme.of(context).textTheme.titleLarge)),
    ]),
  );

  Widget choiceField(String field,String es,String en) => Padding(
    padding:const EdgeInsets.only(bottom:20),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(tr(es,en),style:Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight:FontWeight.w700)),
      const SizedBox(height:5),
      Text(tr('Elige lo que realmente haces en una semana habitual.',
        'Choose what you actually do in a typical week.'),
        style:Theme.of(context).textTheme.bodySmall),
      const SizedBox(height:11),
      Wrap(spacing:8,runSpacing:8,children:[
        for(final code in rhythmOptionsB10[field]!)
          ChoiceChip(
            key:Key('profile-choice-$field-$code'),
            label:Text(label(code)),
            selected:answers[field]==code,
            onSelected:(_)=>setState((){
              answers[field]=code;
              if(field=='sport')additionalSports.remove(code);
            }),
          ),
      ]),
    ]),
  );

  Widget profileSelect(String field,String es,String en)=>
    widget.profileMode?choiceField(field,es,en):
      legacySelect(field,es,en);

  Widget legacySelect(String field,String es,String en) => Padding(
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
            child:FittedText(label(option),overflow:TextOverflow.ellipsis),
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
        child:FittedText(tr(es,en))),
      Wrap(spacing:7,runSpacing:6,children:[
        for(final option in rhythmOptionsB10[field]!)
          FilterChip(
            key:Key('b10-$field-$option'),
            label:FittedText(label(option)),
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
        helperText:widget.profileMode
          ?tr('Describe un momento concreto, no una etiqueta sobre ti.',
            'Describe a real moment, not a label about yourself.')
          :tr('Opcional · sólo esta pantalla',
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
      appBar:AppBar(title:Text(widget.profileMode
        ?tr('Mis tres pilares · Fitted','My three pillars · Fitted')
        :tr('Estudio de ritmo · FITTED (concepto)',
        'Rhythm studio · FITTED (concept)'))),
      body:Center(
        child:ConstrainedBox(
          constraints:BoxConstraints(maxWidth:widget.profileMode?1040:820),
          child:ListView(
            key:const Key('b10-lab'),
            padding:const EdgeInsets.all(18),
            children:[
              if(widget.profileMode)
                profileSections()
              else ...[
              Card(child:Padding(
                padding:const EdgeInsets.all(18),
                child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    FittedText('FITTED · Match your rhythm.',
                      style:Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height:9),
                    FittedText(tr(
                      'Prototipo interactivo del concepto exploratorio. '
                      'No es un perfil guardado, una persona real ni una invitación a citas.',
                      'Interactive exploratory concept. '
                      'Not a saved profile, a real person, or a dating invitation.',
                    ),key:const Key('b10-prototype-only')),
                    const SizedBox(height:9),
                    FittedText(tr(
                      'Nada de lo escrito aquí sale de esta pantalla. '
                      'No hay fotografías, contacto, gimnasio ni horarios exactos.',
                      'Nothing entered here leaves this screen. '
                      'No photos, contact details, gyms, or exact schedules.',
                    )),
                    SwitchListTile(
                      key:const Key('b10-language'),
                      title:const FittedText('English / Español'),
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
                  child:FittedText(tr(
                    'Tus ritmos pueden guardarse con consentimiento separado. '
                    'No se muestran perfiles sin edad verificada.',
                    'Your rhythms can be saved with separate consent. '
                    'No profiles appear without independent age verification.',
                  ),key:const Key('b11-private-persistence')),
                )),
              heading('1. How I Move · Training DNA',
                '1. How I Move · Training DNA',Icons.directions_run_outlined),
              profileSelect('sport','Actividad principal','Primary activity'),
              multi('sport',additionalSports,
                'Otras actividades que disfruto','Other activities I enjoy'),
              profileSelect('frequency','Frecuencia semanal','Weekly frequency'),
              profileSelect('window','Horario general preferido',
                'Preferred general time of day'),
              profileSelect('training_mode','Modo actual','Current mode'),
              profileSelect('training_with','Prefiero entrenar',
                'I prefer to train'),
              profileSelect('competitions','Competiciones',
                'Competition participation'),
              paragraphField('Mi reto actual (opcional)',
                'My current challenge (optional)',challenge,'challenge',max:100),

              heading('2. How I Live · Life Rhythm',
                '2. How I Live · Life Rhythm',Icons.nightlight_outlined),
              profileSelect('weekday','Entre semana suelo…',
                'On weekdays I usually…'),
              multi('weekend',weekends,'Mi fin de semana puede incluir',
                'My weekends may include',max:6),
              profileSelect('sleep','Ritmo de sueño','Sleep rhythm'),
              profileSelect('alcohol','Alcohol (opcional, sin juicios)',
                'Alcohol (optional, no judgment)'),
              profileSelect('food','Alimentación (opcional)',
                'Food approach (optional)'),
              profileSelect('travel','Cuando viajo',
                'When I travel'),
              multi('interests',interests,
                'Más allá del entrenamiento','Beyond training',max:10),

              heading('3. How I Relate · Relationship Rhythm',
                '3. How I Relate · Relationship Rhythm',
                Icons.favorite_outline),
              profileSelect('intent','Qué busco','What I am looking for'),
              profileSelect('together','Tiempo juntos e independencia',
                'Togetherness and independence'),
              profileSelect('train_partner','Entrenar en pareja',
                'Training with a partner'),
              profileSelect('active_importance',
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
              profileSelect('privacy','Modo a estudiar (no guardado)',
                'Mode to explore (not saved)'),
              const SizedBox(height:4),
              ListTile(
                key:const Key('b10-gym-c-locked'),
                leading:const Icon(Icons.lock_outline),
                title:FittedText(tr(
                  'C: Mismo gimnasio sin restricciones',
                  'C: Same gym without restrictions')),
                subtitle:FittedText(tr(
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
              FittedText(tr(
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
                    child:FittedText(tr('Yoga y ritmo similar',
                      'Yoga with a similar rhythm'))),
                  DropdownMenuItem(
                    value:'same_sport_other_rhythm',
                    child:FittedText(tr('Running y ritmos diferentes',
                      'Running with different rhythms'))),
                ],
                onChanged:(value){
                  if(value!=null)setState(()=>scenario=value);
                },
              ),
              const SizedBox(height:12),
              if(validation!=null)
                FittedText(tr('Revisa los campos de la simulación.',
                  'Review the simulation fields.')),
              for(final reason in reasons)
                Card(
                  key:Key('b10-reason-${reason.layer}-${reasons.indexOf(reason)}'),
                  child:ListTile(
                    leading:Icon(reason.importance=='high'
                      ?Icons.favorite_border:Icons.tips_and_updates_outlined),
                    title:FittedText(reason.message(english:english)),
                    subtitle:FittedText(tr(
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
                label:FittedText(tr('Ver ideas hipotéticas de Active Date',
                  'View hypothetical Active Date ideas')),
              ),
              if(showIdeas) ...[
                FittedText(tr(
                  'Sólo después de un match mutuo real, nunca antes. '
                  'No son reservaciones ni ubicaciones reales.',
                  'Only after a real mutual match, never before. '
                  'These are not bookings or real locations.',
                ),key:const Key('b10-after-mutual')),
                for(final idea in hypotheticalActiveDatesB10(answers,sample))
                  ListTile(
                    leading:const Icon(Icons.park_outlined),
                    title:FittedText(switch(idea){
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
                  label:FittedText(tr('Guardar mis tres ritmos privados',
                    'Save my three private rhythms')),
                ),
                if(saveNotice!=null)
                  FittedText(saveNotice!,key:const Key('b11-save-success')),
                if(saveError!=null)
                  FittedText(saveError!,key:const Key('b11-save-error')),
              ]else
                FittedText(tr('Para guardar, acepta primero el consentimiento '
                    'separado de FitDating.',
                  'To save, first accept the separate FitDating consent.'),
                  key:const Key('b11-consent-before-save')),
              const SizedBox(height:18),
              FittedText(tr(
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
            ],
          ),
        ),
      ),
    );
  }
}
