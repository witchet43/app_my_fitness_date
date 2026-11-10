# V19 — Candidato de integración del MVP (solo desarrollo)

**Fecha de revisión:** 27 de octubre de 2026  
**Repositorio:** https://github.com/witchet43/app_my_fitness_date  
**PR consolidado:** https://github.com/witchet43/app_my_fitness_date/pull/23  
**Base:** \`main\`, **en borrador y sin merge**  
**Proyecto DEV:** \`my_fitness_date_dev\` (\`jtrdvnwbxpfdnbzasvcj\`, región us-east-1)

## Integración sin afectar main

- V1–V18 se encuentran en **18 PR encadenados**, todos abiertos en borrador (#1 y #6–#22). La rama de V18 estaba **77 commits por delante y 0 por detrás** de \`main\` cuando comenzó esta iteración.
- La rama \`release/integration-candidate-v19\` parte exactamente de V18. Se abrió un PR adicional, #23, **directamente contra \`main\`** para permitir revisar todos los cambios acumulados de una sola vez.
- Ninguna PR anterior fue cerrada ni fusionada; esto es una vista consolidada para revisión. No se despliega producción, ni se activa registro público, ni se crea usuario alguno.
- La etiqueta V19 describe un candidato técnico, **no una versión aprobada por seguridad o tiendas**.

## Cambios de estabilización

1. **Dependencias reproducibles:** se generó y versionó \`package-lock.json\` en un runner de CI de solo lectura. Ambos workflows sustituyen \`npm install\` por \`npm ci\` para instalar las mismas dependencias transitivas. El workflow temporal de captura se eliminó tras utilizarlo.
2. **Manifiesto de lanzamiento cerrado por defecto:** \`release/readiness.json\` contiene nueve requisitos de beta pendientes. El evaluador valida esquema, proyecto DEV, canal no publicado y evidencias fechadas HTTPS; la beta solo puede considerarse candidata cuando todos estén comprobados.
3. **Auditoría de integración sin credenciales:** \`npm run candidate:audit\` verifica presencia y orden de las migraciones SQL en CI, cobertura de los tests SQL, exportación de ambos bundles, pruebas Auth y protección básica de configuración. Imprime estado y bloqueos, sin modificar backend.
4. **Bloqueo estricto:** \`npm run candidate:require-beta\` devuelve error intencional mientras exista un único requisito pendiente. **No usar ese comando como condición de CI verde** durante desarrollo: la CI comprueba la coherencia del candidato, no aprueba una beta.
5. **Documentación reconciliada:** README, MVP y SECURITY reflejan el estado real posterior a V18 (comunidad, actividades, descubrimiento, notificaciones, moderación, baja/retención), sin afirmar que existen chat, likes o matching mutuo.

## Datos y esquema de Supabase DEV

Inventario aplicado hasta V18 (12 migraciones):

| Unidad | Nombre desplegado |
| --- | --- |
| V1 | \`private_dating_gym_shield_v1\` |
| V2 | \`dating_birthdate_owner_only\` |
| V4 | \`social_profiles_community_events_v4\` |
| V5 | \`trust_safety_reports_blocking_rate_limits_v5\` |
| V6 | \`admin_moderation_audit_v6\` |
| V7 | \`moderation_appeals_private_inbox_v7\` |
| V8 | \`account_export_deletion_request_v8\` |
| V9 | \`operator_erasure_preflight_v9\` |
| V9b | \`erasure_claim_session_guard_v9\` |
| V16 | \`adult_eligibility_gymshield_v16\` |
| V17 | \`moderation_incident_escalation_v17\` |
| V18 | \`privacy_retention_v18\` |

V10–V15 incorporaron principalmente cambios de cliente, CI, documentación y pruebas, no nuevas migraciones permanentes. No se añaden migraciones en V19.

**No hay datos personales ni cuentas Auth activas en DEV** en la auditoría anterior; se repetirá para el cierre. Los tests con identidades sintéticas se realizan en una instancia PostgreSQL efímera, Auth local o transacciones SQL revertidas.

## Alcance real de las pruebas

- **GitHub CI:** TypeScript, pruebas unitarias, bundles JavaScript Android/iOS, migraciones y pruebas PostgreSQL V1–V18.
- **Local Auth + Mailpit:** registro confirmado, emisión y validación de JWT reales, cambio de contraseña, aislamiento entre cuentas, Gym Shield, denuncias y baja pendiente.
- **DEV remoto:** migraciones y comprobación de permisos y datos agregados; no pruebas con cuentas QA hospedadas.
- **Pendiente:** build nativo y pruebas de UI en dispositivos físicos, configuración SMTP/OTP hospedada, borrado integral real mediante Auth Admin, cumplimiento legal y prueba operativa de moderación con personas.

La CI puede pasar todas sus pruebas técnicas mientras el manifiesto correctamente indica \`betaReady=false\`.

## Condiciones para siquiera considerar una beta cerrada

Los nueve requisitos se encuentran **pending**, no \`verified\`: correo/Auth hospedado, verificación de edad externa, moderación dotada de personal, política legal de privacidad/conservación, borrado real end-to-end, QA físico Android, QA físico iOS, auditoría de seguridad independiente y respuesta a incidentes/soporte.

**No basta cambiar un JSON manualmente**: los verificadores exigen URL HTTPS de evidencia y fecha de revisión, pero todavía se necesita una persona responsable que la valide. Estos controles son una lista de comprobación, no un sistema de permisos de producción ni sustituyen la revisión humana.

## Observaciones y deuda

- Se fijaron dependencias npm mediante \`package-lock.json\`; la CLI Supabase de pruebas utiliza \`supabase@latest\` y aún se debería fijar una versión comprobada antes de reproducir un proceso de liberación.
- Los 18 PR anteriores continúan abiertos; mantenerlos separados ayuda al historial de revisión, pero **no fusionar en orden arbitrario**. El PR #23 permite revisión de alcance total y se puede decidir posteriormente una estrategia de merge con autorización explícita.
- La exportación personal es técnica, no una respuesta legal completa. La limpieza auditada de cuotas no elimina documentación de casos ni los respaldos del proveedor.
- El público objetivo y las políticas de tiendas deben evaluarse antes de habilitar acceso, especialmente al tratarse de funcionalidades románticas.

## Veredicto actual

**Candidato de integración listo para revisión técnica, NO listo para beta.**
Se requiere evidencia externa y autorización explícita para pasar a cualquier distribución con personas reales.
