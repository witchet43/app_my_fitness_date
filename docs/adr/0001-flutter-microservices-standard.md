# ADR-0001 — Estándar de arquitectura multiplataforma y microservicios

- **Estado:** ACEPTADA como objetivo obligatorio de arquitectura (sin despliegue)
- **Ámbito:** my_fitness_date y futuras aplicaciones del portafolio
- **Fecha:** 2026-11-09
- **Decisión:** Flutter para web/Android/iOS; clientes exclusivamente de APIs de negocio; microservicios desacoplados; persistencia en nube; CI/CD por plataforma.

## Restricciones no negociables

1. **Frontend:** un monorepositorio de cliente Flutter/Dart compartido para web, Android e iOS con navegación, accesibilidad y layouts adaptativos. No iniciar nuevas pantallas en React Native/Expo.
2. **Canal de datos:** la app Flutter llama a la API HTTPS versionada (REST+JSON, especificada en OpenAPI). Nada de consultas SQL, RPC de negocio de Supabase ni secretos de backend desde Flutter. Los endpoints de login/sesión también se exponen por el backend de identidad/API BFF; los flujos OIDC/PKCE deberán cumplir seguridad móvil y web.
3. **Backend:** API pública/BFF en Google Cloud Run y microservicios por dominios de negocio con despliegue independiente. Propuesta inicial Python+FastAPI, con posibilidad de .NET por dominio si respeta los mismos contratos, seguridad, pruebas y observabilidad. No crear un microservicio por tabla.
4. **Datos:** PostgreSQL en nube; mantener y reutilizar el proyecto Supabase DEV existente. Aislamiento por aplicación y por ambiente (DEV/STAGING/PROD). Migraciones versionadas, RLS/roles, backups y cuentas de servicio de menor privilegio. Para el MVP pueden coexistir dominios en una misma instancia con esquemas/roles propietarios; separar bases físicamente según necesidades de escalado y límites de dominio. Nunca usar la misma base de PROD para QA.
5. **Seguridad:** servicios privados con IAM de servicio a servicio cuando aplique; API pública con verificación JWT (firma/issuer/audience/expiry) y autorización por dominio; RBAC/ABAC; rate limiting; secretos en Secret Manager; no incluir `service_role`, claves privadas ni conexiones de DB en frontend. Proteger datos sensibles por diseño y auditar mutaciones privilegiadas.
6. **CI/CD:** GitHub Actions ejecuta análisis estático, tests unitarios/integración, tests de contrato OpenAPI, escaneo de seguridad, build Flutter web, AAB firmado para pista interna Google Play y build iOS para TestFlight. Desplegar web y microservicios DEV con permisos mínimos mediante Google Workload Identity Federation (OIDC) cuando esté disponible. Promoción STAGING/PROD por gates y aprobación explícita.
7. **Interoperabilidad:** `/v1` API y versionamiento compatible, OpenAPI como contrato, código cliente Dart generado; tareas asíncronas mediante colas/eventos (Cloud Tasks/Pub/Sub) solamente cuando agreguen valor. Correlation ID, logs estructurados, métricas y trazas.
8. **Infraestructura/costo:** Cloud Run, Supabase, almacenamiento, Play Console, firma Android, Apple Developer/TestFlight y runners pueden generar cargos. No asumir costo mensual cero ni activar servicios pagos sin validación y autorización.

## Diagrama lógico

```text
Flutter/Dart shared client
  ├── Web → static hosting/CDN (DEV/STAGING/PROD)
  ├── Android → Google Play Internal Testing → staged production
  └── iOS → TestFlight → App Store
                 |
           HTTPS / REST / JWT
                 v
     API Gateway / BFF (Cloud Run, public ingress)
        ├── Identity & Account service
        ├── Profiles & Privacy service
        ├── Dating/Gym Shield service
        ├── Community service
        ├── Training Events service
        ├── Trust & Safety service
        └── Notifications/Integrations service
            (private Cloud Run IAM, least privilege)
                 |
        PostgreSQL/Supabase managed cloud
       (domain ownership, schemas, grants, RLS)
```

## Dominios iniciales para my_fitness_date

- **identity-account:** autenticación, sesión, aprobación de acceso y ciclo de cuenta. Las operaciones privilegiadas de Auth nunca se realizan en Flutter.
- **profiles-privacy:** perfiles, visibilidad, preferencias y exportación de datos.
- **dating-gym-shield:** preferencias de cita, elegibilidad, coincidencias y protección del gimnasio. Exclusión bilateral de gimnasio/horarios + margen de 30 min se calcula **en el servidor**; jamás revelar motivos o horarios privados.
- **community:** publicaciones e interacciones, con control de acceso y moderación.
- **training-events:** actividades, asistencia/RSVP y organización.
- **trust-safety:** bloqueos, reportes, revisión de edad, moderación, incidentes, auditoría y borrado/retención.
- **notifications-integrations:** entrega asíncrona de mensajes y conectores externos, sujeto a consentimiento.

Se comienza con límites claros de módulos y microservicios de complejidad justificada; no dividir servicios para inflar arquitectura. Cada servicio controla los accesos y escrituras a sus datos, aunque en DEV usemos una única instancia administrada.

## Autenticación y acceso

La implementación existente usa Supabase Auth. En la migración se reutiliza la identidad hospedada detrás del servicio `identity-account` y se definen flujos de login adaptados a móvil y navegador. El API gateway y servicios validan JWT emitidos (por ejemplo con JWKS de Supabase para claves asimétricas) y verifican permisos de recurso antes de consultar datos. Un token válido **no** es autorización suficiente. No usar claims editables por el usuario para permisos privilegiados.

## Decisión específica sobre la implementación existente

El cliente actual está escrito en **Expo/React Native/TypeScript**. Es un legado temporal para QA sintético y referencia de comportamiento, **no cumple** el estándar de frontend definitivo. La arquitectura de datos Supabase existente es recuperable; las RPC/funciones de negocio actuales deben quedar encapsuladas por APIs internas. No reescribir ni descartar migraciones, tests o lógica de Gym Shield sin pruebas de equivalencia.

El PR #23 (candidato V19), PR #24 (APK demo V20) y la rama `main` permanecen intactos. Esta ADR se registra en una nueva rama separada. No cambiar usuarios reales, no habilitar beta, no fusionar a `main` automáticamente.

## Criterios de aceptación

- Flutter web, Android e iOS compilan desde el mismo árbol de código.
- El Flutter frontend invoca solamente API BFF/identidad, nunca PostgreSQL/Supabase Data API o claves secretas.
- Swagger/OpenAPI y tests de contrato para APIs públicas versionadas.
- Gym Shield e identidad verifican autorización y privacidad a nivel servidor.
- CI automatizado sin distribución pública; pruebas de dispositivo y nueve gates de beta aún necesarios.
- DEV/STAGING/PROD segregados con perfiles y secretos independientes.

## Documentación oficial consultada

- Flutter multiplataforma: https://docs.flutter.dev/platform-integration/web
- Flutter release Android: https://docs.flutter.dev/deployment/android
- Cloud Run servicios: https://cloud.google.com/run/docs/overview/what-is-cloud-run
- Cloud Run autenticación entre servicios: https://cloud.google.com/run/docs/authenticating/service-to-service
- Supabase JWT/JWKS: https://supabase.com/docs/guides/auth/jwts
- Workload identity GitHub→GCP: https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines
