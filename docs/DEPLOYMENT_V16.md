# V16 — Despliegue en Supabase DEV y controles de elegibilidad

**Fecha:** 2026-10-27  
**Proyecto:** `my_fitness_date_dev` (`jtrdvnwbxpfdnbzasvcj`), us-east-1  
**Migración instalada:** `adult_eligibility_gymshield_v16`, versión `20261027215402`  
**PR:** [#20](https://github.com/witchet43/app_my_fitness_date/pull/20)

## Alcance instalado
1. `app_private.adult_eligibility`: estado privado de revisión, fecha de caducidad, revocación y referencia opaca al procedimiento externo.
2. RPC `public.my_adult_eligibility()`, accesible únicamente al usuario autenticado, que expone solo `approved`, `expires_at` y `source`; nunca el ticket de revisión.
3. RPC `public.operator_set_adult_eligibility(...)` ejecutable solamente por `service_role`. Permite conceder/revocar de forma controlada, con expiración máxima de 180 días.
4. Verificación `app_private.adult_eligible()` dentro de funciones privadas de configuración y descubrimiento. Las cuentas sin revisión o con revisión vencida no pueden activar ni ver perfiles Dating.
5. Revocación desactiva las citas automáticamente; la caducidad deja de autorizar el acceso aunque exista una configuración previa.
6. Gym Shield mantiene el margen 30 minutos y la privacidad de exclusiones; máximo 10 perfiles por consulta y 10 solicitudes de descubrimiento por hora.
7. En Expo, la pantalla de Dating muestra el bloqueo y no permite activar preferencias mientras no exista aprobación.

## Validación ejecutada
- Preflight V16 en Supabase PostgreSQL real con SQL y datos ficticios dentro de transacción revertida, aprobado; se comprobó que la preflight no persistió la tabla.
- [GitHub CI #40590318477](https://github.com/witchet43/app_my_fitness_date/actions/runs/40590318477) — éxito: TypeScript, pruebas unitarias, bundles Android/iOS, integraciones PostgreSQL y nuevos escenarios V16.
- [GitHub Local Auth E2E #40590318431](https://github.com/witchet43/app_my_fitness_date/actions/runs/40590318431) — éxito: GoTrue/Auth local y Mailpit, con dos cuentas sintéticas, aprobación operativa solamente local y Gym Shield con JWT reales.
- Migración V16 aplicada a DEV y tests `adult_eligibility_integration.sql` repetidos contra la base ya migrada, con `BEGIN/ROLLBACK`: aprobados.
- Estado final real: **0 cuentas Auth, 0 aprobaciones de edad y 0 perfiles Dating**.
- Permisos auditados: anónimo sin consulta de edad; `authenticated` **no** puede aprobarse ni leer la tabla; `service_role` sí puede ejecutar la RPC administrativa.
- Security Advisor: **sin alertas críticas ni de nivel warning**. 15 avisos informativos por RLS en tablas privadas sin políticas deliberadamente cerradas.

## Muy importante: no hay verificación de edad real todavía
Este incremento implementa un **candado de aprobación administrativa**, no un mecanismo independiente de verificación de identidad. Los dos usuarios aprobados durante las pruebas fueron sintéticos y existieron únicamente durante las pruebas locales/transaccionales. Ninguna persona real ha sido verificada o aprobada.

Antes de cualquier beta, se debe:
- Diseñar y contratar una fuente independiente de verificación de mayoría de edad, documentar el proceso y las reglas legales de privacidad aplicables.
- Establecer responsables autorizados, trazabilidad de aprobaciones, revocación, atención de errores y apelaciones de edad.
- Evitar almacenar imágenes de identificación o números de documentos en Supabase o en GitHub.
- Auditar ataques de múltiples cuentas e inferencia de horarios; los límites de consultas reducen el riesgo, no lo eliminan.
- Validar experiencia real en Android/iOS, moderación operativa, retención/eliminación y flujo Hosted Auth (aún sin plantillas verificadas).

No modificar `main`, no abrir beta pública y no comunicar la condición de verificación de edad como resuelta.
