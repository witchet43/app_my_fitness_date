# Despliegue de desarrollo — my_fitness_date

**Fecha:** 2026-10-27 (UTC)  
**Entorno:** Development only — no users reales

## Proyecto Supabase

- Nombre: `my_fitness_date_dev`
- Project ref: `jtrdvnwbxpfdnbzasvcj`
- Región: `us-east-1`
- Panel: https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj
- URL pública de API: `https://jtrdvnwbxpfdnbzasvcj.supabase.co`
- Migración aplicada: `private_dating_gym_shield_v1` (version registrada: `20261027061853`)
- Fuente SQL: `supabase/migrations/202610260001_private_dating.sql`

## Verificación real

- Estado Supabase `ACTIVE_HEALTHY`.
- `public.gyms`: 3 gimnasios **ficticios**.
- Tablas con RLS: `public.gyms`, `app_private.dating_profiles`, `app_private.training_slots`, `app_private.user_blocks`.
- El rol `anon` no tiene permisos de lectura de gimnasios ni de ejecución RPC dating.
- El rol `authenticated` puede leer el catálogo y ejecutar RPC, pero **no** leer directamente tablas privadas.
- Ejecutados contra PostgreSQL real los tests `private_dating_integration.sql` y `private_dating_edge_cases.sql`, con usuarios simulados **en una transacción revertida**.
- Resultado: ninguna aserción falló; revalidación posterior: 0 usuarios Auth, 0 perfiles, 0 horarios, 0 bloqueos. Sólo 3 gimnasios demo.

## Auditoría de Supabase

- Sin alertas críticas en `get_advisors(security)`.
- 3 avisos `INFO: rls_enabled_no_policy` para tablas privadas; son intencionales: se deniega SELECT/INSERT/UPDATE/DELETE directo, incluso a authenticated. Acceso por RPC privada con control de auth.uid().
- 3 avisos `INFO: unused_index`: esperados por ausencia de actividad real. No eliminar índices hasta contar con datos y métricas.

## Configurar app local

Crear un archivo `.env` local ignorado por Git:

```env
EXPO_PUBLIC_SUPABASE_URL=https://jtrdvnwbxpfdnbzasvcj.supabase.co
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_... # obtener desde Dashboard > API Keys
```

**No** copiar `service_role`, `sb_secret_...` ni tokens privilegiados a la app o al repositorio. La publishable key está diseñada para aplicaciones cliente y no es un secreto, pero **el servidor aplica los permisos**.

La interfaz Expo leerá ambas variables y entonces habilitará inicio de sesión y Gym Shield vía RPC. El entorno NO se conectó aún a la aplicación local ni se desplegó una app móvil.

## Pendientes antes de abrir registros externos

- Revisión de seguridad anti-inferencia y límites de frecuencia: distintas consultas podrían revelar pertenencia al gimnasio / horario.
- Verificación real de mayoría de edad; la fecha de nacimiento es autodeclarada.
- Consentimiento y avisos legales; reportes, moderación, abuso, mensajes y eliminación de cuenta.
- Prueba de flujo móvil extremo a extremo con Auth real, ajustes y RPC.
- Política de catálogo de gimnasios/sucursales y zonas horarias.
- PR #1 y PR #6 siguen en revisión. `main` no incluye todavía toda esta implementación.

**No promocionar esta versión como beta pública.**
