# Documentación de producto — My Fitness Date / FitDating

**Fuente de verdad para requisitos de producto versionados dentro del repositorio.** El estándar transversal de ingeniería continúa siendo [SaaS Factory v1.9](https://docs.google.com/document/d/11hytKADuIUpmWzHEmAfZwcYNJ04M7n1ev4A1fbeZy9Q/edit). Los archivos aquí describen hipótesis, decisiones y planes: no prueban que una funcionalidad exista en producción.

## Producto existente y nueva exploración

- **Marca actual:** **My Fitness Date**. La experiencia romántica es **FitDating** (opt-in y exclusivamente para adultos autorizados).
- **Nuevo concepto exploratorio:** **FITTED — Match your rhythm**. Nombre, posicionamiento dating-first, mercado, business model y roadmap **no aprobados**. Leer primero [síntesis del PDF](FITTED_EXPLORATORY_CONCEPT_2026.md).
- **Matriz de 84 referencias a requisitos/controles:** [LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md](LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md) (IDs F/E/N, origen por página y criterios propuestos).
- **Lo existente vs. lo planteado:** [FITTED_GAP_ANALYSIS_DECISIONS.md](FITTED_GAP_ANALYSIS_DECISIONS.md) (D-01..D-14 abiertas; no cambiar de marca ni desactivar comunidad por inferencia).
- **Estado formal del enfoque:** [ADR-0004 — exploración no aprobada](../adr/0004-fitted-lifestyle-discovery-proposed.md).

## Documentación de descubrimiento histórica que se conserva

- [Discovery anterior: comunidad y actividades](DISCOVERY_BRIEF.md).
- [Aprendizajes de clientes (SIN_DATOS)](CUSTOMER_LEARNINGS.md).
- [Experimentos](EXPERIMENTS.md).
- [Métricas y primer valor original](VALUE_METRICS.md).
- [MVP técnico histórico](../MVP.md).
- [Auditoría visual Active Chemistry V25](../design/ACTIVE_CHEMISTRY_AUDIT_V25.md).
- [Gates de release](../../release/readiness.json).

## Proveniencia del documento FITTED

- Archivo suministrado por el propietario: **`FITTED_Concepto_Exploratorio_Spanglish.pdf`**, 8 páginas, 140008 bytes.
- SHA-256 (verificación de integridad): `d0f37a15dc172c605cd82aa30e8ba9790d9fdd809138ef0627206444b3bb01e8`.
- El PDF fuente **no está alojado en este repositorio**: las páginas han sido documentadas en Markdown legible y trazado; para una auditoría de frases originales se requiere conservar el PDF adjunto por separado.
- **Protocolo:** no añadir conclusiones de investigación inventadas, no marcar requisitos como aprobados sin decisión, y no confundir CI verde con aprobación legal/edad/moderación o beta.

## Lectura recomendada para un nuevo sprint

1. Leer [origen](FITTED_EXPLORATORY_CONCEPT_2026.md) y [brechas](FITTED_GAP_ANALYSIS_DECISIONS.md).
2. Elegir decisión concreta D-xx; documentar decisión de producto con su dueño y evidencia.
3. Convertir F/E/N a issues con criterios verificables, impacto en datos, riesgos y prioridades aprobadas.
4. Enlazar issue → PR → pruebas → release; revisar el Estándar Maestro v1.9 y el estado `release/readiness.json` antes de desplegar.

**Estado:** documentación incorporada para análisis; no hay autorización para renombrar el producto ni activar dating/chat/mensajería o nuevos tratamientos de datos.
