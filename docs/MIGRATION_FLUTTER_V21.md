# Roadmap V21 — Migración controlada a Flutter + microservicios

**Tipo de cambio:** arquitectura y transición planificada; no sustituye el cliente Expo existente hasta tener paridad.  
**Base:** release/deployment-ready-v20, PR #24.  
**Estado de release:** DEV únicamente, NO-GO para beta/producción; respetar `release/readiness.json`.

## Inventario base

- Cliente actual Expo/React Native/TypeScript (incluye demo offline), no Flutter.
- Gym Shield con comportamiento protegido que exige paridad de pruebas, no adaptación literal de tipos JavaScript.
- Supabase PostgreSQL DEV `jtrdvnwbxpfdnbzasvcj` con 12 migraciones aplicadas, no recrearlo sin motivo.
- En PR #24 la APK autónoma es válida como **demo sintética** pero no como Flutter o beta real.
- Las rutas hacia Google Play y TestFlight deberán usar clientes Flutter compilados, firmas y cuentas propias.

## Fases ejecutables con evidencia

### Fase A: arquitectura / gobernanza (este PR)
- [x] Registrar ADR-0001 con el stack obligatorio.
- [x] Fijar boundaries de identidad, Gym Shield, comunidad, eventos y seguridad.
- [ ] Aprobar matriz de costos y límites de presupuesto GCP / Supabase / Apple / Google Play.
- [ ] Inventariar scripts SQL y contratos RPC que requieren encapsulación.
- [ ] Definir nombres definitivos de paquetes, dominio web y app IDs por entorno.

### Fase B: backend inicial sin romper DEV
- [ ] Crear `services/api-gateway` (HTTP `/v1`, OpenAPI, JWT, CORS allowlist y health).
- [ ] Crear `services/identity-account` y `services/dating-gym-shield` con contract tests y auth fail-closed.
- [ ] Reutilizar esquema de DEV con credenciales servidor y roles mínimos; evitar exposición de `service_role`.
- [ ] Añadir tests equivalentes a reglas Gym Shield incluyendo ambos usuarios, horarios y margen ±30 minutos.
- [ ] Probar que clientes sin token y tokens sin autorización no pueden acceder ni inferir gimnasio/horarios.
- [ ] Desplegar en Cloud Run DEV solo después de confirmar proyecto GCP, IAM, facturación y presupuesto.

### Fase C: cliente Flutter compartido
- [ ] Crear `apps/flutter_client` con `pubspec.yaml`, `lib/app`, `lib/core/api`, `lib/features`, `test`, y targets web/android/ios.
- [ ] Integrar `http/dio` o alternativa seleccionada a través de un wrapper tipado y OpenAPI generado.
- [ ] Añadir perfiles `dev`, `staging`, `prod`, conexión a Gateway y gestión segura de sesiones.
- [ ] Migrar UI e interacción: Comunidad, Actividades, Citas (Gym Shield), Cuenta, Inbox, Moderación.
- [ ] Conservar accesibilidad, estados vacíos, carga, error, offline y layouts responsive.

### Fase D: CI/CD multiplataforma
- [ ] Ejecutar `flutter analyze`, `flutter test` y tests contractuales por cada PR.
- [ ] Compilar Flutter web y desplegar únicamente a web DEV / hosting autorizado.
- [ ] Android: `flutter build appbundle --release` con firma de carga segura, Play App Signing y Google Play **Internal Testing**; versionCode monotónico.
- [ ] iOS: build y firmado en macOS, App Store Connect/TestFlight para testers autorizados.
- [ ] Workload Identity Federation para Google Cloud, secretos en Secret Manager/GitHub environments protegidos, aprobaciones de distribución.
- [ ] No almacenar firmas, private keys, `.env` ni credenciales en repositorio.
- [ ] Registrar por versión commit SHA, artefactos, tests, changelog, rollback y origen de migraciones.

### Fase E: paridad y gates
- [ ] Test E2E para Flutter web, Android físico y iOS físico.
- [ ] Equivalencia de flujos contra Expo demo y pruebas backend; revisar seguridad externa.
- [ ] Evidencia de los nueve gates de `release/readiness.json`; soporte, moderación, cumplimiento de edad y conservación.
- [ ] Solo con gates aprobados, decidir promoción a beta y luego producción en PR separado.

## Riesgos técnicos

1. Reescritura de UI a Flutter no es automática: evitar eliminar Expo antes de test de paridad.
2. Auth Supabase y los flujos de alta solo pueden habilitarse tras verificación operativa y políticas de edad/privacidad.
3. Reutilizar un proyecto Supabase existente es deseable, pero las escrituras a través del servicio deben preservar la semántica de RLS, auditoría y roles; un backend privilegiado puede saltar RLS si se implementa mal.
4. Separar cada tabla en un microservicio generaría acoplamiento y sobrecostos; definir límites según negocio.
5. Google Play y Apple requieren cuentas, cumplimiento de políticas, firmas y configuración; CI correcto no significa autorización de publicación.
6. No afirmar costo de hosting igual a USD 0 sin proyección y aprobación.

## Definition of Done (completa, no declarada aún)

- Apps Flutter operativas web/Android/iOS consumiendo APIs versionadas.
- Microservicios que implementan Gym Shield y seguridad con tests negativos y positivos.
- Despliegue DEV reproducible en nube; datos segregados sin modificar producción.
- Android Internal Testing e iOS TestFlight accesibles a QA autorizado.
- Documentación de arquitectura, seguridad, costos, observabilidad y rollback.
- Beta con usuarios reales condicionada a gates explícitos y revisión humana.
