# Despliegue V7 — apelaciones y notificaciones internas

**Fecha:** 2026-10-27 (UTC)  
**Supabase:** `my_fitness_date_dev` — `jtrdvnwbxpfdnbzasvcj` (`us-east-1`)  
**Migración:** `moderation_appeals_private_inbox_v7` — versión `20261027143452`

## Alcance instalado
- Notificaciones por ocultamiento/restauración de publicaciones y resultado de apelaciones.
- Bandeja de avisos propia, con marcado individual de lectura.
- Recurso de apelación único por publicación oculta para su autor (20–500 caracteres).
- Segunda revisión por moderador diferente de quien ocultó originalmente la publicación.
- Decisión `upheld` o `overturned` con motivo obligatorio (10–300 caracteres).
- Restauración tras apelación favorable únicamente si no existe otra decisión de ocultamiento vigente.
- Auditoría separada de apelaciones, privada e inaccesible mediante SELECT de usuario.
- Interfaz Expo de Buzón y panel de Apelaciones.

## Validación y resultados
- La primera ejecución aislada de todos los tests en Supabase, con SQL V7 aún sin desplegar y todo encerrado en `BEGIN/ROLLBACK`, fue exitosa.
- La migración V7 se aplicó al proyecto de desarrollo.
- Se repitieron V4/V5/V6/V7 en PostgreSQL ya migrado. El escenario necesitó adaptar la cuenta de notificaciones: en una base V7 las pruebas históricas generan avisos también. **Después de corregir las aserciones, toda la suite pasó.**
- Comprobado al finalizar: **0 usuarios Auth, 0 moderadores, 0 apelaciones, 0 notificaciones, 0 auditorías de apelación, 0 reportes y 0 publicaciones** de prueba persistidos.
- Rol anónimo sin permiso de ejecutar operaciones de avisos o apelaciones. Usuarios autenticados no tienen lectura directa de ninguna tabla privada de notificaciones/apelaciones.
- Security Advisor: **sin alertas críticas**; 12 advertencias informativas `rls_enabled_no_policy` correspondientes a tablas privadas intencionadamente cerradas.
- GitHub Actions: typecheck, pruebas Node, bundle Android y test PostgreSQL incluidos.

## Límites
- No se enviarán correos ni notificaciones push; solo existen avisos **dentro de la aplicación**.
- No existe equipo operativo de moderación ni SLA de apelaciones. No hay moderadores ni cuentas reales designados.
- La aplicación todavía no ha sido probada físicamente desde un dispositivo móvil con sesiones Auth reales.
- No existen retención y borrado integral, verificación de edad/identidad, protección robusta anti-inferencia ni procedimiento completo de quejas y apelaciones.
- Las restricciones de Gym Shield siguen aplicándose solo a las recomendaciones románticas, no invisibilidad social.
- Este proyecto sigue siendo **solo desarrollo** y el repositorio aún es público.
- Los PR apilados permanecen abiertos; **no se fusionó a main**.

## Revisión operativa
Antes de una beta, preparar dos cuentas de moderación de desarrollo diferentes para probar la separación de funciones, y una cuenta de autor, todas controladas por el equipo. El administrador asignará el rol únicamente con SQL privilegiado y verificará la identidad real de la cuenta. No registrar cuentas ficticias permanentes desde scripts de pruebas.

Referencias:
- [PR #11](https://github.com/witchet43/app_my_fitness_date/pull/11)
- [Guía V7](./ITERATION_7.md)
- [Supabase DEV](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj)
