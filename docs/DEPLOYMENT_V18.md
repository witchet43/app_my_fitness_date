# Iteración 18 — Informe de despliegue DEV

**Fecha:** 27 de octubre de 2026  
**Proyecto:** `my_fitness_date_dev` (`jtrdvnwbxpfdnbzasvcj`)  
**Migración aplicada:** `privacy_retention_v18`, versión `20261027232455`  
**Pull request:** [#22](https://github.com/witchet43/app_my_fitness_date/pull/22)

## Componentes

- Índice `dating_request_counters_retention` para localizar cuotas antiguas.
- Tabla privada `app_private.privacy_prune_audit` con RLS y acceso exclusivamente de rol de servicio.
- Inventario de estadísticas `public.operator_privacy_inventory()` (solo `service_role`, sin información identificable).
- RPC `public.operator_prune_ephemeral_counters(p_ticket,p_confirm,p_limit)` para depurar exclusivamente contadores antiguos (30 días); confirmación literal, ticket validado, máximo 500 registros por lote, escritura auditada e idempotencia de ejecuciones repetidas.
- Regla `counter_has_evidence_hold`: incluso datos técnicos temporales de personas implicadas en reportes, apelaciones o auditorías quedan retenidos.
- `app_private.my_account_export` ampliada con estado resumido de revisión de edad y explicación de conservación, sin exponer referencia de la revisión.
- Se modificó el test-only bootstrap para simular `service_role BYPASSRLS` de Supabase alojado. **No se ejecutó el bootstrap contra DEV alojado.**

## Pruebas realmente ejecutadas

1. Preflight con migración y test V18 en una transacción SQL revertida sobre Supabase DEV: **aprobado**.
2. [CI MVP #40601782589](https://github.com/witchet43/app_my_fitness_date/actions/runs/40601782589): **SUCCESS** en TypeScript, pruebas unitarias, bundles Android/iOS y PostgreSQL integrado.
3. La migración `privacy_retention_v18` se aplicó **solo** a Supabase DEV.
4. Test `privacy_retention_integration.sql` repetido sobre el esquema instalado dentro de `BEGIN/ROLLBACK`: **aprobado**.
5. Estado persistente final:
   - Cuentas `auth.users`: **0**
   - `privacy_prune_audit`: **0**
   - `dating_request_counters`: **0**
   - Denuncias y auditorías: **0**
   - Solicitudes de baja: **0**
6. La API de inventario no es ejecutable por anónimo ni por usuario autenticado normal. La depuración solo puede ejecutarla `service_role`; el usuario tampoco puede consultar la nueva tabla de auditoría.
7. Security Advisor: **0 alertas críticas o warning**; **18 INFO** de tablas privadas con RLS activo y sin políticas de lectura directa, configuradas deliberadamente así.

## Limitaciones y advertencias

- **30 días es un umbral técnico exclusivo de las cuotas de Dating**, no una regla jurídica que deba aplicarse a denuncias. Las evidencias de moderación no se borran automáticamente.
- No se ha efectuado ninguna ejecución permanente de depuración con datos reales; solo se comprobó en transacciones reversibles.
- No se garantiza borrado de Auth, Storage, respaldos ni registros de terceros. La cuenta real requiere el flujo V9 con aprobación administrativa y verificaciones adicionales.
- La exportación es una instantánea técnica; no cubre toda la información conservada por el proveedor ni constituye por sí sola respuesta legal completa a una solicitud de datos.
- Faltan política legal mexicana de conservación, responsabilidad operativa, proveedor real de verificación de edad, configuración Auth hospedada y pruebas nativas en dispositivos.
- `main` no se modificó; no se fusionaron PR encadenados ni se autorizó beta pública.

## Referencia operativa

[Guía funcional y procedimiento manual V18](./ITERATION_18.md)
