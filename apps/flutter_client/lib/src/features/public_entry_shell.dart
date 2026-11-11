import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/fitness_date_theme.dart';
import 'pace_calculator.dart';

/// Marketing is public; member screens require verified authentication.
/// Actions require configured production Auth and legal policy URLs.
class PublicEntryShell extends StatefulWidget {
  const PublicEntryShell({super.key, this.onGoogle, this.onEmail,
    this.onEmailRegister, this.onEmailSignIn,
    this.termsUrl = '', this.privacyUrl = ''});
  final VoidCallback? onGoogle;
  final VoidCallback? onEmail;
  final VoidCallback? onEmailRegister;
  final VoidCallback? onEmailSignIn;
  final String termsUrl;
  final String privacyUrl;
  @override
  State<PublicEntryShell> createState() => _PublicEntryShellState();
}

class _PublicEntryShellState extends State<PublicEntryShell> {
  bool register = true;
  bool acceptedLegal = false;
  bool adultDeclared = false;
  bool get legalConfigured => widget.termsUrl.startsWith('https://') &&
      widget.privacyUrl.startsWith('https://');
  Future<void> openPolicy(String raw) async {
    final url=Uri.tryParse(raw);
    if(url!=null && url.scheme=='https') {
      await launchUrl(url,mode:LaunchMode.externalApplication);
    }
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Existing members can sign in without re-declaring age or consent.
    // Registration still requires legal acknowledgement and adult declaration.
    final canRegister=legalConfigured && acceptedLegal && adultDeclared;
    final canContinue=register ? canRegister : legalConfigured;
    final emailAction=register
        ? (widget.onEmailRegister ?? widget.onEmail)
        : (widget.onEmailSignIn ?? widget.onEmail);
    final story = Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [
          Color(0xFF3C243F), Color(0xFF1A2430), Color(0xFF1C3227),
        ]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ACTIVE CHEMISTRY',
          style: TextStyle(color: FitDateColors.lime,
            letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        const Text('Tu próxima conexión también puede compartir tu ritmo.',
          key: Key('landing-headline'),
          style: TextStyle(fontSize: 34, height: 1.12,
            color: FitDateColors.pearl, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        const Text('Muestra quién eres, lo que te apasiona y cómo vives '
          'el deporte. Comunidad, actividades y citas opcionales con privacidad.',
          style: TextStyle(color: FitDateColors.muted, height: 1.5)),
        const SizedBox(height: 20),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          Chip(label: Text('Gym & fuerza')),
          Chip(label: Text('Running')),
          Chip(label: Text('Yoga & studios')),
          Chip(label: Text('Aventuras')),
        ]),
      ]),
    );
    final access = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FitDateColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: FitDateColors.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(register ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
          style: const TextStyle(
            fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Tu perfil comienza privado y tú decides qué compartir.',
          style: TextStyle(color: FitDateColors.muted)),
        const SizedBox(height: 20),
        OutlinedButton(
          key: const Key('google-signin-entry'),
          onPressed:canContinue?widget.onGoogle:null,
          child: const Row(children: [
            Icon(Icons.account_circle_outlined, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Continuar con Google',
              textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('email-entry'),
          onPressed:canContinue?emailAction:null,
          child: Row(children: [
            const Icon(Icons.mail_outline, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              register ? 'Registro con correo' : 'Acceso con correo',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        const SizedBox(height:14),
        if(register) Material(color:Colors.transparent,child:CheckboxListTile(
          value:acceptedLegal,
          controlAffinity:ListTileControlAffinity.leading,
          contentPadding:EdgeInsets.zero,
          title:const Text('Acepto los términos y el aviso de privacidad',
            style:TextStyle(fontSize:13)),
          onChanged:legalConfigured
              ?(v)=>setState(()=>acceptedLegal=v??false):null,
        )),
        if(register) Material(color:Colors.transparent,child:CheckboxListTile(
          value:adultDeclared,
          controlAffinity:ListTileControlAffinity.leading,
          contentPadding:EdgeInsets.zero,
          title:const Text('Declaro ser mayor de 18 años',
            style:TextStyle(fontSize:13)),
          onChanged:(v)=>setState(()=>adultDeclared=v??false),
        )),
        Wrap(spacing:10,children:[
          TextButton(onPressed:legalConfigured
              ?()=>openPolicy(widget.termsUrl):null,
            child:const Text('Términos')),
          TextButton(onPressed:legalConfigured
              ?()=>openPolicy(widget.privacyUrl):null,
            child:const Text('Privacidad')),
        ]),
        if(!legalConfigured || (widget.onGoogle==null && emailAction==null)) ...[
          const SizedBox(height: 16),
          const Text('El acceso todavía no está configurado. '
            'No compartas contraseñas por correo.',
            key: Key('signup-closed'),
            style: TextStyle(color: FitDateColors.muted, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        TextButton(
          key: const Key('switch-entry-mode'),
          onPressed: () => setState(() => register = !register),
          child: Text(register ? 'Ya tengo cuenta' : 'Crear cuenta'),
        ),
        const Text('Solo adultos. FitDating requiere consentimiento '
          'independiente y verificación de edad. '
          'Tus gimnasios y horarios serán privados por defecto.',
          style: TextStyle(color: FitDateColors.muted, fontSize: 11)),
      ]),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite, color: FitDateColors.coral),
          SizedBox(width: 8),
          Flexible(child: Text('My Fitness Date',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800))),
        ]),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1110),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (width >= 780)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: story),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: access),
            ])
          else ...[story, const SizedBox(height: 18), access],
          const SizedBox(height: 25),
          const Card(child: ExpansionTile(
            key: Key('anonymous-pace-tool'),
            title: Text('Calculadora de ritmo · sin registro'),
            subtitle: Text('Tu herramienta deportiva gratuita sigue disponible'),
            leading: Icon(Icons.directions_run_outlined),
            children: [Padding(padding: EdgeInsets.all(12),
              child: PaceCalculator())],
          )),
          const SizedBox(height: 25),
          const Text('Perfiles y actividades de otras personas '
            'solo después de iniciar sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FitDateColors.muted, fontSize: 12)),
        ]),
      ))),
    );
  }
}
