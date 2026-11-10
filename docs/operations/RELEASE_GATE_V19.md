# Gates G0–G5 y preflight release — My Fitness Date
**Resultado inicial: NO-GO para beta y producción.** Este archivo define tareas, no acredita ejecución.

| Gate | Condición y evidencia exigible | Estado |
| --- | --- | --- |
| G0 Discovery | Segmento, JTBD, riesgos, prototipos, primer valor y presupuesto documentados con pruebas representativas | BLOQUEADO |
| G1 PR | CI, code review, scans, pruebas auth/tenant/privacidad, OpenAPI versionado y cambios reversibles | EN_PROGRESO |
| G2 QA | E2E, AA web, TalkBack/VoiceOver, permisos, intermitencia, edad y moderación, Android/iOS físico | BLOQUEADO |
| G3 Beta | Track/canales de prueba, firma, testers adultos autorizados, consentimiento, soporte/telemetría real | BLOQUEADO |
| G4 Producción | Políticas de tiendas, privacidad legal, pagos por canal si aplican, recuperación, costos y aprobación humana | BLOQUEADO |
| G5 Operación | Retención, cohortes, incidentes, soporte, conversión/margen con denominadores, presupuesto y revisión | SIN_DATOS |

## Uso en desarrollo
`python3 scripts/check_saas_factory.py` valida existencia, unicidad, estado y trazabilidad de 219 controles; **no aprueba release**.
`python3 scripts/check_saas_factory.py --release` falla hasta que todos los P0 aplicables tengan `CUMPLE` con owner/evidencia o `NO_APLICA` con owner/justificación. Esto es comprobación documental, NO sustituto de las pruebas.

## Validaciones requeridas
- Ejecutar suites TypeScript, SQL, Flutter, Gateway y Gym Shield con versiones firmadas.
- No asumir que 18 avisos INFO en `app_private` justifican políticas permisivas.
- Verificar aislamiento entre usuarios y alcance del servicio `Gym Shield` con identidad del solicitante, no service_role.
- Monitorizar `/healthz` y `/readyz`/heartbeat en servicio desplegado; verificar 503 en fallo DB.
- Hacer prueba de restauración, RTO/RPO, fallos de proveedores, límites de costo, incidentes y rollback.
- No declarar iOS/Android distribuidos por el resultado de `flutter create` o build web.
- Confirmación de aprobación de lanzamiento, run ID, versión, URL/canal y smoke test posdespliegue.

**Control comercial:** antes de monetizar definir precio y tiendas, impuestos, renovación, devolución, cancelación, entitlements server-side y pruebas sandbox. Sin autorización no se habilita billing.

**Evidencia de la antigua beta:** `release/readiness.json` sigue con nueve gates pendientes. No reemplazar ni cambiar a aprobado sin pruebas.
