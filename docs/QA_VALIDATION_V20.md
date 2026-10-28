# QA release V20 — cierre de compilación y entrega controlada

**Fecha de comprobación:** 2026-10-28  
**Proyecto:** my_fitness_date  
**Rama de código compilado:** `release/deployment-ready-v20`  
**Commit exacto del APK:** `d2ea407123b0b49996c1868932fe70d9e97d6d49`  
**Destino permitido:** equipo Android interno de QA, sin datos reales.

## Evidencia técnica comprobada

| Comprobación | Resultado | Fuente |
| --- | --- | --- |
| CI MVP (TypeScript, tests, bundles, PostgreSQL y preflight) | PASS | [run 40607156094](https://github.com/witchet43/app_my_fitness_date/actions/runs/40607156094) |
| Local Auth E2E / Mailpit (entorno temporal) | PASS | [run 40607156222](https://github.com/witchet43/app_my_fitness_date/actions/runs/40607156222) |
| Android APK autónoma con JS integrado | PASS | [run 40607156150](https://github.com/witchet43/app_my_fitness_date/actions/runs/40607156150) |
| Archivo descargado, extraído y checksum contra log | PASS | Hashes abajo |
| Instalación y pruebas UI en Android físico | PENDIENTE | Sin evidencia de dispositivo |
| QA iOS Simulator / iPhone | PENDIENTE | Sin build verificado |
| Beta con usuarios reales | NO-GO | Nueve gates sin evidencia |

**APK de QA:** [GitHub Actions artifact #12781217299](https://github.com/witchet43/app_my_fitness_date/actions/runs/40607156150/artifacts/12781217299)  
**Nombre:** `app-release.apk` (en ZIP `my-fitness-date-v20-demo-android-apk`)  
**Tamaño APK extraído:** 69,163,425 bytes  
**SHA-256 APK:** `475ff286ffe1b5ec3645b39b79be530d63d3ba594dde21fe2054a0bb1a2b81d8`  
**SHA-256 ZIP de GitHub Actions:** `64be41d72ecfd3444d3b30840968b761839a49d4725ade4c41c4225cae683fbc`  
**Caducidad de artefacto GitHub:** 2026-11-04 00:17:49 UTC (política de 7 días).

Validación de estructura estática: `AndroidManifest.xml`, `classes.dex` y `assets/index.android.bundle` presentes; identificador `APK Sig Block 42` presente. Esto **no sustituye** la verificación criptográfica con `apksigner verify`, ni una instalación de prueba.

### Supabase DEV — verificación solo lectura

- Proyecto `my_fitness_date_dev` (`jtrdvnwbxpfdnbzasvcj`): `ACTIVE_HEALTHY`.
- 12 migraciones aplicadas hasta V18; V20 **no** introduce cambios de esquema.
- 0 usuarios Auth, 0 perfiles sociales, 0 publicaciones, 0 eventos, 0 verificaciones de edad, 0 moderadores y 0 denuncias.
- Las cinco tablas de `public` tienen RLS activo.
- Advisor de seguridad: 0 avisos CRITICAL/WARNING; 18 INFO `rls_enabled_no_policy` sobre tablas `app_private` deliberadamente sin políticas públicas.
- **No verificado:** configuración de registro de GoTrue desde Management API, SMTP hospedado y eliminación efectiva de cuenta real.

### Procedimiento de instalación Android para QA

1. Descargar el ZIP del artefacto de GitHub Actions y extraer `app-release.apk`.
2. Validar checksum SHA-256 del APK con la referencia anterior.
3. Instalar exclusivamente en un emulador o dispositivo personal de pruebas, habilitando instalación externa **solo para esta prueba**.
4. Abrir la aplicación sin un servidor Metro y confirmar que navega sin conexión al backend.
5. Revisar FitCommunity, FitTogether y FitDating, cambiar las modalidades Gym Shield y comprobar que no se admiten credenciales ni cuentas reales.
6. Ejecutar, si se dispone de Maestro configurado, `maestro test maestro/demo-navigation.yaml`.
7. Registrar dispositivo, Android version, resultado PASS/FAIL, capturas, fallos y versión exacta del APK.
8. No distribuir a usuarios reales ni presentar esta compilación como beta conectada.

### Riesgos y siguientes gates

- **NO-GO beta:** `release/readiness.json` mantiene 9 gates pendientes: correo/Auth hospedado, verificación de edad externa, moderación humana, privacidad y retención legal, eliminación Auth real E2E, QA Android físico, QA iOS físico, revisión independiente de seguridad y soporte/incidentes.
- El repositorio GitHub aparece **público**: revisar intencionalidad de visibilidad, historial, secretos y permisos antes de almacenar propiedad intelectual adicional o preparar la beta.
- El release en Gradle informó avisos de metaspace y deprecaciones; no impidieron construir el APK. Planificar mantenimiento del toolchain.
- El código compilado usa `EXPO_PUBLIC_MFD_DEMO_BUILD=YES`, que evita inicializar Supabase. Un APK offline aprobado **no demuestra** la funcionalidad de Auth hospedado ni los controles de acceso de extremo a extremo.

### Decisión operativa

**GO:** compartir la APK sintética con QA interno y ejecutar una prueba en dispositivo.  
**NO-GO:** fusionar a `main` sin aprobación de integración, abrir registro hospedado, beta pública o producción. PR #23 y #24 continúan como borradores.
