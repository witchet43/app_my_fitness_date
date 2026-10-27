# Iteración 4 — comunidad deportiva y actividades (desarrollo)

## Objetivo
my_fitness_date debe funcionar como red social deportiva **sin requerir activar FitDating**.

## Entregables
- Sesión global de Supabase: un registro sirve para las tres secciones.
- Social Profiles: nombre público, ciudad, deportes. No contiene gimnasio, horarios, fecha de nacimiento ni preferencias románticas.
- Feed de publicaciones: crear, consultar y borrar sólo publicaciones propias. Máximo 500 caracteres.
- Actividades: consultar próximos eventos aprobados y gestionar participación voluntaria.
- La lista de participantes **no es pública**; cada cuenta sólo puede consultar su propia asistencia.
- Crear eventos sólo con autorización administrativa mediante `app_private.event_organizers`, nunca `user_metadata`.
- RLS explícita en las tablas `public.social_profiles`, `community_posts`, `sport_events` y `event_rsvps`.
- CI: TypeScript, pruebas unitarias, bundle Expo Android y casos PostgreSQL de suplantación/roles/RSVP.

## Límites intencionales
- No hay verificación real de edad. El registro está limitado a declaraciones de adultos y NO es apto para apertura pública.
- No hay moderación, denuncia, fotos ni eliminación integral de cuenta; no publicar externamente.
- No existen organizadores aprobados reales, por lo que el calendario estará vacío hasta su autorización.
- Las actividades mostradas son por ciudad y fecha, sin ubicación en vivo ni horarios habituales de gimnasio.
- Gym Shield aplica a *Dating*, NO hace invisibles publicaciones, perfiles públicos o eventos sociales.
- No se utiliza `service_role` en móvil, SQL de prueba ni repositorio.

## Probar local
Crear un archivo `.env` que no se sube a GitHub con:
```dotenv
EXPO_PUBLIC_SUPABASE_URL=https://jtrdvnwbxpfdnbzasvcj.supabase.co
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_OBTENER_EN_SUPABASE_DASHBOARD
```
Ejecutar `npm install`, `npm run typecheck`, `npm test`, `npm start`.
Para un despliegue contra datos de prueba, aplicar la migración V4 en el proyecto de desarrollo; usar dos cuentas de prueba para validar autoría de publicaciones y RSVP sin dar de alta Dating.

## Seguridad
La creación de eventos requiere aprobación administrativa explícita. No añadir autorizaciones basadas en `raw_user_meta_data`. Las acciones son sólo para la cuenta del token JWT; en otro dispositivo se requiere autenticar nuevamente.

**Pendiente:** pruebas manuales reales con dos cuentas de Auth en teléfono/simulador, bloqueo/reportes integrales y revisión antispam antes de la beta.
