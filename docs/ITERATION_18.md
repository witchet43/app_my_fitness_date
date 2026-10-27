# Iteración 18 — Privacidad, conservación de evidencias y minimización de datos

**Entorno:** `my_fitness_date_dev` — proyecto `jtrdvnwbxpfdnbzasvcj`  
**Rama:** `feat/privacy-retention-v18`, PR apilado sobre V17

## Nuevas garantías técnicas

**Inventario privado sin datos personales.** `public.operator_privacy_inventory()` es un RPC de solo lectura accesible únicamente por `service_role`. Devuelve agregados del volumen de contadores temporales vencidos (elegibles y retenidos por evidencia), notificaciones, denuncias, apelaciones, auditorías de moderación, incidentes y solicitudes pendientes de baja. No devuelve nombres, emails, ID de personas ni contenidos de casos.

**Depuración mínima y auditada.** `public.operator_prune_ephemeral_counters(p_ticket,p_confirm,p_limit)` requiere rol de servicio, un ticket 12–100 caracteres, la confirmación literal `PRUNE_EXPIRED_DATING_COUNTERS` y un límite de 1–500 filas por operación. Solo borra contadores de cuotas de `dating_request_counters` con bucket anterior a 30 días **sin vínculo con reportes, apelaciones o auditorías**. Se ejecuta con bloqueo de filas y lotes acotados; queda un registro en `app_private.privacy_prune_audit` por cada ejecución (incluso si eliminó 0 filas).

**Evidencia protegida.** Denuncias, apelaciones, contenido oculto, notificaciones, auditorías y registros de incidentes **no se eliminan** por este procedimiento. Ni siquiera se eliminan contadores temporales pertenecientes a personas implicadas como denunciantes, denunciados, revisores o participantes en expedientes. No se implementó ningún cron ni proceso de eliminación automático.

**Transparencia personal.** `my_account_export()` añade `age_review` (solo estado y vencimiento, sin referencia del expediente) e información sobre conservación; mantiene `export_version:1` por compatibilidad de clientes existentes y la información anterior.

## Operación controlada en DEV

Se debe usar únicamente un servidor administrado con credencial `service_role` custodiada fuera de GitHub, Expo, ChatGPT y CI. No es una operación del dispositivo móvil.

1. Auditar: invocar `public.operator_privacy_inventory()` para obtener cifras agregadas. Verificar pendientes legales y el expediente interno.
2. Obtener aprobación explícita del equipo responsable y registrar un ticket. **30 días es un umbral técnico de limpieza de cuotas, no un plazo legal de conservación ni una promesa al usuario.**
3. Ejecutar manualmente `public.operator_prune_ephemeral_counters('TICKET-DEV-PRIVACY-001','PRUNE_EXPIRED_DATING_COUNTERS',100)` bajo rol `service_role`.
4. Repetir el inventario y consultar `app_private.privacy_prune_audit` por un operador autorizado, con las protecciones de acceso correspondientes.
5. Si existen expedientes o políticas de conservación sin resolver, **no** liberar sus registros. La limpieza no elimina cuentas de Auth ni archivos de Storage.

No activar programas de mantenimiento automáticos ni aumentar indiscriminadamente el límite. No almacenar tokens administrativos en archivos versionados.

## Baja y conservación

Se mantienen las garantías previas: una solicitud de baja oculta perfiles y desactiva citas; tras el período de revisión de siete días, un operador independiente verifica aprobación vigente, expedientes, eventos y Storage antes de ejecutar Auth Admin. La baja definitiva **no** está demostrada de extremo a extremo con una cuenta real de Supabase DEV; no se inventa ese resultado.

La retención de pruebas de abuso requiere resolver previamente las bases legales, criterios de acceso restringido, tiempo de conservación, solicitudes ARCO y derechos aplicables. Esta iteración no determina el régimen jurídico mexicano ni fija un tiempo obligatorio para denuncias. Historial técnico y backups podrían sobrevivir a la baja y requieren plan contractual específico.

## Pruebas

- La suite `supabase/tests/privacy_retention_integration.sql` corre con usuarios ficticios en `BEGIN/ROLLBACK`, tanto contra PostgreSQL CI como en el proyecto DEV hospedado.
- Prueba permisos anon/authenticated, exportación propia, ausencia de la referencia de revisión de edad, confirmación inválida, lote >500, eliminación acotada, reintento sin efectos, preservación de contadores sujetos a evidencia y registros de seguridad.
- No se realizaron llamadas destructivas reales. Ningún usuario ni expediente de prueba se conserva después de un rollback.
- Estado pendiente de beta: revisión legal, ciclo completo Auth Admin con cuentas QA autorizadas, configuración Auth hospedada, pruebas físicas Android/iOS y políticas de moderación con personal operativo.

**Resultado esperado:** control administrativo de privacidad y un proceso seguro para minimizar telemetría temporal, no un servicio automático de eliminación completa.
