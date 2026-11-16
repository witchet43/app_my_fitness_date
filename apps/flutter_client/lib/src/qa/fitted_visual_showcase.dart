import 'package:flutter/material.dart';
import '../theme/fitness_date_theme.dart';
import '../features/public_entry_shell.dart';
import '../features/fitted_profile_story_v28.dart';
import '../features/rhythm_concept_lab_b10.dart';
import '../features/member_profile_v26.dart';

/// Isolated compile-time visual acceptance surface: only fixture data.
/// Never authenticates, persists, lists real members or unlocks dating.
class FittedVisualShowcase extends StatefulWidget {
  const FittedVisualShowcase({super.key});
  @override
  State<FittedVisualShowcase> createState() => _FittedVisualShowcaseState();
}

class _FittedVisualShowcaseState extends State<FittedVisualShowcase> {
  int area = 0;
  Map<String,dynamic> profile = {
    'display_name': 'Alex',
    'date_of_birth': '1984-05-10',
    'city': 'Ciudad de ejemplo',
    'headline': 'Me mueve descubrir nuevas rutas.',
    'about_me': 'Running, café, escapadas y conversaciones con sentido.',
    'occupation': 'Profesional independiente',
    'languages': ['Español', 'Inglés'],
    'hobbies': ['Café', 'Naturaleza', 'Viajar'],
    'life_values': ['Honestidad', 'Equilibrio'],
    'sports': ['Running', 'Fuerza'],
    'training_frequency': 'three_to_four',
    'fitness_goals': ['Correr 21K'],
    'achievements': ['Mi primera carrera'],
    'dating_intent': 'long_term',
    'social_visibility': 'private',
  };
  final rhythm = <String,dynamic>{
    'answers': <String,dynamic>{
      'sport':'running',
      'frequency':'four_five',
      'training_mode':'structured',
      'weekday':'home',
      'sleep':'early_bird',
      'intent':'long_term',
      'together':'balanced',
    },
  };

  @override
  Widget build(BuildContext context) {
    const labels = ['Portada', 'Mi perfil', 'Mis tres ritmos', 'Editar perfil'];
    return MaterialApp(
      title:'Fitted | Vista previa visual',
      debugShowCheckedModeBanner:false,
      theme:FitDateTheme.dark(),
      home:Scaffold(
        body:SafeArea(child:Column(children:[
          Container(
            width:double.infinity,
            color:const Color(0xFF123437),
            padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),
            child:const Row(children:[
              Icon(Icons.visibility_outlined,color:FitDateColors.aqua,size:16),
              SizedBox(width:8),
              Expanded(child:Text('PREVIEW NO PRODUCTIVA · DATOS FICTICIOS',
                style:TextStyle(fontSize:10,letterSpacing:1,
                  color:FitDateColors.aqua,fontWeight:FontWeight.w800))),
            ]),
          ),
          Container(
            color:FitDateColors.inkDeep,
            width:double.infinity,
            child:SingleChildScrollView(
              scrollDirection:Axis.horizontal,
              padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
              child:Row(children:[
                for(var i=0;i<labels.length;i++)Padding(
                  padding:const EdgeInsets.only(right:8),
                  child:ChoiceChip(
                    key:Key('preview-tab-$i'),
                    selected:area==i,
                    label:Text(labels[i]),
                    onSelected:(_)=>setState(()=>area=i),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(child:area==0
            ? const PublicEntryShell(
                termsUrl:'https://my-fitness-date.pages.dev/terms/',
                privacyUrl:'https://my-fitness-date.pages.dev/privacy/',
              )
            : area==1
              ? SingleChildScrollView(
                  padding:const EdgeInsets.all(18),
                  child:Center(child:ConstrainedBox(
                    constraints:const BoxConstraints(maxWidth:1000),
                    child:FittedProfileStoryV28(
                      profile:profile,rhythm:rhythm,
                      startingPreference:null,
                      onChooseStarting:(_)async{},
                      onConfigure:()=>setState(()=>area=2),
                      onEditIdentity:()=>setState(()=>area=3),
                    ),
                  )),
                )
              : area==2
                ? const RhythmConceptLabB10(profileMode:true)
                : Center(child:ConstrainedBox(
                    constraints:const BoxConstraints(maxWidth:900),
                    child:ProfileEditorV26(
                      initial:profile,
                      onSave:(data)async{
                        if(mounted)setState(() { profile=data; area=1; });
                      },
                      onCancel:()=>setState(()=>area=1),
                    ),
                  )),
          ),
        ])),
      ),
    );
  }
}
