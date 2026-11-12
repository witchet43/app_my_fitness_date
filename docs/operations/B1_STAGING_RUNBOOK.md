# B1 · Runbook seguro de integración, QA y liberación
**Estado:** SIN EJECUTAR. No aplicar SQL ni desplegar a producción desde este documento.
**Issue maestro:** https://github.com/witchet43/app_my_fitness_date/issues/65

## 0. No desperdiciar el único build remoto
- Comprobar consumo facturable real. No confundir ejecuciones con minutos; revisar costos de Cloud Build en proyecto compartido por build.
- Con permiso explícito, controlar ANTES los workflows `CI MVP`, `Flutter and microservices V22`, `Local Auth E2E`, `Cloudflare Pages production`, scripts y crons. No abrir PR mientras puedan lanzar varios jobs por una sola edición.
- No ejecutar matrices remotas ni reintentos automáticos. Contar cada job como cupo. Mantener B9/B10 como contingencias.
- Usar pruebas locales para commits intermedios y validación manual; alojada solo para paquete B1 consolidado.

## 1. Revisión local (0 cupos)
1. `npm ci && npm run typecheck && npm test` (incluye `scripts/activity-b1.test.ts`).
2. Levantar stack Supabase **local/QA** siguiendo versión CLI fijada por repo; consultar `supabase --help` y `supabase migration --help` antes de cada comando.
3. Aplicar migración `202611120016_activity_rsvp_b1.sql` a la BD QA; verificar restricciones, grants, policies y advisors. No usar PROD para pruebas.
4. En `apps/flutter_client`, con Flutter SDK del workflow: `flutter pub get`, `flutter analyze --no-fatal-infos`, `flutter test`, build web local. Después de comprobar compilar iOS/Android localmente según disponibilidad.
5. Verificar nativamente 390/768/1440px, teclado, zoom 200%, manejo de error, sesión vencida.
6. Verificar que ningún secreto, token MFA, DOB o horarios privados se registra en CI, HTTP ni capturas.

## 2. Base de datos QA y personas sintéticas
- Crear **dos cuentas de prueba adultas** mediante el mecanismo normal de Auth local, sin reutilizar credenciales reales.
- Completar datos privados de perfil y registrar versiones vigentes de términos/privacidad mediante API.
- Aprobar **solo el user_id de la cuenta organizadora QA** en `app_private.event_organizers` mediante un operador privilegiado (nunca exponer INSERT directo a miembros). No inventar credenciales ni UUID en scripts de producción.
- Organizador crea un evento futuro con capacidad 1; miembro A reserva; miembro B intenta el último cupo, recibe `full`. Repetir con 2 llamadas simultáneas en transacciones independientes, verificar conteos.
- Confirmar que `INSERT public.event_rsvps` directo con JWT falla, porque solo el RPC comprueba cupos.
- Verificar que ningún usuario distinto puede consultar RSVPs ajenos, lugares privados o fechas de nacimiento.

## 3. Edge API de QA
- Desplegar `member-api-v26` actualizada en un **proyecto local/staging**, nunca junto a datos reales antes del GO.
- Configurar explícitamente `MFD_ALLOWED_ORIGIN` con un único origen exacto de staging; por defecto producción permanece sin cambios.
- Comprobar GET `/healthz` y GET rutas autenticadas con JWT QA; rechazar sin Auth, bajo edad, no consentido, no organizador, doble RSVP y cupos agotados. Verificar que CORS no refleja orígenes arbitrarios.
- Sólo tras lo anterior, configurar `MFD_API_BASE_URL` de Flutter para ese gateway de QA.

## 4. Inspección y aceptación de producto
Evidencia grabada **sin credenciales, DOB, correo ni códigos MFA**:
- Cuenta nueva se registra, confirma email, acepta términos, crea perfil mínimo sin bucles.
- Organizador autorizado crea una actividad real de QA, claramente etiquetada QA y sin ubicación exacta.
- Miembro entra al catálogo, confirma RSVP, recarga y observa el estado persistente.
- Error de red, 401, 403, 409, doble pulsación, eventos vacíos, vencidos y no aprobados.
- Logout y regreso a la página sin mostrar datos de otro usuario.
- Verificar que Admin/MFA sigue protegido, sin regresión del panel por login miembro.

## 5. Única validación alojada, si D0 está gobernado
- Solicitar permiso explícito para gastar el cupo **B1/10** y lanzar un **único job remoto controlado** que ejecute todos los test/smoke necesarios. Un job fallido también consume B1, NO repetir automáticamente.
- Archivar SHA exacto, logs, artefacto, resultados, checklist y deuda pendiente.
- Si se requiere un segundo intento, necesitará consumir uno de B9/B10 o replanificar un cupo siguiente bajo autorización; **nunca disparar varios workflows** por PR/push.
- Publicar únicamente mediante promoción autorizada de un artefacto verificado, sin compilar otra vez. No activar funciones sociales sensibles reales mientras los 9 gates beta sigan pendientes.

## 6. Decisiones GO/NO-GO
**NO-GO** ante: RLS inválida, sobreventa de capacidad, filtración de datos, login cíclico, acceso a menores, fallos de navegación, email/Auth sin validar, riesgos de edad/moderación, o falta de aprobación del propietario.
**GO para QA/STAGING** solo con pruebas locales, Postgres, Flutter y E2E pasando.
**GO para beta/PROD** solo después de revisión de seguridad/legal y de los gates `release/readiness.json`; no se declara automáticamente por la pantalla publicada.

## 7. Pendientes acumulables
Toda aceptación B1 faltante se traslada de forma explícita a B2 junto con el alcance propio de B2. No rebajar controles de seguridad por la regla de carryover; mantener fail-closed y estado NO-GO.
