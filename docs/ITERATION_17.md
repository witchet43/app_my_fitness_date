# Iteración 17 — Moderación operativa, escalamiento y revisión independiente

## Qué se implementó

- Cola priorizada de denuncias visible **solo a moderadores autorizados**. Clasifica como urgente (motivo unsafe), alta (harassment) o normal (spam/other); indica el tiempo transcurrido y una **fecha objetivo orientativa** de revisión de 1, 4, 24 o 48 horas, respectivamente.
- Tabla `app_private.incident_escalations`: escalamiento por reporte con prioridad, responsable, explicación de 10–300 caracteres, estado abierto/cerrado y revisor independiente.
- Tabla `app_private.incident_audit`: historial de acciones de escalar/revisar, con responsables y notas. El acceso directo a ambas tablas está prohibido a `anon` y `authenticated`.
- RPC `moderator_incident_queue`, `moderator_escalate_report`, `moderator_review_escalation`, a través de wrappers públicos `SECURITY INVOKER` que ejecutan implementaciones protegidas en `app_private`.
- El moderador que escaló no puede cerrar su propia escalación. Tampoco puede revisar un incidente si lo denunció o él mismo es el denunciado.
- La función `moderator_decide` valida conflictos de interés y rechaza descartar, resolver o restaurar una publicación de un incidente escalado hasta que se complete la segunda revisión. Puede mantener la publicación oculta de forma preventiva.
- Pantalla `AdminIncidents` integrada al centro de moderación para revisión de colas, priorización y segunda firma. Sin identidad de los denunciantes en la respuesta al cliente.

## Operación recomendada — DEV, sin moderadores reales aún

1. Una persona moderadora autorizada abre la cola, revisa los incidentes por urgencia y verifica contenido relevante.
2. Si un caso requiere segunda revisión, pulsa Escalar, elige la prioridad y documenta el motivo. Se registra el escalamiento y la auditoría.
3. Un segundo moderador distinto revisa el contexto, escribe su justificación y firma el cierre de la escalación. El backend impide el autoaval.
4. La denuncia subyacente sigue abierta hasta que el moderador efectúe una decisión explícita. La revisión independiente **no** resuelve ni suspende por sí sola una cuenta.
5. Los casos inseguros deben tratarse con un protocolo de seguridad externa y una persona responsable. Una fecha objetivo incumplida solo aparece visualmente; **NO** hay alertas automáticas ni equipo de atención garantizado.

## Cobertura de regresión

- Anónimo y usuario no moderador no pueden ver ni cambiar incidentes.
- Escalamiento, imposibilidad de duplicados, defensa contra conflictos de interés, rechazo de cierre prematuro, revisión por persona distinta y cierre correcto auditado.
- Cola urgente con vencimiento orientativo y casos normales recientes.
- Pruebas en PostgreSQL, con usuarios sintéticos y `BEGIN/ROLLBACK`, tanto en CI como en Supabase DEV. La CI también compila los bundles Android e iOS.
- `main` permanece intacto y las funciones son compatibles con las migraciones previas de denuncias y apelaciones.

## Limitaciones para beta

Este incremento **no activa guardias humanos, notificaciones push, alertas externas, investigación automatizada de abuso ni suspensión de usuarios**. Ninguna persona real ha sido designada moderadora o atendida. La privacidad y seguridad de la aplicación siguen requiriendo procedimientos operativos, retención de evidencias, atención de emergencias, verificación independiente de edad y pruebas móviles reales. No abrir beta pública.

## Procedimiento para prueba con moderadores reales

No asignar el rol a un usuario final por metadatos JWT. El nombramiento debe ocurrir de forma privilegiada mediante `app_private.moderators`, solo después de autenticar y autorizar a la persona responsable, y revocarse al terminar la prueba. Las decisiones sobre contenido real requerirán política escrita y mecanismos de apelación.
