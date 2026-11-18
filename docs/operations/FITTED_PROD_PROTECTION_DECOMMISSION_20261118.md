# Auditoría de protección PROD y decommission — 18 noviembre 2026

## Inventario base (main, antes de cambios)
**39 workflows, no 25**: android-demo-qa.yml, b1-single-gate.yml, b10-final-candidate.yml, b11-github-quality-no-build.yml, b11-local-api-flutter-qa.yml, b11-local-auth-email-qa.yml, b11-local-auth-two-users-qa.yml, b11-one-final-build.yml, b11-static-api-flutter-qa.yml, b2-single-preview.yml, b3-single-global-brand.yml, b4-single-community.yml, b5-single-private-dating.yml, b8-single-candidate.yml, b9-single-candidate.yml, brand-admin-security.yml, brand-lab-static.yml, ci.yml, cloudflare-pages-production.yml, fitted-android-apk-download.yml, fitted-b18-android-apk.yml, fitted-b19-android-apk.yml, fitted-change-ci.yml, fitted-editorial-b19-qa.yml, fitted-glass-trust-qa.yml, fitted-monitor.yml, fitted-motion-f-qa.yml, fitted-release-reconcile.yml, fitted-supabase-deploy.yml, fitted-two-panel-b18-qa.yml, fitted-visual-preview.yml, flutter-services-v22.yml, heartbeat-contract.yml, heartbeat-uptime.yml, local-auth.yml, member-api-live-smoke.yml, mfd-canonical-auth-release.yml, mfd-landing-preview.yml, mfd-retire-legacy-previews.yml.

## Protección de producción GitHub
- La API de GitHub para `branches/main/protection` respondió HTTP 403 `Resource not accessible by integration`. El endpoint de rulesets devolvió una lista vacía. No se certificó branch protection.
- El conector actual no ofrece escrituras de settings/rulesets, environments ni secretos. **Pendiente de configuración administrativa**: required PR review, required checks `Fitted - change-aware quality gate`, no force push; environment `production` con revisores, restricciones de branch y secretos; variable de repositorio `FITTED_PROD_DEPLOY_ENABLED=true` solo al certificar estos controles. En ausencia de esa variable, el job mutante de Supabase no se ejecuta.
- Ningún YAML habilita por sí mismo los required reviewers del entorno.

## Supabase controlado
- Proyecto PROD `jtrdvnwbxpfdnbzasvcj`: activo; 48 migraciones registradas; funciones activas y versiones observadas: `member-api-v26` v9, `fit-ia-v1` v11, `fitted-ai-summary-b18` v4, `heartbeat` v2.
- Se verificó el código desplegado de `heartbeat`: lectura RPC `saas_heartbeat_v1` sin service_role ni datos privados.
- `fitted-supabase-deploy.yml` separa preflight **de solo lectura** de despliegue escrito, con confirmación exacta, allowlist de funciones y variable de autorización que por defecto bloquea writes. Migraciones usan `supabase db push --dry-run` antes del push real, pero la comprobación remota con CLI requiere secretos y entorno aprobados.
- NO se ha ensayado un push ni redeploy real con este workflow hasta configurar las protecciones.

## Baja segura de pipelines
- **Retirado** `cloudflare-pages-production.yml`: su único job escribe un mensaje que dice que el workflow antiguo está retirado; no utiliza Wrangler, CLI, build ni assets; no es dependencia `workflow_run` de los workflows auditados.
- Otros workflows históricos B1–B11 solo se disparan en ramas dedicadas, pero las ramas B1, B2, B3, B4, B5, B8, B9 y B10 siguen existiendo. No pueden declararse sin consumidores sin verificar esos usos. Preservar hasta prueba de equivalencia.
- Mantener `fitted-b19-android-apk.yml` porque `fitted-android-apk-download.yml` depende de su nombre por `workflow_run`.
- Los workflows de QA manual, preview y heartbeat se conservan mientras no se demuestre sustitución de cobertura.

## Edge Functions antiguas
- En Supabase están activas ocho `member-api-b*-preview` (B2, B3, B4, B5, B8, B9, B10, B11). No hay pruebas suficientes de cero tráfico, cero enlaces externos y ausencia de consumidores en todas las ramas. No se borraron.
- Una función con `verify_jwt:false` no demuestra por sí sola acceso inseguro, pero requiere comprobar autenticación interna antes de exponerla.
- Escanear logs de uso y referencias, probar 404/401 de rutas privadas, luego desactivar de una en una con plan de reversión. El conector Supabase actual tampoco expone una operación de borrado de funciones: no simular eliminaciones.

## Pruebas y control
- El workflow de preflight en PR valida heartbeat, manifest de Cloudflare y 401 en rutas privadas, sin credenciales privilegiadas.
- GitHub Actions no sustituye QA autenticado con cuentas reales ni aprobación G0–G5.
- No hay cambio de esquema ni de aplicación funcional en esta intervención.
