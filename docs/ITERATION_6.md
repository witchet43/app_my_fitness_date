# Iteración 6 — Moderación administrativa (solo DEV)

## Alcance implementado
- Alta de moderadores **exclusivamente mediante SQL privilegiado**, sin API de autoasignación.
- Panel integrado en la app Expo: pestaña Moderación visible si `public.is_moderator()` responde true. **Cada API verifica el permiso de nuevo**; ocultar la pestaña NO es seguridad.
- Bandeja de reportes con filtros por `pending`, `reviewing`, `resolved`, `dismissed` y `all`, máximo 50 por llamada.
- Decisiones: `review`, `dismiss`, `resolve` y, para posts, `hide_post`/`restore_post`.
- Justificación obligatoria de 5–200 caracteres y confirmación explícita en la interfaz antes de ejecutar.
- Tabla `app_private.moderation_audit` inmutable para el usuario, con actor, acción, estado previo y posterior, motivo y marca temporal.
- El reportante **no** se expone por la API de listado. Se muestra un resumen del elemento denunciado y los detalles del reporte para el moderador.

## Nombramiento y revocación seguros
El proyecto `my_fitness_date_dev` empieza **sin moderadores designados**. Se requiere una cuenta real de DEV existente; no inventar UIDs.

Operación autorizada al **administrador de base de datos**, desde Supabase SQL Editor:

```sql
-- Solo ejecutar tras revisar y verificar el UUID de una cuenta de DEV:
insert into app_private.moderators(user_id)
values ('UUID_REAL_VERIFICADO'::uuid);
-- Revocación inmediata:
delete from app_private.moderators
where user_id = 'UUID_REAL_VERIFICADO'::uuid;
```

No se debe usar `user_metadata` ni llamar a estas tablas desde la app con service_role.

## Pruebas
- Rechazar acceso anónimo a RPC administrativas.
- Usuario autenticado no moderador: permiso false, lectura y decisiones rechazadas.
- Moderador nombrado mediante SQL privilegiado puede listar reportes y decidir.
- Post puede ocultarse/restaurarse; decisiones auditadas con estado previo/nuevo.
- Nota demasiado corta rechazada.
- Revocación de membresía efectiva incluso en sesión que aún existe.
- Logs de auditoría inaccesibles por lectura/escritura directa para usuarios.

## Limitaciones
- Aún no existe equipo humano 24/7, SLA de reportes, notificación al denunciante, apelación, retención ni política de privacidad integral.
- Resolver un reporte de cuenta o evento solo actualiza el estado: NO suspende usuarios ni eventos. Las acciones disciplinarias requieren un incremento dedicado.
- Ocultar una publicación solo impide verla con los permisos RLS; no sustituye una evaluación legal o de riesgos.
- Los modelos de rate limiting y edad son incompletos para la beta pública. No invitar personas externas.
- No se modifica la rama `main`. El PR V6 depende del PR V5.
