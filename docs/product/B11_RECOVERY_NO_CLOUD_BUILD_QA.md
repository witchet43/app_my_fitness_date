# My Fitness Date · recuperación B5/B11 sin Google Cloud Build

Fecha de recuperación: 12 de noviembre de 2026 (México; ejecuciones de CI registradas en UTC el 13 de noviembre).
Estado: **QA técnica aprobada; no release; PR #77 DRAFT**.
El documento de referencia funcional sigue siendo `docs/product/B10_FITTED_84_REQUIREMENTS_AUDIT.md` y la política de lanzamiento `release/readiness.json`.

## Defectos encontrados y correcciones

| Defecto comprobado | Cambio realizado | Evidencia |
|---|---|---|
| Migración B11 contenía funciones PL/pgSQL con delimitadores `$` incompletos | Delimitadores `$$` reparados | 24 migraciones ejecutadas en PostgreSQL efímero |
| B5 guardaba `dating_enabled=false`; B11 requería `dating_enabled=true`, sin transición explícita | RPC de activación separada: requiere release global, edad independiente, consentimiento, membresía, perfil de ritmo, cuenta activa y gimnasio real; guardar preferencias sigue sin activar citas | Suite SQL de dos adultos sintéticos, activación y denegación |
| Gimnasios demo no podían constituir catálogo comercial real | Panel del mismo administrador, acceso MFA/AAL2, registro auditado de gimnasios, selección privada y modos A/B | SQL de permisos y widgets Flutter |
| Likes y chats previos podían reaparecer después de retiro y nuevo consentimiento | Época de consentimiento: exige nueva reciprocidad después del retiro, preservando evidencias de seguridad bajo revisión de retención | Integración PostgreSQL |
| El test heredado de dos JWT pretendía que verificar edad o configurar gimnasios habilitaba inmediatamente el descubrimiento, ignorando los gates nuevos | `scripts/local-auth-e2e.mts` exige descubrimiento vacío, activación B11 denegada, anonimato bloqueado y perfiles privados entre A/B con JWT emitidos por GoTrue local | GitHub Auth E2E real |

## Evidencia de validación (sin despliegue ni Cloud Build)

1. **Integración técnica completa, GitHub Actions**: [run #43373200546](https://github.com/witchet43/app_my_fitness_date/actions/runs/43373200546), `SUCCESS`: 62 pruebas Node, 24 migraciones + 21 pruebas SQL en PostgreSQL efímero, 8 pruebas Gym Shield, `flutter analyze --no-fatal-infos` exitoso, 75 widget tests Flutter.
2. **Correo y recuperación de contraseña de Auth local**: [run #43373628629](https://github.com/witchet43/app_my_fitness_date/actions/runs/43373628629), `SUCCESS`: confirmación vía Mailpit, código OTP, recuperación/cambio de contraseña, contraseña anterior rechazada y OTP de un solo uso.
3. **Dos cuentas Auth con JWT reales y RLS de PostgREST**: [run #43375861804](https://github.com/witchet43/app_my_fitness_date/actions/runs/43375861804), `SUCCESS`: registro/verificación por email de A/B, sesiones reales, anti-suplantación, datos privados, bloqueo de activación B11 por aprobación externa faltante, borrado solicitado y revocado, cierre y nuevo inicio de sesión.
4. El segundo y tercer run usan únicamente GitHub Actions con contenedores locales desechables. **Google Cloud Build usado por estos runs: 0 minutos.** No se creó `flutter build web`, APK, IPA, artefacto de distribución ni despliegue.

La prueba SQL permite temporalmente **solo dentro de una transacción revertida** simular requisitos externos satisfechos para ensayar matches y chat. **Eso no acredita que esos requisitos estén satisfechos en el proyecto alojado**. La prueba GoTrue con dos personas sintéticas reales de Auth mantiene el gate bloqueado, sin falsear moderación ni verificación independiente.

## Estado real del entorno alojado

- `main` productivo: sin cambiar ni fusionar PR #77.
- En el Supabase conectado, `public.member_rhythm_b11` y `app_private.fitdating_matches_b11` siguen sin instalar.
- Los controles globales de activación de FitDating permanecen `false`.
- `release/readiness.json`: canal `not_published`; los nueve gates de release `pending`.
- El endpoint QA B11 previamente desplegado **no representa una aplicación B11 operativa sin esas tablas**, por lo que no se debe publicitar una preview funcional.

## Criterio de uso inteligente de CI/CD

- Hasta completar funcionalidad + controles humanos, se hacen revisiones de fuente, SQL transaccional y pruebas GitHub sin compilar ni desplegar.
- **Una compilación/distribución** solo cuando existan pruebas de recorrido web real, autenticación e identidad, datos reales autorizados, privacidad/Gym Shield, app Android/iOS, soporte y controles legales/operativos.
- La liberación a producción requiere revisión de seguridad, consentimiento y aprobación explícita del propietario; ni un PR verde ni 75 widgets equivalen a aceptación comercial.
- No modificar flags de edad, moderación, privacidad ni release sin evidencia independiente. No simular usuarios, reportes o gimnasios reales.

## Pendientes no resueltos

Verificación independiente de edad, moderación atendida y SLA, marco legal/retención/erasure, fotografías moderadas, pruebas E2E contra backend alojado con dos miembros autorizados, autenticación de producción y configuración de correo real, pruebas Android/iOS físicas, accesibilidad WCAG 2.2 AA, cobertura ES/EN integral, entrevistas/validación de propuesta FITTED y revisión de seguridad independiente.

Conclusión: **se resolvió una brecha técnica de integración con pruebas reales y sin Cloud Build; la aplicación todavía no reúne los requisitos de lanzamiento comercial**.
