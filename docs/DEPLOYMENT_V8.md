# my_fitness_date — Despliegue de privacidad V8 (desarrollo)

**Fecha:** 2026-10-27 (UTC)  
**Proyecto:** `my_fitness_date_dev`, ref `jtrdvnwbxpfdnbzasvcj`, región `us-east-1`  
**Migración:** `account_export_deletion_request_v8`, versión `20261027145857`

## Entregado
- `public.my_account_export()`: instantánea JSON del usuario autenticado (solo información propia, sin hashes de contraseñas, tokens ni datos de denuncias recibidas).
- `public.my_account_status()`: estado de solicitud de baja.
- `public.request_account_deletion()` y `public.cancel_account_deletion()`: solicitud reversible y cancelación.
- `app_private.account_deletion_requests`: solicitudes privadas, sin SELECT directo a usuarios.
- Al solicitar baja: desactivar Dating, excluir al usuario del descubrimiento por otros gimnasios, ocultar perfiles/publicaciones/eventos, impedir publicaciones/RSVPs y suspender permisos de moderación.
- Al cancelar: restaurar visibilidad social y autorización previa de moderación si existía, sin reactivar Dating.
- Interfaz de Cuenta con exportación técnica por Share y solicitud de baja con reingreso de contraseña y confirmación textual. Es una confirmación cliente, **no MFA ni reautenticación fuerte verificada en PostgreSQL**.

## Verificaciones ejecutadas
- GitHub CI para código TypeScript, pruebas unitarias, bundle Android y pruebas PostgreSQL: aprobado antes del despliegue.
- Preflight completo de pruebas V4–V8 y migración V8 dentro de una transacción `BEGIN ... ROLLBACK` en Supabase real, aprobado.
- Migración aplicada al proyecto DEV exitosamente.
- Pruebas V4–V8 repetidas contra la base ya migrada, usando cuatro identidades ficticias y `ROLLBACK`, aprobadas.
- Después: **0 cuentas Auth**, 0 perfiles sociales, 0 perfiles Dating, 0 solicitudes de eliminación, 0 apelaciones y 0 notificaciones de prueba.
- Control de privilegios: anon **no** ejecuta exportación ni solicitud de baja; authenticated puede llamar exportación propia pero **no** tiene SELECT directo en la tabla de solicitudes.
- Supabase Security Advisor: **sin alertas críticas**, 13 avisos INFO por RLS sin políticas en tablas de `app_private` intencionalmente cerradas.

## Regla operativa fundamental
La solicitud de baja **NO elimina la identidad de Supabase Auth ni purga tablas/backups**. La marca `earliest_review_at` representa el inicio de una revisión después de 7 días, **no** ejecución programada ni promesa de borrado. Esta iteración no envía ninguna baja a un administrador ni inicia una automatización.

## Runbook para baja definitiva (PENDIENTE, NO EJECUTAR AÚN)
Antes de habilitar el borrado irreversible:
1. Definir la base jurídica, plazos de conservación, datos sujetos a preservación y proceso de soporte.
2. Auditar las referencias hacia `auth.users`, especialmente `app_private.appeal_decision_audit.reviewer_id` con `ON DELETE RESTRICT`, y las referencias históricas de `moderation_audit.actor_id`. Prever anonimización/retención controlada y eliminación segura de datos sin integridad referencial rota.
3. Verificar almacenamiento, copias de seguridad, tokens y sesiones Auth activas.
4. Implementar una operación privilegiada de borrado Auth documentada y protegida, no disponible desde la aplicación pública, y confirmar su efecto en PostgreSQL/Storage.
5. Probar con varias cuentas ficticias y reportes cruzados en una base efímera: preservar solo lo legalmente necesario y no dejar datos personales huérfanos.
6. Ofrecer al usuario confirmación final con pruebas de ejecución, manejo de errores, canales de revisión y asistencia.

**No ejecutar SQL `DELETE FROM auth.users` como sustituto del flujo de Auth hasta resolver las dependencias.** No guardar claves service_role en el repositorio ni en Expo.

## Limitaciones
- Exportación es una copia técnica parcial, **no** exportación legal/completa de backups, logs y todos los sistemas.
- No hay test real en teléfono con cuentas Auth controladas.
- Falta verificación real de edad/identidad, eliminación completa, protección contra multi-cuentas e inferencia de Gym Shield y moderación con SLAs.
- Las ramas #1, #6–#12 siguen apiladas sin fusionar a `main`; el repositorio sigue público.
- No abrir la beta pública.

## Referencias
- [PR #12](https://github.com/witchet43/app_my_fitness_date/pull/12)
- [Guía de desarrollo V8](./ITERATION_8.md)
- [Supabase DEV](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj)
