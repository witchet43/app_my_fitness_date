# ADR-0003 — Identidad QA sin registro público (V23)

- **Estado:** IMPLEMENTADA EN CÓDIGO, pendiente de revisión e integración; NO lista para beta.
- **Documento superior:** Estándar Maestro SaaS Factory v1.9; ADR-0001 continúa siendo objetivo de OAuth/OIDC.
- **Riesgo:** datos de salud/actividad, ubicación, gimnasio, relaciones y abuso; no admitir usuarios reales hasta controles P0.

## Alcance permitido

Un adaptador de Supabase Auth dentro del API Gateway expone cuatro endpoints para **cuentas de QA previamente creadas y con correo confirmado**. Flutter nunca llama a Supabase Auth/Data API directamente y no incluye claves de proyecto; obtiene tokens desde el BFF con HTTPS (localhost HTTP únicamente para QA). No existe endpoint de inscripción ni recuperación de contraseña. La autenticación NO concede por sí sola permiso de FitDating: las reglas de edad, consentimiento, bloqueo y privacidad continúan bajo Gym Shield/SQL.

Condición obligatoria doble: el gateway solo expone rutas cuando `MFD_APP_ENV` es `local` o `dev`, `MFD_QA_AUTH_ENABLED=EXISTING_QA_ACCOUNTS_ONLY`, y un email pertenece a `MFD_QA_AUTH_ALLOWLIST` explícita. En producción, aunque se copie la bandera, devuelve 404. La UI solo muestra login con `MFD_QA_LOGIN_UI=true` en build QA y API configurada. El backend nunca confía en esta bandera Flutter para autorizar.

Las contraseñas viajan exclusivamente en POST al Gateway y al proveedor Auth; las respuestas de errores y validación no reflejan inputs. El Gateway revalida identidad/correo confirmado en `/auth/v1/user`, rechaza cuentas fuera de allowlist, anónimas o sin confirmar, y no registra credenciales. `refresh_token` se rota exclusivamente con respuesta de Auth; tokens se mantienen en **memoria volátil**; no SharedPreferences, browser storage, analytics ni logs. Logout elimina inmediatamente la sesión local y solicita revocación remota.

## Decisiones y riesgos conocidos

- Se usa el endpoint **clásico** de Supabase Auth `/auth/v1/token?grant_type=password`, no el servidor OAuth2.1 para terceros. **No se considera implementación de OAuth/OIDC + PKCE**, que sigue pendiente antes de beta según estándar.
- Session persistence no está implementada: al reiniciar se vuelve a iniciar sesión; es intencional para evitar tokens almacenados de forma insegura en QA. Antes de beta valorar seguridad nativa Keychain/Keystore y, para web, BFF cookies HttpOnly/Secure/SameSite con CSRF y protección XSS.
- Logout revoca refresh tokens; los access JWT existentes pueden conservar validez hasta expirar. Antes de producción evaluar revocación de `session_id` en recursos sensibles, expiración corta y MFA/step-up.
- El proveedor aplica sus cuotas de autenticación; rate limiting en API/WAF, protección credential stuffing, reset/recovery, correo hospedado y MFA aún **pendientes** para beta.
- Ningún usuario real fue creado o autenticado en este cambio; las pruebas son sintéticas.
- En DEV se necesitarán cuentas QA precreadas, verificadas y autorizadas, además de configuración hospedada previamente validada. No activar proveedores ni nuevos cobros automáticamente.

## Evidencia requerida

Pruebas negativas 404/401/422/429/503, denegación interusuario, desinfección de mensajes, refresh rotado y logout real, CI Python+Flutter, E2E con Supabase Auth local, revisión de amenazas, QA física y seguridad independiente.

**Decisión de salida:** conservar PR en borrador y `release/readiness.json` con nueve gates pendientes; no publicar.
