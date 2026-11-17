import 'package:flutter/material.dart';

/// One explicit decision at first member access. No opt-in by default.
/// AI never changes profile visibility, dating or sharing permissions.
class FittedAiAccountGate extends StatefulWidget {
  const FittedAiAccountGate({super.key,required this.onChoose});
  final Future<void> Function(bool enabled) onChoose;
  @override
  State<FittedAiAccountGate> createState()=>_FittedAiAccountGateState();
}
class _FittedAiAccountGateState extends State<FittedAiAccountGate>{
  bool busy=false;
  String? error;

  Future<void> choose(bool enabled)async{
    if(busy)return;
    setState((){busy=true;error=null;});
    try{
      await widget.onChoose(enabled);
    }catch(_){
      if(mounted)setState(()=>error=
        'No pudimos guardar tu decisión. Comprueba tu conexión y reintenta.');
    }finally{if(mounted)setState(()=>busy=false);}
  }

  @override
  Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(
      padding:const EdgeInsets.symmetric(horizontal:22,vertical:36),
      child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:540),
        child:Card(child:Padding(padding:const EdgeInsets.all(26),
          child:Column(mainAxisSize:MainAxisSize.min,
            crossAxisAlignment:CrossAxisAlignment.start,children:[
            Icon(Icons.auto_awesome_outlined,size:36,color:colors.primary),
            const SizedBox(height:16),
            Text('Tu experiencia con IA',
              style:Theme.of(context).textTheme.headlineSmall,
              key:const Key('fitted-ai-first-access-title')),
            const SizedBox(height:12),
            const Text('Decide si deseas utilizar inteligencia artificial '
              'en tu cuenta. La elección aplica a todas las herramientas '
              'de IA disponibles en Fitted.'),
            const SizedBox(height:13),
            const Text('Con IA, Fitted puede procesar respuestas de tus '
              'tres pilares y datos seleccionados de tu perfil mediante '
              'OpenAI para generar conversaciones y resúmenes privados. '
              'No se envían tus ubicaciones exactas, horarios ni '
              'documentos de identidad.'),
            const SizedBox(height:13),
            const Text('Tus datos no se publican ni se comparten con otros '
              'miembros por activar esta opción. La visibilidad del '
              'perfil y las funciones de citas tienen sus propios permisos.'),
            const SizedBox(height:18),
            FilledButton.icon(
              key:const Key('fitted-ai-first-access-enable'),
              onPressed:busy?null:()=>choose(true),
              icon:const Icon(Icons.auto_awesome),
              label:const Text('Activar IA en mi cuenta')),
            const SizedBox(height:10),
            OutlinedButton(
              key:const Key('fitted-ai-first-access-disable'),
              onPressed:busy?null:()=>choose(false),
              child:const Text('Continuar sin IA')),
            if(busy)...[
              const SizedBox(height:14),
              const LinearProgressIndicator(),
            ],
            if(error!=null)...[
              const SizedBox(height:12),
              Text(error!,style:TextStyle(color:colors.error)),
            ],
            const SizedBox(height:12),
            Text('Puedes cambiarlo cuando quieras en '
              'Cuenta → Configuración → Inteligencia artificial.',
              style:Theme.of(context).textTheme.bodySmall),
          ]))),
      ),
    ))));
  }
}

/// In-account settings for the single global preference. Sharing is separate.
class FittedAiAccountSettingsDialog extends StatefulWidget{
  const FittedAiAccountSettingsDialog({super.key,required this.initial});
  final bool initial;
  @override
  State<FittedAiAccountSettingsDialog> createState()=>
      _FittedAiAccountSettingsDialogState();
}
class _FittedAiAccountSettingsDialogState
    extends State<FittedAiAccountSettingsDialog>{
  late bool enabled;
  @override
  void initState(){super.initState();enabled=widget.initial;}
  @override
  Widget build(BuildContext context)=>AlertDialog(
    title:const Text('Configuración · Inteligencia artificial'),
    content:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),
      child:Column(mainAxisSize:MainAxisSize.min,
        crossAxisAlignment:CrossAxisAlignment.start,children:[
        SwitchListTile.adaptive(
          key:const Key('fitted-ai-account-switch'),
          contentPadding:EdgeInsets.zero,
          value:enabled,
          onChanged:(v)=>setState(()=>enabled=v),
          title:const Text('Usar IA en mi cuenta'),
          subtitle:Text(enabled?'IA habilitada para todas las funciones '
            'compatibles.':'IA desactivada en toda la cuenta.'),
        ),
        const SizedBox(height:12),
        const Text('Al activar la IA, se permite procesar datos '
          'seleccionados de tu perfil y respuestas con OpenAI para '
          'conversaciones y resúmenes privados. Al desactivarla, '
          'se detienen nuevas solicitudes a los modelos.'),
        const SizedBox(height:10),
        const Text('Tus respuestas y textos manuales permanecen guardados. '
          'Compartir un resumen o participar en citas requiere '
          'permisos adicionales.'),
      ])),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),
        child:const Text('Cancelar')),
      FilledButton(
        key:const Key('fitted-ai-settings-save'),
        onPressed:()=>Navigator.pop(context,enabled),
        child:const Text('Guardar configuración')),
    ],
  );
}
