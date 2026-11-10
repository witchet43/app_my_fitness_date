# V23 — Runbook de autenticación QA en Flutter

**Estado:** código preparado para QA local/DEV; sin configuración habilitada, usuarios hospedados de prueba ni beta real verificada.

## Contrato del API Gateway

| Método | Ruta | Descripción |
| --- | --- | --- |
| POST | `/v1/identity/session` | Email/password de cuenta QA existente; devuelve sesión y usuario verificado |
| POST | `/v1/identity/session/refresh` | Rotación de refresh token; exige usuario QA verificado |
| GET | `/v1/identity/me` | Validación remota de JWT y perfil mínimo |
| DELETE | `/v1/identity/session` | Revocación local de sesión en Auth; HTTP 204 verificado |

Todos los paths devuelven 404 sin doble habilitación servidor: `MFD_APP_ENV=local|dev` y `MFD_QA_AUTH_ENABLED=EXISTING_QA_ACCOUNTS_ONLY`; una allowlist sin comodines es requerida. Nunca usar con cuentas reales, producción o redes públicas. Rechazar sin claves/URL válidas con 503. CORS solo a orígenes configurados, no wildcard; respuesta `Cache-Control:no-store`.

## Ejecutar en un ambiente local aislado

1. Iniciar proyecto Supabase **local** siguiendo el runbook vigente, con cuenta sintética verificada y clave pública `sb_publishable_...`. No usar PROD ni cuentas reales. Consultar documentación actual de Supabase CLI antes de ejecutar una versión nueva.
2. Iniciar Gateway **en host** (desde `services/api_gateway` con dependencias instaladas) y proporcionar mediante variables **locales no registradas en Git**:
   - `MFD_APP_ENV=local`
   - `MFD_SUPABASE_URL=http://127.0.0.1:54321` (solo con Supabase local; alojado requiere HTTPS)
   - `MFD_SUPABASE_PUBLISHABLE_KEY=...`
   - `MFD_QA_AUTH_ENABLED=EXISTING_QA_ACCOUNTS_ONLY`
   - `MFD_QA_AUTH_ALLOWLIST=qa@example.test` (reemplazar por cuenta sintética local)
   - `MFD_WEB_ALLOWED_ORIGINS=http://127.0.0.1:5173,http://localhost:5173`
3. Ejecutar `python -m uvicorn app.main:app --host 127.0.0.1 --port 8080`; nunca publicar ese puerto en Internet. **Docker Compose** solo accede a Supabase hospedado HTTPS salvo configuración local de red adicional; no suponer que `127.0.0.1` dentro del contenedor apunta al host.
4. Desde `apps/flutter_client`: `flutter run -d chrome --web-port=5173 --dart-define=MFD_API_BASE_URL=http://127.0.0.1:8080 --dart-define=MFD_QA_LOGIN_UI=true`. En Android/iOS usar un origen Gateway alcanzable por el dispositivo y HTTPS fuera del host, con permitidos explícitos.
5. Verificar entrada solo a allowlist, 401 ante credenciales inválidas, 404 sin bandera, correo confirmado, renovación y cierre remoto; reiniciar la app: la sesión debe desaparecer (memoria-only).

## Evidencia automatizada
`python -m pytest -q services/api_gateway/tests` desde la carpeta del servicio y `flutter analyze; flutter test; flutter build web --release` con el workflow existente. No crear usuarios reales ni hacer pruebas destructivas en Supabase hospedado.

## Límites y próximos pasos bloqueantes
- OpenAPI generado por FastAPI para contratos QA, cotejar con `docs/api/identity-qa-v23.openapi.yaml`.
- No hay OAuth PKCE, almacenamiento seguro persistente, MFA, reset de contraseñas, habilitación de email hospedado ni rate limits integrales de producción; resolver con ADR y pruebas antes de beta.
- Auth no verifica edad. FitDating permanece cerrado a no autorizados por reglas en servidor y está en UI como **vista previa sin guardar**.
- No garantiza revocación instantánea de access JWT tras logout; requiere plan de revocación `session_id` de alto impacto.
- Sin evidencia de app desplegada/web store ni QA físico; mantener **NO-GO**.
