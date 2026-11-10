# Iteración 13 — Verificación de correo y recuperación segura (DEV local)

## Implementación
- La pantalla de Auth permite registrar cuentas adultas autodeclaradas, confirmar email mediante OTP, solicitar recuperación y establecer una contraseña nueva mediante OTP de un solo uso.
- La recuperación solicita confirmación de código por correo y nueva contraseña de al menos 10 caracteres, repetida dos veces; tras actualizarla cierra la sesión temporal y exige ingresar de nuevo.
- La solicitud de recuperación responde de forma genérica para no revelar si existe la dirección.
- Se mantienen controles actuales de separación entre perfiles sociales y Dating. **La edad sigue siendo autodeclarada, no verificada.**

## E2E con Auth real y Mailpit
- El proyecto local `supabase/config.toml` activa `auth.email.enable_confirmations=true` únicamente en el stack local.
- Plantillas locales de confirmación y recuperación en `supabase/templates/` con `{{ .Token }}`. Los códigos se capturan por la API de Mailpit en loopback; nunca se imprimen ni se envían a servicios externos.
- `scripts/local-auth-e2e.mts` ya no presupone registro sin confirmación: recibe correo de prueba, confirma OTP, obtiene JWT real y ejecuta las comprobaciones V12.
- `scripts/local-email-e2e.mts` verifica rechazo de inicio sin confirmar, login tras confirmación, recuperación, actualización, rechazo de contraseña antigua y código usado, e ingreso con contraseña nueva.
- GitHub Actions ejecuta ambas suites y destruye el stack con `supabase stop --no-backup`.

## Instrucciones locales
```bash
npm install
npx supabase@latest start --exclude studio,realtime,storage,functions,analytics,pooler
set -a
eval "$(npx supabase@latest status -o env)"
set +a
MFD_LOCAL_AUTH_E2E=LOCAL_ONLY npm run test:auth:local
MFD_LOCAL_AUTH_E2E=LOCAL_ONLY npm run test:auth:email:local
npx supabase@latest stop --no-backup
```

No imprimir los valores de `status -o env`. Mailpit local: `http://127.0.0.1:54324`.

## Exclusiones y riesgos
- **Las plantillas OTP están configuradas exclusivamente en Supabase local.** Antes de poder usar estos códigos con la instancia hospedada, un administrador debe configurar y validar allí las plantillas de email y los destinos/redirecciones. No afirmar que el código funciona por defecto con emails hospedados.
- No se ha probado la recuperación de contraseña ni el registro en un dispositivo físico Android/iOS; tampoco se han generado cuentas QA reales en Supabase hospedado.
- El proyecto Supabase DEV no debe modificarse por esta iteración: ningún correo, cuenta, ticket, clave o reporte real.
- Falta verificación sólida de edad, cobertura de recuperación y bloqueo por pérdida de acceso a email, medidas anti-abuso, pruebas de accesibilidad y seguridad.
- Los PR siguen apilados y no fusionados a `main`. Beta pública **no** habilitada.

## Referencias
- [Supabase — Test auth flows](https://supabase.com/docs/guides/auth/testing-auth-flows)
- [Supabase — Email templates](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Mailpit API](https://mailpit.axllent.org/docs/api-v1/)
