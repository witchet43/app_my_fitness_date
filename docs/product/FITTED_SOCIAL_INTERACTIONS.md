# Fitted — lenguaje social: FIT, PULSE, SYNC e IMPULSO

**Versión:** 1.0 · **Fecha:** 2026-11-17  
**Decisión de producto:** los cuatro conceptos están aprobados como lenguaje funcional de Fitted por su propietario.  
**Estado:** especificación aprobada; implementación, pruebas y liberación pendientes de evidencia. No autoriza activación productiva.  
**Trazabilidad:** [Issue #126](https://github.com/witchet43/app_my_fitness_date/issues/126) · [Índice de producto](README.md) · [Matriz de origen](LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md) · [Concepto exploratorio](FITTED_EXPLORATORY_CONCEPT_2026.md). Esta decisión posterior al PDF no modifica la fuente histórica ni resuelve por sí sola otras decisiones abiertas.

## 1. Propósito

Fitted crea un vocabulario propio para conectar personas con estilos de vida activos e intención de relación seria. Reconocer una actividad no equivale a interés romántico; afinidad sugerida no equivale a consentimiento. El primer valor es descubrir personas compatibles y expresar interés respetuosamente, sin presión de popularidad. Público prioritario: adultos mayores de 40 años; identidad elegante, sobria y deportiva, sin clichés románticos.

| Concepto | Tipo | Significado | Icono orientativo |
| --- | --- | --- | --- |
| IMPULSO | Reacción social | Reconozco o celebro algo que compartiste. | Rayo |
| PULSE | Espacio de actividad | Descubro tu ritmo de vida y lo que decides compartir. | Pulso |
| FIT | Interés personal | Quiero conocerte mejor. | Flecha ascendente |
| SYNC | Conexión recíproca | Ambos queremos conocernos. | Eslabones |

PULSE no es un botón de interés ni indicador de presencia en tiempo real. SYNC no es un score ni se obtiene por cantidad de impulsos.

## 2. Reglas funcionales

### IMPULSO
- Reacción a una publicación, foto, logro o actividad visible en PULSE; no a un dato privado. Equivalente conceptual de reconocimiento deportivo, no de interés de pareja.
- Una reacción activa por actor y contenido; puede retirarse. Reintentos idempotentes sin duplicar registros ni notificaciones.
- Visibilidad de reacciones y conteos según privacidad del autor y contenido. No crear rankings de personas.
- Bloqueo, eliminación de contenido o pérdida de autorización impiden nuevas reacciones y ocultan información a actores no autorizados.
- Copy: «Dar Impulso», «Impulso enviado», «Recibiste un Impulso».

### PULSE
- Espacio de perfil/actividad con publicaciones, avances, intereses y retos que la persona decide compartir. Complementa How I Move, How I Live y How I Relate.
- Permite publicar, editar, eliminar y controlar audiencia; privado por defecto hasta publicación voluntaria. Puede existir un perfil sin PULSE publicado.
- No exige conectar fuentes deportivas. Actividades importadas, resúmenes de integraciones (incluido Strava/Fitted Connect), rutas, horarios, gimnasios o datos de salud no se publican automáticamente. La fase privada de Fitted Connect sigue privada; cualquier publicación futura de datos de integración requiere decisión separada, permisos y revisión contractual.
- No mostrar ubicaciones exactas, recorridos ni señales de presencia; sanear imágenes y metadatos.
- Copy: «Mi Pulse», «Explorar Pulse», «Tu Pulse tiene novedades».

### FIT
- Acción explícita, discreta y reversible de interés personal desde Discovery o un perfil elegible. No requiere IMPULSO ni visitar PULSE.
- Solo participantes adultos verificados y con consentimiento para citas; elegibilidad, Gym Shield, bloqueos y límites vigentes se evalúan en servidor.
- FIT unilateral es privado; no constituye contador, ranking, señal pública ni habilita chat. Solo emisor y destinatario autorizado pueden acceder a la información mínima necesaria según privacidad; no revelar a terceros ni motivos de exclusión.
- Permitir enviar/retirar antes de reciprocidad; idempotencia. No confundir FIT con recomendaciones de Fit-IA.
- Copy: «Dar FIT», «FIT enviado», «Retirar FIT», «Alguien te dio FIT» (notificación discreta configurable).

### SYNC
- Dos FIT vigentes y recíprocos, sujetos a comprobación actual de elegibilidad, consentimiento, Gym Shield y bloqueos bilaterales. El servidor crea una conexión única por par, transaccionalmente.
- Solo ambos participantes autorizados ven la conexión. Habilita la posibilidad de conversar cuando chat esté autorizado y operativo; nunca un mensaje automático, obligación de responder o publicación pública.
- Cualquiera puede terminar el SYNC. Desactivar citas, perder elegibilidad o bloquear revoca acceso; bloqueo impide recontacto. Tratamiento de mensajes históricos sujeto a revisión legal y de seguridad.
- Copy: «¡Están en SYNC!», «Iniciar conversación», «Terminar SYNC», «Conexión finalizada».

## 3. Flujo y estados

Recorrido posible: PULSE → IMPULSO → FIT → SYNC → conversación. No obligatorio: FIT directo está permitido; IMPULSO jamás crea FIT automáticamente.

| Evento | Condición | Resultado |
| --- | --- | --- |
| Ver PULSE | Audiencia válida | Contenido autorizado |
| Dar/retirar IMPULSO | Contenido accesible | Reacción activa/retirada |
| A da FIT a B | Elegibilidad bilateral | Interés unilateral pendiente |
| B da FIT a A | Dos FIT activos y elegibles | SYNC activo, único |
| Retirar FIT unilateral | Emisor autorizado | Interés retirado |
| Terminar SYNC | Cualquiera de ambos | Conexión terminada, acceso a chat revocado |
| Bloquear/reportar | Política de seguridad | Bloqueo revoca contacto; reporte se tramita por moderación |

No duplicar conexiones por concurrencia; si permisos cambian, prevalece denegación. Una nueva conexión requiere nueva acción explícita bilateral y no puede eludir bloqueos; detalle de recontacto sujeto a revisión antiabuso.

## 4. UX y notificaciones

Identidad Fitted: fondo azul petróleo/pizarra #1A2D38, menta #8EF0D5, secundario #68D4C7; iconos diferenciados, sin corazones, tipografía legible. WCAG 2.2 AA, etiquetas accesibles, navegación por teclado/lector, estados vacío/carga/error/offline y controles táctiles adecuados. Color nunca es la única señal. Mantener nombres FIT, PULSE, SYNC e IMPULSO; copy localizado ES/EN. No rachas, presión, rankings ni pay-to-rank.

Notificaciones configurables por categoría, deduplicadas y condicionadas a autorización vigente. No exponer identidad, fotos, preferencias, ubicaciones o historial de citas en vistas previas de push/correo. No usar avisos como consentimiento de contacto.

## 5. Diseño técnico candidato (no implementado)

Flutter web/Android/iOS con componentes reutilizables; dominio detrás de Gateway/BFF y persistencia versionada Supabase con RLS y privilegios mínimos. Reutilizar elegibilidad, Gym Shield, contenido, notificaciones y moderación; no introducir microservicios por defecto. OpenAPI, autorización servidor por actor/recurso, idempotencia, rate limits, transacciones y auditoría sin PII. Fit-IA no puede dar FIT/IMPULSO o crear SYNC automáticamente.

Modelo lógico candidato: contenido PULSE (autor, audiencia, estado); IMPULSO (actor, contenido, estado); FIT (emisor, destinatario, estado); SYNC (par canónico, estado, timestamps); preferencias de notificación. Definir retención/borrado, índices y restricciones antes de migrar. No exponer tablas privadas directamente. Mantener bloqueo/reporte gratuito, antispam, antiacoso y antiinferencia de Gym Shield. Ningún dato deportivo privado se comparte por dar FIT o entrar en SYNC.

## 6. Requisitos y criterios verificables

IDs SI-01..SI-12 adicionales, independientes de las 84 referencias históricas al PDF. Todos pendientes de implementación y validación.

| ID | Requisito | Criterio de aceptación |
| --- | --- | --- |
| SI-01 | IMPULSO independiente | Reintentos producen una reacción; retirar no crea FIT |
| SI-02 | Control de PULSE | Crear/editar/eliminar; tercero fuera de audiencia no consulta ni reacciona |
| SI-03 | Importaciones privadas | Importar actividad/resumen no crea publicación ni acceso de terceros |
| SI-04 | FIT explícito | FIT directo sin IMPULSO; no elegible recibe denegación sin motivo privado |
| SI-05 | FIT unilateral privado | Tercero no enumera intereses; no abre chat; permite retirar |
| SI-06 | SYNC recíproco | Dos FIT elegibles generan un único SYNC aun con concurrencia |
| SI-07 | Revocación | Terminar SYNC/desactivar citas/bloquear revoca chat; bloqueo impide recontacto |
| SI-08 | Gym Shield | Preservar consentimiento bilateral y buffer de 30 minutos cuando corresponda; no revelar ubicación/horarios |
| SI-09 | Notificaciones | Preferencias respetadas, sin duplicados ni previews sensibles |
| SI-10 | UX accesible | Cuatro conceptos distinguibles, accesibilidad y copy ES/EN |
| SI-11 | Seguridad | Tests negativos BOLA/RLS, abuso, enumeración, retención y concurrencia con bloqueo |
| SI-12 | Métricas saludables | Telemetría agregada y minimizada sin rankings, mensajes, ubicaciones o PII |

## 7. Backlog y validación

Secuencia propuesta, pendiente de planificación: (1) contratos, amenazas, UX; (2) PULSE e IMPULSO opt-in; (3) FIT y SYNC con Gym Shield; (4) notificaciones, chat solo tras gates, accesibilidad y E2E multiplataforma. Reutilizar infraestructura y evitar costos/despliegues innecesarios.

Validar comprensión de los cuatro conceptos, facilidad de retirar interés y percepción de control/seguridad. Métricas agregadas candidatas: activación voluntaria, FIT recíprocos, SYNC a primera conversación, reportes/bloqueos y satisfacción; sin resultados todavía.

Dependencias de release: edad verificada, opt-in, revisión legal/privacidad, moderación, pruebas sintéticas y negativas, QA física y gates G0–G5 de SaaS Factory v1.9. No se modifica release/readiness.json ni se aprueban gastos, permisos, cambios legales, tiendas o producción por esta decisión.
