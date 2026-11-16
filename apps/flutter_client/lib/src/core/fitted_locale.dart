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
  int _languageChangeCount=0;
  Future<void> _restoreSavedChoice() async {
    try {
      final initialRevision=_languageChangeCount;
      final prefs=await SharedPreferences.getInstance();
      final authenticated=client.auth.currentUser?.userMetadata?['preferred_language'];
      final saved=prefs.getString('fitted-preferred-language');
      final next=(authenticated=='en'||authenticated=='es') ? authenticated
        :(saved=='en'||saved=='es'?saved:'es');
      if(initialRevision==_languageChangeCount && next!=_language){
        _language=next;notifyListeners();
      }
    }catch(_){/* No preferences storage: in-memory locale still works. */}
  }
  String get language=>_language;
  Locale get locale=>Locale(_language);
  bool get english=>_language=='en';

  Future<void> choose(String code) async {
    if(code!='es' && code!='en')throw ArgumentError('Unsupported language');
    if(code==_language)return;
    final prior=_language;
    _languageChangeCount++;
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
  static String translate(BuildContext context,String message)=>
    FittedTranslations.translate(message,languageOf(context));
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
    'Frecuencia de entrenamiento':'Training frequency',
    'Tipo de conexión (privado)':'Connection type (private)',
    'Preferencia social futura':'Future social preference',
    'Tipo':'Type',
    'Zona general (opcional)':'General area (optional)',
    'Cómo quieres que te llamemos':'What should we call you?',
    'Ciudad (sin dirección exacta)':'City (no street address)',
    'Tus deportes':'Your sports',
    'Ej. correr, senderismo, ciclismo':'E.g., running, hiking, cycling',
    '¿Con qué frecuencia entrenas?':'How often do you train?',
    'Familia de prueba':'Sample family',
    'Distribución':'Layout',
    'Tipo de recurso':'Asset type',
    'Licencia de uso declarada':'Declared usage license',
    'Actualizar catálogo':'Refresh catalog',
    'Actualizar estado':'Refresh status',
    '¿Qué buscas?':'What are you looking for?',
    'Mi ritmo deportivo':'My training rhythm',
    'Protección de mi gimnasio':'Gym privacy',
    'Buscar actividad, deporte o ciudad':'Search activities, sports or cities',
    'Borrar búsqueda':'Clear search',
    'Disciplina':'Discipline',
    'Ciudad o zona general (sin domicilio)':'City or general area (no address)',
    'Límite de participantes (1–200)':'Participant limit (1–200)',
    'Actualizar actividades':'Refresh activities',
    'Tema':'Topic',
    'Tu publicación':'Your post',
    'Motivo del reporte':'Report reason',
    'Contexto adicional (opcional)':'Additional context (optional)',
    'Opciones de la publicación':'Post options',
    'Actualizar muro':'Refresh feed',
    '1995-06-15':'1995-06-15',
    'Español, Inglés':'Spanish, English',
    'Café, viajes, música, naturaleza':'Coffee, travel, music, nature',
    'Familia, honestidad, curiosidad':'Family, honesty, curiosity',
    'Running, fuerza, yoga, ciclismo':'Running, strength, yoga, cycling',
    'Mi primer 10K, más fuerza, movilidad':'My first 10K, strength, mobility',
    'Terminé mi primer 21K, carrera de montaña':'Finished my first half marathon, trail running',
    'Mi plan favorito de fin de semana es...':'My favorite weekend plan is...',
    'Eliminar mi foto':'Delete my photo',
    'Guardar preferencias':'Save preferences',
    'Aceptar':'Accept',
    'Guardar y continuar':'Save and continue',
    'Sexo':'Gender',
    'Edad':'Age',
    'Gimnasio':'Gym',
    'Zona':'Area',
    'Entrenamiento':'Training',
    'Recovery':'Recovery',
    'Privacidad':'Privacy',
    'Términos':'Terms',
    'Continuar con Google':'Continue with Google',
    'Continuar con Apple':'Continue with Apple',
    'Entrar con correo':'Sign in with email',
    'No se pudo guardar el idioma / Could not save language':'Could not save language',

    'Participación confirmada y guardada de forma privada.':'Participation confirmed and saved privately.',
    'Actividad publicada correctamente.':'Activity published successfully.',
    'Entrar a la comunidad deportiva':'Join the sports community',
    'Administrar mis eventos':'Manage my events',
    'La participación es voluntaria. ':'Participation is voluntary. ',
    'Publicar actividad curada':'Publish curated activity',
    'Solo publica actividades verificadas. ':'Only publish verified activities. ',
    'Actividad guardada y visible en el catálogo.':'Activity saved and visible in the catalog.',
    'Cancelar actividad publicada':'Cancel published activity',
    'Este evento dejará de recibir reservas. ':'This event will no longer accept reservations. ',
    'Conservar actividad':'Keep activity',
    'Actividades de My Fitness Date':'Fitted activities',
    'Lo que publiques aquí aparecerá en el catálogo ':'What you publish here will appear in the directory ',
    'Todavía no hay actividades publicadas. ':'No activities have been published yet. ',
    'Evento cancelado':'Event cancelled',
    'Configura nombre, paletas, textos, logotipos y portadas. ':'Configure names, palettes, copy, logos and cover images. ',
    'Editar marca en vivo':'Edit live brand',
    'Publica actividades verificadas para los miembros y ':'Publish verified activities for members and ',
    'Ver como miembro (solo lectura)':'View as member (read-only)',
    'Gimnasios para Gym Shield':'Gyms for Gym Shield',
    'Catálogo de gimnasios reales para proteger ':'Directory of verified real gyms to protect ',
    'Revisa denuncias, oculta publicaciones, suspende ':'Review reports, hide posts and suspend ',
    'Los cambios de apariencia internos se guardan sin otro build. ':'Appearance changes are saved without another build. ',
    'Fuente WOFF2 cargada (requiere compilación)':'WOFF2 font uploaded (requires a build)',
    'Las fuentes WOFF2 se conservan en la biblioteca. ':'WOFF2 fonts remain in the library. ',
    'Cómo me muevo · Cómo vivo · Cómo me relaciono':'How I Move · How I Live · How I Relate',
    'El diseño de la portada ya usa esta marca global. ':'The landing page already uses this global brand. ',
    'Logo PNG o WebP':'PNG or WebP logo',
    'Tipografía WOFF2':'WOFF2 font',
    'Portada escritorio':'Desktop cover',
    'Portada móvil':'Mobile cover',
    'Imagen de acceso':'Sign-in image',
    'Imagen de onboarding':'Onboarding image',
    'Imagen interior':'Interior image',
    'Ilustración':'Illustration',
    'Licencia abierta compatible':'Compatible open license',
    'Soy titular de los derechos':'I own the rights',
    'Licencia comercial válida':'Valid commercial license',
    'Imágenes PNG/WebP/JPG hasta 8 MiB; fuentes WOFF2 hasta ':'PNG/WebP/JPG images up to 8 MiB; WOFF2 fonts up to ',
    'No se han creado borradores.':'No drafts have been created.',
    'Consultar historial':'View history',
    'Pulsa Consultar historial para ver las versiones guardadas.':'Select View history to see saved versions.',
    'Las contraseñas, los datos privados y las ':'Passwords, private data, and ',
    'My Fitness Date · Administrador':'Fitted · Administrator',
    'El rol administrador tiene acceso a funciones ':'The administrator role has access to features ',
    'Introduce esta clave en Google Authenticator o ':'Enter this key in Google Authenticator or ',
    'Reintentar configuración':'Retry setup',
    'Comparte una idea o pregunta deportiva. ':'Share an idea or sports question. ',
    'El texto desaparecerá del muro, ':'The text will be removed from the feed, ',
    'Bloquear a esta persona':'Block this person',
    'El reporte es privado y llegará a moderación. ':'Your report is private and goes to moderation. ',
    'Las publicaciones visibles llevan tu nombre público. ':'Visible posts show your public name. ',
    'Acepto participar en la comunidad':'I agree to participate in the community',
    'Volver a participar':'Rejoin community',
    'Comparte experiencias deportivas y conecta con ':'Share sports experiences and connect with ',
    'Reportes revisados por personas. ':'Reports are reviewed by people. ',
    'Cuenta desbloqueada.':'Account unblocked.',
    'No se pudo desbloquear.':'Could not unblock account.',
    'El bloqueo funciona en ambos sentidos dentro ':'Blocking works in both directions within ',
    'Tus publicaciones dejarán de mostrarse ':'Your posts will no longer appear ',
    'Conservar participación':'Stay in community',
    'Esta acción enviará una solicitud humana de baja, ':'This action sends a deletion request for human review, ',
    'Comprendo que es una solicitud, ':'I understand this is a request, ',
    'Conservar cuenta':'Keep account',
    'Puedes consultar los textos que compartiste, ':'You can review the content you shared, ',
    'No has creado publicaciones.':'You have not created any posts.',
    'Puedes dejar la comunidad sin eliminar tu cuenta ':'You can leave the community without deleting your account ',
    'Baja de cuenta':'Account deletion',
    'Solicitar eliminación de mi cuenta':'Request deletion of my account',
    'Resolver reporte':'Resolve report',
    'Las decisiones son definitivas en el historial ':'Decisions are permanently recorded in the audit history ',
    'Desestimar reporte':'Dismiss report',
    'Ocultar publicación':'Hide post',
    'Suspender en comunidad':'Suspend from community',
    'Confirmar decisión':'Confirm decision',
    'Decisión guardada y auditada.':'Decision saved and audited.',
    'Identidad del denunciante reservada.':'Reporter identity is confidential.',
    'Revisar y resolver':'Review and resolve',
    'Requiere gestión humana de retención, ':'Requires human review of retention, ',
    'Nuevo comunicado oficial':'New official announcement',
    'Tu comunicado será visible a los miembros ':'Your announcement will be visible to members ',
    'Publicar comunicado':'Publish announcement',
    'Comunicado oficial publicado para miembros de la comunidad.':'Official announcement published for community members.',
    'Retirar comunicado':'Remove announcement',
    'Dejará de mostrarse a los miembros. ':'It will no longer be shown to members. ',
    'Solo propietario con MFA. Las decisiones de ':'Owner with MFA only. Decisions involving ',
    'El acceso a una beta social real exige personal ':'Access to a real social beta requires staffed ',
    'Autorizar cuenta de prueba':'Authorize test account',
    'La cuenta ya debe existir en My Fitness Date ':'The account must already exist in Fitted ',
    'Autorizar acceso':'Authorize access',
    'Cuenta autorizada para el piloto.':'Account approved for the pilot.',
    'Revocar acceso de piloto':'Revoke pilot access',
    'Conservar acceso':'Keep access',
    'Revocar acceso':'Revoke access',
    'La comunidad permanece CERRADA para cuentas no ':'The community remains CLOSED to unapproved accounts ',
    'Ninguna cuenta está autorizada todavía. ':'No accounts are approved yet. ',
    'El acceso al piloto no constituye autorización para ':'Pilot access does not grant permission for ',
    'Compatibilidad no disponible o evidencia insuficiente.':'Compatibility is unavailable or evidence is insufficient.',
    'Solo miembros adultos elegibles y autorizados. ':'Eligible, approved adult members only. ',
    'Active Date: ideas, no reservas ni ubicaciones reales. ':'Active Date: ideas only, not bookings or actual locations. ',
    'FitDating · privacidad primero':'FitDating · privacy first',
    'Conecta con intención':'Connect with intention',
    'Explora lo que buscas y cómo disfrutas el deporte. ':'Explore what you seek and how you enjoy exercise. ',
    'Explora el concepto FITTED en español e inglés. ':'Explore Fitted in Spanish and English. ',
    'FitDating no está disponible con esta cuenta. ':'FitDating is unavailable for this account. ',
    'No se muestran perfiles ni se envían mensajes ':'Profiles are not shown and messages are not sent ',
    'Último paso · Gym Shield':'Final step · Gym Shield',
    'Ya tienes las verificaciones externas ':'You already have the external verifications ',
    'Completar protección y activar':'Complete protection and activate',
    'Mis preferencias':'My preferences',
    'Deportes que disfruto (hasta ocho)':'Sports I enjoy (up to eight)',
    'Este modo necesitará horarios privados ':'This mode requires private schedules ',
    'Separado de los términos y de la comunidad deportiva.':'Separate from the Terms and sports community.',
    'Dejar preparada mi solicitud de participación':'Prepare my participation request',
    'Solicitar participación no habilita ':'Requesting participation does not enable ',
    'Desactivar mi participación':'Turn off my participation',
    'Protecciones y requisitos':'Protection and requirements',
    'Ver personas, matches y conversaciones':'View people, matches and conversations',
    'La compatibilidad se explica, no se puntúa ':'Compatibility is explained, not scored ',
    'No hay perfiles compatibles disponibles.':'No compatible profiles available.',
    'La búsqueda y los mensajes permanecen ':'Discovery and messages remain ',
    'Solo el administrador con MFA puede registrar gimnasios. ':'Only an MFA-verified administrator can register gyms. ',
    'Todavía no hay gimnasios reales registrados.':'No real gyms are registered yet.',
    'Tu gimnasio y tus horarios son privados. ':'Your gym and schedule are private. ',
    'No hay gimnasios reales aprobados en el ':'There are no approved real gyms in the ',
    'Horarios privados para proteger tu rutina. ':'Private time slots protect your routine. ',
    'Running + gym':'Running + gym',
    'Running + running (otras prioridades)':'Running + running (different priorities)',
    'Tu perfil deportivo':'Your sports profile',
    'Solo lo esencial para encontrar actividades. ':'Only the essentials to find activities. ',
    'Estoy empezando':'Just getting started',
    '1–2 días':'1–2 days',
    '3–4 días':'3–4 days',
    '5 o más días':'5+ days',
    'Esta declaración no sustituye la ':'This statement does not replace ',
    'Volver a mi perfil':'Back to my profile',
    'La fecha no se publica y no constituye una verificación ':'The date is not public and does not constitute verification ',
    'Prefiero decidir después':'I\'d rather decide later',
    'Relación estable':'Long-term relationship',
    'Compañía o amistad':'Companionship or friendship',
    'Explorar con respeto':'Explore respectfully',
    'Miembros, al habilitarse':'Members, when enabled',
    'Guardar esta preferencia NO publica tu perfil ni ':'Saving this preference does NOT publish your profile or ',
    'Club de running':'Running club',
    'El gimnasio y los horarios no se compartirán.':'Your gym and schedule will not be shared.',
    'MI PERFIL · PRIVADO':'MY PROFILE · PRIVATE',
    'Hasta ocho fotos. Se eliminan metadatos y ':'Up to eight photos. Metadata is removed and ',
    'Carga de fotos suspendida hasta completar la sanitización y moderación del servicio.':'Photo uploads are paused pending sanitization and moderation.',
    'Revisa tu elegibilidad, registra el consentimiento separado y consulta personas compatibles cuando se apruebe tu verificación de edad.':'Review eligibility, give separate consent and discover compatible people after age verification is approved.',
    'Dejarás de tener un lugar reservado en esta ':'You will no longer have a reserved spot in this ',
    'Tu participación se canceló y guardó correctamente.':'Your participation was cancelled successfully.',
    'Consulta tus confirmaciones privadas y gestiona ':'Review your private confirmations and manage ',
    'La actividad dejará de aceptar reservas. ':'The activity will stop accepting bookings. ',
    'Actividad cancelada. Se conserva el historial.':'Activity cancelled. History is preserved.',
    'Como organizador autorizado, puedes revisar ':'As an approved organizer, you can review ',
    'Ya tengo contraseña: iniciar sesión':'I already have a password: sign in',
    'Volver a iniciar sesión':'Return to sign in',
    'No compartas tu contraseña ni el enlace de recuperación.':'Never share your password or password reset link.',

    'Personas en movimiento. Conexiones que trascienden.':
      'People in motion. Connections that go further.',
    'Entrenamiento, recovery y rutinas intencionales. Conecta por tus valores y estilo de vida, incluso si practican deportes distintos.':
      'Training, recovery, and intentional routines. Connect through shared values and lifestyle, even when you practice different sports.',
    'Entrenamiento, recovery y rutinas intencionales. Conecta con alguien por sus valores y estilo de vida, incluso si practican deportes distintos.':
      'Training, recovery, and intentional routines. Connect through values and lifestyle, even when you practice different sports.',
    'Personas en movimiento. Conexiones con intención.':
      'People in motion. Intentional connections.',
    'Conexiones con intención.':
      'Intentional connections.',
    'Conexiones con intención. Las funciones de citas se habilitarán cuando concluyan las verificaciones de seguridad.':
      'Intentional connections. Dating features will open when safety checks are complete.',

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
      return '${List.filled(prefix, ' ').join()}$value${List.filled(suffix, ' ').join()}';
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
