# V22 — API Gateway + Gym Shield microservice + Flutter scaffold

**Rama:** `feat/flutter-gateway-gymshield-v22` (apilada sobre ADR V21).
**Estado:** código y pruebas agregados; no equivale a despliegue Cloud Run, web ni tiendas.
**Release:** DEV y QA sintético exclusivamente; beta real continúa NO-GO.

## Entrega

1. `services/api_gateway`: FastAPI REST `GET /healthz`, `GET /v1/dating/candidates?limit=1..10`; se exige Bearer y se verifica remotamente vía Supabase Auth antes de llegar al servicio interno. Usa identidad IAM de Cloud Run (ID token `X-Serverless-Authorization`) al consumir Gym Shield en ambiente no local.
2. `services/gym_shield`: endpoint interno `GET /internal/v1/dating/candidates`; vuelve a validar el token de usuario y usa la RPC servidor existente `public.discover_dating_candidates` **con JWT del usuario**, nunca con service_role. Esta RPC retiene los controles server-side de RLS/privacidad, revisión externa de edad, bloqueo, consentimiento, cuotas, horarios y buffer de 30 minutos. Respuestas exponen solo ID, nombre público, ciudad y deportes.
3. `services/gym_shield/app/domain.py`: implementación pura Python de las reglas Gym Shield, trasladada de TypeScript, con pruebas de paridad: opción estricta, autorización bilateral, horarios de otro día y diferencia de 29 vs 30 minutos, sesiones múltiples, falta de gimnasio y bloqueos. **Esta implementación es de dominio, pero todavía no sustituye la RPC SQL en producción/DEV**. Para mover la consulta de datos privados al microservicio se necesita un repositorio con roles mínimos, control de edad/quota y pruebas de equivalencia reales.
4. `apps/flutter_client`: estructura Flutter/Dart común Web/Android/iOS, navegación responsive Comunidad/Actividades/Citas, opciones visuales Gym Shield, API client tipado HTTP que no llama directamente Supabase; UI no muestra datos reales sin identidad aprobada.
5. `services/docker-compose.yml`: ambos contenedores locales; solo API Gateway publicado en localhost, Gym Shield no expuesto.
6. `.github/workflows/flutter-services-v22.yml`: jobs separados Python y Flutter, con tests, análisis y build web DEV sin despliegue.

## Contrato HTTP

```http
GET /healthz
200 {"status":"ok","service":"api-gateway"}

GET /v1/dating/candidates?limit=10
Authorization: Bearer <supabase-user-access-token>
200 {"items":[{"id":"uuid","display_name":"...","city":"...","sports":["..."]}],"count":1}
401 {"detail":"Authentication required"}
403 {"detail":"Dating unavailable"}
503 {"detail":"Service unavailable"}
```

- No se admiten `viewer_id`, `gym_id`, `weekly_slots` ni `candidate_id` como parámetros.
- `X-End-User-Token` solo entre servicios privados: contiene el JWT y no se registra ni devuelve.
- `X-Serverless-Authorization` autentica al Gateway con Google Cloud Run; el servicio Gym Shield debe tener `--no-allow-unauthenticated` y una vinculación `roles/run.invoker` para la cuenta de servicio del Gateway.
- El OpenAPI generado por FastAPI puede consultarse en `/openapi.json` de los servicios durante QA local; no exponer documentación interactiva en producción sin revisión.

## Ejecutar local

```bash
cd services
docker compose up --build
curl http://127.0.0.1:8080/healthz
curl -i http://127.0.0.1:8080/v1/dating/candidates
```

La segunda llamada debe devolver 401. Sin `MFD_SUPABASE_URL` y
`MFD_SUPABASE_PUBLISHABLE_KEY` en el contenedor, cualquier llamada
autenticada debe fallar cerrada. Esos valores públicos deben llegar
por variables de entorno, no quedar incorporados en Flutter ni en Git.
Para Flutter Web, configurar \`MFD_WEB_ALLOWED_ORIGINS\` con el origen HTTPS exacto del sitio (sin comodín). Compose permite únicamente \`localhost:5173\` para QA. Para Cloud Run remoto usar HTTPS y cuenta de servicio/IAM. No conectar
Auth hospedado ni abrir registro público hasta completar los nueve gates
de `release/readiness.json`.

## Pendientes antes de desplegar

- Definir proyecto de Google Cloud, presupuestos, service accounts, IAM y dominios.
- Ejecutar CI y corregir los fallos observados, si los hay.
- Implementar sesión de identidad en Flutter y canal Auth alojado.
- Sustituir gradualmente el repositorio RPC por consultas seguras del
  microservicio con roles DB limitados y pruebas negativas de privacidad.
- Versionar los runners Flutter nativos con IDs y firmas definitivas;
  comprobar web, Android físico e iOS físico.
- No fusionar V19/V20/V21/V22 a `main` ni activar la beta sin validación.
