import 'package:flutter/material.dart';
import '../core/dating_repository_b11.dart';
import '../core/fitted_locale.dart';
import '../theme/fitness_date_theme.dart';
import '../widgets/fitted_glass_atmosphere.dart';

/// After a mutually confirmed offline encounter, a member can describe
/// subjective alignment with the other member's stated lifestyle.
/// The review is private pending moderation; never a public "liar" badge.
class FittedPulseRealPanel extends StatefulWidget {
  const FittedPulseRealPanel({super.key,required this.api,required this.matchId});
  final DatingRepositoryB11 api;
  final String matchId;

  @override
  State<FittedPulseRealPanel> createState()=>_FittedPulseRealPanelState();
}

class _FittedPulseRealPanelState extends State<FittedPulseRealPanel>{
  Map<String,dynamic>? status;
  String dimension='move';
  String observation='aligned';
  String? message;
  bool loading=true,busy=false;

  @override
  void initState(){super.initState();load();}
  Future<void> load() async{
    try{
      final value=await widget.api.pulseRealStatusB12(widget.matchId);
      if(mounted)setState((){status=value;loading=false;});
    }catch(_){
      if(mounted)setState((){status=null;loading=false;});
    }
  }
  Future<void> changeConsent(bool accept) async {
    if(busy)return;
    final approved=await showDialog<bool>(context:context,builder:(ctx)=>
      AlertDialog(
        title:Text(accept?'Activar Pulso Real':'Retirar consentimiento'),
        content:Text(accept
          ?'Tus observaciones después de citas se procesarán de forma privada, sin publicación automática. Puedes retirar tu consentimiento.'
          :'Se eliminarán las observaciones asociadas a ti y tus confirmaciones. Esto no deshace reportes de seguridad independientes.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text('Confirmar')),
        ],
      ));
    if(approved!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      final result=await widget.api.setPulseRealConsentB12(accept);
      if(mounted)setState(()=>message=result=='accepted'
        ?'Consentimiento registrado para Pulso Real.'
        :'Consentimiento retirado y observaciones relacionadas eliminadas.');
      await load();
    }catch(_){if(mounted)setState(()=>message='No fue posible actualizar el consentimiento.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> confirm() async{
    if(busy)return;
    setState(()=>busy=true);
    try{
      final result=await widget.api.confirmMeetupB12(widget.matchId);
      if(!mounted)return;
      setState(()=>message=result=='both_confirmed'
        ?'Encuentro confirmado por ambas personas.'
        :'Confirmado por ti. La otra persona aún debe confirmarlo.');
      await load();
    }catch(_){if(mounted)setState(()=>message='No se pudo confirmar el encuentro.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> submit() async{
    if(busy)return;
    final en=FittedLocaleScope.languageOf(context)=='en';
    final confirmed=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:Text(en?'Submit your private observation?':'¿Enviar tu observación privada?'),
        content:Text(en
          ?'This is a subjective experience, not proof of dishonesty. It will not appear publicly without moderation and due process.'
          :'Es tu experiencia, no una prueba de mentira. No será visible públicamente sin moderación y posibilidad de réplica.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text(en?'Cancel':'Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text(en?'Submit':'Enviar')),
        ],
      ));
    if(confirmed!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      final result=await widget.api.submitPulseRealB12(
        widget.matchId,dimension,observation);
      if(!mounted)return;
      setState(()=>message=result=='pending_moderation'
        ?'Observación privada recibida, pendiente de moderación.'
        :'Esta evaluación ya fue registrada o no está disponible.');
      await load();
    }catch(_){
      if(mounted)setState(()=>message='La evaluación no pudo registrarse de forma segura.');
    }finally{if(mounted)setState(()=>busy=false);}
  }

  @override
  Widget build(BuildContext context){
    final en=FittedLocaleScope.languageOf(context)=='en';
    final available=status?['available']==true;
    final both=status?['both_confirmed']==true;
    final own=status?['my_confirmation']==true;
    final consent=status?['my_consent']==true;
    final bothConsent=status?['both_consented']==true;
    final total=(status?['my_observations'] as num?)?.toInt()??0;
    return Stack(children:[
      Positioned.fill(child:ClipRRect(
        borderRadius:BorderRadius.circular(23),
        child:FittedRhythmLines(density:.7))),
      FittedGlassPanel(
        radius:23,blur:8,
        padding:EdgeInsets.all(17),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Container(
              width:37,height:37,
              decoration:BoxDecoration(
                color:FitDateColors.aqua.withValues(alpha:.16),
                borderRadius:BorderRadius.circular(13)),
              child:Icon(Icons.fact_check_outlined,
                color:FitDateColors.aqua,size:20)),
            SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text('PULSO REAL',
                  style:TextStyle(color:FitDateColors.aqua,fontSize:11,
                    letterSpacing:2,fontWeight:FontWeight.w900)),
                SizedBox(height:3),
                Text(en?'Beyond the profile':'Más allá de lo que se cuenta',
                  style:Theme.of(context).textTheme.titleMedium),
              ])),
          ]),
          SizedBox(height:10),
          Text(en
            ?'After a date, you can privately evaluate whether what you experienced aligned with what was shared.'
            :'Después de una cita puedes valorar en privado si tu experiencia coincidió con lo que la otra persona compartió.',
            style:Theme.of(context).textTheme.bodySmall),
          SizedBox(height:10),
          if(loading)LinearProgressIndicator(),
          if(!loading&&!available)
            Text(en
              ?'Available after mutual matching and approved safety checks.'
              :'Disponible después de un match mutuo y las verificaciones de seguridad.',
              style:TextStyle(color:FitDateColors.muted,fontSize:12)),
          if(available)...[
            SwitchListTile.adaptive(
              key:Key('pulse-real-consent'),
              contentPadding:EdgeInsets.zero,
              value:consent,
              onChanged:busy?null:changeConsent,
              title:Text(en?'Optional private feedback consent':
                'Consentimiento independiente y opcional'),
              subtitle:Text(en?'Reversible; withdrawal deletes associated observations.':
                'Revocable; al retirarlo se eliminan las observaciones asociadas.'),
            ),
            if(consent&&!own)
              OutlinedButton.icon(
                key:Key('pulse-real-confirm-date'),
                onPressed:busy?null:confirm,
                icon:Icon(Icons.handshake_outlined),
                label:Text(en?'Confirm we met':'Confirmar que nos conocimos')),
            if(consent&&own&&!both)
              Text(en?'Waiting for the other person to confirm the encounter.':
                'Esperando la confirmación de la otra persona.',
                style:TextStyle(color:FitDateColors.muted)),
            if(consent&&both&&!bothConsent)
              Text('La otra persona aún no ha aceptado el tratamiento de evaluaciones.',
                style:TextStyle(color:FitDateColors.muted)),
            if(consent&&both&&bothConsent)...[
              SizedBox(height:6),
              Text(en?'Which dimension did you experience?':
                '¿Qué parte de su estilo de vida observaste?',
                style:TextStyle(fontWeight:FontWeight.w700)),
              SizedBox(height:7),
              Wrap(spacing:7,runSpacing:7,children:[
                for(final d in const ['move','live','relate'])
                  ChoiceChip(
                    key:Key('pulse-real-dimension-$d'),
                    selected:dimension==d,
                    label:Text(switch(d){
                      'move'=>'How I Move','live'=>'How I Live',_=>'How I Relate',
                    }),
                    onSelected:busy?null:(_)=>setState(()=>dimension=d)),
              ]),
              SizedBox(height:12),
              Text(en?'Did the experience match their description?':
                '¿Coincidió con lo que decía su perfil?',
                style:TextStyle(fontWeight:FontWeight.w700)),
              SizedBox(height:6),
              for(final signal in const ['aligned','unclear','not_aligned'])
                RadioListTile<String>(
                  key:Key('pulse-real-signal-$signal'),
                  contentPadding:EdgeInsets.zero,
                  dense:true,
                  value:signal,groupValue:observation,
                  onChanged:busy?null:(value)=>setState(
                    ()=>observation=value??'unclear'),
                  title:Text(switch(signal){
                    'aligned'=>en?'It aligned':'Sí, coincidió',
                    'unclear'=>en?'I cannot tell':'No pude comprobarlo',
                    _=>en?'It did not match my experience':
                      'No coincidió con mi experiencia',
                  }),
                ),
              FilledButton.icon(
                key:Key('pulse-real-submit'),
                onPressed:busy?null:submit,
                icon:Icon(Icons.lock_outline),
                label:Text(en?'Submit private observation':
                  'Enviar observación privada')),
              SizedBox(height:6),
              Text(en?'Your submitted dimensions: $total of 3':
                'Dimensiones registradas: $total de 3',
                style:TextStyle(color:FitDateColors.muted,fontSize:11)),
            ],
          ],
          if(message!=null)...[
            SizedBox(height:8),
            Text(message!,key:Key('pulse-real-message'),
              style:TextStyle(color:FitDateColors.aqua,fontSize:12)),
          ],
          SizedBox(height:8),
          Text('Sin acusaciones automáticas · Sin publicación inmediata · Con moderación y réplica.',
            style:TextStyle(fontSize:11,color:FitDateColors.muted,height:1.5)),
        ]),
      ),
    ]);
  }
}
