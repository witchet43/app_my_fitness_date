# my_fitness_date — Despliegue de seguridad V5 (DEV)

**Fecha:** 2026-10-27 (UTC)  
**Supabase:** `my_fitness_date_dev` — `jtrdvnwbxpfdnbzasvcj` (`us-east-1`)  
**Migración aplicada:** `trust_safety_reports_blocking_rate_limits_v5` — `20261027071950`

## Implementado y validado
- Denuncias privadas en `app_private.safety_reports` (usuarios, publicaciones, eventos); solo el backend acepta nuevos reportes mediante RPC autenticada.
- Ocultamiento administrativo de publicaciones en `app_private.hidden_posts`.
- Bloqueos recíprocos aplicados mediante RLS a perfiles sociales, publicaciones y actividades; Gym Shield ya bloqueaba candidatos románticos.
- Límite inicial por cuenta: 30 consultas Dating/hora y 12 guardados de configuración/día.
- Selección explícita del motivo de reporte en la UI de Comunidad, Actividades y Citas.

## Pruebas
- GitHub Actions: TypeScript, pruebas unitarias, generación bundle Android, casos PostgreSQL, aprobados.
- Tests de reportes, bloqueo, ocultamiento y cuotas ejecutados en el proyecto Supabase real junto con los tests sociales; identidades sintéticas en una transacción `BEGIN; ... ROLLBACK;`.
- Confirmados después del test: 0 cuentas Auth, 0 perfiles, 0 posts, 0 actividades, 0 reportes, 0 publicaciones ocultas y 0 contadores de frecuencia.
- Privilegios: rol `anon` **no** puede llamar `submit_safety_report`; `authenticated` puede enviar reportes pero **no** leer reportes u ocultar publicaciones por acceso directo.
- Security Advisor: sin alertas críticas; 7 avisos `INFO` por tablas privadas intencionalmente sin políticas, que mantienen denegado el acceso directo.

## Límites y riesgos abiertos
- **Los límites son mitigaciones parciales, no prevención completa de inferencia.** Crear múltiples cuentas y variar preferencias puede revelar información. Se requieren mecanismos adicionales, auditoría adversaria y monitoreo.
- La tabla de reportes no significa que exista personal de moderación en operación. No hay SLA, proceso de apelaciones ni panel administrativo.
- Los reportes no ocultan automáticamente contenido; un administrador debe tomar la decisión en un proceso controlado. Bloquear sí oculta el contenido al usuario.
- Falta verificación de edad e identidad, políticas de protección y respuesta a incidentes, eliminación de cuenta, revisión de datos personales y pruebas manuales en dispositivo con usuarios Auth.
- No subir secretos a GitHub. El repo sigue público: considerar privado. No lanzar beta pública ni aceptar personas reales.

## Operación de desarrollo (administradores)
Desde el SQL Editor del proyecto, con permisos de administración:

```sql
select id,target_type,target_id,reason,status,created_at
from app_private.safety_reports
where status='pending'
order by created_at
limit 50;
```

No copiar información de reportes a issues públicas ni publicar nombres, emails o datos reales. Las acciones de moderación todavía son manuales.
