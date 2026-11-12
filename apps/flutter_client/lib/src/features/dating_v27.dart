import 'package:flutter/material.dart';

import '../core/dating_preferences_b5.dart';
import '../core/dating_repository_b5.dart';

/// B5 — Private readiness and preferences, NOT an unrestricted dating launch.
/// Independent age verification, safety review, moderation staffing and
/// release approval remain server-side NO-GO. Never show private gym schedules.
class DatingV27 extends StatefulWidget {
  const DatingV27({super.key,required this.api});
  final DatingRepositoryB5 api;

  @override
  State<DatingV27> createState()=>_DatingV27State();
}

class _DatingV27State extends State<DatingV27> {
  Map<String,dynamic>? status;
  List<Map<String,dynamic>> candidates=[];
  bool loading=true;
  bool submitting=false;
  bool acceptedConsent=false;
  String intent='serious';
  String frequency='flexible';
  String privacy='other_gyms';
  final Set<String> sports={};
  bool requested=false;
  String? error;
  String? note;

  @override
  void initState(){
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if(!mounted)return;
    setState((){loading=true;error=null;});
    try {
      final latest=await widget.api.datingStatus();
      if(!mounted)return;
      final enabled=latest['enabled']==true;
      final matches=enabled?await widget.api.datingCandidates()
          :<Map<String,dynamic>>[];
      if(!mounted)return;
      setState((){
        status=latest;
        candidates=matches;
        final proposedIntent=latest['relationship_intent']?.toString();
        if(datingIntentOptionsB5.containsKey(proposedIntent))intent=proposedIntent!;
        final proposedFrequency=latest['lifestyle_frequency']?.toString();
        if(datingFrequencyOptionsB5.containsKey(proposedFrequency)){
          frequency=proposedFrequency!;
        }
        final proposedPrivacy=latest['gym_privacy_mode']?.toString();
        if(datingPrivacyOptionsB5.containsKey(proposedPrivacy)){
          privacy=proposedPrivacy!;
        }
        final values=latest['sports'];
        sports.clear();
        if(values is List){
          for(final item in values){
            if(item is String && datingSportOptionsB5.containsKey(item)){
              sports.add(item);
            }
          }
        }
        requested=latest['participation_requested']==true;
        acceptedConsent=latest['dating_consent']==true;
      });
    } catch (_) {
      if(mounted)setState(()=>
        error='No fue posible consultar el estado de FitDating. '
          'Tus datos siguen privados.');
    } finally {
      if(mounted)setState(()=>loading=false);
    }
  }

  Future<void> save() async {
    if(submitting || status==null || status!['status']!='available')return;
    final issue=validateDatingChoicesB5(
      intent:intent,frequency:frequency,privacyMode:privacy,
      sports:sports,requested:requested,consent:acceptedConsent,
    );
    if(issue!=null){setState(()=>error=issue);return;}
    setState((){submitting=true;error=null;note=null;});
    try {
      if(acceptedConsent && status!['dating_consent']!=true){
        await widget.api.acceptDating();
      }
      await widget.api.saveDatingPreferences(datingDraftB5(
        intent:intent,frequency:frequency,privacyMode:privacy,
        sports:sports,requested:requested,
      ));
      if(!mounted)return;
      await reload();
      if(mounted)setState(()=>note='Preferencias privadas guardadas. '
        'No se activó la búsqueda de personas.');
    } catch (_) {
      if(mounted)setState(()=>
        error='No se pudieron guardar tus preferencias. '
          'No se activó la búsqueda.');
    } finally {
      if(mounted)setState(()=>submitting=false);
    }
  }

  Future<void> disable() async {
    if(submitting)return;
    setState((){submitting=true;error=null;note=null;});
    try {
      await widget.api.disableDating();
      if(!mounted)return;
      await reload();
      if(mounted)setState(()=>note='FitDating desactivado. '
        'No apareces en el descubrimiento.');
    } catch (_) {
      if(mounted)setState(()=>error=
        'No se pudo confirmar la desactivación. Reintenta.');
    } finally {
      if(mounted)setState(()=>submitting=false);
    }
  }

  Widget gateRow({required String title,required bool satisfied,
      required String message}) => ListTile(
    leading:Icon(satisfied?Icons.check_circle_outline:Icons.lock_outline,
      color:satisfied?Colors.green:Theme.of(context).colorScheme.secondary),
    title:Text(title),
    subtitle:Text(message),
  );

  @override
  Widget build(BuildContext context){
    final data=status??<String,dynamic>{};
    final active=data['enabled']==true;
    final age=data['age_verified']==true;
    final consent=data['dating_consent']==true;
    final pilot=data['pilot_member']==true;
    final verifiedProvider=data['independent_provider_ready']==true;
    final released=data['discovery_release_ready']==true;
    final available=data['status']=='available';
    return Scaffold(
      appBar:AppBar(
        title:const Text('FitDating · privacidad primero'),
        actions:[
          IconButton(
            tooltip:'Actualizar estado',
            key:const Key('b5-refresh'),
            onPressed:loading||submitting?null:reload,
            icon:const Icon(Icons.refresh),
          ),
        ],
      ),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:820),
        child:ListView(
          key:const Key('b5-dating-readiness'),
          padding:const EdgeInsets.all(20),
          children:[
            Text('Conecta con intención',
              style:Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height:8),
            const Text('Explora lo que buscas y cómo disfrutas el deporte. '
              'Tus preferencias no publican tus gimnasios, horarios, '
              'rutas, teléfono ni ubicación exacta.'),
            const SizedBox(height:20),
            if(loading)const Center(child:CircularProgressIndicator()),
            if(error!=null) Padding(
              padding:const EdgeInsets.symmetric(vertical:12),
              child:Text(error!,key:const Key('b5-error'),
                style:const TextStyle(color:Colors.redAccent)),
            ),
            if(note!=null) Padding(
              padding:const EdgeInsets.symmetric(vertical:12),
              child:Text(note!,key:const Key('b5-saved-status')),
            ),
            if(!loading && !available)
              const Card(child:Padding(
                padding:EdgeInsets.all(20),
                child:Text('FitDating no está disponible con esta cuenta. '
                  'El perfil deportivo y las actividades siguen separados.'))),
            if(!loading && available) ...[
              Card(child:Padding(
                padding:const EdgeInsets.all(17),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    Text(active?'Descubrimiento habilitado':
                      'Preparación privada · descubrimiento deshabilitado',
                      key:const Key('b5-availability'),
                      style:Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height:10),
                    const Text('No se muestran perfiles ni se envían mensajes '
                      'hasta aprobar verificación independiente de edad, '
                      'moderación y los controles de privacidad.'),
                  ]))),
              const SizedBox(height:15),
              Text('Mis preferencias',
                style:Theme.of(context).textTheme.titleLarge),
              const SizedBox(height:10),
              DropdownButtonFormField<String>(
                isExpanded:true,
                key:ValueKey('b5-intent-$intent'),
                initialValue:intent,
                decoration:const InputDecoration(labelText:'¿Qué buscas?'),
                items:[
                  for(final item in datingIntentOptionsB5.entries)
                    DropdownMenuItem(value:item.key,child:Text(item.value)),
                ],
                onChanged:submitting?null:(v){
                  if(v!=null)setState(()=>intent=v);
                },
              ),
              const SizedBox(height:14),
              DropdownButtonFormField<String>(
                isExpanded:true,
                key:ValueKey('b5-frequency-$frequency'),
                initialValue:frequency,
                decoration:const InputDecoration(
                  labelText:'Mi ritmo deportivo'),
                items:[
                  for(final item in datingFrequencyOptionsB5.entries)
                    DropdownMenuItem(value:item.key,child:Text(item.value)),
                ],
                onChanged:submitting?null:(v){
                  if(v!=null)setState(()=>frequency=v);
                },
              ),
              const SizedBox(height:18),
              const Text('Deportes que disfruto (hasta ocho)'),
              const SizedBox(height:8),
              Wrap(spacing:8,runSpacing:4,children:[
                for(final item in datingSportOptionsB5.entries)
                  FilterChip(
                    key:Key('b5-sport-${item.key}'),
                    label:Text(item.value),
                    selected:sports.contains(item.key),
                    onSelected:submitting?null:(selected){
                      setState((){
                        if(selected&&sports.length<8)sports.add(item.key);
                        if(!selected)sports.remove(item.key);
                      });
                    },
                  ),
              ]),
              const SizedBox(height:20),
              DropdownButtonFormField<String>(
                isExpanded:true,
                key:ValueKey('b5-privacy-$privacy'),
                initialValue:privacy,
                decoration:const InputDecoration(
                  labelText:'Protección de mi gimnasio'),
                items:[
                  for(final item in datingPrivacyOptionsB5.entries)
                    DropdownMenuItem(
                      value:item.key,
                      child:Text(item.value,maxLines:1,
                        overflow:TextOverflow.ellipsis),
                    ),
                ],
                onChanged:submitting?null:(v){
                  if(v!=null)setState(()=>privacy=v);
                },
              ),
              if(privacy=='same_gym_other_time')const Padding(
                padding:EdgeInsets.only(top:10),
                child:Text('Este modo necesitará horarios privados '
                  'configurados y separación de al menos 30 minutos. '
                  'No activa coincidencias por sí mismo.'),
              ),
              const SizedBox(height:14),
              CheckboxListTile(
                key:const Key('b5-separate-consent'),
                controlAffinity:ListTileControlAffinity.leading,
                value:acceptedConsent,
                onChanged:submitting||consent?null:(v)=>
                  setState(()=>acceptedConsent=v??false),
                title:Text(consent
                  ?'Consentimiento independiente registrado'
                  :'Acepto voluntariamente participar en FitDating'),
                subtitle:const Text(
                  'Separado de los términos y de la comunidad deportiva.'),
              ),
              SwitchListTile(
                key:const Key('b5-request-participation'),
                value:requested,
                onChanged:submitting?null:(v)=>
                  setState(()=>requested=v),
                title:const Text('Dejar preparada mi solicitud de participación'),
                subtitle:const Text('Solicitar participación no habilita '
                  'descubrimiento ni anula verificaciones.'),
              ),
              const SizedBox(height:12),
              FilledButton.icon(
                key:const Key('b5-save-preferences'),
                onPressed:submitting?null:save,
                icon:const Icon(Icons.shield_outlined),
                label:Text(submitting?'Guardando…':
                  'Guardar mis preferencias privadas'),
              ),
              const SizedBox(height:10),
              OutlinedButton.icon(
                key:const Key('b5-disable'),
                onPressed:submitting?null:disable,
                icon:const Icon(Icons.visibility_off_outlined),
                label:const Text('Desactivar mi participación'),
              ),
              const SizedBox(height:24),
              Text('Protecciones y requisitos',
                style:Theme.of(context).textTheme.titleLarge),
              gateRow(title:'Verificación de edad registrada',
                satisfied:age,
                message:'La declaración personal no equivale '
                  'a verificación externa.'),
              gateRow(title:'Proveedor independiente verificado',
                satisfied:verifiedProvider,
                message:'Aún no está habilitado para este producto. '
                  'No envíes documentos personales por correo.'),
              gateRow(title:'Consentimiento de FitDating',
                satisfied:consent,
                message:'Independiente de la comunidad y revocable.'),
              gateRow(title:'Acceso al piloto cerrado',
                satisfied:pilot,
                message:'El acceso al piloto lo autoriza un administrador.'),
              gateRow(title:'Moderación, privacidad y liberación',
                satisfied:released,
                message:'Control obligatorio del servidor, no del cliente.'),
              const SizedBox(height:10),
              if(active) ...[
                Text('Personas compatibles',
                  style:Theme.of(context).textTheme.titleLarge),
                if(candidates.isEmpty)
                  const Text('No hay perfiles compatibles disponibles.'),
                for(final person in candidates)
                  Card(child:ListTile(
                    leading:const Icon(Icons.person_outline),
                    title:Text((person['display_name']??'Deportista').toString()),
                    subtitle:Text((person['city']??'').toString()),
                  )),
              ] else
                const Text('La búsqueda y los mensajes permanecen '
                  'deshabilitados. Tu comunidad deportiva no requiere FitDating.'),
            ],
          ],
        ),
      )),
    );
  }
}
