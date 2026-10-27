# my_fitness_date — Despliegue V6: panel de moderación (DEV)

**Fecha:** 2026-10-27 (UTC)  
**Proyecto:** `my_fitness_date_dev` — `jtrdvnwbxpfdnbzasvcj`, `us-east-1`  
**Migración instalada:** `admin_moderation_audit_v6` — versión `20261027141137`.

## Componentes desplegados
- Tabla privada `app_private.moderators`: nombramientos **solo por SQL privilegiado**. No se designó a nadie durante el despliegue.
- Tabla privada `app_private.moderation_audit`: actor, reporte, decisión, estado previo/posterior, justificación y marca temporal.
- RPC autenticadas `public.is_moderator()`, `public.moderator_list_reports()`, `public.moderator_decide()`, `public.moderator_recent_actions()`. Las funciones internas requieren pertenencia actual a `app_private.moderators` para **cada** operación.
- Interfaz Expo en pestaña Moderación, visible solo cuando el servidor autoriza el rol, con filtros por estado, justificación obligatoria y confirmación explícita.

## Resultados de las pruebas en el PostgreSQL real
- Se ejecutó primero la migración y las pruebas en `BEGIN / ROLLBACK` antes del despliegue.
- Se aplicó la migración definitiva a Supabase.
- Se ejecutó nuevamente la suite social + seguridad V5 + moderación V6 en una transacción revertida con **cuatro usuarios estrictamente ficticios**.
- No moderador: lista y decisiones denegadas.
- Moderador autorizado de manera privilegiada: lectura de reportes, actualización de estado, ocultamiento y restauración de posts y auditoría.
- Revocación de rol: bloquea consultas inmediatamente para la misma sesión.
- Auditoría con 4 acciones registradas dentro de la transacción.
- Validación posterior: **0 usuarios Auth, 0 moderadores, 0 reportes, 0 entradas auditadas y 0 publicaciones ocultas** almacenadas.
- Supabase Security Advisor: ningún hallazgo crítico en el resultado. **9 avisos INFO** por tablas privadas con RLS activado y sin políticas de acceso directo; es el comportamiento buscado.
- Rol `anon` no ejecuta API administrativa; `authenticated` no puede autoasignarse, leer directamente la auditoría ni los reportes.

## Operación administrativa: nombrar/revocar moderadores
Nunca insertar UUID ficticio ni conceder rol por atributos `user_metadata`. Primero crear una cuenta de DEV controlada por el operador, verificar su UUID desde el proyecto y ejecutar **solo desde el SQL Editor con privilegios de administrador**:

```sql
-- Sustituir el marcador por un UUID verificado de la cuenta de DEV.
insert into app_private.moderators(user_id)
values ('UUID_VERIFICADO_DE_DEV'::uuid)
on conflict (user_id) do nothing;

-- Para revocar al instante:
delete from app_private.moderators
where user_id = 'UUID_VERIFICADO_DE_DEV'::uuid;
```

No exponer `service_role` al cliente. El permiso de una pestaña nunca sustituye el chequeo de servidor.

## Límites y decisiones pendientes
- El panel y backend **no constituyen un equipo de moderación en operación**. Faltan SLAs, guías de decisión, apelaciones, notificaciones a afectados y procedimiento de escalamiento.
- Una decisión sobre un usuario o evento actualiza el estado del reporte, pero no suspende el usuario o cancela el evento.
- La aplicación móvil aún **no** se ha probado en un dispositivo físico con cuentas Auth reales.
- Faltan verificación de edad/identidad, protección frente a inferencia por cuentas múltiples, respuesta a incidentes, eliminación integral y políticas de privacidad.
- El repositorio sigue público y las ramas PR #1, #6, #7, #8, #9 y #10 todavía no están fusionadas a `main`.
- No abrir el registro a personas externas ni publicar la beta.

## Referencias
- [PR #10](https://github.com/witchet43/app_my_fitness_date/pull/10)
- [Guía funcional V6](./ITERATION_6.md)
- [Proyecto Supabase DEV](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj)
