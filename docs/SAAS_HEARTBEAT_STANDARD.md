# SaaS Factory — API heartbeat v1.0

**Aplicación:** My Fitness Date. **Estado:** implementación versionada, validación de despliegue por separado.

## Contrato obligatorio
- `GET /functions/v1/heartbeat` en Supabase: comprueba una RPC de PostgreSQL de solo lectura; devuelve HTTP **200** cuando `status=ok` y `dependencies.database=ok`; devuelve **503** y `status=degraded` ante fallo.
- `HEAD` equivale a `GET` sin cuerpo; `OPTIONS` responde sin leer la BD; métodos mutables devuelven **405**.
- JSON incluye exclusivamente `status`, `service`, `dependencies.database`, `checked_at` (ISO 8601 UTC).
- `Cache-Control: no-store`; no números de versión de base de datos, SQL, secretos, datos personales, identidades ni detalles de conexión.
- FastAPI Gateway: `GET /healthz` es *liveness* del proceso; `GET /readyz` y `GET /heartbeat` son *readiness*, con consulta real de la misma RPC vía PostgREST.


## Seguridad y costos
1. La RPC `public.saas_heartbeat_v1()` usa **SECURITY INVOKER**, carece de argumentos y devuelve una constante; permisos explícitos a `anon` y `authenticated`, sin acceso a tablas privadas.
2. La Edge Function usa solamente clave pública/anon y privilegios mínimos. No usar `service_role`, escribir en tablas de negocio ni ampliar RLS.
3. Mantener el chequeo barato, con timeout de 4 segundos. Activar límites de tráfico/abuso en el perímetro si el volumen lo justifica.
4. Medir total de requests, errores 5xx, última comprobación exitosa, estado, duración y cuota de Edge Functions. Registrar la fuente y la hora de cada métrica.
5. Un endpoint `/healthz` que responde 200 **no** prueba que Postgres esté disponible; monitorear siempre `/heartbeat`/`/readyz`.

## Operación: desarrollo, preview y producción
- Realizar sondeos mediante monitoreo externo a la aplicación, evitando depender del teléfono del usuario o del navegador abierto.
- Supabase Free puede suspender proyectos por inactividad; la documentación oficial recomienda **varias peticiones de usuario a la base de datos al día**, sin garantía de evitar suspensión. Un ping cada tres días no es suficiente como estrategia confiable.
- Sugerencia de control de baja frecuencia: **cada 8 horas** para ambientes DEV de coste cero, sujeto a las cuotas disponibles. No es SLA ni sustituto de monitoreo profesional.
- Para productos SaaS con usuarios reales y disponibilidad exigida, utilizar un servicio/plan con las garantías apropiadas; no basar continuidad comercial en este mecanismo.
- Despliegue: aplicar DDL aditivo, desplegar `heartbeat` con `verify_jwt=false` (endpoints públicos deliberados), validar 200 y simular 503, configurar monitor, alertas y límites.

## Pruebas de aceptación
- RPC local devuelve `{"status":"ok"}` y otorga ejecución sólo a roles previstos.
- Llamada HTTP GET de monitor produce 200 sin información privada.
- Ante BD caída/credenciales mal configuradas, el endpoint produce 503 sin exponer secretos.
- Un POST no modifica nada y devuelve 405.
- Demostrar que no se lee ninguna tabla de usuarios y que los intentos cuentan en las cuotas correspondientes.
- No atribuir actividad de los pings a usuarios reales ni considerarlos una medida de retención.

Referencia: https://supabase.com/docs/guides/platform/free-project-pausing
