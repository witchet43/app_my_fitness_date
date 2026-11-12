# B1 · Primera entrega de valor — My Fitness Date
**Estado:** IMPLEMENTADO EN RAMA · SIN QA E2E/RELEASE APROBADO · NO DESPLEGADO.
**Rama:** `feature/b1-member-activities-rsvp-20261112`
**Budget:** B1 utiliza como máximo una unidad remota una vez D0 controle todos los triggers. Los ensayos locales no consumen cupo remoto.
**Relaciones:** backlog #65 · acceso/perfil #3 · actividades #5 · retención posterior #66.

## Problema y oportunidad
Una persona adulta con intereses deportivos quiere encontrar una actividad y confirmar su asistencia voluntariamente sin publicar su gimnasio, horario privado, domicilio o preferencias románticas. El login por sí solo no aporta valor.

## Alcance B1 (una sola vertical)
1. **Identidad y sesión:** Supabase Auth por email, correo confirmado; recuperación y logout, cancelación/red/timeout; roles comprobados antes de datos, administrador nunca entra como miembro por fallo de permisos. Google OAuth se muestra solo si ya está verificado/configurado.
2. **Onboarding mínimo:** nombre visible, ciudad general, 1–16 deportes, frecuencia, fecha de nacimiento privada y declaración 18+. Aceptación previa de términos/privacidad (ya existente); persiste en `member_profiles_v26` con `social_visibility=private` y `onboarding_complete=true`. No activa citas. Verificación independiente de edad para FitDating permanece una puerta separada.
3. **Catálogo curado:** GET de hasta 25 actividades futuras, publicadas por organizadores aprobados, descripción, deporte, ciudad general, fecha, capacidad y estado de RSVP del propio usuario. Pantalla vacía honesta sin fixtures que pretendan ser actividades reales.
4. **Organizadores autorizados:** la aprobación del organizador se mantiene en `app_private.event_organizers`, fuera del alcance del usuario normal. Solo un organizador aprobado puede publicar título, descripción, deporte, ciudad general, inicio futuro y cupo 1–200; el backend usa identidad derivada del JWT, nunca user_id enviado por cliente.
5. **RSVP privado:** el RPC `confirm_activity_rsvp` comprueba la identidad confirmada, membresía no anónima, perfil completo de adulto, aceptación de términos/privacidad, actividad futura y publicada. Bloquea la fila del evento para que dos usuarios simultáneos no superen la capacidad. Repetir RSVP del mismo usuario devuelve `already_confirmed`, no duplica ni revela a otros participantes.
6. **Resultado observable:** confirmación guardada en `public.event_rsvps` y el botón de la tarjeta pasa a "Participación confirmada". Un refresco posterior reconstruye el estado con los datos del servidor.
7. **B2, no B1:** historial completo "Mis actividades", cancelación, notificaciones de cambios y estados ampliados. El RSVP se persiste desde B1 para poder construir B2 sin migrar datos.

## Criterios de aceptación obligatorios
| Caso | Prueba requerida | Estado |
|---|---|---|
| AC-01 | Cuenta QA con correo confirmado inicia sesión una sola vez, no entra en bucles y puede cerrar sesión | PENDIENTE E2E |
| AC-02 | Un miembro declara 18+, guarda perfil mínimo, vuelve a entrar y ve datos guardados | PENDIENTE E2E |
| AC-03 | Menor, identidad anónima, perfil incompleto o sin consentimiento no puede confirmar RSVP ni llamar al RPC | PENDIENTE SQL/E2E |
| AC-04 | Organizador no aprobado no ve creación de eventos y REST rechaza inserción aun si forja endpoint | PENDIENTE SQL/E2E |
| AC-05 | Organizador aprobado crea evento válido; el resto de miembros lo encuentra con datos no sensibles | PENDIENTE E2E |
| AC-06 | RSVP de usuario A guardado; refresca y permanece; usuario B no puede leer RSVPs de A | PENDIENTE SQL/E2E |
| AC-07 | Dos solicitudes simultáneas al último cupo producen 1 confirmación y 1 `full`, nunca sobreventa | PENDIENTE SQL CONCURRENCIA |
| AC-08 | RSVP repetido es idempotente; actividad vencida, oculta o completa rechaza nuevo RSVP | PENDIENTE SQL/E2E |
| AC-09 | Sin eventos aparece estado vacío honesto; red caída muestra error/reintento, sin spinner infinito | PENDIENTE WIDGET/E2E |
| AC-10 | Flutter 390px y desktop, navegación teclado, textos 200%, accesibilidad y contraste revisados | PENDIENTE QA |
| AC-11 | Solo un build remoto B1 y sin triggers de producción automáticos; artefacto inmutable y rollback | BLOQUEADO POR D0 |
| AC-12 | Release bajo autorización expresa; gates reales de beta (9 pendientes) impiden abrir acceso al público | NO-GO HASTA GATES |

**Regla de término:** CI verde NO equivale a B1 completo. Se necesitan evidencias E2E de navegador, Postgres/RLS, QA de interacción y aceptación del propietario. No declarar producción ni beta sin gates.

## Contratos de API (JWT end-user obligatorio)
| Verbo | Ruta | Resultado |
|---|---|---|
| GET | `/v1/activities` | `{items:[{id,title,description,sport,city,starts_at,capacity,joined}]}` |
| GET | `/v1/me/organizer-status` | `{approved:boolean}` |
| POST | `/v1/organizer/activities` | `{activity:...}` 201; solo organizador |
| POST | `/v1/activities/:uuid/rsvp` | `{status:"confirmed"|"already_confirmed"}`; 403 no autorizado; 409 lleno/vencido |

No exponer: email, DOB, gimnasio, entrenamiento, attendee list, ubicación exacta, motivos privados de exclusión, datos de otros miembros, keys privilegiadas ni logs de tokens.

## Modelo y diseño
- Reutiliza `public.member_profiles_v26`, `public.member_consents_v26`, `public.sport_events`, `public.event_rsvps`, `app_private.event_organizers`.
- Migración B1 agrega `capacity`, `is_published`, FK al usuario organizador y RPC transaccional; elimina INSERT directo RSVP.
- Edge Function autenticada con JWT de usuario real; ninguna clave `service_role`; RLS para perfil, eventos y RSVPs. SECURITY DEFINER solo en RPC limitado y sin datos privados devueltos.
- UX Flutter: `MemberOnboardingB1` → `MemberProfileHomeV26` / `ActivitiesB1`, API mediante `ActivityRepository` testeable.
- Servidor devuelve resultado explícito, UI solo muestra confirmación después del ACK. Un error no modifica estado local.
- `MFD_ALLOWED_ORIGIN` define un único origen confiable por despliegue Edge, por defecto el dominio PROD. Ningún CORS wildcard.

## Riesgos / mitigación
- **No hay actividades ni organizadores en la BD actual:** la pantalla vacía es esperada. QA requiere crear un organizador QA aprobado en un entorno aislado, no sembrar un evento inventado en producción.
- **Faltan herramientas Flutter/Postgres en este entorno de trabajo:** código y casos de prueba fueron añadidos, pero NO se afirma que corrieron. Ejecutar suites localmente antes del único build autorizado.
- **Acceso histórico en bucle:** ruta `refresh()` coalescida y validación de sesión con tiempos límite; probar varias sesiones, MFA admin y recuperación en navegador real.
- **Gates de beta:** moderación humana, seguridad externa, verificación de edad, legal, borrado y dispositivos físicos siguen siendo NO-GO. D1/B1 se valida en QA con cuentas autorizadas.
- **Costos:** el tope 10/10 sigue siendo una política documental hasta que D0 controle triggers de PR/push/schedule. No abrir PR/merge ni desplegar de forma automática antes de ello.

## Revisión por etapas SDLC
Análisis y aceptación: presente en este documento.
Diseño arquitectura/datos/API: presente en migración y endpoints.
Implementación: rama aislada.
Pruebas unitarias/contrato: archivos agregados, ejecución local pendiente.
Pruebas integración y seguridad: pendientes.
QA UX, regresión y aceptación: pendientes.
Publicación: bloqueada (D0 + gates).
Operación y observabilidad: métricas sin PII deben validarse antes de activarlas.
