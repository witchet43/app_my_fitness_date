# my_fitness_date — Iteración 4 desplegada en DEV

**Fecha UTC:** 2026-10-27  
**Proyecto Supabase:** `my_fitness_date_dev` — `jtrdvnwbxpfdnbzasvcj`  
**Zona de datos:** `us-east-1`  
**Migración:** `social_profiles_community_events_v4` — versión `20261027064749`

## Cambios implantados

| Tabla | Lectura | Escritura |
| --- | --- | --- |
| `public.social_profiles` | Usuarios autenticados | Solo propietario, nombre público/ciudad/deportes |
| `public.community_posts` | Usuarios autenticados | Solo autor crea y elimina |
| `public.sport_events` | Usuarios autenticados | Solo organizador aprobado en base de datos, eventos futuros |
| `public.event_rsvps` | Solo dueño de la inscripción | Solo dueño confirma y cancela |
| `app_private.event_organizers` | Sin acceso directo de usuario | Solo administración privilegiada |

Los datos románticos y horarios continúan en `app_private` separados. La comunidad no requiere activar Dating.

## Validaciones efectuadas

- GitHub Actions del PR #8 en verde: TypeScript, pruebas Node, bundle Android y pruebas de integración PostgreSQL.
- Migración aplicada con resultado de éxito en Supabase real.
- Prueba en PostgreSQL real, en una transacción `BEGIN/ROLLBACK` con cuatro identidades ficticias: 
  - Lector anónimo sin permisos.
  - Publicación propia permitida, suplantación de autor denegada.
  - Creación de evento prohibida para no aprobados, permitida para organizador autorizado.
  - RSVP propio visible y ajeno oculto.
  - Eliminación de publicación de otro autor impedida.
  - Cancelación de RSVP propio permitida.
- Revisión posterior: 0 usuarios Auth, 0 perfiles sociales, 0 publicaciones, 0 eventos, 0 RSVPs, 0 organizadores aprobados.
- Supabase Security Advisor: 4 avisos informativos `rls_enabled_no_policy` en tablas privadas (diseño de denegación explícita), sin alertas de alta gravedad en la respuesta.

## Advertencias

- No existe todavía un flujo manual validado con dos cuentas de Auth desde un teléfono.
- Eventos permanecen vacíos hasta aprobar un organizador real dentro de un ambiente de prueba. No asignar organizadores por `user_metadata`.
- Faltan moderación de posts, reporte/bloqueo social, verificación de edad, protección ante scraping/inferencia y eliminación integral de cuenta.
- Registro por email puede estar disponible según las opciones por defecto de Supabase; **no invitar ni registrar usuarios externos**.
- No hay despliegue de aplicación de producción.
- El repositorio se encuentra **público**, por lo que no debe contener tokens ni datos privados. Solo usar la clave `publishable` en cliente; nunca `service_role` ni secret keys.
- PR #8 depende de #7 → #6 → #1, todos aún bajo revisión; `main` no ha sido modificado.

### Enlaces
- [Supabase DEV](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj)
- [PR #8](https://github.com/witchet43/app_my_fitness_date/pull/8)
- [Guía V4](./ITERATION_4.md)
