# B8 · Candidato de integración — agenda privada y preparación de lanzamiento

Fecha: 2026-11-12. Estado: IMPLEMENTADO EN RAMA, pendiente de QA Flutter y navegador real. NO-GO producción y beta.

## Fuente de verdad
- PR base: #69, rama feature/b5-private-fitdating-readiness-20261112.
- B1–B5 técnicos están integrados en esa rama; B6 y B7 no tienen entregables independientes verificados.
- Presupuesto de compilaciones remotas: 7/10 consumidas; quedan 3. No usar ejecuciones para builds de corrección aislada.
- Estándar Maestro SaaS Factory v1.9 y AGENTS.md vinculantes.

## Resultado visible de B8
- La pantalla de perfil muestra **Tu próxima actividad** después del encabezado y antes de las secciones privadas.
- El dato se consulta de la API ya autenticada `GET /v1/me/activities`; no se inventan actividades, participantes, lugares ni fechas.
- Se muestra la próxima reserva futura confirmada. Se excluyen reservas canceladas y eventos cancelados; la API sigue siendo responsable de verificar identidad y autorización.
- Acceso directo a explorar actividades y revisar reservas; al volver se actualiza el resumen.
- Estados de carga, vacío, red fallida, reintento y pantalla angosta, con etiquetas accesibles.
- No incluye social abierto, chat, descubrimiento romántico o nuevas credenciales.

## Contratos verificables
1. Selección de la próxima reserva por fecha; exclusión de canceladas, pasadas y fechas inválidas.
2. Estado vacío honesto cuando no hay próximas confirmadas.
3. Error de carga sin mostrar datos previos obsoletos; reintento y recuperación.
4. Navegación a catálogo y reservas; actualización al regresar.
5. Regresión B1–B5: TypeScript, SQL estático, Flutter analyze + todos los widgets, Gym Shield.
6. Gate de E2E real con administrador MFA + 2 cuentas adultas invitadas; no atribuir a CI una prueba humana.
7. Respetar no autorización del lanzamiento; `release/readiness.json` sigue pendiente.

## Carryover y release
- **B6 identidad**: ya existe configuración global en vivo de B3, pero falta aceptación navegador con 2 cuentas y verificación visual.
- **B7 multiplataforma**: Flutter web se compila en QA; Android/iOS nativos, accesibilidad WCAG 2.2 AA y dispositivos físicos siguen pendientes.
- **B8 integración**: agenda privada y preparación de candidato. Falta navegador real, E2E RSVP concurrente, BOLA/IDOR, proveedor independiente de mayoría de edad, moderación, privacidad, bajas y aprobación del propietario.
- No merge a main, no activar OAuth/descubrimiento, no publicar producción, no probar con perfiles ficticios como si fueran reales.

## Evidencia
- Tests de selección/UI: `apps/flutter_client/test/member_dashboard_b8_test.dart`.
- Implementación: `apps/flutter_client/lib/src/features/member_dashboard_b8.dart`.
- Preflight local estático: `scripts/check_b8_static.py`.
