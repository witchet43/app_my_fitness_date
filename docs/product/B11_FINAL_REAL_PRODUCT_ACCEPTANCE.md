# Build 11 — ÚNICA candidata de cierre basada en FITTED
Fecha: 2026-11-12 (México). Issue #76. Rama `feature/b11-one-final-real-product-20261112`.
Documento fuente: `FITTED_Concepto_Exploratorio_Spanglish.pdf` (8 páginas); matriz previa: `docs/product/B10_FITTED_84_REQUIREMENTS_AUDIT.md`.

## Resultado orientado a la persona y no al despliegue
**En código fuente**, el perfil en tres capas cuenta con operaciones de lectura y guardado de preferencias por el propietario, condicionadas al consentimiento FitDating. **Estas operaciones aún no se han demostrado en el entorno alojado**, porque la migración `public.member_rhythm_b11` no se aplicó en el Supabase conectado y la última CI no completó PostgreSQL ni Flutter. No se publican nombres de gimnasios, franjas exactas ni ubicaciones; RLS exige propietario y consentimiento. Se pueden revocar consentimiento y ritmo en la misma operación segura.

La infraestructura también implementa perfiles candidatos explicables, interés bidireccional, matches, chat solo tras reciprocidad, reporte/bloqueo y propuestas de Active Date posteriores al match. La API usa JWT sin service_role y funciones privadas con controles de elegibilidad, suspensión, edad independiente, privacidad y cuotas; la UI no inventa personas y no puede levantar flags.

**Limitaciones no maquilladas:** este código no crea un proveedor de edad independiente, moderadores atendiendo reportes, fotografías moderadas, consentimiento legal validado, un catálogo completo de gimnasios no ficticios, un onboarding bilingüe integrado para todo el producto, ni entrevistas de clientes. Las cinco banderas de B5 siguen cerradas; sin ellas la API de citas niega acceso aunque el código exista. El flujo legado requiere además configurar un gimnasio real y reglas privadas Gym Shield antes de ser totalmente utilizable. Por tanto una prueba de API 401/403 y tests sintéticos no prueban matches reales. La UI B11 sigue esencialmente en español fuera del estudio bilingüe.

## Reconciliación de los ocho módulos del PDF
| Módulo | Implementación B11 | Criterio pendiente |
|---|---|---|
| 1. Onboarding | Auth/consentimiento/perfil B1, preferencias románticas B5, ritmos B11 | Integración ES/EN completa y radio de movilidad consentido |
| 2. Training DNA | Opciones y guardado real por dueño | Validación en navegador con adultos autorizados |
| 3. Life Rhythm | Sueño, semana/finde, alcohol opcional, comida, viajes, intereses | QA humana y revisión legal de finalidad/retención |
| 4. Relationship Rhythm | Intención, autonomía, entrenar juntos, prompts | QA funcional multiusuario y cultura de país |
| 5. Discovery | RPC con Gym Shield, códigos explicables y 403 por defecto | Proveedor edad, fotos moderadas, consentimiento y piloto real |
| 6. Gym Shield | Reutiliza reglas A/B de privacidad de gimnasio y buffer de 30 min | Probar con gimnasio real y revisar C; sin abrir por mera preferencia |
| 7. Mutual match + chat | RPC de interés, match recíproco, chat, bloqueo y reporte a moderación B4 | Auditoría antiabuso y staff real; gate edad y legal |
| 8. Active Date | Sugerencias rule-based desde RPC luego de match real | QA de no divulgación y valor humano |

## Gates de aceptación innegociables
1. **Suite técnica:** `npm test` con B11, `candidate:audit`, 24 migraciones SQL completas y `fitted_lifestyle_b11_integration.sql` en PostgreSQL efímero, Gym Shield pytest, hosted API 401, `flutter analyze` y `flutter test` en un solo run dedicado.
2. **Artifact SHA:** build Flutter web `0.28.0+28`, despliegue QA solamente `b11-preview`, SHA remoto idéntico al commit revisado.
3. **Backend:** `member-api-b11-preview` aislado; la función producción `member-api-v26` no se reemplaza. El despliegue de migración en la DB alojada requiere SQL verificado y no habilita el sistema de citas.
4. **Seguridad:** `release/readiness.json` mantiene `not_published` y 9 `pending`, además los 5 flags de `fitdating_gate_b5` siguen `false`. No hay publicación romántica ni autoaprobación.
5. **Experiencia humana:** prueba de dos cuentas adultas reales bajo QA, MFA administrativo, consentimiento/revocación/baja, navegadores ES/EN, Android/iOS reales y accesibilidad; sin ejecutar NO reportar aceptación comercial.
6. **Negocio/legal:** 15–20 entrevistas, branding FITTED/trademark, política y soporte operativo verificables; no falsear investigación o contratar proveedores/gastos sin autorización.

## Política final
- Candidato único: NO repetir builds en caso de fallo; documentar exactamente el error y mantener el PR en Draft.
- Solo se permite merge/producción si todas las verificaciones externas y requerimientos de release están probados y un propietario lo aprueba de manera informada.
- Un éxito en CI no es equivalencia a producto comercial terminado.

## Resultado real de la única ejecución B11 (sin suposiciones)

- Ejecución: https://github.com/witchet43/app_my_fitness_date/actions/runs/43368513212; **FAILURE** en `Node and SQL contracts B1+B2+B3+B5`.
- 62 pruebas Node pasaron, `npm run candidate:audit` aprobó la reconciliación de 24 migraciones.
- Causa: `scripts/check_b5_static.py` exigía el tipo `DatingRepositoryB5` escrito directamente, aunque B11 lo extiende; contrato de comprobación corregido en commit posterior `9a52dc00beb2d81e36d89a811f41050cab8d38ab`.
- PostgreSQL, Gym Shield, Flutter analyzer/widgets, Flutter web y Cloudflare B11: **NO EJECUTADOS**. **No existe preview B11 validada** y la URL B10 corresponde exclusivamente a B10.
- Migración B11: **SOLO EN REPOSITORIO**; no se aplicó a Supabase conectado. API QA `member-api-b11-preview` sí existe pero sus rutas B11 dependen de una tabla no instalada, por lo que no se debe presentar como producto funcionando.
- No se repetirá ni ocultará el error bajo una ejecución nueva. El PR B11 permanece en borrador; producción `main` y los 9 release gates permanecen sin cambios.
