# Adopción de SaaS Factory v1.9 — My Fitness Date
**Corte de auditoría:** 2026-11-10. **Estado:** trabajo en PR borrador; NO-GO para beta, usuarios reales, PROD y tiendas.

## Fuentes
- Índice canónico: https://docs.google.com/document/d/1jl6c96siJ1ef501iYKH3tM7eEV1bcB_IRDmownnxiLQ/edit
- Norma v1.9: https://docs.google.com/document/d/11hytKADuIUpmWzHEmAfZwcYNJ04M7n1ev4A1fbeZy9Q/edit
- Matriz de referencia: https://docs.google.com/spreadsheets/d/1OgWp18gBoaWNxFARNqjDmdP-ZSKIl6RT9ggpV96MC-8/edit
- Plantillas y checklist: https://drive.google.com/drive/folders/1MMB_wgOi53Vy4gagsmOxEZj-KYh7C3Xo

## Lectura del estado real
- `main`: README mínimo; el trabajo reciente vive en PR drafts #23 V19 → #24 V20 → #25 V21 → #26 V22 → #27 heartbeat.
- Esta adaptación se apila sobre `feat/saas-heartbeat-standard`, no ejecuta merges previos ni toca PROD.
- V22: Flutter inicial, FastAPI Gateway público, Gym Shield interno y RPC Supabase como autoridad de elegibilidad. Dos servicios existentes no autorizan extraer servicios nuevos sin necesidad probada.
- Supabase DEV `jtrdvnwbxpfdnbzasvcj`: estado ACTIVE_HEALTHY, 5 tablas public con RLS y sin datos en lectura puntual; 13 migraciones hospedadas (incluida heartbeat). 18 avisos INFO de tablas `app_private` con RLS sin policy: no deben "arreglarse" abriendo acceso. No confirma una auditoría formal de seguridad completa.
- Edge Function heartbeat ACTIVE con JWT deshabilitado para ese endpoint público; la función de borrado operador requiere JWT. Un estado ACTIVE no certifica contract test HTTP extremo a extremo actual.
- `release/readiness.json` contiene nueve bloqueos pendientes; ni builds sintéticos ni demo Android son QA física o autorización de beta.

## Alcance de este PR
1. `product.manifest.yaml` con decisiones comprobadas vs campos PENDIENTE.
2. Registro de 219 controles por producto en CSV: la matriz publicada en Sheets tiene 209 filas de controles (ENG/UX/AI/INT/DEV/DOC/ID/SAAS/FAC/SAFE/COST/MP/XPLAT/PX); se complementan localmente OPS-HB-01..10 del estándar maestro. NO se edita Drive.
3. `scripts/check_saas_factory.py`: comprueba integridad y rechaza la aprobación de release ante P0 no evidenciados; no concede aprobaciones automáticas.
4. Documentos de Product Discovery, primer valor, soporte, aprendizaje y experimentación con incógnitas explícitas.
5. Runbook de gates y prioridades de ingeniería; un CI verde no equivale a cumplimiento de norma.

## Brechas críticas por secuencia
| Lote | Tipo | Requisito / prueba de cierre | Gate |
| --- | --- | --- | --- |
| A | P0 | Auth hospedado con sesiones y permisos, QA con identidades sintéticas; bloqueo real de menores | G1–G3 |
| A | P0 | Evidencia anti-BOLA/RLS + denegación entre usuarios, moderación y soporte reales | G1–G3 |
| A | P0 | Consentimiento, privacidad, baja/borrado E2E hospedado, tratamiento de datos privados | G0–G3 |
| B | P0 | OpenAPI versionado, pruebas de contrato y errores 401/403/409/422/429/5xx | G1–G2 |
| B | P0 | Plan de fallos/rollback, restauración probada, RTO/RPO, monitoreo externo | G1–G4 |
| B | P0 | Flutter real, adaptativo y accesible; pruebas físicas Android+iOS y firma | G2–G4 |
| C | P0 comercial | Términos, pagos por canal, soporte, cancelación y unit economics si se monetiza | G0–G4 |
| C | P0 producto | JTBD, entrevistas consentidas, tarea de primer valor observada y evidencias | G0–G3 |
| D | P1 | Retención, cohortes, reputación, dashboards y evolución basada en datos | G5 |

## Prioridades de seguridad
- No inferir que el usuario es mayor de edad sólo por declarar fecha de nacimiento.
- FitDating es opt-in. No divulgar gimnasio, horario, ubicación precisa, listas de bloqueo o criterios de rechazo.
- No copiar identidades ni JWT reales a Issues, analítica ni documentos.
- Mantener Gym Shield privado tras IAM en Cloud Run y Auth per-request en el Gateway.
- No tratar `NO_EVALUADO` como `CUMPLE`. Antes de marcar `CUMPLE`, incluir owner, evidencia y fecha de revisión.

## Reglas de costo y operación
- Objetivo DEV incremental: USD 0, no garantía de gasto total cero.
- Antes de Cloud Run, email transaccional, tiendas, observabilidad o APIs de IA: revisar cuota, licencia comercial, costos variables, presupuesto y autorización.
- GitHub Actions existente se reutiliza; no crear sondeos costosos o cron redundante. Las programaciones de Actions operan desde la rama por defecto, no desde PR drafts.

## Decisión pendiente
La ADR-0001 anterior declara microservicios independientes obligatorios; la norma transversal v1.9 recomienda modular-first y extracción justificada. Propuesta: conservar los dos servicios ya implementados y documentar por ADR cualquier nueva extracción. Esto no invalida los límites de servicio ni el objetivo Flutter/BFF.
