import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A display preference, NEVER an authorization signal.
/// Supabase Auth stores the preference in the signed-in user's metadata.
class FittedLocaleController extends ChangeNotifier {
  FittedLocaleController(this.client) {
    final stored=client.auth.currentUser?.userMetadata?['preferred_language'];
    _language=stored=='en'?'en':'es';
    unawaited(_restoreSavedChoice());
  }
  final SupabaseClient client;
  String _language='es';
  Future<void> _restoreSavedChoice() async {
    try {
      final prefs=await SharedPreferences.getInstance();
      final authenticated=client.auth.currentUser?.userMetadata?['preferred_language'];
      final saved=prefs.getString('fitted-preferred-language');
      final next=(authenticated=='en'||authenticated=='es') ? authenticated
        :(saved=='en'||saved=='es'?saved:'es');
      if(next!=_language){_language=next;notifyListeners();}
    }catch(_){/* No preferences storage: in-memory locale still works. */}
  }
  String get language=>_language;
  Locale get locale=>Locale(_language);
  bool get english=>_language=='en';

  Future<void> choose(String code) async {
    if(code!='es' && code!='en')throw ArgumentError('Unsupported language');
    if(code==_language)return;
    final prior=_language;
    _language=code;
    notifyListeners();
    try {
      final prefs=await SharedPreferences.getInstance();
      await prefs.setString('fitted-preferred-language',code);
    }catch(_){/* Persist to account metadata below when available. */}
    if(client.auth.currentSession==null)return;
    try {
      await client.auth.updateUser(UserAttributes(
        data:{'preferred_language':code},
      ));
    }catch(_){
      _language=prior;
      notifyListeners();
      try {
        (await SharedPreferences.getInstance()).setString(
          'fitted-preferred-language',prior);
      }catch(_){}
      rethrow;
    }
  }
  void syncFromSession() {
    final stored=client.auth.currentUser?.userMetadata?['preferred_language'];
    final next=(stored=='en'||stored=='es')?stored:_language;
    if(next==_language)return;
    _language=next; notifyListeners();
  }
}

class FittedLocaleScope extends InheritedNotifier<FittedLocaleController> {
  const FittedLocaleScope({
    super.key,
    required FittedLocaleController controller,
    required super.child,
  }):super(notifier:controller);

  static FittedLocaleController? maybeOf(BuildContext context)=>
    context.dependOnInheritedWidgetOfExactType<FittedLocaleScope>()?.notifier;
  static String languageOf(BuildContext context)=>
    maybeOf(context)?.language??'es';
  static String t(BuildContext context,String es,String en)=>
    languageOf(context)=='en'?en:es;
}

class FittedText extends StatelessWidget {
  const FittedText(this.data,{
    super.key,this.style,this.strutStyle,this.textAlign,this.textDirection,
    this.locale,this.softWrap,this.overflow,this.textScaler,this.maxLines,
    this.semanticsLabel,this.textWidthBasis,this.textHeightBehavior,
    this.selectionColor,
  });
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  @override
  Widget build(BuildContext context)=>Text(
    FittedTranslations.translate(data,FittedLocaleScope.languageOf(context)),
    style:style,strutStyle:strutStyle,textAlign:textAlign,
    textDirection:textDirection,locale:locale,softWrap:softWrap,
    overflow:overflow,textScaler:textScaler,maxLines:maxLines,
    semanticsLabel:semanticsLabel,textWidthBasis:textWidthBasis,
    textHeightBehavior:textHeightBehavior,selectionColor:selectionColor,
  );
}

abstract final class FittedTranslations {
  static const Map<String,String> en={
    'UNA CONEXIÓN A TU ALTURA':'A CONNECTION THAT MATCHES YOUR AMBITION',
    'TU PRÓXIMO CAPÍTULO':'YOUR NEXT CHAPTER',
    'CONEXIONES CON INTENCIÓN':'INTENTIONAL CONNECTIONS',
    'Para personas activas que buscan algo auténtico. Porque compartir valores importa tanto como compartir una pasión.':
      'For active people looking for something real. Shared values matter as much as shared passions.',
    'Crea tu cuenta y descubre una forma distinta de conectar.':
      'Create an account and discover a different way to connect.',
    'Accede a tu espacio y continúa donde lo dejaste.':
      'Sign in to your space and pick up where you left off.',
    '¿Ya tienes cuenta? Inicia sesión':'Already have an account? Sign in',
    '¿Aún no tienes cuenta? Regístrate':'New here? Sign up',
    'Un estilo de vida en común':'A lifestyle in common',
    'Conoce personas que valoran el bienestar y el movimiento.':
      'Meet people who value wellness and movement.',
    'Afinidad con intención':'Intentional compatibility',
    'Conecta por valores, intereses y manera de vivir.':
      'Connect through values, interests, and the way you live.',
    'Privacidad antes que exposición':'Privacy comes first',
    'Tu rutina y tus espacios de entrenamiento son privados.':
      'Your routines and training locations stay private.',
    'Conexiones con intención. Las funciones de citas se habilitarán cuando concluyan las verificaciones de seguridad.':
      'Intentional connections. Dating features will open when safety checks are complete.',
    'Mi perfil 360°':'My 360° profile',
    'Mi perfil':'My profile',
    'Completa tu perfil':'Complete your profile',
    'Quién eres como persona y cómo disfrutas el movimiento.':
      'Who you are and how you enjoy movement.',
    'Mi lugar de entrenamiento':'My training location',
    'Mis objetivos':'My goals',
    'Mis logros':'My achievements',
    'Solo yo':'Only me',
    'Solo tú ves estos lugares. Nunca mostramos ':'Only you can see these places. We never show ',
    'Añadir lugar privado':'Add private place',
    'Guardar':'Save',
    'Guardar cambios':'Save changes',
    'Editar perfil':'Edit profile',
    'Cancelar':'Cancel',
    'Cerrar sesión':'Sign out',
    'Reintentar':'Try again',
    'Volver':'Back',
    'Continuar':'Continue',
    'Salir de mi cuenta':'Sign out',
    'Tu acceso está protegido':'Your access is protected',
    'Necesitamos validar tu cuenta.':'We need to verify your account.',
    'Tu privacidad primero':'Your privacy comes first',
    'Antes de crear tu perfil':'Before creating your profile',
    'Tu perfil comienza privado. FitDating requiere verificación independiente y consentimiento posterior.':
      'Your profile starts private. FitDating requires independent verification and separate consent.',
    'Leer Términos de uso':'Read Terms of Use',
    'Leer Aviso de privacidad':'Read Privacy Notice',
    'He leído y acepto los Términos':'I have read and accept the Terms',
    'He leído el Aviso de privacidad':'I have read the Privacy Notice',
    'Declaro ser mayor de 18 años':'I confirm I am 18 or older',
    'La declaración no sustituye la verificación externa de edad.':
      'This declaration does not replace independent age verification.',
    'Guardando...':'Saving...',
    'Entrar':'Sign in',
    'Registrarme':'Sign up',
    'Iniciar sesión':'Sign in',
    'Crear cuenta con correo':'Create account with email',
    'Correo electrónico':'Email address',
    'Contraseña':'Password',
    'Crear o recuperar mi contraseña':'Create or reset my password',
    'No fue posible iniciar sesión con Google.':'Could not sign in with Google.',
    'No fue posible iniciar sesión con Apple.':'Could not sign in with Apple.',
    'Tu próxima actividad':'Your next activity',
    'Tu agenda es privada: solo muestra tus reservaciones.':
      'Your agenda is private: only your bookings are shown.',
    'Volver a intentar':'Try again',
    'Aún no tienes próximas actividades confirmadas.':
      'You have no confirmed upcoming activities.',
    'Explora actividades reales y reserva tu lugar.':
      'Explore real activities and reserve your spot.',
    'Participación confirmada':'Booking confirmed',
    'Explorar actividades':'Explore activities',
    'Mis reservas':'My bookings',
    'Explorar actividades deportivas':'Explore sports activities',
    'Mis actividades y reservas':'My activities and bookings',
    'Explorar FitDating':'Explore FitDating',
    'Comunidad deportiva':'Sports community',
    'Mis actividades':'My activities',
    'Tus próximas experiencias':'Your upcoming experiences',
    'Próximas':'Upcoming',
    'Anteriores':'Past',
    'Sólo próximas':'Upcoming only',
    'Todos los deportes':'All sports',
    'Todas las ciudades':'All cities',
    'Limpiar filtros':'Clear filters',
    'Crear actividad deportiva':'Create a sports activity',
    'Publicar actividad':'Publish activity',
    'Explorar actividades':'Explore activities',
    'Reintentar':'Try again',
    'Cupo máximo':'Capacity',
    'Aún no hay actividades publicadas. No mostramos ':
      'No activities have been published yet. We do not show ',
    'No encontramos actividades con esos filtros. ':
      'No activities match those filters. ',
    'Todavía no tienes actividades reservadas. ':
      'You have no booked activities yet. ',
    'Cancelar participación':'Cancel participation',
    'Conservar mi lugar':'Keep my spot',
    'Sí, cancelar':'Yes, cancel',
    'Cancelar esta actividad':'Cancel this activity',
    'Cancelar evento':'Cancel event',
    'Actividades organizadas':'Organized activities',
    'Mis eventos publicados':'My published events',
    'Aún no has publicado actividades.':'You have not published any activities.',
    'Cancelado':'Cancelled',
    'Comunidad opcional':'Optional community',
    'Compartimos el movimiento':'Movement connects us',
    'Crear publicación':'Create post',
    'Compartir con la comunidad':'Share with the community',
    'Retirar mi publicación':'Remove my post',
    'Retirar publicación':'Remove post',
    'Compartir con la comunidad':'Share with the community',
    'Conservar':'Keep',
    'Publicar':'Publish',
    'Enviar reporte':'Submit report',
    'Reportar publicación':'Report post',
    'Reportar perfil':'Report profile',
    'Reportar comunicado':'Report announcement',
    'Bloquear persona':'Block person',
    'Bloquear':'Block',
    'Personas bloqueadas':'Blocked people',
    'Desbloquear':'Unblock',
    'Salir de la comunidad':'Leave community',
    'Privacidad y baja':'Privacy and deletion',
    'Solicitar baja de cuenta':'Request account deletion',
    'Enviar solicitud de baja':'Submit deletion request',
    'Tus publicaciones':'Your posts',
    'Participación voluntaria':'Voluntary participation',
    'No tienes personas bloqueadas.':'You have no blocked people.',
    'Todavía no hay publicaciones. ':'No posts yet. ',
    'Seguridad de la comunidad':'Community safety',
    'Moderación de comunidad':'Community moderation',
    'Reportes pendientes':'Pending reports',
    'No hay reportes pendientes.':'No pending reports.',
    'No hay solicitudes de baja pendientes.':'No pending deletion requests.',
    'Publicar comunicado oficial':'Publish official announcement',
    'Todavía no hay comunicados oficiales.':'No official announcements yet.',
    'Gestionar acceso al piloto cerrado':'Manage closed pilot access',
    'Acceso a piloto cerrado':'Closed pilot access',
    'Autorizar participantes':'Authorize participants',
    'Autorizar cuenta registrada':'Authorize registered account',
    'Revocar':'Revoke',
    'Catálogo de gimnasios':'Gym directory',
    'Gimnasios administrados':'Managed gyms',
    'Confirmar gimnasio real':'Verify real gym',
    'Registrar':'Register',
    'Gym Shield · catálogos':'Gym Shield · directories',
    'Configurar Gym Shield':'Configure Gym Shield',
    'Añadir franja privada':'Add private time slot',
    'Compatibilidad de vida':'Lifestyle compatibility',
    'Compatibilidad antes que mismo deporte':'Compatibility beyond the same sport',
    'Personas compatibles':'Compatible people',
    'Todavía no hay perfiles autorizados. ':'No eligible profiles yet. ',
    '¿Por qué somos compatibles?':'Why are we compatible?',
    'Me interesa':'I’m interested',
    'Matches mutuos':'Mutual matches',
    'Aún no hay interés recíproco.':'No mutual interest yet.',
    'Interés confirmado por ambas personas':'Both people expressed interest',
    'Solo habrá match si ambos expresan interés.':
      'A match happens only when both people express interest.',
    '¿Te interesa conocer a esta persona?':'Would you like to meet this person?',
    'Expresar interés':'Express interest',
    'Reportar y bloquear a esta persona':'Report and block this person',
    'Reporte enviado y cuenta bloqueada.':'Report submitted and account blocked.',
    'Chat privado solo después de un match mutuo. ':
      'Private chat is available only after mutual interest. ',
    'Se requieren suficientes respuestas para calcular.':
      'More answers are needed to calculate compatibility.',
    'Calculadora del match':'Match Calculator',
    'Ponderaciones · total 100 %':'Weights · total 100%',
    'Restaurar':'Restore defaults',
    'Guardar ponderaciones · requiere MFA':'Save weights · MFA required',
    'No se pudo cargar la configuración. Verifica MFA y la migración del servidor.':
      'Could not load settings. Verify MFA and server migrations.',
    'Simulador auditable con perfiles ficticios. Un mismo deporte no es requisito: intención, estilo de vida, entrenamiento, recuperación y autonomía se ponderan juntos.':
      'Auditable simulator with fictional profiles. Shared sports are not required: intent, lifestyle, training, recovery, and autonomy are weighted together.',
    'Prototipo de cálculo, no política activa en producción. guardar ponderaciones NO activa el descubrimiento real. Faltan evaluación y controles de seguridad del motor.':
      'Scoring prototype. Saving weights does NOT enable real discovery; safety evaluation and controls are still required.',
    'Marca en vivo':'Live brand',
    'Diseñador de Marca':'Brand Designer',
    'Calculadora del match':'Match Calculator',
    'Resumen':'Overview',
    'Biblioteca':'Library',
    'Borradores':'Drafts',
    'Historial':'History',
    'Nombre y comunicación':'Name and messaging',
    'Paletas y colores':'Palettes and colors',
    'Mis paletas guardadas':'My saved palettes',
    'Crear paleta en catálogo':'Create palette',
    'Tipografía':'Typography',
    'Logotipos del catálogo':'Logo collection',
    'Volver a los logos del catálogo':'Back to logo collection',
    'Vista oscura':'Dark mode',
    'Editorial':'Editorial',
    'Minimalista':'Minimal',
    'Guardado automático activo':'Autosave enabled',
    'Vista previa en vivo':'Live preview',
    'Móvil':'Mobile',
    'Conocer nuestra propuesta':'Explore our vision',
    'Sincronizar':'Sync',
    'Actividades deportivas':'Sports activities',
    'Administrar actividades':'Manage activities',
    'Administrar gimnasios':'Manage gyms',
    'Moderación y privacidad':'Moderation and privacy',
    'Seguridad de comunidad':'Community safety',
    'No hay solicitudes de revisión ni builds por cada cambio.':
      'Brand changes do not require additional builds or approvals.',
    'No hay recursos privados.':'No private assets yet.',
    'Aún no hay recursos privados.':'No private assets yet.',
    'Comenzar una propuesta nueva':'Start a new proposal',
    'Ver historial del borrador':'View draft history',
    'Diseños guardados':'Saved designs',
    'Reporte':'Report',
    'Cerrar':'Close',
    'Confirmar':'Confirm',
    'Aprobar':'Approve',
    'Eliminar':'Delete',
    'Estado':'Status',
    'Activo':'Active',
    'Inactivo':'Inactive',
    'Fecha':'Date',
    'Título':'Title',
    'Descripción':'Description',
    'Nombre':'Name',
    'Ciudad':'City',
    'Deporte':'Sport',
    'Hora':'Time',
    'Detalles':'Details',
    'Guardar cambios':'Save changes',
    'Editar':'Edit',
    'Actualizar':'Refresh',
    'Sin información':'No information',
    'Aún sin información':'No information yet',
  };

  static String translate(String source,String language) {
    if(language!='en')return source;
    final exact=en[source];
    if(exact!=null)return exact;
    final compact=source.trim();
    final value=en[compact];
    if(value!=null){
      final prefix=source.length-source.trimLeft().length;
      final suffix=source.length-source.trimRight().length;
      return '${' '*prefix}$value${' '*suffix}';
    }
    return source;
  }
}

class FittedLanguageSelector extends StatelessWidget {
  const FittedLanguageSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final ctrl=FittedLocaleScope.maybeOf(context);
    if(ctrl==null)return const SizedBox.shrink();
    return Semantics(
      label:'Language / Idioma',
      child:DropdownButton<String>(
        key:const Key('fitted-language-selector'),
        value:ctrl.language,
        underline:const SizedBox.shrink(),
        items:const [
          DropdownMenuItem(value:'es',child:Text('ES')),
          DropdownMenuItem(value:'en',child:Text('EN')),
        ],
        onChanged:(v)async{
          if(v==null)return;
          try {
            await ctrl.choose(v);
          }catch(_){
            if(context.mounted){
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content:Text(
                  'No se pudo guardar el idioma / Could not save language')));
            }
          }
        },
      ),
    );
  }
}
