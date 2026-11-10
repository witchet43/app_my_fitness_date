# My Fitness Date — Cloudflare Pages producción web pública V24

**Objetivo:** entregar valor real en producción con un primer módulo anónimo (calculadora de ritmo), siguiendo el modelo de Cloudflare Pages de Mi Universidad Virtual. No equivale a beta de comunidad ni FitDating.

## Arquitectura y controles

- Repo: `witchet43/app_my_fitness_date`; fuente de verdad `main`.
- Hosting web: **Cloudflare Pages Direct Upload**, proyecto `my-fitness-date`, rama de producción `main`; build Flutter desde `apps/flutter_client`.
- Compilación obligatoria: analizar código, `flutter test`, `flutter build web --release --dart-define=MFD_PUBLIC_PRODUCTION=true --dart-define=MFD_QA_LOGIN_UI=false --dart-define=MFD_API_BASE_URL=`.
- Función útil al público: calculadora de ritmo/velocidad de carrera, operando exclusivamente en el navegador; sin sesión, cookies, base de datos, almacenamiento, analítica ni captura de PII.
- La navegación Comunidad y FitDating es informativa. Los servicios de datos, registro, login de QA, citas, preferencias de gimnasio y recomendaciones **NO están conectados ni accesibles desde este build**.
- Los 9 gates de `release/readiness.json` siguen pendientes y son obligatorios para **usuarios reales y funcionalidades sensibles**, pero no impiden publicar una herramienta anónima sin backend.
- No hay integración directa Supabase en Flutter, ni llaves `service_role`, ni `sb_secret_`. Toda futura función de negocio requerirá API Gateway privado y controles.

## CI/CD

- GitHub Actions ejecuta `Flutter analyze, test, web build` en PRs y cada push relevante a `main`; `CI MVP` mantiene auditorías del legado.
- Cloud Build se configura en proyecto dedicado `jv-apps-ci-cd-hub`, región `us-central1`, repositorio 2nd gen GitHub y cuenta **separada** `mfd-cloudbuild-runner`.
- `cloudbuild.yaml`: Flutter SDK 3.47.9 con hash SHA256 fijo, pruebas obligatorias, build producción y verificación de `mfd-release.json` contra commit exacto.
- La única credencial de Cloudflare se obtiene en tiempo de ejecución desde `cloudflare-pages-api-token` de Secret Manager; no se descarga ni registra en Git.
- `_DEPLOY=false` por defecto en ejecuciones manuales, `_DEPLOY=true` solo para trigger de rama `main` o ejecución explícita de producción.
- Wrangler ejecuta Direct Upload al proyecto `my-fitness-date`; si no existe, intenta crearlo con rama `main`. Nunca modifica el proyecto `mi-universidad-virtual`.
- El smoke verifica contenido HTML público y marcador JSON del commit, no solo HTTP 200. Si falla, debe reportarse como despliegue fallido.
- Las cuotas gratuitas de Cloud Build y Cloudflare no equivalen a gasto garantizado cero. Mantener presupuestos/alertas del hub CI/CD y revisar consumo.

## URL y recuperación

URL prevista: `https://my-fitness-date.pages.dev/`. **No declarar la URL funcional hasta comprobar una respuesta HTTP del despliegue y su commit.** En caso de que el nombre esté ocupado, registrar el nombre real devuelto por Cloudflare y actualizar workflow/documentación.

Rollback: en Cloudflare Pages seleccionar el despliegue anterior en `Deployments` y realizar `Rollback to this deployment`, o promover en `main` un revert mediante PR. Ninguna migración ni edición de Supabase forma parte de esta entrega.

## Evolución

Cada próximo incremento pasa por PR, pruebas, merge a `main`, despliegue Cloudflare y smoke contra URL pública. Para activar Comunidad o FitDating se necesita hosting de Gateway/Gym Shield, Auth hospedado, privacidad y controles legales, moderación y revisión de seguridad. El código por sí solo no los habilita.
