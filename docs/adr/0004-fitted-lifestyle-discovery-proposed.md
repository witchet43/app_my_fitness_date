# ADR-0004 — FITTED como hipótesis de compatibilidad lifestyle (NO APROBADA)

- **Estado:** PROPUESTA / DISCOVERY; **no** decisión aceptada.
- **Fecha de registro:** 2026-11-11.
- **Responsable de negocio:** pendiente de decisión del propietario.
- **Fuente:** `FITTED_Concepto_Exploratorio_Spanglish.pdf` (8 páginas, 2026; SHA-256 `d0f37a15dc172c605cd82aa30e8ba9790d9fdd809138ef0627206444b3bb01e8`).
- **Documentación relacionada:** [concepto](../product/FITTED_EXPLORATORY_CONCEPT_2026.md), [requisitos](../product/LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md), [brechas](../product/FITTED_GAP_ANALYSIS_DECISIONS.md), `AGENTS.md`, Estándar Maestro SaaS v1.9.

## Contexto

My Fitness Date ya contempla comunidad/actividades deportivas y la experiencia romántica opcional **FitDating**, con controles de Gym Shield, edad, privacidad y RLS. El PDF presenta un producto exploratorio **dating-first**, bilingüe LATAM, fundamentado en compatibilidad de hábitos cotidianos y expectativas románticas **más que en coincidencia del mismo deporte**.

Su concepto de marca **FITTED — Match your rhythm** no está validado. El PDF exige investigar mercado, competidores, trademark, dominios, apps stores, pronunciación y legal. Sus pesos de matching, business model y roadmap son hipótesis, no requisitos finalizados.

## Decisiones PROPUESTAS PARA DISCUSIÓN — no adoptadas

1. Considerar «How I Move / How I Live / How I Relate» como **candidato** de modelo de compatibilidad, priorizando privacidad por defecto y consentimiento.
2. Tratar **FITTED** y su lema únicamente como territorio creativo de investigación. Continuar usando **My Fitness Date** y **FitDating** mientras no exista aprobación de rebranding y due diligence.
3. Validar con participantes de diversas disciplinas si las explicaciones de compatibilidad ayudan más que la coincidencia del mismo deporte, sin inventar puntuaciones ni resultados.
4. Mantener reglas de Gym Shield y revisión externa de edad existentes; **no** interpretar la opción C del PDF como relajación de seguridad.
5. Conservar los módulos de comunidad existentes hasta resolver expresamente dating-first vs community-first. No eliminar módulos o alterar monetización por inferencia.
6. Preferir matching simple basado en reglas y razones comprensibles para el experimento inicial; no crear IA compleja ni wearables en MVP.

## Alternativas a evaluar

- **A:** conservar My Fitness Date community-first y enriquecer FitDating con el concepto.
- **B:** migrar My Fitness Date a dating-first, con repercusiones legales, UX, datos, marca y clientes existentes.
- **C:** producto/marca FITTED separada, reutilizando solo componentes y servicios autorizados.
- **D:** validar el concepto en prototipos sin decisiones de integración todavía.

**Criterios de comparación:** JTBD, valor validado, confianza, densidad local, costo, arquitectura, operación de moderación, edad, cumplimiento legal, marca y accesibilidad ES/EN.

## Consecuencias y límites mientras esté PROPUESTA

- Se autorizó **documentar y estudiar** el PDF en el repositorio; **no** se aprobó renombrar aplicaciones, añadir campos de salud/estilo de vida a PROD, mostrar fotos, activar chat, cambiar reglas de Gym Shield o monetizar.
- Cualquier proyecto de ingeniería debe partir de las decisiones D-01..D-14 y registrar criterios, evidencias y PRs.
- Las release gates `release/readiness.json` siguen sin aprobación automática; QA, edad verificada, moderación y privacidad anteceden a la exposición de datos de citas.
- Un nuevo ADR de aceptación o actualización con firma del decisor sustituirá el estado PROPUESTA; no modificar retroactivamente el PDF.

## Evidencia requerida para ACEPTAR

Investigación anónima 15–20 entrevistas, 2–3 perfiles de prueba, validación de Gym Shield, prototipos bilingües, revisión de privacidad, análisis de naming, prioridad de MVP, owner, fecha y referencia a decisión aprobada. Hasta entonces **sin conclusión de mercado o de preferencia real de usuarios**.
