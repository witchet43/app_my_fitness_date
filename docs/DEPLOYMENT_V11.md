# my_fitness_date — Iteración 11, validación de integración DEV

**Fecha:** 27 de octubre de 2026  
**Supabase DEV:** `my_fitness_date_dev` (`jtrdvnwbxpfdnbzasvcj`, `us-east-1`)  
**GitHub:** [PR #15](https://github.com/witchet43/app_my_fitness_date/pull/15), rama `feat/qa-end-to-end-v11`

## Entregables

- Prueba transaccional `supabase/tests/mvp_e2e_v11.sql` integrada al CI.
- Prueba de dos identidades QA sintéticas en perfiles, comunidad, actividades y Gym Shield.
- Casos de Gym Shield 29 minutos prohibido / 30 minutos admitido, consentimiento recíproco y gimnasio diferente.
- Solicitud de baja que retira perfiles del descubrimiento y evita nuevas publicaciones.
- Barra de navegación móvil horizontal desplazable para todas las pestañas (incluida moderación, cuando procede).

## Evidencia real

- [GitHub Actions #40534019398](https://github.com/witchet43/app_my_fitness_date/actions/runs/40534019398): **SUCCESS**. TypeScript, unitarios, generación de bundle Android, PostgreSQL y nuevo test E2E SQL aprobados.
- Misma prueba SQL V11 ejecutada contra PostgreSQL hospedado en Supabase `my_fitness_date_dev` **dentro de BEGIN/ROLLBACK**, aprobada.
- Verificación inmediatamente después de ejecutar el test alojado:
  - `auth.users`: **0**
  - `public.social_profiles`: **0**
  - `public.community_posts`: **0**
  - `public.sport_events`: **0**
  - `public.event_rsvps`: **0**
  - `app_private.dating_profiles`: **0**
  - `app_private.account_deletion_requests`: **0**
- Sin migraciones adicionales, cambios persistidos en Supabase ni bajas definitivas.

## Qué NO se ha probado

**La prueba SQL simula autenticación mediante roles/JWT en PostgreSQL**; no se ha iniciado sesión realmente mediante Supabase Auth/GoTrue con correo y contraseña. No se ha probado la UI en un emulador Android ni en teléfono físico. La compilación del bundle Android no prueba visualmente navegación, pulsaciones o accesibilidad.

- Hosted Auth en DEV conserva **0 cuentas QA confirmadas**, por lo que `npm run smoke:dev` no pudo ejecutarse con dos sesiones reales.
- Para registro/correo de prueba, Supabase recomienda entorno local con Mailpit; ver [Test auth flows](https://supabase.com/docs/guides/auth/testing-auth-flows).
- Ningún token, secreto, contraseña o dato identificable se ha publicado.
- Faltan verificación de edad, políticas de protección de datos, pruebas de teléfono y moderación operativa. **No abrir beta pública**.

## Siguiente bloque de validación

1. Preparar dos cuentas QA creadas por los flujos oficiales de Auth en un entorno controlado, con correos de prueba confirmados. **No insertar identidades directamente en auth.users del servicio administrado**.
2. Ejecutar `npm run smoke:dev` mediante credenciales locales seguras, sin compartirlas en chat o GitHub.
3. Repetir flujo real en Android y iOS, cambio de cuentas, baja pendiente y rechazo por pérdida de conexión.
4. Capturar solo resultados y errores despersonalizados. No registrar gimnasios ni horarios privados en logs.
5. Realizar revisión de seguridad y legal antes de invitar usuarios reales.

El código sigue en PR encadenado sobre #14; `main` permanece intacto.
