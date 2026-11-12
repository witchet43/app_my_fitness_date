# Build 4 — Comunidad deportiva segura · My Fitness Date

**Estado:** Desarrollo aislado · validación pendiente. Piloto cerrado por defecto. **No es una autorización de beta pública.**
**Base acumulada:** B1 actividades/RSVP, B2 historial/cancelaciones, B3 marca global.
**Rama:** `feature/b4-community-safety-20261112`. **Presupuesto planeado:** B4 será el quinto job consumido en el plan 10/10; B9 ya se utilizó; B10 permanece reservado.

## Objetivo de valor
Un miembro adulto y con correo confirmado, que acepte expresamente la comunidad, puede compartir una publicación deportiva y ver contenido genuino. Puede reportar un post o perfil, bloquear a otra persona en ambos sentidos dentro del muro, retirar su propio texto y consultar historial personal. El propietario puede publicar avisos oficiales reales y gestionar una cola humana auditada, sin hacerse pasar por miembro.

## Vistas implementadas
- **Comunidad deportiva:** consentimiento `community-v1` separado de `dating-v1`; feed de texto real con categoría deportiva; publicación y retiro propios; reportar post o perfil; bloquear y desbloquear perfiles, paginación de 15.
- **Privacidad y baja:** historial propio, incluido contenido oculto/retirado; solicitud de eliminación con advertencia de que NO borra Auth, backups ni Storage automáticamente; oculta publicaciones y revoca acceso a la comunidad de forma inmediata.
- **Panel Administrador:** cola de denuncias sin identidad del denunciante, acciones `hide_post`, `suspend_user`, `dismiss` con justificación y auditoría; bandeja de solicitudes de baja; comunicaciones oficiales con límite y auditoría.
- **Protecciones server-side:** no chat, no mensajes directos, no matching, no lista de asistentes, no gimnasios ni horarios privados; texto limitado 15–480; rechazo básico de URLs, correos y teléfonos; 3 posts/hora, 10 reportes/día, 30 bloqueos nuevos/día y 5 comunicados oficiales/día. Todas las operaciones pasan por RPC que valida identidad; ninguna tabla comunitaria tiene lectura/escritura directa para anon/authenticated.

## Matriz de aceptación (requiere evidencia, CI no equivale a E2E)
| ID | Caso | Estado inicial |
|---|---|---|
| B4-01 | Usuario sin sesión/no confirmado/menor/sin perfil o términos no puede leer/publicar | POR PROBAR SQL/E2E |
| B4-02 | Usuario con términos y privacidad actuales, sin consentimiento social, ve opt-in; no se activa FitDating | POR PROBAR E2E |
| B4-03 | Miembro aceptado publica texto real; otro miembro lo ve sin correo, DOB, domicilio, gimnasio ni horarios | POR PROBAR E2E |
| B4-04 | Dos miembros se bloquean; en AMBOS sentidos desaparecen publicaciones inmediatamente tras refresh | POR PROBAR SQL/E2E |
| B4-05 | Bloqueo no se elude con petición REST/UUID; tabla de bloqueos no es directamente legible | POR PROBAR SQL/E2E |
| B4-06 | Reporte post/perfil único, sin enumeración, sin exponer identidad del denunciante | POR PROBAR SQL/E2E |
| B4-07 | Admin con MFA AAL2 ve cola, oculta/suspende/desestima y deja auditoría; miembro/admin AAL1 denegado | POR PROBAR SQL/E2E |
| B4-08 | Propietario publica comunicado genuino, visible a miembros y reversible con historial | POR PROBAR E2E |
| B4-09 | Rate-limit adversarial, carreras concurrentes, contenido prohibido | POR PROBAR SQL concurrencia |
| B4-10 | Baja oculta publicaciones y prohíbe nuevas; marca solicitud pendiente sin afirmar borrado completo | POR PROBAR SQL/E2E |
| B4-11 | Regresión B1–B3: login sin bucle, MVP actividades, RSVP, branding global MFA | PENDIENTE E2E REAL |
| B4-12 | Flutter analyze/tests/web build, API health/auth, preview SHA exacto y costo un job | PENDIENTE CI |
| B4-13 | Moderación humana, escalación incidentes, edad verificada externa, privacidad completa y gates #28 | **NO-GO PARA BETA** |

## Riesgos y pendientes explícitos
- Bloqueo bidireccional está garantizado **dentro de esta comunidad**. La exclusión integral en futuras pantallas de FitDating es parte de B5 y permanece NO-GO para citas.
- **No existe moderación automática confiable ni equipo humano operativo aún.** Los checks de texto son heurísticos, no filtros suficientes para usuarios reales sin apoyo humano.
- **Baja definitiva pendiente:** la solicitud genera trabajo para el operador y bloquea nueva actividad social; no elimina la cuenta, backups, pagos o fotografías. No prometer borrado sin evidencia.
- **Sin datos ficticios:** comunidad vacía si nadie publicó; el propietario puede crear un comunicado REAL. No sembrar publicaciones sintéticas en PROD.
- **Edad y seguridad:** 18+ autodeclarado no reemplaza proveedor independiente de verificación; beta pública bloqueada.
- **E2E entre dos identidades no es verificable desde las suites aisladas:** debe aprobarse con dos cuentas QA reales sin utilizar credenciales del propietario.
- Se necesita confirmar que la versión de Flutter realmente es accesible en navegador de usuario y que no se repite el bucle de login.
- La página principal y la aplicación distribuida continúan sin incluir B4 hasta una promoción explícita y gates aprobados.

## Criterio de salida de B4
Se exige compilación/test automatizados y, para considerar valor aceptado, demostración de post genuino, bloqueo real, reporte y acción moderadora con MFA con cuentas separadas. Si un criterio no pasa, se traslada a B5 **más** el alcance propio B5 sin gastar un nuevo build individual para arreglarlo. Detener nuevas ejecuciones en 10/10.

## Adiciones de privacidad B4 verificables
- `020_community_optout_b4.sql`: revocar consentimiento con salida voluntaria independiente de baja de cuenta. Al salir, se retiran las publicaciones y no se restauran al volver; se preservan reservas.
- `021_community_closed_pilot_b4.sql`: `community_pilot_b4` vacía por defecto y auditada. Sin invitación verificada por owner con MFA el backend devuelve `pilot_closed`, aunque la cuenta tenga perfil y consentimiento.
- El propietario puede autorizar o revocar **solo cuentas existentes con correo confirmado**, desde el panel de Moderación → Gestionar acceso al piloto cerrado. Revocación suprime al autor de la comunidad, sin eliminar otros datos.
- No existen cuentas QA creadas artificialmente ni publicaciones ficticias.
- La matriz B4 debe incluir prueba de cuenta no invitada, acceso invitado, revocación y reingreso; son pruebas **pendientes** con dos cuentas reales y MFA.
