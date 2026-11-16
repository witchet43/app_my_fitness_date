# Build 9 — encontrar actividades reales, filtros y QA acumulada

Fecha: 2026-11-12. Rama `feature/b9-activity-discovery-20261112`. Issue #72.
**Estado:** implementación en rama para validación; **NO-GO beta ni producción**.

## Primera experiencia de valor
Un miembro con sesión válida necesita encontrar una actividad deportiva real y reservarla. La aplicación recibe únicamente el catálogo de la API autorizada; la pantalla de B1 añade filtrado de presentación sin abrir una API de búsqueda nueva, perfiles, gimnasios, horarios ni ubicación exacta.

Se implementaron:
- Buscar por título, disciplina o ciudad, sin sensibilidad a mayúsculas ni acentos.
- Filtros por deporte y ciudad generados únicamente desde el catálogo recibido.
- Mostrar solo próximas por defecto, con opción explícita para incluir actividades pasadas; próximas ordenadas por fecha ascendente, pasadas descendente.
- Eventos cancelados quedan fuera. No hay reservas ficticias, anuncios de proveedores ni participantes visibles.
- Estado vacío real y **sin resultados** diferenciados; botón para limpiar filtros, recarga y errores con reintento.
- Mis reservas, navegación, confirmación RSVP y organizadores originales sin cambio de autorización.
- Fixture B1 con año lejano para evitar fallos aleatorios dependientes de la fecha.

## Criterios de aceptación medibles
1. B9-01: actividad futura más próxima primero; eventos cancelados ausentes.
2. B9-02: búsqueda por ciudad sin acento y combinaciones deporte/ciudad.
3. B9-03: opción «Sólo próximas» y recuperación del historial cuando el usuario lo elige.
4. B9-04: listado no cambia por mutación de la función de filtrado; desempates estables.
5. B9-05: pantalla móvil y escritorio, 0 resultados explícitos, reiniciar filtros.
6. B9-06: permiso RSVP verificado por API previa y no liberado por filtros locales.
7. B9-07: ejecutar 1 CI remota B9 con todos los contratos B1–B5+B8+B9, Flutter, API QA y Git SHA idéntico en preview.
8. B9-08: no tocar main, publicar en beta, aprobar descubrimiento FitDating o alterar políticas de seguridad.

## Trazabilidad
- Base acumulada: PR #71 (B8), base de #71: PR #69 (B1–B5).
- GitHub Issue #72, PR B9 en borrador.
- Fuente: `apps/flutter_client/lib/src/core/activity_discovery_b9.dart`
- UI: `apps/flutter_client/lib/src/features/activities_b1.dart`
- Tests: `apps/flutter_client/test/activity_discovery_b9_test.dart`
- Static: `scripts/check_b9_static.py`
- Presupuesto: primera ejecución B9 #43337039505 consumió 9/10 y falló exclusivamente en interacción de widget móvil fuera del viewport (Dart analyze, Node, Gym Shield y API PASS). Corrección de prueba en rama; queda **1 ejecución remota máxima**, destinada a la validación consolidada de B9. No se declara preview publicada hasta comprobarla.

## Brechas que no se cierran por una CI verde
- B6: aceptación interactiva del cambio de branding por administrador MFA y dos cuentas.
- B7: pruebas reales Android/iOS y accesibilidad; build web no equivale a dispositivos físicos.
- Aprobación legal, privacidad y retención, borrado integral, operador de moderación, proveedor externo verificable de edad, seguridad BOLA/IDOR con distintas cuentas, E2E RSVP concurrente.
- `release/readiness.json` sigue NO-PUBLICADO y gates pendientes.
- Producción `main` y Edge API principal no se reemplazan.
